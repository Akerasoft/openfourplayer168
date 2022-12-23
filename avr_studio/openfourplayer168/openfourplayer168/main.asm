;
; openfourplayer168.asm
;
; Created   : 1/3/2022 11:03:24 AM
; Author    : Akerasoft
; Developer : Robert Kolski
;

; I/O REGISTERS
#define PIN_FOURPLAYER_ENABLE PIND
#define PORT_FOURPLAYER_ENABLE PORTD
#define PIN_NES_PORT      PIND
#define PORT_NES_PORT     PORTD
#define PIN_CTRL1         PINB
#define PORT_CTRL1        PORTB
#define PIN_CTRL234       PINC
#define PORT_CTRL234      PORTC

; PIN D / PORT D
#define NES_PORT1_CLK     PD2
#define NES_PORT2_CLK     PD3
#define NES_LATCH         PD4
#define FOURPLAYER_ENABLE PD5
#define NES_PORT1_D0      PD6
#define NES_PORT2_D0      PD7

; PIN B / PORT B
#define CTRL1_CLK         PB0
#define CTRL1_DATA        PB1

; PIN C / PORT C
#define CTRL2_CLK         PC0
#define CTRL2_DATA        PC1
#define CTRL3_CLK         PC2
#define CTRL3_DATA        PC3
#define CTRL4_CLK         PC4
#define CTRL4_DATA        PC5

; DEDICATED REGISTER VARIABLES
#define CLKCTR1           r18
#define CLKCTR2           r19
#define ID1_BITS          r20
#define ID2_BITS          r21

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
; 16 - SS           - N/C             - CTRL1_LATCH - buffer design / N/C immediate latch design
; 17 - MOSI         - ICSP PIN        - CTRL2_LATCH - buffer design / N/C immediate latch design
; 18 - MISO         - ICSP PIN        - CTRL3_LATCH - buffer design / N/C immediate latch design
; 19 - SCK          - ICSP PIN        - CTRL4_LATCH - buffer design / N/C immediate latch design
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
	
	ldi  r16, 0x03          ; enable both INT1 and INT0
	out  EIMSK, r16
	
	ldi  r16, 0x07          ; Rising Edge of INT1 or INT0
	sts  EICRA, r16

	ldi  r16, 0x04          ; enable PCIE2 (PCINT2:PCINT16 to PCINT23)
	sts  PCICR, r16
	
	ldi  r16, (1<<PCINT20)  ; enable PCINT20, which is also pin PD4
	sts  PCMSK2, r16
	
	ldi  r16, (1<<PD7) | (1<<PD6) ; PIN 0..5 input, pin 6..7 output
	out  DDRD, r16         
	
	ldi  r16, 0x15          ; 0b00010101 ; PC5/PC3/PC1 - input, PC4/PC2/PC0 - output, PC7/PC6 input for safety
	out  DDRC, r16
	
	ldi  r16, 0x01          ; 0b00000001 ; PB0 - output, PB1 - input PB7/PB6/PB5/PB4/PB3/PB2 input for safety
	out  DDRB, r16
	
	ldi  r16, ~((1<<PD7) | (1<<PD6))         ; make all inputs high
	out  PORTD, r16
	
	ldi  r16, ~0x15         ; make all inputs high
	out  PORTC, r16         
	
	ldi  r16, ~0x01         ; make all inputs high
	out  PORTB, r16         

	clr  CLKCTR1
	clr  CLKCTR2
	ldi  ID1_BITS, ~0x10
	ldi  ID2_BITS, ~0x20
	
	ldi  ZL, low(WAITING_LOOP)
	ldi  ZH, high(WAITING_LOOP)

	sei   ; enable interrupts
	
	ijmp  ; jump to WAITING_LOOP
	
