# openfourplayer168

(c) 2021 Akerasoft
Akerasoft - author for purposes of copyright.

Credits:
Developer - Robert Kolski

Contact: robert.kolski@akeraiotitasoft.com

Thanks
www.nesdev.org
https://www.famicomworld.com/forum/index.php?topic=15160.15
lifewithmatthew on https://www.famicomworld.com posted the schematic on that website that I included.
https://en.wikipedia.org/wiki/NES_Four_Score


##History
I began a company to make software and games.  For a while I was not sure what I would work on.  Then eventually I decided to work on Nintendo
based arcades.  So I wanted to know how all of the Nintendo hardware worked.

I am aware that it is possible to connect 6 4021 registers together to get a total of 32 buttons and 16 ID signals sent.
That is 2 data circuits in parallel 3 4021 registers per circuit.  The 8-bit 4021 registers are in series of 3 of them.
I forgot the page where I read about that.

However I wanted to make some parts interchangable so in order to make controllers that can be plugged in a 4 player adapter of some sort
needs to be created.

##What this is:
This is a project to simulate the NES Four Score to run on real Nintendo Hardware and compatible hardware such as Retron1 HD.

Based on my understanding the NES runs at approximately 1MHz.
Due to limited number of instructions possible, this means that this simulator needs to run at 20MHz and try to complete a cycle in approximately 1 to 2 NES Cycles.
1 cycle of NES sends either LATCH or CLK signal, then the next cycle reads the value of D0 (data pin) for each controller.
So need to completely respond to interrupt and then copy data within 20 clock cycles... maybe as many as 40 clock cycles...
That is why 20MHz is important here.
If testing shows that it just does not make it, then the next test will be to use ATXMEGA at 32MHz.
If further testing shows that also does not work then we should try 100MHz processor, faster should not be necessary.

Assembly language was used in order to make the most of the processor.
At this time SRAM is only used for the stack.  And only used to store the Program Counter.
All data is stored in the registers to make this program run as quickly as possible.

This is not compatible with Arduino because I program 100% in assembly.  So WinAVR2010 or Microchip Studio are needed.
An ICSP programmer is need for this.  This was designed for ATMEGA168P but I don't see why ATMEGA328P would not work.

Please note that this is my first program in avr-gcc as an assembly program (I know avr-gcc calls the assembler).

I also did not take the time to finish my KiCAD PCB.  But the schematic is complete.  It is only for a development board.
It uses 2 5-pin JST-XH connectors 2.54mm as input.  And has 4 5-pin connectors to connect to controllers.  It is for making
cut extension cords have a 5-pin connector to the board on one side and 7-pin connector on the other side.

Please note that there are different algorithms possible, some like the one included here in this initial attempt use the
NES latch and send it to the controller.  This method has a race that the latch and clock have to be responeded to in time
so that the data signals can be sent back in time.

I have an althernate algorithm that uses C++ that could produce it's own latch signals.
This one is not posted yet.  I was thinking of using Teensy 2.0 for it.  (Which can be programmed by Arduino).
It does not have the race condition, but the controller input might be more stale.

Anyway this has not been tested yet because I do not have the capacitors for the Crystal.
So my proto board is not completed yet.

I'm also not sure if avr-gcc is compiling (assembling) it correctly.

## Credit of trademarks
Please note that Nintendo and NES are trademarks/registered trademarks of Nintendo Co. Ltd. of Japan and Nintendo of America, Inc.
The manufacturer of the original Four Score is HORI.

## About the Company
Akerasoft is a DBA for Akeraiotitasoft LLC
http://www.akeraititasoft.com
https://www.akerasoft.com