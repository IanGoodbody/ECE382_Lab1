# Lab1
# Assembly Language Calculator

## Objectives

The lab's purpose was to design an unsigned 8 bit calculator for a TI MSP430 microcontroller. The design specificatons and functionalities required the calculator to read a series of byte instructions from ROM, effeciently process the data, then output the results to RAM. The required functions were addition, subtraction, O(log n) multiplication, clear, and an end operation. Additional functionality for the unsigned value calculator required the results for addition and subtraction remain within 255 and 0 and that the result should show these maxes should an overflow or carry occure. The result from each operation should be stored and used in the next operation

## Preliminary Design

Per the lab requirements the instructions for the calculator program were to be stored as 8 bit words in the following pattern:

    0xValue, 0xOperand, 0xValue, 0xOperand, 0xValue . . . 0xEnd_Op
    
Operands were to be 0x11 for addition, 0x22 for subtraction, 0x33 for multiplication, 0x44 for clear which stores 0 to memory and loads the next value, and 0x55 for the end operation which ceases the program. The logical structe of the design would then be to store the first value then read the operand to jump to the indicated operation and finally to read in the second value, perform the operation, store it to memory, and then increment the address pointer. The outline of this implementation is shown below:

![alt text](https://github.com/IanGoodbody/ECE382_Lab1/Calc_Flowchart.jpg "Logo Title Text 1")

#### O(log n) Multiplication implementation

While all the other operations are fairly obvious from the flowchart, the implementation fo the multiplication function requires further calarification. Because the reduced instruction set compiler does not have a hardware or emulated multiplication instruction, only multiplication by powers of two can be emulated using a rotate left instruction. However, the fact that the calculator stores binary numbers can be utalized in combination with this binary multiplication to multiply any two numbers that will not overflow.

Take the two operands 