;; -------------------
;; END OF main
;;--------------------






	
; CLK NES PORT 1 Interrupt
;;---------------------------------
;; BEGINING OF NES PORT1 CLK INTERRUPT
;;---------------------------------
PORT1_CLK:
	inc  CLKCTR1              ; increment clock counter for port 1
	sbrc CLKCTR1, 3           ; check if 8 clocks
	subi ZL, -0x40            ; if 8 clocks change state, subtract negative 0x40 means add 0x40.
	andi CLKCTR1, 0x7         ; only allow 8 clocks max, 0 being the first
	breq PORT1_FIRST_CLOCK    ; branch for first clock

	sbrc ZL, 6
	jmp  PORT1_CLK_40L
	sbrc ZL, 7
	jmp  PORT1_CLK_CLK_DONE
	sbi  PORT_CTRL1, CTRL1_CLK
	jmp  PORT1_CLK_CLK_DONE
PORT1_CLK_40L:
	sbi  PORT_CTRL234, CTRL3_CLK

PORT1_CLK_CLK_DONE:
    sbrc ZL, 7                ; check for states 0xn400 or 0xn500
	lsr  ID1_BITS             ; in those states not the first clock does a shift
	
	; this sequence causes a return from interrupt to go to the begining of the state
	pop  r16
	pop  r16
	push ZL
	push ZH
	reti

PORT1_FIRST_CLOCK:
	; this sequence causes a return from interrupt to go to the begining of the state
	pop  r16
	pop  r16
	push ZL
	push ZH
	reti

	
;;---------------------------------
;; END OF NES PORT1 CLK INTERRUPT
;;---------------------------------



; CLK NES PORT 2 Interrupt
;;---------------------------------
;; BEGINING OF NES PORT2 CLK INTERRUPT
;;---------------------------------
PORT2_CLK:
	inc  CLKCTR2              ; increment clock counter for port 2
	sbrc CLKCTR2, 3           ; check if 8 clocks
	inc  ZH                   ; if 8 clocks change state
	andi CLKCTR2, 0x7         ; only allow 8 clocks max, 0 being the first
	breq PORT2_FIRST_CLOCK    ; branch for first clock

	cpi  ZH, 0x40
	brge PORT3_CLK_CLK_DONE
	cpi  ZH, 0x30
	brge PORT3_CLK_30H
	sbi  PORT_CTRL234, CTRL2_CLK
	jmp  PORT3_CLK_CLK_DONE
PORT3_CLK_30H:
	sbi  PORT_CTRL234, CTRL4_CLK
PORT3_CLK_CLK_DONE:

    sbrc ZH, 6                ; check for states 0x4n00 or 0x5n00
	lsr  ID2_BITS             ; in those states not the first clock does a shift
	
	; this sequence causes a return from interrupt to go to the begining of the state
	pop  r16
	pop  r16
	push ZL
	push ZH
	reti

PORT2_FIRST_CLOCK:
	; this sequence causes a return from interrupt to go to the begining of the state	
	pop  r16
	pop  r16
	push ZL
	push ZH
	reti

;;---------------------------------
;; END OF NES PORT2 CLK INTERRUPT
;;---------------------------------


; NES LATCH Interrupt	
;;---------------------------------
;; BEGINNING OF NES LATCH INTERRUPT
;;---------------------------------
LATCH:
	sbis PIN_NES_PORT, NES_LATCH
	rjmp EXIT_LATCH

	clr  CLKCTR1
	clr  CLKCTR2
	
	; ATMEGA168P / ATMEGA328P pinout
	ldi  r16, 0x2A ; PORTC = DATA HIGH / CLOCK LOW
	out  PORTC, r16
	ldi  r16, 0x02 ; PORTB = DATA HIGH / CLOCK LOW
	out  PORTB, r16

	;	sbic PIN_FAMICOM_ENABLE, FAMICOM_ENABLE
	;	rjmp LATCH_FAMICOM

	sbis PIN_FOURPLAYER_ENABLE, FOURPLAYER_ENABLE ; skip next statement if FOURPLAYER_ENABLE is HIGH
	ldi  ZH, high(STATE_2_PLAYER)                 ; state is NES 2 player state
	sbic PIN_FOURPLAYER_ENABLE, FOURPLAYER_ENABLE ; skip next statement if FOURPLAYER_ENABLE is LOW
	ldi  ZH, high(STATE1)                         ; state is STATE1 for four player adapter for NES

	; NES mode
	ldi  ZL, 0x00                           ; State is NES Mode
	ldi  ID1_BITS, ~0x10
	ldi  ID2_BITS, ~0x20

	; this sequence causes a return from interrupt to go to the begining of the state
	pop  r16
	pop  r16
	push ZL
	push ZH
	reti
	
