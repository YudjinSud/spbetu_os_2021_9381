
TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	 ORG 100H
START: JMP BEGIN

;ДАННЫЕ
pc_type_text DB 'type of PC - ', '$'
pct_1 DB 'PC', 0DH, 0AH, '$'
pct_2 DB 'PC/XT', 0DH, 0AH, '$'
pct_3 DB 'AT', 0DH, 0AH, '$'
pct_4 DB 'PS2 model 30', 0DH, 0AH, '$'
pct_5 DB 'PS2 model 50 or 60', 0DH, 0AH, '$'
pct_6 DB 'PS2 model 80', 0DH, 0AH, '$'
pct_7 DB 'PCjr', 0DH, 0AH, '$'
pct_8 DB 'PC Convertible', 0DH, 0AH, '$'
pct_unknown DB '     error. Unknown', 0DH, 0AH ,'$'
System_version DB 'System version:  .  ',0DH, 0AH, '$'
OEM DB 'OEM:   ', 0DH, 0AH, '$'
user_number DB 'Serial user number:       ',0DH, 0AH, '$'

;процедуры
TETR_TO_HEX PROC near ;представляет 4 младших бита al в виде цифры 16-ой с.сч. и представляет её в символьном виде
	 and AL,0Fh
	 cmp AL,09
	 jbe NEXT
	 add AL,07
NEXT: 
	 add AL,30h ; результат в al
	 ret
TETR_TO_HEX ENDP
;----------------------------------

BYTE_TO_HEX PROC near
; байт в al переводится в 2 символа шест. числа в AX
	 push CX
	 mov AH,AL
	 call TETR_TO_HEX
	 xchg AL,AH
	 mov CL,4
	 shr AL,CL
	 call TETR_TO_HEX ;в AL старшая цифра
	 pop CX ;в AH 	младшая
	 ret
BYTE_TO_HEX ENDP
;-------------------------------  
WRD_TO_HEX PROC near
; перевод в 16 с/c 16-ти разрядного числа
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

;---------------------------------
BYTE_TO_DEC PROC near
; перевод в 10 с/c. SI - адрес поля младшей цифры
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
end_l: 
	   pop DX
	   pop CX
	   ret
BYTE_TO_DEC ENDP

WRITE PROC NEAR
	push ax
	mov   AH, 9
    int   21h  ; Вызов функции DOS по прерыванию
	pop ax
    ret
WRITE ENDP

GET_PC_TYPE PROC NEAR ; получение типа PC
	push ax
	push dx
	push es
	mov ax, 0F000h 
	mov es, ax
	mov al, es:[0FFFEh]
	mov dx, offset pc_type_text
	call WRITE
	
	cmp al, 0FFh ;распознавание типа PC по специльной таблице
	je pct_1_case
	cmp al, 0FEh
	je pct_2_case
	cmp al, 0FBh
	je pct_2_case
	cmp al, 0FCh
	je pct_3_case
	cmp al, 0FAh
	je pct_4_case
	cmp al, 0FCh
	je pct_5_case
	cmp al, 0F8h
	je pct_6_case
	cmp al, 0FDh
	je pct_7_case
	cmp al, 0F9h
	je pct_8_case
	jmp pct_unknown_case
	
pct_1_case:
	mov dx, offset pct_1 ; загрузка в зависимости от значения al смещения нужной строки 
	jmp final_step
pct_2_case:
	mov dx, offset pct_2
	jmp final_step
pct_3_case:
	mov dx, offset pct_3
	jmp final_step
pct_4_case:
	mov dx, offset pct_4
	jmp final_step
pct_5_case:
	mov dx, offset pct_5
	jmp final_step
pct_6_case:
	mov dx, offset pct_6
	jmp final_step
pct_7_case:
	mov dx, offset pct_7
	jmp final_step
pct_8_case:
	mov dx, offset pct_8
	jmp final_step
	
pct_unknown_case: ; в случае несоответствия ни одному элементу таблицы вывод сообщения о неизвестном типе
	mov dx, offset pct_unknown
	push ax
	call BYTE_TO_HEX 
	mov si, dx
	mov [si], al
	inc si
	mov [si], ah ; в начало сообщения записывается код "ошибки" в 16-ричном виде
	pop ax
final_step:
	call write
end_of_proc:
	pop es
	pop dx
	pop ax
	ret
GET_PC_TYPE ENDP

GET_VERSRION PROC NEAR
	push ax
	push dx
	MOV AH,30h
	INT 21h
	;write version number
	
;Сначала надо обработать al, а потом ah и записать в конец System_version
		push ax
		push si
		lea si, System_version
		add si, 16
		call BYTE_TO_DEC
		add si, 3
		mov al, ah
		call BYTE_TO_DEC
		pop si
		pop ax
;OEM
	mov al, bh
	lea si, OEM
	add si, 7
	call BYTE_TO_DEC
	
;get_user_number
	mov al, bl
	call BYTE_TO_HEX ; 
	lea di, user_number
	add di, 20
	mov [di], ax 
	mov ax, cx
	lea di, user_number
	add di, 25
	call WRD_TO_HEX

version_:
	mov dx, offset System_version
	call WRITE
get_OEM:
	mov dx, offset OEM
	call write
get_user_number:
	mov dx, offset user_number
	call write
end_of_proc_2:
	pop dx
	pop ax
	ret
GET_VERSRION ENDP
;------------------------------- 

;код
BEGIN: ;вызов основных процедур
call GET_PC_TYPE
call GET_VERSRION
;выход в ДОС
	 xor AL,AL
	 mov AH,4Ch
	 int 21H
	 
TESTPC ENDS
	   END START 
	   end
; КОНЕЦ МОДУЛЯ, START - ТОЧКА ВХОДА
