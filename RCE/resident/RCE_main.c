/*
 * Copyright (c) 2020-2023 Leseratte10
 * This file is part of the Priiloader Wiimmfi patch hack by Leseratte.
 * https://github.com/Leseratte10/priiloader-patch-wiimmfi
 * 
 *
 * It contains C source code for the STATUS record security fix found in 2021.
 * Written in plain C without any library calls so it can be embedded in a Priiloader hack.
 *
 */


int _wrap_memcmp(char * data1, char * data2, int length);
void _wrap_memcpy(char * dest, char * src, int length);

static inline unsigned int GetOpcode(unsigned int * instructionAddr) {
    return ((*instructionAddr >> 26) & 0x3f);
}

static inline unsigned int GetImmediateDataVal(unsigned int * instructionAddr) {
    return (*instructionAddr & 0xffff);
}

static inline int GetLoadTargetReg(unsigned int * instructionAddr) {
    return (int)((*instructionAddr >> 21) & 0x1f);
}

static inline int GetComparisonTargetReg(unsigned int * instructionAddr) {
    return (int)((*instructionAddr >> 16) & 0x1f);
}

void MainWiimmfiPatch() {
    char * cur = (char *)0x80004000;
    const char * end = (char *)0x80900000;
    int hasGT2Error = 0;

    char gt2locator[] = { 0x38, 0x61, 0x00, 0x08, 0x38, 0xA0, 0x00, 0x14 };

    // Opcode list for p2p: 
    unsigned char opCodeChainP2P_v1[22] =    { 32, 32, 21, 21, 21, 21, 20, 20, 31, 40, 21, 20, 20, 31, 31, 10, 20, 36, 21, 44, 36, 16 };
    unsigned char opCodeChainP2P_v2[22] =    { 32, 32, 21, 21, 20, 21, 20, 21, 31, 40, 21, 20, 20, 31, 31, 10, 20, 36, 21, 44, 36, 16 };

    // Opcode list for MASTER: 
    unsigned char opCodeChainMASTER_v1[22] = { 21, 21, 21, 21, 40, 20, 20, 20, 20, 31, 31, 14, 31, 20, 21, 44, 21, 36, 36, 18, 11, 16 };
    unsigned char opCodeChainMASTER_v2[22] = { 21, 21, 21, 21, 40, 20, 20, 20, 20, 31, 31, 14, 31, 20, 21, 36, 21, 44, 36, 18, 11, 16 };
    

    int MASTERopcodeChainOffset = 0;


    do {
        if (_wrap_memcmp(cur, (char *)"<GT2> RECV-0x%02x <- [--------:-----] [pid=%u]", 0x2e) == 0) {
            hasGT2Error++;
        }
    } while (++cur < end);
    cur = (char *)0x80004000;

    do {
        if (_wrap_memcmp(cur, "User-Agent\x00\x00RVL SDK/", 20) == 0) {
            // Found user agent, let's patch it. 

            if (hasGT2Error) 
                _wrap_memcpy(cur + 12, "E-3-1\x00", 6); 
            else
                _wrap_memcpy(cur + 12, "E-3-0\x00", 6); 
        }

    } while (++cur < end); 

    cur = (char *)0x80004000;

    do {
        if (hasGT2Error) {
            if (_wrap_memcmp(cur, (char *)&gt2locator, 8) == 0) {
				int found_opcode_chain_P2P_v1 = 1; 
                int found_opcode_chain_P2P_v2 = 1; 
                for (int i = 0; i < 22; i++) {
                    int offset = (i * 4) + 12;
                    if (opCodeChainP2P_v1[i] != (unsigned char)(GetOpcode((unsigned int *)(cur + offset)))) {
                        found_opcode_chain_P2P_v1 = 0; 
                    }
                    if (opCodeChainP2P_v2[i] != (unsigned char)(GetOpcode((unsigned int *)(cur + offset)))) {
                        found_opcode_chain_P2P_v2 = 0; 
                    }
                }
                int found_opcode_chain_MASTER;
                for (int dynamic = 0; dynamic < 40; dynamic += 4) {
                    found_opcode_chain_MASTER = 1; 
                    int offset = 0; 
                    for (int i = 0; i < 22; i++) {
                        offset = (i * 4) + 12 + dynamic;
                            if (
                                (opCodeChainMASTER_v1[i] != (unsigned char)(GetOpcode((unsigned int *)(cur + offset)))) && 
                                (opCodeChainMASTER_v2[i] != (unsigned char)(GetOpcode((unsigned int *)(cur + offset))))
                            ) {
                                found_opcode_chain_MASTER = 0; 
                            }
                    }

                    if (found_opcode_chain_MASTER) {
                        // we found the opcode chain, let's take a note of the offset
                        MASTERopcodeChainOffset = (int)(cur + offset);
                        break;
                    }

                }
                if (found_opcode_chain_P2P_v1 || found_opcode_chain_P2P_v2) {
                        // Opcodes match known opcode order for part of DWCi_HandleGT2UnreliableMatchCommandMessage.


                        if (
                            GetImmediateDataVal((unsigned int *)(cur + 0x0c)) == 0x0c && 
                            GetImmediateDataVal((unsigned int *)(cur + 0x10)) == 0x18 &&
                            GetImmediateDataVal((unsigned int *)(cur + 0x30)) == 0x12 &&
                            GetImmediateDataVal((unsigned int *)(cur + 0x48)) == 0x5a &&
                            GetImmediateDataVal((unsigned int *)(cur + 0x50)) == 0x0c && 
                            GetImmediateDataVal((unsigned int *)(cur + 0x58)) == 0x12 && 
                            GetImmediateDataVal((unsigned int *)(cur + 0x5c)) == 0x18 && 
                            GetImmediateDataVal((unsigned int *)(cur + 0x60)) == 0x18
                        )
                        {
                            int loadedDataReg = GetLoadTargetReg((unsigned int *)(cur + 0x14));
                            int comparisonDataReg = GetComparisonTargetReg((unsigned int *)(cur + 0x48));
                            
                            if (found_opcode_chain_P2P_v1) {
                                // Found DWCi_HandleGT2UnreliableMatchCommandMessage, altering instructions
                                *(int *)(cur + 0x14) = (0x88010011 | (comparisonDataReg << 21)); // lbz comparisonDataReg, 0x11(r1)
                                *(int *)(cur + 0x18) = (0x28000080 | (comparisonDataReg << 16)); // cmplwi comparisonDataReg, 0x80
                                *(int *)(cur + 0x24) = 0x41810064;                               // bgt- +0x64
                                *(int *)(cur + 0x28) = 0x60000000;                               // nop
                                *(int *)(cur + 0x2c) = 0x60000000;                               // nop
                                *(int *)(cur + 0x34) = (0x3C005A00 | (comparisonDataReg << 21)); // lis comparisonDataReg, 0x5a00
                                *(int *)(cur + 0x48) = (0x7C000000 | (comparisonDataReg << 16) | (loadedDataReg << 11)); // cmpw comparisonDataReg, loadedDataReg
                            }
                            if (found_opcode_chain_P2P_v2) {

                                // Bugfix ...
                                loadedDataReg = 12;

                                // Found DWCi_HandleGT2UnreliableMatchCommandMessage, altering instructions
                                *(int *)(cur + 0x14) = (0x88010011 | (comparisonDataReg << 21)); // lbz comparisonDataReg, 0x11(r1)
                                *(int *)(cur + 0x18) = (0x28000080 | (comparisonDataReg << 16)); // cmplwi comparisonDataReg, 0x80
                                *(int *)(cur + 0x1c) = 0x41810070;                               // bgt- +0x70
                                *(int *)(cur + 0x24) = *(int *)(cur + 0x28); // move around
                                *(int *)(cur + 0x28) = (0x8001000c | (loadedDataReg << 21));     // lwz loadedDataReg, 0x0c(r1)
                                *(int *)(cur + 0x2c) = (0x3C005A00 | (comparisonDataReg << 21)); // lis comparisonDataReg, 0x5a00
                                *(int *)(cur + 0x34) = (0x7c000000 | (comparisonDataReg << 16) | (loadedDataReg << 11)); // cmpw comparisonDataReg, loadedDataReg
                                *(int *)(cur + 0x48) = 0x60000000; // nop
                            }

                        }
                    }
                else if (found_opcode_chain_MASTER) {
                    // Opcodes match known opcode order for part of DWCi_QR2ClientMsgCallback.

                    if (
                        GetImmediateDataVal((unsigned int *)(MASTERopcodeChainOffset + 0x10)) == 0x12 &&
                        GetImmediateDataVal((unsigned int *)(MASTERopcodeChainOffset + 0x2c)) == 0x04 &&
                        
                        GetImmediateDataVal((unsigned int *)(MASTERopcodeChainOffset + 0x48)) == 0x18 &&
                        GetImmediateDataVal((unsigned int *)(MASTERopcodeChainOffset + 0x50)) == 0x00 &&
                        GetImmediateDataVal((unsigned int *)(MASTERopcodeChainOffset + 0x54)) == 0x18
                    )
                    {


                        int master_patch_version = 0; 

                        // Check which version we have:
                        if ((GetImmediateDataVal((unsigned int *)(MASTERopcodeChainOffset + 0x3c)) == 0x12 && 
                        GetImmediateDataVal((unsigned int *)(MASTERopcodeChainOffset + 0x44)) == 0x0c) ) {
                            master_patch_version = 1; 
                        }
                        else if ((GetImmediateDataVal((unsigned int *)(MASTERopcodeChainOffset + 0x3c)) == 0x0c && 
                        GetImmediateDataVal((unsigned int *)(MASTERopcodeChainOffset + 0x44)) == 0x12) ) {
                            master_patch_version = 2; 
                        }


                        if (master_patch_version == 2) {
                            // Different opcode order ...
                            *(int *)(MASTERopcodeChainOffset + 0x3c) = *(int *)(MASTERopcodeChainOffset + 0x44);
                        }

                        if (master_patch_version != 0) {

                            // MASTERopcodeChainOffset is now 0x9c
                            int rY = GetComparisonTargetReg((unsigned int *)MASTERopcodeChainOffset);    // r8
                            int rX = GetLoadTargetReg((unsigned int *)MASTERopcodeChainOffset);          // r7  

                            /* 0x9c */  *(int *)(MASTERopcodeChainOffset + 0x00) = 0x38000004 | (rX << 21); // li rX, 4;
                            /* 0xa0 */  *(int *)(MASTERopcodeChainOffset + 0x04) = 0x7c00042c | (rY << 21) | (3 << 16) | (rX << 11); // lwbrx rY, r3, rX;
                            /* 0xb0 */  *(int *)(MASTERopcodeChainOffset + 0x14) = 0x9000000c | (rY << 21) | (1 << 16); // stw rY, 0xc(r1);
                            /* 0xb4 */  *(int *)(MASTERopcodeChainOffset + 0x18) = 0x88000011 | (rY << 21) | (1 << 16); // lbz rY, 0x11(r1);
                            /* 0xc4 */  *(int *)(MASTERopcodeChainOffset + 0x28) = 0x28000080 | (rY << 16); // cmplwi rY, 0x80
                            /* 0xd4 */  *(int *)(MASTERopcodeChainOffset + 0x38) = 0x60000000; // nop
                            /* 0xe0 */  *(int *)(MASTERopcodeChainOffset + 0x44) = 0x41810014; // bgt- 0x800e5a94

                        }

                    }

                }
            }
        }
    } while (++cur < end);
}