;LATCH_FAMICOM:
;	sbis PIN_FOURPLAYER_ENABLE, FOURPLAYER_ENABLE ; skip next statement if FOURPLAYER_ENABLE is HIGH
;	ldi  ZH, high(STATE_4_PLAYER_SIMP)                 ; state is NES 2 player state
;	sbic PIN_FOURPLAYER_ENABLE, FOURPLAYER_ENABLE ; skip next statement if FOURPLAYER_ENABLE is LOW
;	ldi  ZH, high(FSTATE1)                         ; state is STATE1 for four player adapter for NES
;	ldi  ZL, 0x00                           ; State is FAMICOM Mode
;	ldi  ID1_BITS, 0x20                     ; id bits are swapped as compared to NES mode 4 player
;	ldi  ID2_BITS, 0x10

;    ; this sequence causes a return from interrupt to go to the begining of the state
;	pop  r16
;	pop  r16
;	push ZL
;	push ZH
;	reti

EXIT_LATCH:
	; this is the only place where returning from the interrupt continues execution
	; as normal.
	reti

;;---------------------------------
;; END OF NES LATCH INTERRUPT
;;---------------------------------


undefined_interrupt:
	reti

.org 0x0200
STATE1:
	cbi   PORT_CTRL1, CTRL1_CLK
	cbi   PORT_CTRL234, CTRL2_CLK

	sbic  PIN_CTRL1, CTRL1_DATA
	sbi   PORT_NES_PORT, NES_PORT1_D0
	sbis  PIN_CTRL1, CTRL1_DATA
	cbi   PORT_NES_PORT, NES_PORT1_D0
	
	sbic  PIN_CTRL234, CTRL2_DATA
	sbi   PORT_NES_PORT, NES_PORT2_D0
	sbis  PIN_CTRL234, CTRL2_DATA
	cbi   PORT_NES_PORT, NES_PORT2_D0
	ijmp

.org 0x0240
STATE2:
	cbi   PORT_CTRL234, CTRL3_CLK
	cbi   PORT_CTRL234, CTRL2_CLK

	sbic  PIN_CTRL234, CTRL3_DATA
	sbi   PORT_NES_PORT, NES_PORT1_D0
	sbis  PIN_CTRL234, CTRL3_DATA
	cbi   PORT_NES_PORT, NES_PORT1_D0
	
	sbic  PIN_CTRL234, CTRL2_DATA
	sbi   PORT_NES_PORT, NES_PORT2_D0
	sbis  PIN_CTRL234, CTRL2_DATA
	cbi   PORT_NES_PORT, NES_PORT2_D0
	ijmp

.org 0x0280
STATE3:
	cbi   PORT_CTRL234, CTRL2_CLK
	sbrc  ID1_BITS, 0
	sbi   PIN_NES_PORT, NES_PORT1_D0
	sbrs  ID1_BITS, 0
	cbi   PIN_NES_PORT, NES_PORT1_D0

	sbic  PIN_CTRL234, CTRL2_DATA
	sbi   PORT_NES_PORT, NES_PORT2_D0
	sbis  PIN_CTRL234, CTRL2_DATA
	cbi   PORT_NES_PORT, NES_PORT2_D0
	ijmp
	
