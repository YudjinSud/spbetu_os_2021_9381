AStack SEGMENT STACK
	DW 12 DUP(?)
AStack ENDS
	
DATA SEGMENT
	erroraload	DB	"ERROR: already set",0Dh,0Ah, '$'
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE,DS:DATA,SS:AStack
key1 db 1Eh 					;a
key2 db 30h 					;b
ident		DW	0FA94h
accumulate		DB	0
oldpsp	DW	0	
unloadid	DB	0
oldvec dd ?

ROUT PROC FAR
	push ax
	push es
	push cx

	in al,60h
	cmp al,key1
	jz do_req1
	cmp al,key2
	jz do_req2

	pop cx
	pop es
	pop ax

	jmp cs:oldvec


    do_req1:
	in al,61h
	mov ah,al
	or al,80h
	out 61h,al
	xchg ah,al
	out 61h,al
	mov al,20h
	out 20h,al

	push ax
	push es
	mov ax,040h
	mov es,ax
	mov al,es:[17h]
	pop es
	and al,01000011b 			;shift
	pop ax
	jnz wrkey1
	mov cl,0Eh
	jmp write_key
    wrkey1:
	mov cl,'A'
	jmp write_key


    do_req2:
	in al,61h
	mov ah,al
	or al,80h
	out 61h,al
	xchg ah,al
	out 61h,al
	mov al,20h
	out 20h,al

	push ax
	push es
	mov ax,040h
	mov es,ax
	mov al,es:[17h]
	pop es
	and al,01000b 				;alt
	pop ax
	jnz wrkey2
	mov cl,0Fh
	jmp write_key
    wrkey2:
	mov cl,10h
	jmp write_key

    write_key:	
	mov ah,05h
	mov ch,00h
	int 16h
	or al,al
	jnz skip
	jmp end_rout
	
    skip:
	push es
	cli
	mov ax,04h
	mov es,ax
	mov al,es:[1ah]
	mov es:[1ah],al
	sti
	int 16h
	pop es

    end_rout:	
	pop cx
	pop es
	pop ax

	mov AL,20H
	out 20H,AL

	IRET
ROUT ENDP

printsymb	PROC	NEAR
	add al, 47
	mov ah,09h 
	mov bh,0 
	mov bl, 22
	mov cx,1 
	int 10h 
	ret
printsymb	ENDP

tailid	PROC NEAR 
	push dx
	push cx
	push si
	mov dl, es:[82h]
	cmp dl, '/'
	jne nounload
	mov dl, es:[83h]	
	cmp dl, 'u'
	jne nounload
	mov dl, es:[84h]	
	cmp dl, 'n'
	jne nounload
	pop si
	pop	cx
	pop dx
	mov unloadid,0
	ret

	nounload:
	pop si
	pop cx
	pop dx
	mov unloadid,1
	ret
tailid ENDP

load	PROC	NEAR
	push ds
	mov dx, offset ROUT 
	mov ax, seg ROUT 
	mov ds, ax 
	mov ah, 25h 
	mov al, 09h 
	int 21h 
	pop ds
	mov dx, offset END_CODE
	add dx,100h
	mov cl,4
	shr dx,cl
	inc dx
	mov ah, 31h
	int 21h
	
	ret
load	ENDP

unload	PROC	NEAR
	mov ah, 35h
	mov al, 09h 
	int 21h
	
	CLI
	PUSH DS
	MOV DX,word ptr ES:[oldvec]
	MOV AX,word ptr ES:[oldvec+2]
	MOV DS, AX
	MOV AH, 25H
	MOV AL, 09H
	INT 21H
	POP DS
	STI
	
	mov ax,es:[oldpsp]
	push ax
	mov es,ax
	mov ax,es:[2ch]
	mov es,ax
	mov ah,49h		
	int 21h	
	pop es		
	mov ah,49h	
	int 21h
	ret
unload	ENDP

MAIN	PROC FAR

	push DS
	xor AX,AX
	push AX
	mov AX,DATA
	mov	DS,AX

	push	es
	mov oldpsp, es 
	mov ah, 35h
	mov al, 09h 
	int 21h
	mov word ptr oldvec, bx 
	mov word ptr oldvec+2, es 
	push AX
	push BX
	mov AX,ident 
	mov BX,ES:[ident]
	cmp AX,BX
	pop BX
	pop AX
	pop ES
	jnz continue
	call tailid
	cmp unloadid,1
	jz errstr
	call unload
	jmp exit

	errstr:	
	mov DX, offset erroraload
	mov AH, 09h
	int 21h
	jmp exit
	continue:
	call load
exit:	
	xor AL,AL
	mov AH,4Ch
	int 21H

MAIN	ENDP
DW 20 DUP(?)
END_CODE:
CODE ENDS
END MAIN
	

	
