#!/bin/bash

# Copyright (c) 2020-2023 Leseratte10
# This file is part of the Priiloader Wiimmfi patch hack by Leseratte.
# https://github.com/Leseratte10/priiloader-patch-wiimmfi
# 
# It contains the build script / build process for the Priiloader hack.
# 


rm -rf build 
mkdir -p build

IOS_EXPL_PARAM_ADDRESS=0x812fef00
IOS_EXPL_LOAD_ADDRESS=0x812fee00	# Address the code blob for the IOS change is loaded

WIIMMFI_LOAD_ADDRESS=0x812ff000		# Address the code blob is loaded at
WIIMMFI_CODE_START=0x812ff030		# Address the actual code starts
									# 4 bytes at the beginning are the branch addr.,
									# The 44 bytes after that are 42 bytes patcher
									# string, then a space, then a nullbyte
									# The code as of this address must be identical
									# for all regions!

WIIMMFI_NEW_PATCH_OFFSET=0x812fe700		# Warning: If this is changed, it needs to be changed in the Makefile for the binary, too!!



# This function compiles the patch for a given version, places code into 
# the custom build folder. Use v 0 to compile the master
function compile_ios_exploit_fix {
	# $1 needs to be the version for the system menu
	#set -e
	powerpc-eabi-gcc -DVERSION=$1 -DFUNCTIONCALL=$FNCALL -DPARAMS=$IOS_EXPL_PARAM_ADDRESS -DLOADADDRESS=$IOS_EXPL_LOAD_ADDRESS -DPATCHADDR=$OFS -nostartfiles -nostdlib -mregnames -Os -c patch_exploit-fix.S -o build/patch-$1.o
	powerpc-eabi-objcopy -S -O binary build/patch-$1.o
	#set +e
}

# This function compiles the patch for a given version, places code into 
# the custom build folder. Use v 0 to compile the master
function compile_wiimmfi {
	# $1 needs to be the version for the system menu
	#set -e
	powerpc-eabi-gcc -DVERSION=$1 -DLOADADDRESS=$WIIMMFI_LOAD_ADDRESS -DPATCHADDR=$OFS -nostartfiles -nostdlib -mregnames -Os -c patch_wiimmfi.S -o build/patch-$1.o
	powerpc-eabi-objcopy -S -O binary build/patch-$1.o
	#set +e
}

# This function takes a compiled binary and converts it into the "patch" line
# for the Priiloader hacks file. 
function binaryToPatchString {
	# $1 is the version
	(
		count=0
		echo -n "patch="
		while read -r line; do
			#echo "DBG: $line" 
			if (( count >= 720 )); then
				count=0
				echo ""
				echo -n "patch="
			fi
			echo -n "0x$line,"
			((count++))

		done < <(xxd -c 4 -g4 build/patch-$1.o | cut -d\  -f2)
	) | head -c-1
	echo 
}

function binaryToPatchStringWiimmfi2 {
	# $1 is the file name
	(
		count=0
		echo -n "patch="
		while read -r line; do
			#echo "DBG: $line" 
			if (( count >= 720 )); then
				count=0
				echo ""
				echo -n "patch="
			fi
			echo -n "0x$line,"
			((count++))

		done < <(xxd -c 4 -g4 $1 | cut -d\  -f2)
	) | head -c-1
	echo 

}

OFS=0


function verToOffset_ios_exploit {
	case "$1" in 
          0)  OFS=0           FNCALL=0 ;; 
		448)  OFS=0x8137ade4  FNCALL=0x81598a34;;   # 4.1J
		449)  OFS=0x8137b930  FNCALL=0x8156faf8;;   # 4.1U
		450)  OFS=0x8137b9d8  FNCALL=0x8156fbf4;;   # 4.1E
		454)  OFS=0x8137ad0c  FNCALL=0x815488f8;;   # 4.1K
		480)  OFS=0x8137b244  FNCALL=0x81599300;;   # 4.2J
		481)  OFS=0x8137bd90  FNCALL=0x815703c0;;   # 4.2U
		482)  OFS=0x8137be38  FNCALL=0x815704bc;;   # 4.2E
		486)  OFS=0x8137b124  FNCALL=0x81549178;;   # 4.2K
		512)  OFS=0x8137b3dc  FNCALL=0x8159a9bc;;   # 4.3J
		513)  OFS=0x8137bf28  FNCALL=0x81571a7c;;   # 4.3U		
		514)  OFS=0x8137bfd0  FNCALL=0x81571b78;;   # 4.3E
		518)  OFS=0x8137b2bc  FNCALL=0x8154a834;;   # 4.3K
		# [[wiiu]]
		608)  OFS=0x8137bd80  FNCALL=0x8159d710 ;;  # WiiU 4.3J
		609)  OFS=0x8137c8cc  FNCALL=0x815747d0 ;;  # WiiU 4.3U
		610)  OFS=0x8137c974  FNCALL=0x815748cc ;;  # WiiU 4.3E
		4609) OFS=0x8137c1cc  FNCALL=0x815716e0;;   # Wii Mini 4.3U
		4610) OFS=0x8137c298  FNCALL=0x81571800;;   # Wii Mini 4.3E
	esac
	return;
}