.org 0x02C0
STATE4:
	subi   ZL, 0x40 ; go back to state 3
	ijmp

	
	


.org 0x0300
STATE5:
	cbi   PORT_CTRL1, CTRL1_CLK
	cbi   PORT_CTRL234, CTRL4_CLK
	sbic  PIN_CTRL1, CTRL1_DATA
	sbi   PORT_NES_PORT, NES_PORT1_D0
	sbis  PIN_CTRL1, CTRL1_DATA
	cbi   PORTD, NES_PORT1_D0
	
	sbic  PIN_CTRL234, CTRL4_DATA
	sbi   PORT_NES_PORT, NES_PORT2_D0
	sbis  PIN_CTRL234, CTRL4_DATA
	cbi   PORT_NES_PORT, NES_PORT2_D0
	ijmp
	
.org 0x0340
STATE6:
	cbi   PORT_CTRL234, CTRL3_CLK
	cbi   PORT_CTRL234, CTRL4_CLK
	sbic  PIN_CTRL234, CTRL3_DATA
	sbi   PORT_NES_PORT, NES_PORT1_D0
	sbis  PIN_CTRL234, CTRL3_DATA
	cbi   PORTD, NES_PORT1_D0
	
	sbic  PIN_CTRL234, CTRL4_DATA
	sbi   PORT_NES_PORT, NES_PORT2_D0
	sbis  PIN_CTRL234, CTRL4_DATA
	cbi   PORT_NES_PORT, NES_PORT2_D0
	ijmp
	
.org 0x0380
STATE7:
	cbi   PORT_CTRL234, CTRL4_CLK
	sbrc  ID1_BITS, 0
	sbi   PIN_NES_PORT, NES_PORT1_D0
	sbrs  ID1_BITS, 0
	cbi   PIN_NES_PORT, NES_PORT1_D0

	sbic  PIN_CTRL234, CTRL4_DATA
	sbi   PORT_NES_PORT, NES_PORT2_D0
	sbis  PIN_CTRL234, CTRL4_DATA
	cbi   PORT_NES_PORT, NES_PORT2_D0
	ijmp

.org 0x03C0
STATE8:
	subi  ZL, 0x40 ; go back to state 7
	ijmp



.org 0x0400
STATE9:
	cbi   PORT_CTRL1, CTRL1_CLK
	sbic  PIN_CTRL1, CTRL1_DATA
	sbi   PORT_NES_PORT, NES_PORT1_D0
	sbis  PIN_CTRL1, CTRL1_DATA
	cbi   PORTD, NES_PORT1_D0
	
	sbrc  ID2_BITS, 0
	sbi   PIN_NES_PORT, NES_PORT2_D0
	sbrs  ID2_BITS, 0
	cbi   PIN_NES_PORT, NES_PORT2_D0
	ijmp
	
.org 0x0440
STATE10:
	cbi   PORT_CTRL234, CTRL3_CLK
	sbic  PIN_CTRL234, CTRL3_DATA
	sbi   PORT_NES_PORT, NES_PORT1_D0
	sbis  PIN_CTRL234, CTRL3_DATA
	cbi   PORTD, NES_PORT1_D0

	sbrc  ID2_BITS, 0
	sbi   PIN_NES_PORT, NES_PORT2_D0
	sbrs  ID2_BITS, 0
	cbi   PIN_NES_PORT, NES_PORT2_D0
	ijmp
	
.org 0x0480
STATE11:
	sbrc  ID1_BITS, 0
	sbi   PIN_NES_PORT, NES_PORT1_D0
	sbrs  ID1_BITS, 0
	cbi   PIN_NES_PORT, NES_PORT1_D0

	sbrc  ID2_BITS, 0
	sbi   PIN_NES_PORT, NES_PORT2_D0
	sbrs  ID2_BITS, 0
	cbi   PIN_NES_PORT, NES_PORT2_D0
	ijmp
	
