ORG 0000H
LJMP 9000H
ORG 23H
LJMP SERIAL_ISR

ORG 9000H
LCALL SERIAL_INITIATE;calls the intitate subroutine
SETB TR1;runs the clock
TOTAL_CHECK:
CJNE R3, #01H, NEXT;checks for EOF
MOV IE, #00H
SJMP EXIT_ROUTINE
NEXT:
CJNE R3, #02H, READY_TO_ACCEPT;checks for error
MOV IE, #00H
sjmp ERROR
NOP
READY_TO_ACCEPT:
MOV R4, #00H
LOOP:
CJNE R4, #01H, LOOP;loops until R4 is 01H, which happens after returning from ISR.
SJMP TOTAL_CHECK

SERIAL_ISR:
MOV A, SBUF
COND_ONE:
CJNE R7, #00H, COND_TWO; the header condition
CJNE R0, #30H, PASSED_COLON
mov r6, #00h
CJNE A, #3AH, RETURN;returnif colon is not the first received data in the header
PASSED_COLON:
MOV @R0, A
INC R0
ADD A, R6
MOV R6, A
CJNE R0, #35h, NEXT_IN_ISR
mov a, 34h
CJNE a, #01H, NEXT_IN_ISR;check whether the data type is EOF
MOV R3, #01H
NEXT_IN_ISR:
CJNE R0, #35H, RETURN
inc r7
ACALL LENGTH_CALL
mov R0, #30h
SJMP RETURN
COND_TWO:
CJNE R7, #01H, COND_THREE;data receive condition
MOV DPH, 32H
MOV DPL, 33H
MOVX @DPTR, A
LCALL 18ADH
INC DPTR
MOV 32H, DPH
MOV 33H, DPL
ADD A, R6
MOV R6, A
DJNZ R1, RETURN
INC R7
SJMP RETURN
COND_THREE:; checksum condition
MOV R5, A
MOV A, r6
SUBB A, #3AH
CPL A
INC A
SUBB A, R5
JNZ ERROR_IN_ISR; error in checksum
MOV R6, #00H
mov r7, #00h
sjmp return
ERROR_IN_ISR:
MOV R3, #02H
RETURN:
MOV R4, #01H
CLR RI
RETI

;updates the length every time it is called and the intitial address of the start of the code in 40h and 41h at the very begining.
LENGTH_CALL:
MOV R1, 31H
jnb 00h, clear
mov 40h, 32h
mov 41h, 33h
clear:
clr 00h
RET
ERROR:
ljmp 04fdh;jumps to monitor control if error

;The exit subroutine

EXIT_ROUTINE:
ljmp 9087h

;this executes the program received from serial communication in the address given by the user.
org 9087h
mov r0, #50h
mov r1, #00h
loop_1:
lcall 02a2h
mov @r0, a
inc r1
inc r0
cjne r1, #04h, loop_1; loops 4 times
mov a, 50h
swap a
orl a, 51h
mov dph, a
mov a, 52h
swap a
orl a, 53h
mov dpl, a
mov 60h, dph
mov 61h, dpl
mov a, #02h
lcall 18adh
inc dptr
mov a, 40h
lcall 18adh
inc dptr
mov a, 41h
lcall 18adh
mov a, 60h
mov dptr, #9543h
lcall 18adh
mov a, 63h
mov dptr, #9544h
lcall 18adh
ljmp 0000h

;Initiates all the registers in use and all the serial SFR's to be used to proper values
org 90CCh
SERIAL_INITIATE:
mov tmod, #20h
mov th1, #0fdh
mov scon, #50h
mov ie, #90h
MOV R6, #00H
MOV R3, #00H
mov r4, #00h
mov r0, #30h
mov r7, #00h
setb 00h
RET
