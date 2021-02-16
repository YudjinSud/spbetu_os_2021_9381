TESTPC SEGMENT
		ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG 100H
START: 	JMP	BEGIN

;ДАННЫЕ
PC_Type			db	'PC Type:  ', 0dh, 0ah,'$'
Mod_numb		db	'Modification number:  .  ', 0dh, 0ah,'$'
OEM				db	'OEM:   ', 0dh, 0ah, '$'
S_numb	    db	'Serial Number:       ', 0dh, 0ah, '$'

;ПРОЦЕДУРЫ
;--------------------------------------------------------------------------------
;печать строки
PRINT_STRING PROC near
		mov 	ah, 09h
		int		21h
		ret
PRINT_STRING ENDP

;--------------------------------------------------------------------------------
;перевод десятичной цифры в код символа
TETR_TO_HEX		PROC	near
		and		al, 0fh ;логическое умножение всех пар битов
		cmp		al, 09
		jbe		NEXT ;Переход если ниже или равно
		add		al, 07
NEXT:	add		al, 30h
		ret
TETR_TO_HEX		ENDP

;--------------------------------------------------------------------------------
;перевод байта 16 с.с в символьный код
;байт в AL переводится в два символа шестнадцетиричного числа в AX
BYTE_TO_HEX		PROC near
		push	cx
		mov		al, ah
		call	TETR_TO_HEX
		xchg	al, ah
		mov		cl, 4
		shr		al, cl ;логический сдвиг вправо
		call	TETR_TO_HEX ;в AL старшая цифра
		pop		cx 			;в AH младшая
		ret
BYTE_TO_HEX		ENDP

;--------------------------------------------------------------------------------
;перевод в 16 с/с 16-ти разрядного числа
;в АХ - число, DI - адрес последнего символа
WRD_TO_HEX		PROC	near
		push	bx
		mov		bh, ah
		call	BYTE_TO_HEX
		mov		[di], ah
		dec		di
		mov		[di], al
		dec		di
		mov		al, bh
		xor		ah, ah
		call	BYTE_TO_HEX
		mov		[di], ah
		dec		di
		mov		[di], al
		pop		bx
		ret
WRD_TO_HEX		ENDP

;--------------------------------------------------------------------------------
;перевод байта 16 с.с в символьный код 10 с.с
;si - адрес поля младшей цифры
BYTE_TO_DEC		PROC	near
		push	cx
		push	dx
		push	ax
		xor		ah, ah
		xor		dx, dx
		mov		cx, 10
loop_bd:div		cx
		or 		dl, 30h
		mov 	[si], dl
		dec 	si
		xor		dx, dx
		cmp		ax, 10
		jae		loop_bd
		cmp		ax, 00h
		jbe		end_l
		or		al, 30h
		mov		[si], al
end_l:	pop		ax
		pop		dx
		pop		cx
		ret
BYTE_TO_DEC		ENDP

;--------------------------------------------------------------------------------
BEGIN:
		;PC_Type
		push	es
		push	bx
		push	ax
		mov 	bx, 0F000h
		mov 	es, bx
		mov 	ax, es:[0FFFEh]
		mov 	ah, al
		call	BYTE_TO_HEX
		lea		bx, PC_Type
		mov 	[bx + 9], ax; смещение на количество символов
		pop		ax
		pop 	bx
		pop 	es

		;Mod_numb
		mov 	ah, 30h
		int		21h
		push	ax
		push	si
		lea		si, Mod_numb
		add		si, 21
		call	BYTE_TO_DEC
		add		si, 3
		mov 	al, ah
		call   	BYTE_TO_DEC
		pop 	si
		pop 	ax

		;OEM
		mov 	al, bh
		lea		si, OEM
		add		si, 7
		call	BYTE_TO_DEC

		;S_numb
		mov 	al, bl
		call	BYTE_TO_HEX
		lea		di, S_numb
		add		di, 15
		mov 	[di], ax
		mov 	ax, cx
		lea		di, S_numb
		add		di, 20
		call	WRD_TO_HEX

		lea		dx, PC_Type
		call	PRINT_STRING
		lea		dx, Mod_numb
		call	PRINT_STRING
		lea		dx, OEM
		call 	PRINT_STRING
		lea		dx, S_numb
		call	PRINT_STRING

		xor		al, al
		mov 	ah, 4ch
		int		21h
		ret
TESTPC 	ENDS
		END  	START
