;
; openfourplayer168.asm
;
; Created   : 1/3/2022 11:03:24 AM
; Author    : Akerasoft
; Developer : Robert Kolski
;

; PIN D / PORT D
#define NES_PORT1_CLK     2
#define NES_PORT2_CLK     3
#define NES_LATCH         4
#define FOURPLAYER_ENABLE 5
#define NES_PORT1_DATA    6
#define NES_PORT2_DATA    7

; PIN B / PORT B
#define CTRL1_CLK         0
#define CTRL1_DATA        1

; PIN C / PORT C
#define CTRL2_CLK         0
#define CTRL2_DATA        1
#define CTRL3_CLK         2
#define CTRL3_DATA        3
#define CTRL4_CLK         4
#define CTRL4_DATA        5

; DEDICATED REGISTER VARIABLES
#define NES_PORT1_STATE   r18
#define NES_PORT2_STATE   r19
#define ID1_BITS          r20
#define ID2_BITS          r21
#define FOURPLAYER_BOOL   r22

; NOTE r16 and r17 are for general use


.cseg
.org 0
init:
;; INTERRUPT VECTORS
;; there are 26 of them on ATMEGA168
;; vector 1 - reset or program start
jmp main
;; vector 2 - INT0 pin interrupt
jmp PORT1_CLK
;; vector 3 - INT1 pin interrupt
jmp PORT2_CLK
;; vector 4 - PCINT0
jmp undefined_interrupt
;; vector 5 - PCINT1
jmp undefined_interrupt
;; vector 6 - PCINT2
jmp LATCH
;; vector 7 - WDT
jmp undefined_interrupt
;; vector 8 - TIMER2 COMPA
jmp undefined_interrupt
;; vector 9 - TIMER2 COMPB
jmp undefined_interrupt
;; vector 10 - TIMER2 OVF
jmp undefined_interrupt
;; vector 11 - TIMER1 CAPT
jmp undefined_interrupt
;; vector 12 - TIMER1 COMPA
jmp undefined_interrupt
;; vector 13 - TIMER1 COMPB
jmp undefined_interrupt
;; vector 14 - TIMER1 OVF
jmp undefined_interrupt
;; vector 15 - TIMER0 COMPA
jmp undefined_interrupt
;; vector 16 - TIMER0 COMPB
jmp undefined_interrupt
;; vector 17 - TIMER0 OVF
jmp undefined_interrupt
;; vector 18 - SPI, STC
jmp undefined_interrupt
;; vector 19 - UAART, RX
jmp undefined_interrupt
;; vector 20 - USART, UDRE
jmp undefined_interrupt
;; vector 21 - USART, TX
jmp undefined_interrupt
;; vector 22 - ADC
jmp undefined_interrupt
;; vector 23 - EE READY
jmp undefined_interrupt
;; vector 24 - ANALOG COMP
jmp undefined_interrupt
;; vector 25 - TWI
jmp undefined_interrupt
;; vector 26 - SPM READY
jmp undefined_interrupt

;
; PINOUT
; 1 - RESET         - RESET / ICSP PIN
; 2 - RX            - N/C or Serial or TURBOA
; 3 - TX            - N/C or Serial or TURBOB
; 4 - INT0    / PD2 - CLK NES PORT 1 - Interrupt
; 5 - INT1    / PD3 - CLK NES PORT 2 - Interrupt
; 6 - PCINT20 / PD4 - NES LATCH  - Interrupt
; 7 - VCC           - +5V
; 8 - GND           - GND
; 9 - XTAL1         - crystal (or N/C)
; 10 - XTAL2        - crystal (or N/C)
; 11 - PD5          - 2/4 Players - HIGH 4 Players / LOW 2 Players
; 12 - PD6          - NES PORT 1 DATA - OUTPUT
; 13 - PD7          - NES PORT 2 DATA - OUTPUT
; 14 - PB0          - Player 1 CLK    - OUTPUT
; 15 - PB1          - Player 1 DATA   - INPUT
; 16 - SS           - N/C             - CTRL1_LATCH - LOOP and interrupt design / N/C interrupt only
; 17 - MOSI         - ICSP PIN        - CTRL2_LATCH - LOOP and interrupt design / N/C interrupt only
; 18 - MISO         - ICSP PIN        - CTRL3_LATCH - LOOP and interrupt design / N/C interrupt only
; 19 - SCK          - ICSP PIN        - CTRL4_LATCH - LOOP and interrupt design / N/C interrupt only
; 20 - AVCC         - VCC
; 21 - AREF         - N/C
; 22 - GND          - GND
; 23 - PC0          - Player 2 CLK    - OUTPUT
; 24 - PC1          - Player 2 DATA   - INPUT
; 25 - PC2          - Player 3 CLK    - OUTPUT
; 26 - PC3          - Player 3 DATA   - INPUT
; 27 - PC4          - Player 4 CLK    - OUTPUT
; 28 - PC5          - Player 4 DATA   - INPUT