.org 0x04C0
STATE12:
	subi   ZL, 0x40 ; go back to state 11
	ijmp

.org 0x0500
STATE13:
	dec   ZH        ; go back to state 9
	ijmp
	
.org 0x0540
STATE14:
	dec   ZH        ; go back to state 10
	ijmp


.org 0x0580
STATE15:
	dec   ZH        ; go back to state 11
	ijmp

.org 0x05C0
STATE16:
	cli
	subi  ZL, 0x40  ; go back to state 11
	dec   ZH        ; go back to state 11
	sei
	ijmp





;.org 0x0A00
;FSTATE1:
;	sbic  PIN_NES_PORT, NES_PORT1_CLK
;	sbi   PORT_CTRL1, CTRL1_CLK
;	sbis  PIN_NES_PORT, NES_PORT1_CLK
;	cbi   PORT_CTRL1, CTRL1_CLK

;	sbic  PIN_NES_PORT, NES_PORT2_CLK
;	sbi   PORT_CTRL234, CTRL2_CLK
;	sbis  PIN_NES_PORT, NES_PORT2_CLK
;	cbi   PORT_CTRL234, CTRL2_CLK

;	sbic  PIN_CTRL1, CTRL1_DATA
;	sbi   PORT_NES_PORT, NES_PORT1_D1
;	sbis  PIN_CTRL1, CTRL1_DATA
;	cbi   PORT_NES_PORT, NES_PORT1_D1
	
;	sbic  PIN_CTRL234, CTRL2_DATA
;	sbi   PORT_NES_PORT, NES_PORT2_D1
;	sbis  PIN_CTRL234, CTRL2_DATA
;	cbi   PORT_NES_PORT, NES_PORT2_D1
;	ijmp
	
	
;.org 0x0A40
;FSTATE2:
;	sbic  PIN_NES_PORT, NES_PORT1_CLK
;	sbi   PORT_CTRL234, CTRL3_CLK
;	sbis  PIN_NES_PORT, NES_PORT1_CLK
;	cbi   PORT_CTRL234, CTRL3_CLK

;	sbic  PIN_NES_PORT, NES_PORT2_CLK
;	sbi   PORT_CTRL234, CTRL2_CLK
;	sbis  PIN_NES_PORT, NES_PORT2_CLK
;	cbi   PORT_CTRL234, CTRL2_CLK

;	sbic  PIN_CTRL234, CTRL3_DATA
;	sbi   PORT_NES_PORT, NES_PORT1_D1
;	sbis  PIN_CTRL234, CTRL3_DATA
;	cbi   PORT_NES_PORT, NES_PORT1_D1
	