function verToOffset_wiimmfi {
	case "$1" in 
		448)  OFS=0x8137aea8 ;; # 4.1J
		449)  OFS=0x8137b9f4 ;; # 4.1U
		450)  OFS=0x8137ba9c ;;	# 4.1E
		454)  OFS=0x8137add0 ;; # 4.1K
		480)  OFS=0x8137b308 ;; # 4.2J
		481)  OFS=0x8137be54 ;; # 4.2U
		482)  OFS=0x8137befc ;;	# 4.2E
		486)  OFS=0x8137b1e8 ;; # 4.2K
		512)  OFS=0x8137b4a0 ;; # 4.3J
		513)  OFS=0x8137bfec ;; # 4.3U		
		514)  OFS=0x8137c094 ;;	# 4.3E
		518)  OFS=0x8137b380 ;; # 4.3K
		# [[wiiu]]
		608)  OFS=0x8137be44 ;; # WiiU 4.3J
		609)  OFS=0x8137c990 ;; # WiiU 4.3U
		610)  OFS=0x8137ca38 ;; # WiiU 4.3E
		4609) OFS=0x8137c290 ;; # Wii Mini 4.3U
		4610) OFS=0x8137c35c ;; # Wii Mini 4.3E
	esac
	return;
}

VNAME="Invalid"

function versionToWrittenName {
	case "$1" in 
		448)  VNAME="4.1J";;
		449)  VNAME="4.1U";;
		450)  VNAME="4.1E";;
		454)  VNAME="4.1K";;
		480)  VNAME="4.2J";;
		481)  VNAME="4.2U";;
		482)  VNAME="4.2E";;
		486)  VNAME="4.2K";;
		512)  VNAME="4.3J";;
		513)  VNAME="4.3U";;
		514)  VNAME="4.3E";;
		518)  VNAME="4.3K";;
		608)  VNAME="WiiU 5.2.0J";;
		609)  VNAME="WiiU 5.2.0U";;
		610)  VNAME="WiiU 5.2.0E";;
		4609) VNAME="Wii Mini USA";;
		4610) VNAME="Wii Mini PAL";;
		*)    VNAME="Invalid";;
	esac
	return
}


# This function takes a version and prints the two patch lines for the
# branch instruction
function versionToBranchCode_ios_exploit {	
	if [[ "$OFS" == "0" ]]; then
		echo "ERROR" >/dev/stderr
		exit 4;
	fi
	
	# Take the offset of the original instruction (different in each version)
	# and then calculate the branch instruction to our code. 
	echo "offset=$OFS"
	echo "patch=$( printf "0x%x\n" $(( 0x48000000 + (( $IOS_EXPL_LOAD_ADDRESS - $OFS ) & 0x3ffffff ) )) )"
}
function versionToBranchCode_wiimmfi {	
	if [[ "$OFS" == "0" ]]; then
		echo "ERROR" >/dev/stderr
		exit 4;
	fi
	
	# Take the offset of the original instruction (different in each version)
	# and then calculate the branch instruction to our code. 
	echo "offset=$OFS"
	echo "patch=$( printf "0x%x\n" $(( 0x48000000 + (( $WIIMMFI_CODE_START - $OFS ) & 0x3ffffff ) )) )"

}

########## FULL COMPILE START (with MASTER)

	compile_wiimmfi 0
	echo "[Wiimmfi Patch v5 - hidden MASTER]"
	echo "minversion=1"
	echo "maxversion=65535"
	echo "amount=3"
	echo "master=wiimmfi-v5"
	echo "offset=$WIIMMFI_CODE_START"		# offset for wiimmfi master
	binaryToPatchString 0			# patch for wiimmfi master


	verToOffset_ios_exploit 0
	compile_ios_exploit_fix 0
	echo "offset=$IOS_EXPL_LOAD_ADDRESS"		# offset for the IOS58 exploit fix
	binaryToPatchString 0			# patch for the exploit fix

	cd RCE
	make clean >/dev/null 2>&1
	make >/dev/null 2>&1 || (echo ERROR; exit 1)
	echo "offset=$WIIMMFI_NEW_PATCH_OFFSET"
	binaryToPatchStringWiimmfi2 bin/resident.bin
	cd ..


# Now for all the version(s): 
for version in 514 482 450 513 481 449 512 480 448 518 486 454 4609 4610 608 609 610; do

	verToOffset_wiimmfi $version
	compile_wiimmfi $version
	versionToWrittenName $version
	echo "[Wiimmfi Patch v5 for $VNAME]"
	echo "maxversion=$version"
	echo "minversion=$version"
	echo "amount=4"
	echo "require=wiimmfi-v5"
	versionToBranchCode_wiimmfi $version
	echo "offset=$WIIMMFI_LOAD_ADDRESS"
	binaryToPatchString $version



	verToOffset_ios_exploit $version
	compile_ios_exploit_fix $version
	versionToBranchCode_ios_exploit $version
	echo "offset=$IOS_EXPL_PARAM_ADDRESS"					# offset for ios exploit fix
	binaryToPatchString $version					# patch for ios exploit fix
	
done

########## FULL COMPILE END



cd "$olddir"