; please note about pin 16,17,18,19 -- this codes does not use them
; so the board that was developed for this should have 4 switches switched to use NES_LATCH for all 4 controllers.
; 20MHz crystal with divide by 1 is recommended.


COPYRIGHT:
	.db "(c) AKERASOFT 2021", 0,0
AUTHOR:
	.db "author: Robert Kolski", 0
PHONE:
	.db "phone: +1 (805) 978-2190", 0,0
EMAIL:
	.db "email: robert.kolski@akeraiotitasoft.com", 0,0

; program execution begins here
;;-------------------------------
;; BEGINING OF main
;;-------------------------------
main:
    ; set stack pointer to top of RAM
	ldi  r16, high(RAMEND)
	out  SPH,r16
	ldi  r16, low(RAMEND)
	out  SPL,r16
	
	clr  r1                 ; make r1 = 0
	
	ldi  r16, 0x03          ; enable both INT1 and INT0
	out  EIMSK, r16
	
	ldi  r16, 0x05          ; Any change to INT1 or INT0
	sts   EICRA, r16

	ldi  r16, 0x04          ; enable PCIE2 (PCINT2:PCINT16 to PCINT23)
	sts  PCICR, r16
	
	ldi  r16, 0x10          ; enable PCINT20
	sts  PCMSK2, r16
	
	ldi  r16, 0xB3          ; 0b11000000 ; PD5/PD4/PD3/PD2 - input, PD7/PD6 - output, PD0/PD1 input for safety
	out  DDRD, r16         
	
	ldi  r16, 0x15          ; 0b00010101 ; PC5/PC3/PC1 - input, PC4/PC2/PC0 - output, PC7/PC6 input for safety
	out  DDRC, r16
	
	ldi  r16, 0x01          ; 0b00000001 ; PB0 - output, PB1 - input PB7/PB6/PB5/PB4/PB3/PB2 input for safety
	out  DDRB, r16
	
	ldi  r16, ~0xB3         ; make all inputs high
	out  PORTD, r16
	
	ldi  r16, ~0x15         ; make all inputs high
	out  PORTC, r1         
	
	ldi  r16, ~0x01         ; make all inputs high
	out  PORTB, r1         

	ldi  NES_PORT1_STATE, 1
	ldi  NES_PORT2_STATE, 1
	ldi  ID1_BITS, 0x10
	ldi  ID2_BITS, 0x20
	
	in   r16, PIND
	sbrs r16, FOURPLAYER_ENABLE ; skip next statement if FOURPLAYER_ENABLE is HIGH
	clr  FOURPLAYER_BOOL        ; not skipped so FOURPLAYER_BOOL = 0 FALSE
	sbrc r16, FOURPLAYER_ENABLE ; skip next statement if FOURPLAYER_ENABLE is LOW
	ser  FOURPLAYER_BOOL        ; not skipped so FOURPLAYER_BOOL = 0xFF TRUE
	
	ldi  ZL, low(STATE1)
	ldi  ZH, high(STATE1)

	sei   ; enable interrupts
	
	ijmp  ; should jump to STATE1

