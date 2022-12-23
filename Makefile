# Hey Emacs, this is a -*- makefile -*-

# MCU name
MCU = atmega168

# Processor frequency.
#     This will define a symbol, F_CPU, in all source code files equal to the 
#     processor frequency. You can then use this symbol in your source code to 
#     calculate timings. Do NOT tack on a 'UL' at the end, this will be done
#     automatically to create a 32-bit value in your source code.
#     Typical values are:
#         F_CPU =  1000000
#         F_CPU =  1843200
#         F_CPU =  2000000
#         F_CPU =  3686400
#         F_CPU =  4000000
#         F_CPU =  7372800
#         F_CPU =  8000000
#         F_CPU = 11059200
#         F_CPU = 14745600
#         F_CPU = 16000000
#         F_CPU = 18432000
#         F_CPU = 20000000

# recommended is F_CPU = 20000000
# but I have not set up this crystal yet, nor did I program the fuses.

F_CPU = 20000000

OBJDIR=.

# Default target.
all:
	avr-gcc -c -mmcu=$(MCU) -o openfourplayer168.o openfourplayer168.S -Wa,-adhlns=openfourplayer168.lst,-gstabs,--listing-cont-lines=100
	avr-ld -e init -o openfourplayer168.elf openfourplayer168.o
	avr-objcopy -O ihex openfourplayer168.elf openfourplayer168.hex
