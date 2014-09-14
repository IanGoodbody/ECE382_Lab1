# Lab1
# Assembly Language Calculator

## Objectives

The lab's purpose was to design an unsigned 8 bit calculator for a TI MSP430 microcontroller. The design specifications and functionalities required the calculator to read a series of byte instructions from ROM, efficiently process the data, and then output the results to RAM. The required functions were addition, subtraction, O(log n) multiplication, clear, and an end operation. Additional functionality for the unsigned value calculator required the results for addition and subtraction remain within 255 and 0 and that the result should show these maxes should an overflow or carry occur. The result from each operation should be stored and used in the next operation

## Preliminary Design

Per the lab requirements the instructions for the calculator program were to be stored as 8 bit words in the following pattern:
````
    0xValue, 0xOperand, 0xValue, 0xOperand, 0xValue . . . 0xEnd_Op
````    
Operands were to be 0x11 for addition, 0x22 for subtraction, 0x33 for multiplication, 0x44 for clear which stores 0 to memory and loads the next value, and 0x55 for the end operation which ceases the program. The logical structure of the design would then be to store the first value then read the operand to jump to the indicated operation and finally to read in the second value, perform the operation, store it to memory, and then increment the address pointer. The outline of this implementation is shown below:

![alt text](https://raw.githubusercontent.com/IanGoodbody/ECE382_Lab1/master/Calc_Flowchart.jpg "Program Flowchart")

#### O(log n) Multiplication implementation

While all the other operations are fairly obvious from the flowchart, the implementation of the multiplication function requires further clarification. Because the reduced instruction set compiler does not have a hardware or emulated multiplication instruction, only multiplication by powers of two can be emulated using a rotate left instruction. However, the fact that the calculator stores binary numbers can be utilized in combination with this rotation multiplication in order to multiply any two numbers, given that they will not overflow.

The process can be shown in the following example:
````
7 * 6 
7 * 0110b
7 * (0*2^3 + 1*2^2 + 1*2^1 + 0*2^0)
7*2^2 + 7*2^1
RL(RL(7)) + RL(7)
````
Thus, by using the binary representation of one operand to separate it into a sum of binary powers and distributing the other operand through this sum, the result of the multiplication can be achieved by summing the rotated operands. The number of rotations is determined by the order of each '1' bit in the other operand.

Practically implementing this scheme in the flowchart involved rotating the second operand right to retrieve the bits from least significant to most significant, adding the first operand to an accumulating register if the retrieved bit was '1', then rotating the first operand left to represent the next order of multiplication. This process was looped until the second operand was 0, was completely multiplied out. With each rotate left and addition the program checks for a carry to ensure that the number has not overflowed.

While an O(n) multiplication algorithm, such as a looped addition (adding 7 into an accumulating register 6 times), this algorithm is roughly O(log n) as the program will only loop until it reaches the most significant '1' bit (7*6 only loops 3 times as opposed to 6).

## Testing and Debugging

### Deviations from the preliminary design

The assembly program was subsequently created based on the flowchart scheme; however, a number of implementation issues surfaced while coding.

1. The rotate commands RRC and RLC move the carry bit into the MSB of the number being rotated before moving the LSB into the carry position. In order to rotate one operand right to zero and the other left to achieve binary multiplication the carry bit had to be reset prior to each rotation.

2. In order to check for a negative result in subtraction, the flowchart tested the processor's overflow bit. However this bit only triggers if a bit carries into the "signed" MSB of the number and is useful mostly for _signed_ arithmetic. Instead the functionality was implemented using the JLO (jump if lower) instruction which was designed for _unsigned_ operations. This instruction checks if a carry had not occurred which indicates that the signed bit is in essence stuck in the unsigned number rather than carrying out.

3. The overflow error catching shown in the flow chart, where an error LED turned on and the process terminated, did not meet the functionality requirements to set the result to the max or min for an unsigned 8 bit number and to move on with the program. Separate code processes were created to set the result to the required value, 255 or 0 for max and min respectively, and to jump back into the program.

4. The flowchart implementation for multiplication raised an error if the rotate left instruction produced a carry, i.e. it would add a number on the next iteration that was out of 8 bit range. However, because this operation takes place at the end of the loop before the program checks if multiplication is complete, there is a possibility that it will be rejecting the multiplication because of an overflowed number that will not be used in the actual process. An additional check was used if the doubling rotation produced a carry to see if multiplication was complete before it raised an error.

### Test programs

Included in the top of the code file are a number of calculator test programs, with labels as to their function. In general the programs conduct a basic functionality test, ensure that 2+2 = 4, then a stress test to ensure that the error checking functionality was valid. 

Most of these programs are fairly straightforward, excepting the multiplication testing program which was consolidated into one string of numbers to save developer headache. A detailed explanation is provided below.

````
0x02, 0x33, 0x7F
````
This preformed a basic function test using a fairly large number as the second operand. The result, 0xFE, was meant to push the result up to the most extreme value. It should be noted that the speed of the multiplication algorithm varies significantly with the order of the factors, where 0x02 * 0x7F will be completed using only two iterations of the loop, 0x7F * 0x02 will require 7 iterations through the looping algorithm.

````
(0xFE), 0x33, 0x02
````
This operation tested the rotation overflow check which should result in the max value 0xFF. This program in particular should trigger the carry test after the 7th rotation iteration (the program will try to conduct 8).

````
0x80, 0x33, 0x01
````
This tests the identity multiplication case, and pushes the limits of the rotation overflow. Upon completion of the first iteration (adding 0x80 into the accumulating register) the program will rotate 0x80 left and place a '1' in the carry bit which triggers an error unless the program recognizes that the multiplication is complete.

````
0x02, 0x33, 0xFF
````
This operation should produce a maximum error based on rotation.

````
0x00, 0x33, 0xAA
````
This operation tests one of the special cases of multiplication, it should produce 0. In addition this operation is another example of how the speed of the program is contingent on order. A possible future improvement would be to select which number performed which function within the multiplication program based on their size rather than their order.

````
0x0F, 0x33, 0x07
````
The final multiplication test case is designed to push the limits of the multiplication algorithm by multiplying factors with large number of '1' bits.

In the end, all of the designer made tests and instructor provided functionality tests, produced the desired outputs and the project was considered complete.

### Documentation

1. Referenced the MSP430 family users guide for clarification on instruction operations
2. Used the [github help documentation](http://git-scm.com/doc) for a review on github operations. (It was/is very much worth my time in reading)