STATE1:
	cli
	sbic  PINB, CTRL1_DATA
	sbi   PORTD, NES_PORT1_DATA
	sbis  PINB, CTRL1_DATA
	cbi   PORTD, NES_PORT1_DATA
	sbic  PINC, CTRL2_DATA
	sbi   PORTD, NES_PORT2_DATA
	sbis  PINC, CTRL2_DATA
	cbi   PORTD, NES_PORT2_DATA
	sei
	ijmp
	
STATE2:
	cli
	sbic  PINB, CTRL3_DATA
	sbi   PORTD, NES_PORT1_DATA
	sbis  PINB, CTRL3_DATA
	cbi   PORTD, NES_PORT1_DATA
	sbic  PINC, CTRL2_DATA
	sbi   PORTD, NES_PORT2_DATA
	sbis  PINC, CTRL2_DATA
	cbi   PORTD, NES_PORT2_DATA
	sei
	ijmp

STATE3:
	cli
	sbrc  ID1_BITS, 0
	sbi   PORTD, NES_PORT1_DATA
	sbrs  ID1_BITS, 0
	cbi   PORTD, NES_PORT1_DATA
	sbic  PINC, CTRL2_DATA
	sbi   PORTD, NES_PORT2_DATA
	sbis  PINC, CTRL2_DATA
	cbi   PORTD, NES_PORT2_DATA
	sei
	ijmp
	
STATE4:
	cli
	sbic  PINB, CTRL1_DATA
	sbi   PORTD, NES_PORT1_DATA
	sbis  PINB, CTRL1_DATA
	cbi   PORTD, NES_PORT1_DATA
	sbic  PINC, CTRL4_DATA
	sbi   PORTD, NES_PORT2_DATA
	sbis  PINC, CTRL4_DATA
	cbi   PORTD, NES_PORT2_DATA
	sei
	ijmp
	
STATE5:
	cli
	sbic  PINB, CTRL3_DATA
	sbi   PORTD, NES_PORT1_DATA
	sbis  PINB, CTRL3_DATA
	cbi   PORTD, NES_PORT1_DATA
	sbic  PINC, CTRL4_DATA
	sbi   PORTD, NES_PORT2_DATA
	sbis  PINC, CTRL4_DATA
	cbi   PORTD, NES_PORT2_DATA
	sei
	ijmp
	
STATE6:
	cli
	sbrc  ID1_BITS, 0
	sbi   PORTD, NES_PORT1_DATA
	sbrs  ID1_BITS, 0
	cbi   PORTD, NES_PORT1_DATA
	sbic  PINC, CTRL4_DATA
	sbi   PORTD, NES_PORT2_DATA
	sbis  PINC, CTRL4_DATA
	cbi   PORTD, NES_PORT2_DATA
	sei
	ijmp

STATE7:
	cli
	sbic  PINB, CTRL1_DATA
	sbi   PORTD, NES_PORT1_DATA
	sbis  PINB, CTRL1_DATA
	cbi   PORTD, NES_PORT1_DATA
	sbrc  ID2_BITS, 0
	sbi   PORTD, NES_PORT2_DATA
	sbrs  ID2_BITS, 0
	cbi   PORTD, NES_PORT2_DATA
	sei
	ijmp
	
STATE8:
	cli
	sbic  PINC, CTRL3_DATA
	sbi   PORTD, NES_PORT1_DATA
	sbis  PINC, CTRL3_DATA
	cbi   PORTD, NES_PORT1_DATA
	sbrc  ID2_BITS, 0
	sbi   PORTD, NES_PORT2_DATA
	sbrs  ID2_BITS, 0
	cbi   PORTD, NES_PORT2_DATA
	sei
	ijmp

STATE9:
	cli
	sbic  PINC, CTRL3_DATA
	sbi   PORTD, NES_PORT1_DATA
	sbis  PINC, CTRL3_DATA
	cbi   PORTD, NES_PORT1_DATA
	sbrc  ID2_BITS, 0
	sbi   PORTD, NES_PORT2_DATA
	sbrs  ID2_BITS, 0
	cbi   PORTD, NES_PORT2_DATA
	sei
	ijmp
	
;; -------------------
;; END OF main
;;--------------------


undefined_interrupt:
	reti

; this array may not be used
; it also has not been double checked
; the values might not be accurate
array:
	.dw array_0, array_1, array_2, array_3
	
