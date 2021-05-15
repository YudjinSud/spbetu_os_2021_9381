AStack SEGMENT STACK
	DW 12 DUP(?)
AStack ENDS
	
DATA SEGMENT
	erroraload	DB	"ERROR: already set",0Dh,0Ah, '$'
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE,DS:DATA,SS:AStack
ident		DW	0FA94h
accumulate	DB	0
oldcs		DW	0 
oldip		DW	0 
oldpsp		DW	0	
unloadid	DB	0

ROUT PROC FAR
	push ax
	push bx
	push dx
	push cx
	mov ah,03h
	mov bh,0
	int 10h 
	push dx
	mov ah,02h
	mov bh,0
	mov dh, 20
	mov dl, 15
	int 10h 

	inc accumulate
	mov al,accumulate
	cmp accumulate,10
	jne routne
	mov accumulate,0

	routne:	
	call printsymb
	mov ah,02h
	mov bh,0
	pop dx
	int 10h 
	
	pop cx
	pop dx
	pop bx
	pop ax
	MOV AL, 20H
	OUT 20H,AL
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
	pop cx
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
	mov al, 1ch 
	int 21h 
	pop ds
	mov dx, offset ENDS_HERE
	add dx,100h
	mov cl,4
	shr dx,cl
	inc dx
	mov ah, 31h
	int 21h
	
	ret
load	ENDP
ENDS_HERE:

unload	PROC	NEAR
	mov ah, 35h
	mov al, 1ch 
	int 21h
	
	CLI
	PUSH DS
	MOV DX, ES:[oldip]
	MOV AX, ES:[oldcs]
	MOV DS, AX
	MOV AH, 25H
	MOV AL, 1CH
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
	mov DS,AX

	push es
	mov oldpsp, es 
	mov ah, 35h
	mov al, 1ch 
	int 21h
	mov oldip, bx 
	mov oldcs, es 
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
	

