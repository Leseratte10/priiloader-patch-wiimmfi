//
// Copyright (c) 2020-2023 Leseratte10
// This file is part of the Priiloader Wiimmfi patch hack by Leseratte.
// https://github.com/Leseratte10/priiloader-patch-wiimmfi
// 
//
// This is the actual patcher code that runs in the context of the
// System Menu and applies all the necessary Wiimmfi patches to the game
// before it is executed. 
//
//


/// PARAMETERS:

#if VERSION != 0
	.int PATCHADDR + 4;		// patchaddr + 4 for return so the code knows where to return to.

	// This is the patcher info string that's injected into MKWii so Wiimmfi knows which patcher is used.
	data_patcher_info:
	#if VERSION == 514 		// v514 - 4.3E
		.asciz "Priiloader patch rev 4 (4.3E)              "	// must be this long
	#elif VERSION == 482 	// v482 - 4.2E
		.asciz "Priiloader patch rev 4 (4.2E)              "	// must be this long
	#elif VERSION == 450	// v450 - 4.1E
		.asciz "Priiloader patch rev 4 (4.1E)              "	// must be this long
	#elif VERSION == 513	// v513 - 4.3U
		.asciz "Priiloader patch rev 4 (4.3U)              "	// must be this long
	#elif VERSION == 481	// v481 - 4.2U
		.asciz "Priiloader patch rev 4 (4.2U)              "	// must be this long
	#elif VERSION == 449 	// v449 - 4.1U
		.asciz "Priiloader patch rev 4 (4.1U)              "	// must be this long
	#elif VERSION == 512	// v512 - 4.3J
		.asciz "Priiloader patch rev 4 (4.3J)              "	// must be this long
	#elif VERSION == 480 	// v480 - 4.2J
		.asciz "Priiloader patch rev 4 (4.2J)              "	// must be this long
	#elif VERSION == 448 	// v448 - 4.1J
		.asciz "Priiloader patch rev 4 (4.1J)              "	// must be this long
	#elif VERSION == 518 	// v518 - 4.3K
		.asciz "Priiloader patch rev 4 (4.3K)              "	// must be this long
	#elif VERSION == 486 	// v486 - 4.2K
		.asciz "Priiloader patch rev 4 (4.2K)              "	// must be this long
	#elif VERSION == 454 	// v454 - 4.1K
		.asciz "Priiloader patch rev 4 (4.1K)              "	// must be this long
	#elif VERSION == 4609	// v4609 - Wii Mini NTSC 4.3U
		.asciz "Priiloader patch rev 4 (4.3U Mini)         "	// must be this long
	#elif VERSION == 4610	// v4610 - Wii Mini PAL 4.3E
		.asciz "Priiloader patch rev 4 (4.3E Mini)         "	// must be this long
	#elif VERSION == 608 	// v608 - WiiU 4.3J
		.asciz "Priiloader patch rev 4 (WiiU 5.2.0J)       "	// must be this long
	#elif VERSION == 609 	// v609 - WiiU 4.3U
		.asciz "Priiloader patch rev 4 (WiiU 5.2.0U)       "	// must be this long
	#elif VERSION == 610 	// v610 - WiiU 4.3E
		.asciz "Priiloader patch rev 4 (WiiU 5.2.0E)       "	// must be this long
	#else
	#warning "invalid version"
		.asciz "Priiloader patch rev 4 (unknown version)   "	// must be this long
	#endif
#else

#endif

#if VERSION == 0 || FULL == 1