array_0:
	.dw STATE1, STATE4, STATE7, STATE7
	
array_1:
	.dw STATE2, STATE5, STATE8, STATE8

array_2:
	.dw STATE3, STATE6, STATE9, STATE9

array_3:
	.dw STATE3, STATE6, STATE9, STATE9

;;---------------------------------------
;; BEGINING OF INTERRUPT TRANSITION FUNCTION
;;---------------------------------------

; usage: at the end of an interrupt
; in scenarios where a transition
; may occur, jump here instead of
; calling reti

; this may be too slow to use
END_OF_INTERRUPT_COMPUTE_TRANSITION:
	ldi  XL, low(array)
	ldi  XH, high(array)
	mov  r16, NES_PORT1_STATE
	swap r16
	andi r16, 0xF
	add  XL, r16
	adc  XH, r1
	ld   YL, X+
	ld   YH, X
	mov  r16, NES_PORT2_STATE
	swap r16
	andi r16, 0xF
	add  YL, r16
	adc  YH, r1
	ld   ZL, Y+
	ld   ZH, Y
	reti

;;---------------------------------------
;; END OF INTERRUPT TRANSITION FUNCTION
;;---------------------------------------


	
; CLK NES PORT 1 Interrupt
;;---------------------------------
;; BEGINING OF NES PORT1 CLK INTERRUPT
;;---------------------------------
PORT1_CLK:
	in   r16, PIND            ; PORTD = 0xb ; bit 2 = PORT 1 CLK, bit 5 = 4 player mode
	inc  NES_PORT1_STATE      ; increment state by 1

	tst  FOURPLAYER_BOOL      ; zero is FALSE, non zero is TRUE
	breq PLAYER1_CLK          ; branch on FALSE - only 2 players, so always player 1
	
	; controller 1 = 0 to 15   --> bit 4 is clear
	; controller 3 = 16 to 31  --> bit 4 is set
	; id bit       = 32 to 63  --> bit 5 set - just keep between 32 to 63 so that id is forever (see andi 0x2F)
	;                               because of andi 0x2F in practice getting 48 gets set back to 32
	
	sbrc NES_PORT1_STATE, 5      ; skip next instruction if number is less than 32
	rjmp ID1_CLK
	
	sbrc NES_PORT1_STATE, 4      ; skip next instruction if number is less than 16
	rjmp PLAYER3_CLK

	; no jump implies Player 1 CLK
PLAYER1_CLK:
    ; copy status of PORT1_CLK to CTRL1_CLK
    sbrc  r16, NES_PORT1_CLK      ; skip next instruction if PORT 1 CLK is LOW
	sbi   PORTB, CTRL1_CLK        ; instruction not skipped copy HIGH to CTRL1_CLK
	sbrs  r16, NES_PORT1_CLK      ; skip next instruction if PORT 1 CLK is HIGH
	cbi   PORTB, CTRL1_CLK        ; instruction not skipped copy LOW to CTRL1_CLK
    reti

PLAYER3_CLK:
	mov   r17, NES_PORT1_STATE
	andi  r17, 0x0E               ; Ignore bit 0.  if bit 3 or bit 2 or bit 1 is set that implies not the first iteration
	breq  PLAYER3_CLK_FIRST       ; branch on first iteration

    ; copy status of PORT3_CLK to CTRL3_CLK
    sbrc  r16, NES_PORT1_CLK      ; skip next instruction if PORT 1 CLK is LOW
	sbi   PORTC, CTRL3_CLK        ; instruction not skipped copy HIGH to CTRL3_CLK
	sbrs  r16, NES_PORT1_CLK      ; skip next instruction if PORT 1 CLK is HIGH
	cbi   PORTC, CTRL3_CLK        ; instruction not skipped copy LOW to CTRL3_CLK

PLAYER3_CLK_FIRST:
	sbrc NES_PORT2_STATE, 5      ; skip next instruction if number is less than 32
	rjmp PORT1_CLK_TRANSITION_STATE8
	
	sbrc NES_PORT2_STATE, 4      ; skip next instruction if number is less than 16
	rjmp PORT1_CLK_TRANSITION_STATE5
	