;	sbic  PIN_CTRL234, CTRL2_DATA
;	sbi   PORT_NES_PORT, NES_PORT2_D1
;	sbis  PIN_CTRL234, CTRL2_DATA
;	cbi   PORT_NES_PORT, NES_PORT2_D1
;	ijmp

	
;.org 0x0A80
;FSTATE3:
;	sbic  PIN_NES_PORT, NES_PORT2_CLK
;	sbi   PORT_CTRL234, CTRL2_CLK
;	sbis  PIN_NES_PORT, NES_PORT2_CLK
;	cbi   PORT_CTRL234, CTRL2_CLK
;
;	sbrc  ID1_BITS, 0
;	sbi   PIN_NES_PORT, NES_PORT1_D1
;	sbrs  ID1_BITS, 0
;	cbi   PIN_NES_PORT, NES_PORT1_D1
;
;	sbic  PIN_CTRL234, CTRL2_DATA
;	sbi   PORT_NES_PORT, NES_PORT2_D1
;	sbis  PIN_CTRL234, CTRL2_DATA
;	cbi   PORT_NES_PORT, NES_PORT2_D1
;	ijmp
;	
;	
;.org 0x0AC0
;FSTATE4:
;	subi   ZL, 0x40 ; go back to state 3
;	ijmp
;
;
.;org 0x0B00
;FSTATE5:
;	sbic  PIN_NES_PORT, NES_PORT1_CLK
;	sbi   PORT_CTRL1, CTRL1_CLK
;	sbis  PIN_NES_PORT, NES_PORT1_CLK
;	cbi   PORT_CTRL1, CTRL1_CLK
;
;	sbic  PIN_NES_PORT, NES_PORT2_CLK
;	sbi   PORT_CTRL234, CTRL4_CLK
;	sbis  PIN_NES_PORT, NES_PORT2_CLK
;	cbi   PORT_CTRL234, CTRL4_CLK
;
;	sbic  PIN_CTRL1, CTRL1_DATA
;	sbi   PORT_NES_PORT, NES_PORT1_D1
;	sbis  PIN_CTRL1, CTRL1_DATA
;	cbi   PORT_NES_PORT, NES_PORT1_D1
;	
;	sbic  PIN_CTRL234, CTRL4_DATA
;	sbi   PORT_NES_PORT, NES_PORT2_D1
;	sbis  PIN_CTRL234, CTRL4_DATA
;	cbi   PORT_NES_PORT, NES_PORT2_D1
;	ijmp
;
;	
;.org 0x0B40
;FSTATE6:
;	sbic  PIN_NES_PORT, NES_PORT1_CLK
;	sbi   PORT_CTRL234, CTRL3_CLK
;	sbis  PIN_NES_PORT, NES_PORT1_CLK
;	cbi   PORT_CTRL234, CTRL3_CLK
;
;	sbic  PIN_NES_PORT, NES_PORT2_CLK
;	sbi   PORT_CTRL234, CTRL4_CLK
;	sbis  PIN_NES_PORT, NES_PORT2_CLK
;	cbi   PORT_CTRL234, CTRL4_CLK
;
;	sbic  PIN_CTRL234, CTRL3_DATA
;	sbi   PORT_NES_PORT, NES_PORT1_D1
;	sbis  PIN_CTRL234, CTRL3_DATA
;	cbi   PORT_NES_PORT, NES_PORT1_D1
;	
;	sbic  PIN_CTRL234, CTRL4_DATA
;	sbi   PORT_NES_PORT, NES_PORT2_D1
;	sbis  PIN_CTRL234, CTRL4_DATA
;	cbi   PORT_NES_PORT, NES_PORT2_D1
;	ijmp
;	
;	
;.org 0x0B80
;FSTATE7:
;	sbic  PIN_NES_PORT, NES_PORT2_CLK
;	sbi   PORT_CTRL234, CTRL4_CLK
;	sbis  PIN_NES_PORT, NES_PORT2_CLK
;	cbi   PORT_CTRL234, CTRL4_CLK
;
;	sbrc  ID1_BITS, 0
;	sbi   PIN_NES_PORT, NES_PORT1_D1
;	sbrs  ID1_BITS, 0
;	cbi   PIN_NES_PORT, NES_PORT1_D1
;
;	sbic  PIN_CTRL234, CTRL4_DATA
;	sbi   PORT_NES_PORT, NES_PORT2_D1
;	sbis  PIN_CTRL234, CTRL4_DATA
;	cbi   PORT_NES_PORT, NES_PORT2_D1
;	ijmp
;
;
;.org 0x0BC0
;FSTATE8:
;	subi  ZL, 0x40 ; go back to state 7
;	ijmp
;
;
;.org 0x0C00
;FSTATE9:
;	sbic  PIN_NES_PORT, NES_PORT1_CLK
;	sbi   PORT_CTRL1, CTRL1_CLK
;	sbis  PIN_NES_PORT, NES_PORT1_CLK
;	cbi   PORT_CTRL1, CTRL1_CLK
;
;	sbic  PIN_CTRL1, CTRL1_DATA
;	sbi   PORT_NES_PORT, NES_PORT1_D1
;	sbis  PIN_CTRL1, CTRL1_DATA
;	cbi   PORT_NES_PORT, NES_PORT1_D1
;	
;	sbrc  ID2_BITS, 0
;	sbi   PIN_NES_PORT, NES_PORT2_D1
;	sbrs  ID2_BITS, 0
;	cbi   PIN_NES_PORT, NES_PORT2_D1
;	ijmp
;
;	
;.org 0x0C40	
;FSTATE10:
;	sbic  PIN_NES_PORT, NES_PORT1_CLK
;	sbi   PORT_CTRL234, CTRL1_CLK
;	sbis  PIN_NES_PORT, NES_PORT1_CLK
;	cbi   PORT_CTRL234, CTRL1_CLK
;
;	sbic  PIN_CTRL234, CTRL3_DATA
;	sbi   PORT_NES_PORT, NES_PORT1_D1
;	sbis  PIN_CTRL234, CTRL3_DATA
;	cbi   PORT_NES_PORT, NES_PORT1_D1
;	
;	sbrc  ID2_BITS, 0
;	sbi   PIN_NES_PORT, NES_PORT2_D1
;	sbrs  ID2_BITS, 0
;	cbi   PIN_NES_PORT, NES_PORT2_D1
;	ijmp
;
;	
;.org 0x0C80	
;FSTATE11:
;	sbrc  ID1_BITS, 0
;	sbi   PIN_NES_PORT, NES_PORT1_D1
;	sbrs  ID1_BITS, 0
;	cbi   PIN_NES_PORT, NES_PORT1_D1
;
;	sbrc  ID2_BITS, 0
;	sbi   PIN_NES_PORT, NES_PORT2_D1
;	sbrs  ID2_BITS, 0
;	cbi   PIN_NES_PORT, NES_PORT2_D1
;	ijmp
;	
;	
;.org 0x0CC0
;FSTATE12:
;	subi   ZL, 0x40 ; go back to state 11
;	ijmp
;
;	
;.org 0x0D00
;FSTATE13:
;	dec   ZH        ; go back to state 9
;	ijmp
;
;
;.org 0x0D40	
;FSTATE14:
;	dec   ZH        ; go back to state 10
;	ijmp
;
;	
;.org 0x0D80	
;FSTATE15:
;	dec   ZH        ; go back to state 11
;	ijmp
;
;
;
;.org 0x0DC0	
;FSTATE16:
;	cli
;	dec   ZH        ; go back to state 11
;	subi   ZL, 0x40 ; go back to state 11
;	sei
;	ijmp
;
;



