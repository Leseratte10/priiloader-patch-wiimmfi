//
// Copyright (c) 2020-2023 Leseratte10
// This file is part of the Priiloader Wiimmfi patch hack by Leseratte.
// https://github.com/Leseratte10/priiloader-patch-wiimmfi
// 
//
// It provides the two library functions memcmp and memcpy. 
//
//

.globl _wrap_memcmp

_wrap_memcmp: 
	addi r7, r4, -1;		// r7 = ptr to 2nd string-1
	addi r6, r3, -1; 		// r6 = ptr to 1st string-1
	addi r4, r5, 1;			// r4 = length+1
	b 2f;					// go to length check

1:	lbzu r3, 1(r6);
	lbzu r0, 1(r7); 
	cmplw r3, r0; 
	beq 2f;

	li r3, 1; 
	blr;
			// if we end up here, the strings aren't equal.
			// I don't care which of the chars is larger than the other
			// (we aren't using the return value of memcmp other than checking != 0)
			// so we can just always return 1.
	
	
2:	addic. r4, r4, -1;		// if we aren't done yet, go to 1b and compare a byte
	bne 1b;
	li r3, 0;				// if we are done, and we end up here, well, strings are equal. return 0.
	blr;

.globl _wrap_memcpy
_wrap_memcpy: 
		cmpwi   cr7,r5,0
		addi    r5,r5,-1
		beqlr   cr7

		addi    r9,r5,1
		addi    r3,r3,-1
		addi    r4,r4,-1
		mtctr   r9

	1:	lbzu    r9,1(r4)
		stbu    r9,1(r3)
		bdnz    1b;
		
		blr