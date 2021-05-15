TESTPC  SEGMENT
        ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
        ORG 100H
START:  JMP BEGIN
; Данные
string_available_size  db 'Available memory:','$'
amount_available_mem   db '        b','$'
string_extended_size   db 'Extended memory:','$'
exstended_mem_size     db '        kb','$'
mcb 	               db 'List of MCB:','$'
MCB_type               db 'MCB type: 00h' ,'$'
PSP_adress 	           db 'PSP adress: 0000h','$'
size_s 	               db 'Size:          b','$'
endl	               db  13, 10, '$'
tab		               db 	9,'$'

; Процедуры
;-----------------------------------------------------
TETR_TO_HEX PROC near 
            and AL,0Fh
            cmp AL,09
            jbe NEXT
            add AL,07
NEXT:   add AL,30h
        ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
; Байт в AL переводится в два символа шестн. числа AX
            push CX
            mov AH,AL
            call TETR_TO_HEX
            xchg AL,AH
            mov CL,4
            shr AL,CL
            call TETR_TO_HEX ; В AL Старшая цифра 
            pop CX           ; В AH младшая цифра
            ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_DEC proc near
    push 	cx
    push 	dx
    mov  	cx, 10
wloop_bd:   
    div 	cx
    or  	dl, 30h
    mov 	[si], dl
    dec 	si
	xor 	dx, dx
    cmp 	ax, 10
    jae 	wloop_bd
    cmp 	al, 00h
    je 		wend_l
    or 		al, 30h
    mov 	[si], al
wend_l:      
    pop 	dx
    pop 	cx
    ret
WRD_TO_DEC endp
;-------------------------------
WRD_TO_HEX PROC near
; Перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа   
        push BX
        mov BH,AH
        call BYTE_TO_HEX
        mov [DI],AH
        dec DI
        mov [DI],AL
        dec DI
        mov AL,BH
        call BYTE_TO_HEX
        mov [DI],AH
        dec DI
        mov [DI],AL
        pop BX
        ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC PROC near
; Перевод в 10с/с, SI - адрес поля младшей цифры 
        push CX
        push DX
        xor AH,AH
        xor DX,DX
        mov CX,10
loop_bd: div CX
        or DL,30h
        mov [SI],DL
        dec SI
        xor DX,DX
        cmp AX,10
        jae loop_bd
        cmp AL,00h
        je end_l
        or AL,30h
        mov [SI],AL
end_l: pop DX
      pop CX
      ret
BYTE_TO_DEC ENDP

PRINT  PROC NEAR    ; вывод строки на экран
      push ax
      mov ah, 9h
      int 21H
      pop ax
      ret
PRINT ENDP

AVAILABLE_MEMORY_SIZE PROC NEAR
	mov ah, 4Ah
 	mov bx, 0FFFFh
 	int 21h
	mov dx, offset string_available_size
	call PRINT
	xor	dx, dx
	mov ax, bx
	mov cx, 16
	mul cx
	mov si, offset amount_available_mem+7
	call WRD_TO_DEC
	mov dx, offset amount_available_mem
	call PRINT
	mov	dx, offset endl
    call PRINT
	;освобождение памяти
    mov 	ax,offset SegEnd
    mov 	bx, 10h
    xor 	dx, dx
    div 	bx
    inc 	ax
    mov 	bx, ax
    mov 	al, 0
    mov 	ah, 4Ah
    int 	21h
 	ret
AVAILABLE_MEMORY_SIZE ENDP

EXTENDED_MEMORY_SIZE PROC NEAR
	mov	al, 30h
	out	70h, al
	in	al, 71h
	mov	bl, al ;младший байт
	mov	al, 31h
	out	70h, al
	in	al, 71h ;старший байт
	mov	ah, al
	mov	al, bl
	mov	si, offset exstended_mem_size +7
	xor dx, dx
	call WRD_TO_DEC
	mov	dx, offset string_extended_size
	call PRINT
	mov	dx, offset exstended_mem_size
	call PRINT
	mov	dx, offset endl
    call PRINT
	ret
EXTENDED_MEMORY_SIZE ENDP

PRINT_SYMB PROC NEAR
	push	ax
	push	dx
	mov		ah, 02h
	int		21h
	pop		dx
	pop		ax
	ret
PRINT_SYMB ENDP

PRINT_LIST_MSB PROC NEAR
	mov	dx, offset mcb
    call PRINT
	mov	dx, offset endl
    call PRINT
	mov	ah, 52h
    int 21h
    mov ax, es:[bx-2]
    mov es, ax
block_start:
	;тип MCB
	mov al, es:[0000h]
    call BYTE_TO_HEX
    mov	di, offset MCB_type+10
    mov [di], ax
    mov	dx, offset MCB_type
    call PRINT
    mov	dx, offset tab
    call PRINT  
    ;адрес PSP   
    mov ax, es:[0001h]
    mov di, offset PSP_adress+15
    call WRD_TO_HEX 
    mov	dx, offset PSP_adress
    call PRINT
    mov	dx, offset tab
    call PRINT 
    ;размер участка в параграфах
    mov ax, es:[0003h]
    mov cx, 10h 
    mul cx
	mov	si, offset size_s+13
    call WRD_TO_DEC
    mov	dx, offset size_s
    call PRINT  
    mov	dx, offset tab
    call PRINT
    ;выводим последние 8 байт
    push ds
    push es
    pop ds
    mov dx, 08h
    mov di, dx
    mov cx, 8
last_8_byte:
	cmp	cx,0
	je	next_or_exit
    mov	dl, byte PTR [di]
    call PRINT_SYMB
    dec cx
    inc	di
    jmp	last_8_byte
next_or_exit:    
	pop ds
	mov	dx, offset endl
    call PRINT
    ;проверка на последний блок
    cmp 	byte ptr es:[0000h], 5ah
    je 		quit
    ;адрес следующего блока
    mov ax, es
    add ax, es:[0003h]
    inc ax
    mov es, ax
    jmp block_start
quit:
	ret
PRINT_LIST_MSB ENDP

;-------------------------------
; КОД
BEGIN:
        call AVAILABLE_MEMORY_SIZE
		call EXTENDED_MEMORY_SIZE
		call PRINT_LIST_MSB
; Выход в DOS
        xor AL,AL
        mov AH,4Ch
        int 21H
SegEnd:
TESTPC  ENDS
        END START ; Конец модуля, START - точка входа