; 2_PLAYER      at 0x1000
; 2_PLAYER_FIX1 at 0x1040 (fix data and jump to 0x1000)
; 2_PLAYER_FIX2 at 0x1100 (fix data and jump to 0x1000)
.org 0x1000
STATE_2_PLAYER:
	sbic  PIN_NES_PORT, NES_PORT1_CLK
	sbi   PORT_CTRL1, CTRL1_CLK
	sbis  PIN_NES_PORT, NES_PORT1_CLK
	cbi   PORT_CTRL1, CTRL1_CLK

	sbic  PIN_NES_PORT, NES_PORT2_CLK
	sbi   PORT_CTRL234, CTRL2_CLK
	sbis  PIN_NES_PORT, NES_PORT2_CLK
	cbi   PORT_CTRL234, CTRL2_CLK

	sbic  PIN_CTRL1, CTRL1_DATA
	sbi   PORT_NES_PORT, NES_PORT1_D0
	sbis  PIN_CTRL1, CTRL1_DATA
	cbi   PORTD, NES_PORT1_D0
	
	sbic  PIN_CTRL234, CTRL2_DATA
	sbi   PORT_NES_PORT, NES_PORT2_D0
	sbis  PIN_CTRL234, CTRL2_DATA
	cbi   PORT_NES_PORT, NES_PORT2_D0
	ijmp

