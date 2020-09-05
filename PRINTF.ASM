.model tiny
.code
org 100h

public fprintf
extrn memcpy:proc
extrn strchr:proc
extrn strcpy:proc

start:
	mov ax, 0b800h
	mov es, ax

	push 1231	; float (= num*1000)
	push 19		; age
	mov cx, offset  input_string  ; Name
	mov dx, offset format_string
	mov si, offset output_string
	mov di, ds
	call fprintf

	mov ax, 4c00h
	int 21h
;-------------------------------------------------------------------------------;
;Input
;	parameters: 
;	fprintf(o_str:seg, o_str:addr, form_str:seg, form_str:addr, param_1, ...)
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

fprintf proc
	push bp
	mov bp, sp
			; di - output:seg
			; si - output:addr
			; dx - format:addr (format:seg = ds)
			; cx - param_1

	mov bx, 0  	; param counter
	mov es, di
	mov di, si
	mov si, dx	; es - output:seg
			; di - output:addr
			; si - format:addr (ds - seg)
	
find_%:	
	push di si		; cx - cur_param
	mov di, '%' ; for strchr	
	call strchr
	pop si di
	cmp ax, 0
	je finish

	push ax

	sub ax, si
	mov dx, ax	; dx = ax - si

	call memcpy

	pop si
	inc si		; si = &'%'+1
	
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
	jmp end_switch

do_string:
	push si
	mov si, cx
	call strcpy
	pop si
	jmp end_switch

do_char:
	mov ax, cx
	stosb
	jmp end_switch

do_decimal:
	mov ax, cx
	stosb
	jmp end_switch

do_float:

	mov ax, cx
	stosb
	jmp end_switch

do_%:
	mov ax, '%'
	stosb
	jmp find_%
	
end_switch:
	inc bx		; used 1 param

	mov ax, bx
	inc ax				;      word  push bp
	add ax, ax			;	|      |
	add bp, ax			;       |      |
	mov cx, word ptr [bp]		; [bp + 2*bx + 2]
	sub bp, ax	
				; cx = next_param
	jmp find_%

error:
	mov sp, bp
	pop bp
	mov ax, cx
	ret

finish:
	call strcpy

done:
	mov sp, bp
	pop bp
	ret

endp



.data
format_string: db 'Hello, %s! Your %% age is [%d]. {%f}', 0
input_string:  db 'Nikita', 0
output_string: db '00000000000000000000000000000000000000000000000000',0

end	 start