PORT1_CLK_TRANSITION_STATE2:
	ldi  ZL, low(STATE2)
	ldi  ZH, high(STATE2)
	reti

PORT1_CLK_TRANSITION_STATE5:
	ldi  ZL, low(STATE5)
	ldi  ZH, high(STATE5)
	reti

PORT1_CLK_TRANSITION_STATE8:
	ldi  ZL, low(STATE8)
	ldi  ZH, high(STATE8)
	reti

ID1_CLK:
	andi  NES_PORT1_STATE, 0x2F   ; ensure that getting 0x40 is not possible, this would unset bit 5
	mov   r17, NES_PORT1_STATE
	andi  r17, 0x0E               ; Ignore bit 0.  if bit 3 or bit 2 or bit 1 is set that implies not the first iteration
	breq  ID1_FIRST               ; branch on first iteration
	
	sbrc  r16, NES_PORT1_CLK      ; skip next instruction if clock is LOW
	lsr   ID1_BITS                ; shift right
ID1_FIRST:
	sbrc NES_PORT2_STATE, 5      ; skip next instruction if number is less than 32
	rjmp PORT1_CLK_TRANSITION_STATE9
	
	sbrc NES_PORT2_STATE, 4      ; skip next instruction if number is less than 16
	rjmp PORT1_CLK_TRANSITION_STATE6
	
PORT1_CLK_TRANSITION_STATE3:
	ldi  ZL, low(STATE3)
	ldi  ZH, high(STATE3)
	reti

PORT1_CLK_TRANSITION_STATE6:
	ldi  ZL, low(STATE6)
	ldi  ZH, high(STATE6)
	reti

PORT1_CLK_TRANSITION_STATE9:
	ldi  ZL, low(STATE9)
	ldi  ZH, high(STATE9)
	reti
	
;;---------------------------------
;; END OF NES PORT1 CLK INTERRUPT
;;---------------------------------



; CLK NES PORT 2 Interrupt
;;---------------------------------
;; BEGINING OF NES PORT2 CLK INTERRUPT
;;---------------------------------
PORT2_CLK:
	in   r16, PIND            ; PORTD = 0xb ; bit 3 = PORT 2 CLK, bit 5 = 4 player mode
	inc  NES_PORT2_STATE      ; increment state by 1

	tst  FOURPLAYER_BOOL      ; zero is FALSE, non zero is TRUE
	breq PLAYER2_CLK          ; branch on FALSE - only 2 players so always player 2 CLK if branch is taken
	
	; controller 2 = 0 to 15   --> bit 4 is clear
	; controller 4 = 16 to 31  --> bit 4 is set
	; id bit       = 32 to 63  --> bit 5 set - just keep between 32 to 63 so that id is forever (see andi 0x2F)
	;                               because of andi 0x2F in practice getting 48 gets set back to 32
	
	sbrc NES_PORT2_STATE, 5      ; skip next instruction if number is less than 32 (0x20)
	rjmp ID2_CLK
	sbrc NES_PORT2_STATE, 4      ; skip next instruction if number is less than 16 (0x10)
	rjmp PLAYER4_CLK

	; no jump implies Player 2 CLK
PLAYER2_CLK:
    ; copy status of PORT2_CLK to CTRL2_CLK
    sbrc  r16, NES_PORT2_CLK      ; skip next instruction if PORT 2 CLK is LOW
	sbi   PORTC, CTRL2_CLK        ; instruction not skipped copy HIGH to CTRL2_CLK
	sbrs  r16, NES_PORT2_CLK      ; skip next instruction if PORT 2 CLK is HIGH
	cbi   PORTC, CTRL2_CLK        ; instruction not skipped copy LOW to CTRL2_CLK
	reti

PLAYER4_CLK:
	mov   r17, NES_PORT2_STATE
	andi  r17, 0x0E               ; Ignore bit 0.  if bit 3 or bit 2 or bit 1 is set that implies not the first iteration
	breq  PLAYER4_CLK_FIRST       ; branch on first iteration

    ; copy status of PORT2_CLK to CTRL4_CLK
    sbrc  r16, NES_PORT2_CLK      ; skip next instruction if PORT 2 CLK is LOW
	sbi   PORTC, CTRL4_CLK        ; instruction not skipped copy HIGH to CTRL4_CLK
	sbrs  r16, NES_PORT2_CLK      ; skip next instruction if PORT 2 CLK is HIGH
	cbi   PORTC, CTRL4_CLK        ; instruction not skipped copy LOW to CTRL4_CLK

