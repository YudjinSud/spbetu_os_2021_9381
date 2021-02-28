AStack    SEGMENT  STACK
AStack    ENDS

DATA SEGMENT
    PC_INFO     db 'PC type: ', '$'
    PC          db 'PC',13,10,'$'
    PC_XT       db 'PC/XT',13,10,'$'
    AT          db 'AT',13,10,'$'
    PS2_30      db 'PS2 model 30',13,10,'$'
    PS2_80      db 'PS2 model 80',13,10,'$'
    PC_jr       db 'PCjr',13,10,'$'
    PC_Convertible db 'PC Convertible',13,10,'$'
    PC_Unknown  db 'PC unknown',13,10,'$'

    MSDOS_VERSION_INFO db 'MSDOS  version: ', '$'
    MSDOS_VERSION DB '  .  ', 13, 10, '$'
    OEM_VERSION_INFO   db 'OEM  version: ', '$'
    OEM_VERSION   db '  ',13,10,'$'
    USER_NUMBER_INFO   db 'User serial number : $'
    USER_NUMBER   db '        ',13,10,'$'
DATA ENDS

CODE SEGMENT
		ASSUME CS:CODE, DS:DATA, SS:AStack
		ORG 100H
START: 	JMP	BEGIN

;ПРОЦЕДУРЫ
;--------------------------------------------------------------------------------
; Перевод тетрады (4-ех младших байтов AL) в 16-ичную СС и ее представление в виде символа
TETR_TO_HEX PROC NEAR
	and al, 0Fh
	cmp al, 09
	jbe next
	add al, 07
next:
	add al, 30h
	ret
TETR_TO_HEX ENDP

; Перевод байта AL в 16-ичную СС и его представление в виде символов
BYTE_TO_HEX PROC NEAR
	push cx
	mov ah, al
	call TETR_TO_HEX
	xchg al, ah
	mov cl, 4
	shr al, cl
	call TETR_TO_HEX
	pop cx
	ret
BYTE_TO_HEX ENDP

; Перевод слова AX в 16-ичную СС и его представление в виде символов
WORD_TO_HEX PROC NEAR
	push bx
	mov bh, ah
	call BYTE_TO_HEX
	mov [di], ah
	dec di
	mov [di], al
	dec di
	mov AL, bh
	call BYTE_TO_HEX
	mov [di], ah
	dec di
	mov [di], al
	pop bx
	ret
WORD_TO_HEX ENDP

; Перевод байта AL в 10-ичную СС и его представление в виде символов
BYTE_TO_DEC PROC NEAR
	push cx
	push dx
	xor ah, ah
	xor dx, dx
	mov cx, 10
loop_bd:
	div cx
	or dl,30h
	mov [si], dl
	dec si
	xor dx, dx
	cmp ax, 10
	jae loop_bd
	cmp al, 00h
	je end_l
	or al, 30h
	mov [si], al
end_l:
	pop dx
	pop cx
	ret
BYTE_TO_DEC ENDP

; Вызывает функцию вывода строки на экран
PRINT PROC NEAR
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP

;--------------------------------------------------------------------------------


PRINT_PC_TYPE PROC NEAR
    mov ax, 0F000h
	mov es, ax
	mov al, es:[0FFFEh]
    mov dx, offset PC_INFO
    call PRINT
    cmp al, 0ffh
    je pc_msg
    cmp al, 0feh
    je pc_xt_msg
    cmp al, 0fbh
    je pc_xt_msg
    cmp al, 0fch
    je at_msg
    cmp al, 0fah
    je ps2_30_msg
    cmp al, 0f8h
    je ps2_80_msg
    cmp al, 0fdh
    je pcjr_msg
    cmp al, 0f9h
    je pc_conv_msg
    jmp pc_undef_msg
pc_msg:
    mov dx, offset PC
    jmp print_call
pc_xt_msg:
    mov dx, offset PC_XT
    jmp print_call
at_msg:
    mov dx, offset AT
    jmp print_call
ps2_30_msg:
    mov dx, offset PS2_30
    jmp print_call
ps2_80_msg:
    mov dx, offset PS2_80
    jmp print_call
pcjr_msg:
    mov dx, offset PC_jr
    jmp print_call
pc_conv_msg:
    mov dx, offset PC_Convertible
    jmp print_call
pc_undef_msg:
    mov dx, offset PC_Unknown
    jmp print_call
print_call:
    call PRINT
    ret
PRINT_PC_TYPE ENDP


PRINT_MSDOS_VERSION PROC NEAR
    mov ah, 30h
    int 21h

    mov si, offset MSDOS_VERSION + 1
    mov ch, ah
    call BYTE_TO_DEC
    mov al, ch
    add si, 3
    call BYTE_TO_DEC
    mov dx, offset MSDOS_VERSION_INFO
    call PRINT
    mov dx, offset MSDOS_VERSION
    call PRINT

    mov al, bh
    call BYTE_TO_HEX
    mov di, offset OEM_VERSION
    mov [di], ax
    mov dx, offset OEM_VERSION_INFO
    call PRINT
    mov dx, offset OEM_VERSION
    call PRINT

    mov al, bl
    call BYTE_TO_DEC
    mov di, offset USER_NUMBER
    mov [di], ax
    mov ax, cx
    add di,5
    call WORD_TO_HEX
    mov dx, offset USER_NUMBER_INFO
    call PRINT
    mov dx, offset USER_NUMBER
    call PRINT

    ret
PRINT_MSDOS_VERSION ENDP


BEGIN:
	push  ds
    sub   ax, ax
    push  ax
    mov   ax, DATA
    mov   ds, ax
	call PRINT_PC_TYPE
	call PRINT_MSDOS_VERSION

	xor		al, al
	mov 	ah, 4ch
	int		21h
	ret

CODE 	ENDS
		END  	START
