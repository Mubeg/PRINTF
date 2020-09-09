.model tiny
.code
org 100h

color = 07h

public printf
extrn  memcpy_add_attr:proc
extrn            strchr:proc
extrn  strcpy_add_attr:proc
extrn           str2chr:proc

start:
	mov ax, 0b800h
	mov es, ax

	push 2222
	mov cx, 1231
	mov dx, 2222
	mov si, offset input_string
	mov di, offset format_string
	call printf

	mov ax, 4c00h
	int 21h
;-------------------------------------------------------------------------------;
;Input
;	parameters: 
;	printf(form_str:addr, param_1, param2, param3, ...)
;		format_string: ["text"%(p/s/c/d/f)"text"] !"%%" for % as text!
;		param_i is placed --->  format_string[%(p/s/c/d/f)#i]
;		...  ===  fastcall with di, si, dx, cx
;Output
;	ax = 0 	if no error
;	ax = n  if error on n's '%'
;
;presumed : ds - data segment
;destroyed: ax, es, di, si, dx, cx, bx
; 
;----------------------------------------------------------------------------;

printf proc
	push bp
	mov bp, sp
			; di - format:addr (format:seg = ds)
			; si - param_1
			; dx - param_2
			; cx - param_3

	push dx cx ds			; convinient for [bp - 2*bx]
	mov cx, si 				; cx = cur_param
	mov si, 0040h
	mov ds, si
	mov si, 0062h

	lodsb 					; active page_num
	mov ah, 0h
	add ax, 0050h
	mov si, ax
	lodsw					; dx = cursor clm|row (low|hi) in active page
	mov dx, ax

	mov si, 04eh
	lodsw					; cx = page_offset
	push cx
	mov cx, ax

	mov si, 0b800h
	mov es, si
	mov si, di

	mov al, dh
	mov bl, 0a0h
	mul bl
	mov dh, 0h
	add dl, dl
	add ax, dx		; ax = [160*dh + 2*dl]
	add ax, cx
	mov di, ax
		 	; di = carr addr

pop cx ds
mov bx, 0  		; bx - param counter
			; es - output:seg
			; di - output:addr
			; si - format:addr (ds - seg)





	
find_%or_slash:	
	push bx cx si		; cx - cur_param
	mov bx, '%' ; for str2chr
	mov cx, '\'	
	call str2chr
	pop si cx
	cmp ax, 0
	jne not_finish
	jmp finish 		;not enough jump
not_finish:


	push ax

	sub ax, si
	mov dx, ax	; dx = ax - si
	mov al, color

	call memcpy_add_attr

	pop si
	inc si		; si = &'%'+1
	
	cmp bx, '%'	; found '%' or '\'
	pop bx
	jne commands

formating:
	lodsb
	cmp al, 'p'
	je do_pointer
	cmp al, 's'
	je do_string
	cmp al, 'c'
	je do_char
	cmp al, 'd'
	je do_decimal
	cmp al, 'f'
	je do_float
	cmp al, '%'
	je do_%
	jmp error
		
			; es = out:seg
			; di = out:adr
			; ax - destroyed
do_pointer:
	mov ax, '0x'
	stosw
	mov ax, cx	; print "0x%ADDR%"
	jmp end_switch_form

do_string:
	push si
	mov si, cx
	mov ah, color
	call strcpy_add_attr
	pop si
	sub di, 2		; start writing from \0
	jmp end_switch_form

do_char:
	mov al, cl
	mov ah, color
	stosw
	jmp end_switch_form

do_decimal:
	mov ax, cx
	stosw
	jmp end_switch_form

do_float:

	mov ax, cx
	stosw
	jmp end_switch_form

do_%:
	mov al, '%'
	mov ah, color
	stosw
	jmp find_%or_slash
	
end_switch_form:
	inc bx		; used 1 param

	cmp bx, 3
	jl get_local_mem

	mov ax, bx
	sub ax, 1			;             word    n_param   push bp ret
	add ax, ax			;	            |         |      |   |
	add bp, ax			;               |         |      |   |
	mov cx, word ptr [bp]		; [bp + 2 * (bx - 3)  +  2 + 2]
	sub bp, ax	
				; cx = next_param
	jmp find_%or_slash

get_local_mem:
	mov ax, bx
	add ax, ax

	sub bp, ax
	mov cx, word ptr [bp] ;  [bp - 2*bx]
	add bp, ax

	jmp find_%or_slash


commands:
	lodsb
	cmp al, 'n'
	je do_new_line
	cmp al, 'r'
	je do_ret_carr
	cmp al, '\'
	je do_slash
	jmp error
		
			; es = out:seg
			; di = out:adr
			; ax - destroyed
do_new_line:
	push bx

	mov ax, di
	mov bl, 0a0h
	div bl

	mov al, ah
	mov ah, 0h
	sub di, ax

	mov bh, 0h
	add di, bx

	pop bx
	jmp end_switch_comm

do_ret_carr:
	push bx

	mov ax, di
	mov bl, 0a0h
	div bl

	mov al, ah
	mov ah, 0h
	sub di, ax

	pop bx
	jmp end_switch_comm

do_slash:
	mov al, '\'
	mov ah, color
	stosw
	jmp find_%or_slash
	
end_switch_comm:
	jmp find_%or_slash







error:
	mov sp, bp
	pop bp
	mov ax, cx
	ret

finish:
	mov ah, color
	call strcpy_add_attr

done:
	mov ax, di
	mov bl, 0a0h
	div bl

	mov dh, al

	mov bl, 02h
	mov al, ah
	mov ah, 0h
	div bl
	sub al, 01h		; set cursor to '\0'
	mov dl, al

	mov bh, 0h
	mov ax, 0200h
	int 10h 		; set cursor to end


	cmp dh, 25
	jl no_scroll

	mov ax, 0500h
	int 10h
;	mov al, dh
;mov al, 2;	sub al, 25
;	mov ah, 6h
;	mov bh, color
;	mov dx, 0h
;	mov ch, 24
;	mov cl, 79
;	int 10h  ; scroll 

no_scroll:
	mov sp, bp
	pop bp
	ret

endp



.data
format_string: 		db 'Hello, %s\\! \rYour %% age is [%d]. {%f} = %d\nlalaq', 0
input_string:  		db 'Nikitalllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaallllllllllllllllllllllllllllllka',

end	 start