.globl _loading
// "loading" is the very first function that runs. and needs to be on top of the file. stores stack crap, then calls main
_loading:
	// store stack stuff:
	stwu r1, -172(r1);
	stw r0,8(r1)
	mflr r0
	stw r0,176(r1)
	stmw r2,20(r1)

	// at this point we would call OSDisableInterrupts. that function
	// just has 4 lines (+blr), let's just include it in here, then
	// we don't have to bother about porting it to all the different regions
	mfmsr r3; 
	rlwinm r4, r3, 0x0, 0x11, 0xf; 
	mtmsr r4; 
	rlwinm r3, r3, 0x11, 0x1f, 0x1f; 
	
	stw r3, 12(r1); 	// store current interrupts
	
	// All the setup is done. Stack is stored, interrupts are saved. 
	// Fall through into wiimmfi_patcher

	wiimmfi_patcher:
		// This is the actual code for the Wiimmfi patch. Registers are all stored already, we just need to jump back to loading when we're done.
	
		// First, do the normal Wiimmfi patch for all games:
	
		// HTTPS -> HTTP conversion
		lis r27, 0x8000;	// r27 is 0x80000000 and stays that way during execution. 
		ori r3, r27, 0x4000; 	// r3 = start / current address
		lis r4, 0x8090; 	// r4 = end address
	
		lis r6, 0x6874; 	// r6 = "http"
		ori r6, r6, 0x7470;
		lis r7, 0x733a; 	// r7 = "s://"
		ori r7, r7, 0x2f2f;
	
	loop1:
		cmpw r3, r4;
		bge- nextcheck;
		addi r3, r3, 1;
		lwz r5, 0(r3); 		// loop until we find "http"
		cmpw r5, r6;
		bne+ loop1;
	
		lwz r5, 4(r3);		// now that we found "http", check for "s://"
		cmpw r5, r7;
		bne+ loop1;
	
					// now we found a full https URL that begins at r3. need to patch somehow.
		addi r8, r3, 4; 	// r8 = source
		addi r9, r3, 3; 	// r9 = dest. need to copy byte for byte until NULL
	
	loop2: 		// loop through that URL
		lbzu r10, 1(r8);
		stbu r10, 1(r9);
	
		cmpwi r10, 0;
		bne+ loop2;
		b loop1;
	
	nextcheck: 	// HTTPS is now patched, now patch Wiimmfi URLs
		// now that we did that "http" -> "https" change, lets do the "nintendowifi.net" -> "wiimmfi.de" change
		ori r3, r27, 0x4000; 	// r3 = start / current address. r27 is 0x80000000
		lis r4, 0x8090; 	// r4 = end address
	
		lis r12, 0x6e69; 	// "ni"
		ori r12, r12, 0x6e74; 	// "nt"
		lis r19, 0x656e; 	// "en"
		ori r19, r19, 0x646f; 	// "do"
		lis r14, 0x7769; 	// "wi"
		ori r14, r14, 0x6669; 	// "fi"
		lis r15, 0x2e6e; 	// ".n"
		ori r15, r15, 0x6574; 	// "et"
	
		lis r16, 0x7769; 	// "wi"
		ori r16, r16, 0x696d; 	// "im"
		lis r17, 0x6d66; 	// "mf"
		ori r17, r17, 0x692e; 	// "i."
		lis r18, 0x6465; 	// "de"
	
	loop3:
		cmpw r3, r4;
		bge- gamecheck;
		addi r3, r3, 1;
	
		lwz r5, 0(r3); 		// loop until we find "nint ..."
		cmpw r5, r12;
		bne+ loop3;
	
		lwz r5, 4(r3);		// "... endo ..."
		cmpw r5, r19;
		bne- loop3;
	
		lwz r5, 8(r3);		// "... wifi ..."
		cmpw r5, r14;
		bne- loop3;
	
		lwz r5, 12(r3);		// "... .net ..."
		cmpw r5, r15;
		bne- loop3;
	
		// if we're still here, we found a "nintendowifi.net" URL at r3. So first, copy the "wiimmfi.de" URL over that:
		stw r16, 0(r3);
		stw r17, 4(r3);
		stw r18, 8(r3);
	
		// now copy over the rest:
	
		addi r8, r3, 15; 	// r8 = source
		addi r9, r3, 9; 	// r9 = dest. need to copy byte for byte until NULL
	
	loop4: 		// loop through that URL
		lbzu r10, 1(r8);
		stbu r10, 1(r9);
	
		cmpwi r10, 0;
		bne+ loop4;
		b loop3;
	
		// Wiimmfi patch done.
		b gamecheck;
	
	
	
	db_call:
		bl datablob_return;
	datablob:
		nop;
		ca_url:
		.asciz "http://ca.nas.wiimmfi.de/ca"
	
		ac_url:
		.asciz "http://naswii.wiimmfi.de/ac"
	
		payload_url:
		.asciz "https://main.nas.wiimmfi.de/pp\x00"
	
		// space at 80001000: 192 instructions.
		// Wiimmfi patches and REL patches take 120+44+20 = 184 ins. perfect

		// The first two patches (patch_bean_1 and patch_bean_2) are the Wiimmfi update code
		// for MKWii that makes the game download and install the game updates from Wiimmfi. 
		// The third patch (patch_staticr) is code that hooks into MKWii when the StaticR has 
		// been fully loaded and linked and then runs a rudimentary Wiimmfi patcher (just URL
		// replacements) on the StaticR so all the URLs that are in that file are also patched
		// for Wiimmfi.
	
		patch_bean_1: // 20 ins
		.long 0x2C030000, 0x40810040, 0x8061000C, 0x800D9738
		.long 0x2C000002, 0x41820014, 0x906DA14C, 0x38000002
		.long 0x900D9738, 0x48000020, 0x38830003, 0x5484003A
		.long 0x88A40000, 0x7CA42A14, 0x7C0028AC, 0x7CA803A6
		.long 0x4E800021, 0x3860FFFF, 0x2C030000, 0x00000000
	
		patch_bean_2: // 44 ins
		.long 0x808DA14C, 0x28040001, 0x408100A0, 0x9421FF80
		.long 0x38610020, 0x3C00801D, 0x600024f4, 0x7C0803A6
		.long 0x4E800021, 0x38610020, 0x808DA14C, 0x38A00554
		.long 0x90BC00C4, 0x3C00801D, 0x60002544, 0x7C0803A6
		.long 0x4E800021, 0x38610020, 0x38810010, 0x3C00801D
		.long 0x600025f8, 0x7C0803A6, 0x4E800021, 0x48000018
		.long 0x0fff1f07, 0x00e638c9, 0x49fbeffa, 0x79022d3a
		.long 0x84ab134F, 0x7C6802A6, 0x3881000C, 0x38A00005
		.long 0x7CA903A6, 0x84A30004, 0x84C40004, 0x7C062800
		.long 0x40820008, 0x4200FFF0, 0x7C062800, 0x38210080
		.long 0x808DA14C, 0x41820008, 0x38800000, 0x00000000
	
		patch_staticr: // 120 ins
		.long 0x7C651B78, 0x88C50000, 0x2C060068, 0x40A20068, 0x88C50001, 0x2C060074, 0x40A2005C, 0x88C50002	//  82
		.long 0x2C060074, 0x40820050, 0x88C50003, 0x2C060070, 0x40820044, 0x88C50004, 0x2C060073, 0x40820038    //  90
		.long 0x88C50005, 0x2C060000, 0x40820010, 0x38C00000, 0x98C50004, 0x48000020, 0x38E50003, 0x39050004    //  98
		.long 0x8D280001, 0x9D270001, 0x2C090000, 0x4082FFF4, 0x9D270001, 0x88C50000, 0x2C06006E, 0x40A20118    // 106
		.long 0x88C50001, 0x2C060069, 0x40A2010C, 0x88C50002, 0x2C06006E, 0x40820100, 0x88C50003, 0x2C060074    // 114
		.long 0x408200F4, 0x88C50004, 0x2C060065, 0x408200E8, 0x88C50005, 0x2C06006E, 0x408200DC, 0x88C50006    // 122
		.long 0x2C060064, 0x408200D0, 0x88C50007, 0x2C06006F, 0x408200C4, 0x88C50008, 0x2C060077, 0x408200B8    // 130
		.long 0x88C50009, 0x2C060069, 0x408200AC, 0x88C5000A, 0x2C060066, 0x408200A0, 0x88C5000B, 0x2C060069    // 138
		.long 0x40820094, 0x88C5000C, 0x2C06002E, 0x40820088, 0x88C5000D, 0x2C06006E, 0x4082007C, 0x88C5000E    // 146
		.long 0x2C060065, 0x40820070, 0x88C5000F, 0x2C060074, 0x40820064, 0x38E00077, 0x98E50000, 0x38E00069    // 154
		.long 0x98E50001, 0x98E50002, 0x98E50006, 0x38E0006D, 0x98E50003, 0x98E50004, 0x38E00066, 0x98E50005    // 162
		.long 0x38E0002E, 0x98E50007, 0x38E00064, 0x98E50008, 0x38E00065, 0x98E50009, 0x39050009, 0x3925000F    // 170
		.long 0x8CE90001, 0x9CE80001, 0x2C070000, 0x4082FFF4, 0x9CE80001, 0x38A50001, 0x3D208089, 0x6129A66C    // 178
		.long 0x7C092800, 0x41820014, 0x3D208089, 0x6129A738, 0x7C092800, 0x40A20008, 0x38A50040, 0x3D2080A0    // 186
		.long 0x7C092800, 0x4181FE40, 0x38A00000, 0x3D00801A, 0x61086FFC, 0x7D0903A6, 0x4E800420                // 194
	
		end_of_bean_patches:
		nop;
	
		korea_patches:
		// These are instructions that need to be modified in the code above to work for Korean games.
		.long 0x800d9758, 0x906da16c, 0x900d9758, 0x808da16c, 0x60002850, 0x808da16c, 0x600028A0, 0x60002954, 0x808dA16c
	
	
	
	gamecheck:
		// At this point the generic Wiimmfi patch is done, and MKWii would throw a 23904 (outdated patcher) error
		// now we have to add
		// 	A) the MKWii-specific updater code, and
		// 	B) the StaticR.rel patching code
	
		// r27 is 0x80000000
		li r4, 0x52; 	// 'R'
		li r5, 0x4d; 	// 'M'
		li r6, 0x43; 	// 'C'
	
		lbz r7, 0(r27);
		cmpw r7, r4;
		bne- 5f;
	
		lbz r7, 1(r27);
		cmpw r7, r5;
		bne 5f;
	
		lbz r7, 2(r27);
		cmpw r7, r6;
		bne 5f;
	
	
		// now that we're here, we know that this is MKWii. Let's determine the region and store that (forever) in r31.
		lbz r31, 3(r27);
	
		// also, we now know the address of memcpy so let's grab that
		ori r30, r27, 0x5f34; 	// r30 is now the address of memcpy.
	
		// get addr of data blob and store in r29 forever:
		b db_call;
	datablob_return:
		mflr r29; 	// r29 now contains start address of datablob
	
		// STEP 1: Get dest addr for patcher string.
	
			lis r3, 0x8027; 	// 1st half for all regions
	
			cmpwi r31, 0x50;
			bne 1f;
			ori r3, r3, 0x6054; 	// load PAL addr.
	
		1:	cmpwi r31, 0x45;
			bne 1f;
			ori r3, r3, 0x1d14; 	// USA addr.
	
		1:	cmpwi r31, 0x4a;
			bne 1f;
			ori r3, r3, 0x59f4; 	// JAP addr.
	
		1: 	cmpwi r31, 0x4b;
			bne 2f;
			lis r3, 0x8026;
			ori r3, r3, 0x3e34; 	// KOR addr.
	
		2:	// r3 now contains destination for the patcher string.
			// r4 is supposed to contain the src, so get the ptr to the data string
			
			lis r4, LOADADDRESS@ha; 
			addi r4, r4, LOADADDRESS@l; 
			addi r4, r4, 4; 
	
			// r5 is the length, so load 42
			li r5, 42;
	
			// call memcpy to copy the patcher name:
			mtlr r30;
			blrl;
	
		// STEP 2: Patch the login server URLs
		// define destination address:
	
			lis r3, 0x8027;
	
			cmpwi r31, 0x50;
			bne 1f;
			ori r3, r3, 0xa400; 	// PAL addr.
	
		1:	cmpwi r31, 0x45;
			bne 1f;
			ori r3, r3, 0x60c0; 	// USA addr.
	
		1:	cmpwi r31, 0x4a;
			bne 1f;
			ori r3, r3, 0x9da0; 	// JAP addr.
	
		1: 	cmpwi r31, 0x4b;
			bne 1f;
			lis r3, 0x8026;
			ori r3, r3, 0x82b0; 	// KOR addr.
	
			// r3 is dest for 1st login url -> backup in r28
		1: 	mr r28, r3;
	
		// STEP 2a: Copy first URL (CA):
	
			addi r4, r29, ca_url - datablob;
	
			// r5 is the length, so load 28 as that's the strlen of the ca_url
			li r5, 28;
	
			// call memcpy to copy the 1st URL:
			mtlr r30;
			blrl;
	
		// STEP 2b: Copy 2nd URL (AC):
			addi r3, r28, 0x28;
			addi r4, r29, ac_url - datablob;
	
			// r5 = length
			li r5, 28;
	
			// call memcpy
			mtlr r30;
			blrl;
			
		// STEP 2c: Fix last letter:
	
			addi r3, r31, 0x20; 	// r3 is now the lowercase region letter
			addi r4, r29, payload_url - datablob + 29; 	// r4 is the offset
	
			stb r3, 0(r4); 		// store the byte
	
		// STEP 2d: Copy 3rd URL (payload):
	
			addi r3, r28, 0x4c;
			addi r4, r29, payload_url - datablob;
	
			// r5 = length
			li r5, 31;
	
			// call memcpy
			mtlr r30;
			blrl;
	
		// STEP 2e: Two more patches:
	
			lis r15, 0x733a;
			ori r15, r15, 0x2f2f;
			lis r16, 0x3bc0;
			lis r17, 0x800e;
	
			cmpwi r31, 0x45;
			bne 1f;
			// USA patch:
			lis r3, 0x8029;
			ori r3, r3, 0xd12c;
			stw r15, 0(r3);
			stw r15, 0xe20(r3); 
			ori r17, r17, 0xca0c;
			stw r16, 0(r17);
			b 2f;
	
		1:	cmpwi r31, 0x4a;
			bne 1f;
			// JAP patch:
			lis r3, 0x802a;
			ori r3, r3, 0x0e0c;
			stw r15, 0(r3);
			stw r15, 0xe20(r3); 
			ori r17, r17, 0xc9cc;
			stw r16, 0(r17);
			b 2f;
	
		1: 	cmpwi r31, 0x4b;
			bne 1f;
			// KOR patch:
			lis r3, 0x8028;
			ori r3, r3, 0xf474;
			stw r15, 0(r3);
			stw r15, 0xe20(r3); 
			ori r17, r17, 0xcb24;
			stw r16, 0(r17);
			b 2f;
	
		1: 	// PAL patch:
			lis r3, 0x802a;
			ori r3, r3, 0x146c;
			stw r15, 0(r3);
			stw r15, 0xe20(r3);
			ori r17, r17, 0xcaac;
			stw r16, 0(r17);
		2: 	
	
	
		// STEP 3a: Get some space at 80001000 for the Wiimmfi patches.
	
		// r27 is 0x80000000, so this makes r28 = 0x80001000
		ori r28, r27, 0x1000;
	
		// STEP 3b: Copy patches over:
	
			mr r3, r28;
			addi r4, r29, patch_bean_1 - datablob;
			li r5, end_of_bean_patches - patch_bean_1
	
			// call memcpy
			mtlr r30;
			blrl;
	
		// STEP 3c: Fix the non-PAL regions:
	
			cmpwi r31, 0x45;
			bne 1f;
			// USA patch:
			lis r3, 0x6000;
			addi r4, r3, 0x2454;
			addi r5, r3, 0x24a4;
			addi r6, r3, 0x2558;
			stw r4, 26*4(r28);
			stw r5, 34*4(r28);
			stw r6, 40*4(r28);
			lis r3, 0x6129;
			ori r4, r3, 0x5c74;
			ori r5, r3, 0x5d40;
			lis r3, 0x6108;
			ori r6, r3, 0x6f5c;
			stw r4, 167*4(r28);
			stw r5, 171*4(r28);
			stw r6, 180*4(r28);
			b 3f;
	
	
		1:	cmpwi r31, 0x4a;
			bne 1f;
			// JAP patch:
			lis r3, 0x6000;
			addi r4, r3, 0x2414;
			addi r5, r3, 0x2464;
			addi r6, r3, 0x2518;
			stw r4, 26*4(r28);
			stw r5, 34*4(r28);
			stw r6, 40*4(r28);
			lis r3, 0x6129;
			ori r4, r3, 0x97cc;
			ori r5, r3, 0x9898;
			lis r3, 0x6108;
			ori r6, r3, 0x6f1c;
			stw r4, 167*4(r28);
			stw r5, 171*4(r28);
			stw r6, 180*4(r28);
			b 3f;
	
		1: 	cmpwi r31, 0x4b;
			bne 3f;
			// KOR patch:
			addi r3, r29, korea_patches - datablob;
	
			lwz r4, 0(r3);
			stw r4, 3*4(r28);
	
			lwz r4, 4(r3);
			stw r4, 6*4(r28);
	
			lwz r4, 8(r3);
			stw r4, 8*4(r28);
	
			lwz r4, 12(r3);
			stw r4, 20*4(r28);
	
			lwz r4, 16(r3);
			stw r4, 26*4(r28);
	
			lwz r4, 20(r3);
			stw r4, 30*4(r28);
	
			lwz r4, 24(r3);
			stw r4, 34*4(r28);
	
			lwz r4, 28(r3);
			stw r4, 40*4(r28);
	
			lwz r4, 32(r3);
			stw r4, 60*4(r28);
	
			lis r4, 0x3d20;
			ori r4, r4, 0x8088;
	
			stw r4, 166*4(r28);
			stw r4, 170*4(r28);
	
			lis r4, 0x6129;
			ori r5, r4, 0x8aa4;
			ori r6, r4, 0xab58;
	
			stw r5, 167*4(r28);
			stw r6, 171*4(r28);
	
			lis r4, 0x6108;
			ori r4, r4, 0x7358;
			stw r4, 180*4(r28);
	
		3:
	
		// STEP 4: Finally install all the hooks to the patches:
		// code start r28
	
		// code_offset_1 (start of bean code 1):    0
		// code_offset_2 (return of bean code 1):  76
		// code_offset_3 (start of bean code 2):   80
		// code_offset_4 (return of bean code 2): 252
		// code_offset_5 (start of REL code):     316
	
	
		// r15 = patch1_offset
		// r16 = patch2_offset
		// r17 = patch3_offset
	
		lis r15, 0x800e;
		lis r16, 0x801d;
		lis r17, 0x801a;
	
			cmpwi r31, 0x45;
			bne 1f;
			// USA patch:
			ori r15, r15, 0xe300;
			ori r16, r16, 0x4e5c;
			ori r17, r17, 0x7240;
			b 2f;
	
		1:	cmpwi r31, 0x4a;
			bne 1f;
			// JAP patch:
			ori r15, r15, 0xe2c0;
			ori r16, r16, 0x4e1c;
			ori r17, r17, 0x7200;
			b 2f;
	
		1: 	cmpwi r31, 0x4b;
			bne 1f;
			// KOR patch:
			ori r15, r15, 0xe418;
			ori r16, r16, 0x5258;
			ori r17, r17, 0x763c;
			b 2f;
	
		1: 	// PAL patch:
			ori r15, r15, 0xe3a0;
			ori r16, r16, 0x4efc;
			ori r17, r17, 0x72e0;
		2: 	
	
	
	
		// void code_patcher_BL(void * function, int offset, void * branch_dest) {
	
		// code start r28
	
		// code_offset_1 (start of bean code 1):    0
		// code_offset_2 (return of bean code 1):  76
		// code_offset_3 (start of bean code 2):   80
		// code_offset_4 (return of bean code 2): 252
		// code_offset_5 (start of REL code):     256
	
	
		// r15 = patch1_offset
		// r16 = patch2_offset
		// r17 = patch3_offset
	
	
		mr r3, r28;
		li r4, 76;
		addi r5, r15, 4;
		bl code_patcher_B;
	
		mr r3, r28;
		li r4, 252;
		addi r5, r16, 4;
		bl code_patcher_B;
	
		mr r3, r15;
		li r4, 0;
		addi r5, r28, 0;
		bl code_patcher_B;
	
		mr r3, r16;
		li r4, 0;
		addi r5, r28, 80;
		bl code_patcher_B;
	
		mr r3, r17;
		li r4, 0;
		addi r5, r28, 256;
		bl code_patcher_B;

		b 6f;
	
	5:	
	// This is NOT MKWii. Do the additional GP2 and MASTER security patches.
	// For MKWii these are handled by the Wiimmfi update, for other games we need
	// to handle that here.
	// This calls a function from the binary blob from the other patch, see folder "RCE". 
	lis r3, 0x812f; 
	ori r3, r3, 0xe700; 
	mtlr r3; 
	blrl; 



	6:
	// END of Wiimmfi patch
	
	// restore interrupts
	// at this point we would call OSRestoreInterrupts. that function
	// just has a couple lines, let's just include it in here, then
	// we don't have to bother about porting it to all the different regions
	lwz r3, 12(r1);
	// OSRestoreInterrupts:
	cmpwi r3, 0; 
	mfmsr r4; 
	beq 1f;
	ori r5, r4, 0x8000; 
	b 2f; 
1:	rlwinm r5, r4, 0x0, 0x11, 0xf; 
2: 	mtmsr r5; 
	//rlwinm r3, r4, 0x11, 0x1f, 0x1f; 	
		// This line is included in OSRestoreInterrupts, but that's just for
		// the return value, which we don't care about, so we can ignore it.

	// restore stack stuff:
  	lwz r0,176(r1)
	mtlr r0
	lmw r2,20(r1)
	lwz r0,8(r1)
	addi r1,r1,172
	isync
	
	// Prepare to return to game: 
	.long 0x7f45d378; 	// original instruction
	lis r6, LOADADDRESS@ha; 
	lwz r6, LOADADDRESS@l(r6);
	mtctr r6;
	bctr;


code_patcher_B:
	add     r9,r3,r4
	subf    r5,r9,r5
	clrlwi  r10,r5,6
	addis   r10,r10,18432
	stwx    r10,r3,r4
	dcbf    0,r9
	icbi    0,r9
	blr



#endif