.org 0x1040
STATE_2_PLAYER_FIX1:
	subi  ZL, 0x40
	ijmp

.org 0x1100
STATE_2_PLAYER_FIX2:
	dec   ZH
	ijmp


; 4_PLAYER_SIMP      at 0x8080
; 4_PLAYER_SIMP_FIX1 at 0x8180 (fix data and jump to 0x8080)
; 4_PLAYER_SIMP_FIX2 at 0x9080 (fix data and jump to 0x8080)
;.org 0x1200
;STATE_4_PLAYER_SIMP:
;	sbic  PIN_NES_PORT, NES_PORT1_CLK
;	sbi   PORT_CTRL1, CTRL1_CLK
;	sbis  PIN_NES_PORT, NES_PORT1_CLK
;	cbi   PORT_CTRL1, CTRL1_CLK

;	sbic  PIN_NES_PORT, NES_PORT2_CLK
;	sbi   PORT_CTRL234, CTRL2_CLK
;	sbis  PIN_NES_PORT, NES_PORT2_CLK
;	cbi   PORT_CTRL234, CTRL2_CLK

;	sbic  PIN_NES_PORT, NES_PORT1_CLK
;	sbi   PORT_CTRL234, CTRL3_CLK
;	sbis  PIN_NES_PORT, NES_PORT1_CLK
;	cbi   PORT_CTRL234, CTRL3_CLK

;	sbic  PIN_NES_PORT, NES_PORT2_CLK
;	sbi   PORT_CTRL234, CTRL4_CLK
;	sbis  PIN_NES_PORT, NES_PORT2_CLK
;	cbi   PORT_CTRL234, CTRL4_CLK

;	sbic  PIN_CTRL1, CTRL1_DATA
;	sbi   PORT_NES_PORT, NES_PORT1_D0
;	sbis  PIN_CTRL1, CTRL1_DATA
;	cbi   PORT_NES_PORT, NES_PORT1_D0
	
;	sbic  PIN_CTRL234, CTRL2_DATA
;	sbi   PORT_NES_PORT, NES_PORT2_D0
;	sbis  PIN_CTRL234, CTRL2_DATA
;	cbi   PORT_NES_PORT, NES_PORT2_D0

;	sbic  PIN_CTRL234, CTRL3_DATA
;	sbi   PORT_NES_PORT, NES_PORT1_D1
;	sbis  PIN_CTRL234, CTRL3_DATA
;	cbi   PORT_NES_PORT, NES_PORT1_D1
	
;	sbic  PIN_CTRL234, CTRL4_DATA
;	sbi   PORT_NES_PORT, NES_PORT2_D1
;	sbis  PIN_CTRL234, CTRL4_DATA
;	cbi   PORT_NES_PORT, NES_PORT2_D1
;	ijmp


;.org 0x1240
;STATE_4_PLAYER_SIMP_FIX1:
;	subi  ZL, 0x40
;	ijmp

;.org 0x1300
;STATE_4_PLAYER_SIMP_FIX2:
;	subi  ZH, 0x10
;	ijmp

; this is a location in program memory
; that is designed to ignore all operations
; until a LATCH interrupt
; clock signals are jumped to on interrupt
; but executing the CLK has no effect
; on changing the PIN outputs.
.org 0x1400
WAITING_LOOP:
	clr CLKCTR1
	clr CLKCTR2
	ijmp      ; should LOOP until the latch or clock
	
.org 0x1440
WAITING_LOOP_FIX1:
	clr CLKCTR1
	clr CLKCTR2
    subi  ZL, 0x40   ; go back to WAITING_LOOP
	ijmp             ; should LOOP until the latch or clock

.org 0x1500
WAITING_LOOP_FIX2:
	clr CLKCTR2    ; clock 2 incrementing caused this transition, so clear it first
	clr CLKCTR1
	dec  ZH        ; go back to WAITING_LOOP
	ijmp           ; should LOOP until the latch or clock

.dseg