PLAYER4_CLK_FIRST:
	sbrc NES_PORT1_STATE, 5      ; skip next instruction if number is less than 32
	rjmp PORT2_CLK_TRANSITION_STATE6
	
	sbrc NES_PORT1_STATE, 4      ; skip next instruction if number is less than 16
	rjmp PORT2_CLK_TRANSITION_STATE5
	
PORT2_CLK_TRANSITION_STATE4:
	ldi  ZL, low(STATE4)
	ldi  ZH, high(STATE4)
	reti

PORT2_CLK_TRANSITION_STATE5:
	ldi  ZL, low(STATE5)
	ldi  ZH, high(STATE5)
	reti

PORT2_CLK_TRANSITION_STATE6:
	ldi  ZL, low(STATE6)
	ldi  ZH, high(STATE6)
	reti

ID2_CLK:
	andi  NES_PORT2_STATE, 0x2F   ; ensure that getting 0x40 is not possible, this would unset bit 5
	mov   r17, NES_PORT2_STATE
	andi  r17, 0x0E               ; Ignore bit 0.  if bit 3 or bit 2 or bit 1 is set that implies not the first iteration
	breq  ID2_FIRST               ; branch on first iteration
	
	sbrc  r16, NES_PORT2_CLK      ; skip next instruction if clock is LOW
	lsr   ID2_BITS                ; shift right
ID2_FIRST:
	sbrc NES_PORT1_STATE, 5      ; skip next instruction if number is less than 32
	rjmp PORT1_CLK_TRANSITION_STATE9
	
	sbrc NES_PORT1_STATE, 4      ; skip next instruction if number is less than 16
	rjmp PORT1_CLK_TRANSITION_STATE8
	
PORT2_CLK_TRANSITION_STATE7:
	ldi  ZL, low(STATE7)
	ldi  ZH, high(STATE7)
	reti

PORT2_CLK_TRANSITION_STATE8:
	ldi  ZL, low(STATE8)
	ldi  ZH, high(STATE8)
	reti

PORT2_CLK_TRANSITION_STATE9:
	ldi  ZL, low(STATE9)
	ldi  ZH, high(STATE9)
	reti
;;---------------------------------
;; END OF NES PORT1 CLK INTERRUPT
;;---------------------------------



; NES LATCH Interrupt	
;;---------------------------------
;; BEGINNING OF NES LATCH INTERRUPT
;;---------------------------------
LATCH:
	in   r16, PIND              ; read NES LATCH and FOURPLAYER_ENABLE
	sbrs r16, NES_LATCH         ; skip next statement if LATCH is HIGH
	rjmp LATCH_LOW        ; if not skipped LATCH is low so goto copy data
	
    ; LATCH is HIGH
	; the following instructions are good for a delay 
	; so that it gives the controller time to
	; respond to the LATCH
    
	sbrs r16, FOURPLAYER_ENABLE ; skip next statement if FOURPLAYER_ENABLE is HIGH
	clr  FOURPLAYER_BOOL        ; not skipped so FOURPLAYER_BOOL = 0 FALSE
	sbrc r16, FOURPLAYER_ENABLE ; skip next statement if FOURPLAYER_ENABLE is LOW
	ser  FOURPLAYER_BOOL        ; not skipped so FOURPLAYER_BOOL = 0xFF TRUE
	ldi  NES_PORT1_STATE, 1
	ldi  NES_PORT2_STATE, 1
	ldi  ID1_BITS, 0x10
	ldi  ID2_BITS, 0x20
	
LATCH_LOW:
	ldi  ZL, low(STATE1)
	ldi  ZH, high(STATE1)
	reti
;;---------------------------------
;; END OF NES LATCH INTERRUPT
;;---------------------------------

.dseg
