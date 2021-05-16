ASSUME CS:OVERLAY, DS:OVERLAY

OVERLAY SEGMENT
 push DS
 mov AX, CS
 mov DS, AX
 mov DI, offset MSG
 add DI, 30
 call WRD_TO_HEX
 mov AH, 09h
 mov DX, offset MSG
 int 21h
 pop DS
 retf

MSG db 'Overlay 2 segment address:    ',0DH,0AH,'$'

TETR_TO_HEX PROC near       
 and AL,0Fh
 cmp AL,09
 jbe NEXT
 add AL,07
NEXT: add AL,30h
 ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near 
 push CX
 mov AH,AL
 call TETR_TO_HEX
 xchg AL,AH
 mov CL,4
 shr AL,CL
 call TETR_TO_HEX 
 pop CX 
 ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near
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
OVERLAY ENDS
END 
