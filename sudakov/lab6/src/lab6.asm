MY_STACK segment stack
	dw 128 dup(?)
MY_STACK ends

DATA segment
	PROGRAM db 'lab2.com', 0
	PARAMETER_BLOCK dw 0
					dd 0
					dd 0
					dd 0
    MEM_FLAG db 0
	CMD db 1h, 0dh
	POS_CL db 128 dup(0)
	KEEP_SS dw 0
	KEEP_SP dw 0
	KEEP_PSP dw 0

	CRASH_MCB_ERR db 'Error! MCB crashed!', 0dh, 0ah, '$'
	NO_MEM_ERR db 'Error! Not enough memory!', 0dh, 0ah, '$'
	ADDR_ERR db 'Error! Invalid memory address!', 0dh, 0ah, '$'
	FN_ERR db 'Error! Invalid function number', 0dh, 0ah, '$'
	FILE_ERROR_STR db 'Error! File not found.', 0dh, 0ah, '$'
	DISK_ERR db 'Error! Disk error!', 0dh, 0ah, '$'
	MEMORY_ERR db 'Error! Insufficient memory', 0dh, 0ah, '$'
	EVN_ERR db 'Error! Wrong string of environment ', 0dh, 0ah, '$'
	FORMAT_ERR db 'Error! Wrong format', 0dh, 0ah, '$'
	DEVICE_ERR db 0dh, 0ah, 'PROGRAM ended by device error' , 0dh, 0ah, '$'

	FREE_MEMORY_MSG db 'Memory has been freed' , 0dh, 0ah, '$'

	NORMAL_END db 0dh, 0ah, 'PROGRAM ended with code    ' , 0dh, 0ah, '$'
	CTRL_END db 0dh, 0ah, 'PROGRAM ended by CTRL-break' , 0dh, 0ah, '$'
	END_31 db 0dh, 0ah, 'PROGRAM ended by int 31h' , 0dh, 0ah, '$'
	END_DATA db 0
DATA ends

CODE segment

assume cs:CODE, ds:DATA, ss:MY_STACK

PRINT proc
 	push ax
 	mov ah, 09h
 	int 21h
 	pop ax
 	ret
PRINT endp

MEMORY_FREE proc
	push ax
	push bx
	push cx
	push dx

	mov ax, offset END_DATA
	mov bx, offset FINISH
	add bx, ax

	mov cl, 4
	shr bx, cl
	add bx, 2bh
	mov ah, 4ah
	int 21h

	jnc FINISH_FREE
	mov MEM_FLAG, 1

CRASH_MCB:
	cmp ax, 7
	jne NOT_ENOUGH_MEMORY
	mov dx, offset CRASH_MCB_ERR
	call PRINT
	jmp RET_F
NOT_ENOUGH_MEMORY:
	cmp ax, 8
	jne ADDRESS_FAIL
	mov dx, offset NO_MEM_ERR
	call PRINT
	jmp RET_F
ADDRESS_FAIL:
	cmp ax, 9
	mov dx, offset ADDR_ERR
	call PRINT
	jmp RET_F
FINISH_FREE:
	mov MEM_FLAG, 1
	mov dx, offset FREE_MEMORY_MSG
	call PRINT

RET_F:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
MEMORY_FREE endp

LOAD proc
	push ax
	push bx
	push cx
	push dx
	push ds
	push es
	mov KEEP_SP, sp
	mov KEEP_SS, ss

	mov ax, DATA
	mov es, ax
	mov bx, offset PARAMETER_BLOCK
	mov dx, offset CMD
	mov [bx+2], dx
	mov [bx+4], ds
	mov dx, offset POS_CL

	mov ax, 4b00h
	int 21h

	mov ss, KEEP_SS
	mov sp, KEEP_SP
	pop es
	pop ds

	jnc loads

F_N_ERROR:
	cmp ax, 1
	jne FILE_ERROR
	mov dx, offset FN_ERR
	call PRINT
	jmp load_end
FILE_ERROR:
	cmp ax, 2
	jne DISK_ERROR
	mov dx, offset FILE_ERROR_STR
	call PRINT
	jmp load_end
DISK_ERROR:
	cmp ax, 5
	jne MEMORY_ERROR
	mov dx, offset DISK_ERR
	call PRINT
	jmp load_end
MEMORY_ERROR:
	cmp ax, 8
	jne ENV_ERROR
	mov dx, offset MEMORY_ERR
	call PRINT
	jmp load_end
ENV_ERROR:
	cmp ax, 10
	jne FORMAT_ERROR
	mov dx, offset EVN_ERR
	call PRINT
	jmp load_end
FORMAT_ERROR:
	cmp ax, 11
	mov dx, offset FORMAT_ERR
	call PRINT
	jmp load_end

loads:
	mov ah, 4dh
	mov al, 00h
	int 21h

	cmp ah, 0
	jne CTRL_FUNC
	push di
	mov di, offset NORMAL_END
	mov [di+26], al
	pop si
	mov dx, offset NORMAL_END
	call PRINT
	jmp load_end
CTRL_FUNC:
	cmp ah, 1
	jne DEVICE
	mov dx, offset CTRL_END
	call PRINT
	jmp load_end
DEVICE:
	cmp ah, 2
	jne INT_31
	mov dx, offset DEVICE_ERR
	call PRINT
	jmp load_end
INT_31:
	cmp ah, 3
	mov dx, offset END_31
	call PRINT

load_end:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
load endp

FIND_PATH proc
	push ax
	push bx
	push cx
	push dx
	push di
	push si
	push es

	mov ax, KEEP_PSP
	mov es, ax
	mov es, es:[2ch]
	mov bx, 0

LOOKING_PATH:
	inc bx
	cmp byte ptr es:[bx-1], 0
	jne LOOKING_PATH

	cmp byte ptr es:[bx+1], 0
	jne LOOKING_PATH

	add bx, 2
	mov di, 0

FIND_LOOP:
	mov dl, es:[bx]
	mov byte ptr [POS_CL+di], dl
	inc di
	inc bx
	cmp dl, 0
	je QUIT_LOOP
	cmp dl, '\'
	jne FIND_LOOP
	mov cx, di
	jmp FIND_LOOP

QUIT_LOOP:
	mov di, cx
	mov si, 0

END_FN:
	mov dl, byte ptr [PROGRAM+si]
	mov byte ptr [POS_CL+di], dl
	inc di
	inc si
	cmp dl, 0
	jne END_FN

	pop es
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
FIND_PATH endp

BEGIN proc far
	push ds
	xor ax, ax
	push ax
	mov ax, DATA
	mov ds, ax
	mov KEEP_PSP, es
	call MEMORY_FREE
	cmp MEM_FLAG, 0
	je QUIT
	call FIND_PATH
	call LOAD
QUIT:
	xor al, al
	mov ah, 4ch
	int 21h

BEGIN   endp

FINISH:
CODE ends
end BEGIN
