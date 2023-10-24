###############################################################################
# makefile
#  modified by Leseratte
#  based on makefile by Alex Chadwick
#
###############################################################################

# helper variables
C := ,

###############################################################################
# devkitppc settings

DEVKITPPC_VER ?= 33

ifeq ($(strip $(DEVKITPPC)),)
  $(error "Please set DEVKITPPC in your environment. export DEVKITPPC=<path to>devkitPPC")
endif

ifeq ($(strip $(DEVKITPRO)),)
  $(error "Please set DEVKITPRO in your environment. export DEVKITPRO=<path to>devkitPRO")
endif

ifeq ($(OS),Windows_NT)
  $(info Compiling from $(OS))

  PATH := $(DEVKITPPC)/bin:$(PORTLIBS)/bin:$(PATH)
  ifeq ($(DEVKITPRO),$(subst :, ,$(DEVKITPRO)))
    DEVKITPRO := $(patsubst /$(firstword $(subst /, ,$(DEVKITPRO)))/%,$(firstword $(subst /, ,$(DEVKITPRO))):/%,$(DEVKITPRO))
    $(info DEVKITPRO corrected to $(DEVKITPRO))
  else
    $(info DEVKITPRO is $(DEVKITPRO))
  endif

  ifeq ($(DEVKITPPC),$(subst :, ,$(DEVKITPPC)))
    DEVKITPPC := $(patsubst /$(firstword $(subst /, ,$(DEVKITPPC)))/%,$(firstword $(subst /, ,$(DEVKITPPC))):/%,$(DEVKITPPC))
    $(info DEVKITPPC corrected to $(DEVKITPPC))
  else
    $(info DEVKITPPC is $(DEVKITPPC))
  endif
else
  $(info Compiling from Unix)
  PATH := $(DEVKITPPC)/bin:$(PATH)
  $(info DEVKITPPC is $(DEVKITPPC))
endif

###############################################################################
# Compiler settings

# The toolchain to use.
PREFIX  ?= powerpc-eabi-
# Tools to use
AS      := $(PREFIX)as
LD      := $(PREFIX)ld
CC      := $(PREFIX)g++
OBJDUMP := $(PREFIX)objdump
OBJCOPY := $(PREFIX)objcopy

LDFLAGS  :=


# -O2: has to be used to avoid calls to _restgpr_no_x, which we don't have
# -g: Debug symbols
# -Wall: generate lots of warnings
# -x c: compile as C code
# -std=gnu99: use the C99 standard with GNU extensions
# -DGEKKO: define the symbol GEKKO (used in some libogc headers)
# -DHW_RVL: define the symbol HW_RVL (used in some libogc headers)
# -D__wii__: define the symbol __wii__ (used in some libogc headers)
# -mrvl: enable wii/gamecube compilation
# -mcpu=750: enable processor specific compilation
# -mhard-float: enable hardware floating point instructions
# -memb: enable embedded application specific compilation
# -ffunction-sections: split up functions so linker can garbage collect
# -fdata-sections: split up data so linker can garbage collect
# -ffreestanding: no standard libraries
# -nostartfiles: no startup routines
# -fno-common: don't use COMMON sections
# 
CFLAGS   += -O2 -Wall -x c -std=gnu99 \
            -DGEKKO -DHW_RVL -D__wii__ \
            -mrvl -mcpu=750 -mhard-float \
            -memb -ffunction-sections -fdata-sections \
            -ffreestanding -nostartfiles -fno-common 
# -mregnames allow friendly register naming.
SFLAGS   += -mregnames

MAKE_TIME := $(shell LC_ALL=C date -u +"%F %T")
CFLAGS += -DBUILDTIME='"$(MAKE_TIME)"'

ifdef DEVKITPPC_VER
  CFLAGS += -DDEVKITPPC_VER=$(DEVKITPPC_VER)
endif

###############################################################################
# Parameters


ADDR_RESI ?= 0x812fe700	


# Used to suppress command echo.
Q      ?= @
LOG    ?= @echo $@
# The intermediate directory for compiled object files.
BUILD  ?= build
# The output directory for compiled results.
BIN    ?= bin

###############################################################################
# Variable init

# The names of libraries to use.
LIBS     :=
# The source files to compile.
SRC_RESI :=
# Phony targets
PHONY    :=
# Include directories
INC_DIRS :=
# Library directories
LIB_DIRS :=

###############################################################################
# Rule to make everything.
PHONY += all

all : $(BIN)/resident.bin list

###############################################################################
# Recursive rules

include resident/makefile.mk

LDFLAGS += $(patsubst %,-l %,$(LIBS)) $(patsubst %,-l %,$(LIBS)) \
           $(patsubst %,-L %,$(LIB_DIRS)) $(patsubst %,-L %/lib,$(LIB_DIRS))
CFLAGS  += $(patsubst %,-I %,$(INC_DIRS)) \
           $(patsubst %,-I %/include,$(LIB_DIRS)) -iquote $(CURDIR)

OBJECTS_RESI := $(patsubst %.c,$(BUILD)/%.c.o,$(filter %.c,$(SRC_RESI))) \
                $(patsubst %.S,$(BUILD)/%.S.o,$(filter %.S,$(SRC_RESI)))

ifeq ($(words $(filter clean%,$(MAKECMDGOALS))),0)
  -include $(patsubst %.c,$(BUILD)/%.c.d,$(filter %.c,$(SRC_RESI)))
endif

###############################################################################
# Special build rules

# Rule to make the final payload.
$(BIN)/resident.bin : $(BUILD)/resident.elf | $(BIN)
	$(LOG)
	$Q$(OBJCOPY) -Obinary --only-section=.data $< $@

$(BUILD)/resident.ld : $(BUILD)/resident.elf | $(BUILD)
	$(LOG)
	$Q$(OBJDUMP) -t $< \
		| sed -ne 's/^\([0-9a-f]\{8\}\) g.* \(.*\)/PROVIDE(\2 = 0x\1);/p' \
		> $@

$(BUILD)/resident.bin.o : $(BUILD)/resident.bin | $(BUILD)
	$(LOG)
	$Qxxd -i $< | sed -e 's/$(subst .,_,$(subst \,_,$(subst /,_,$<)))/build_resident_bin/' | $(CC) $(CFLAGS) -c -xc - -o $@

# Rule to make the final resident section.
$(BUILD)/resident.bin : $(BUILD)/resident.elf | $(BUILD)
	$(LOG)
	$Q$(OBJCOPY) -Obinary $< $@

# Rule to make the resident section as an elf file.
$(BUILD)/resident.elf $(BUILD)/resident.map : $(OBJECTS_RESI) resident/resident.ld | $(BUILD) $(BIN)
	$(LOG)
	$Q$(LD) $(OBJECTS_RESI) $(LDFLAGS) -o $@ \
		-Tresident/resident.ld \
		--section-start .data=$(ADDR_RESI) \
		$(patsubst %,-Map  %,$(strip $(BIN)/resident.map))


# Rule to make intermediate directory
$(BUILD) :
	$Qmkdir -p $@

# Rule to make output directory
$(BIN) :
	$Qmkdir -p $@

###############################################################################
# Standard build rules

$(BUILD)/%.c.o: %.c | $(BUILD)
	$(LOG)
	$Qmkdir -p $(dir $@)
	$Q$(CC) -c $(CFLAGS) $< -o $@
$(BUILD)/%.c.d: %.c | $(BUILD)
	$(LOG)
	$Qmkdir -p $(dir $@)
	$Q$(RM) $(wildcard $@)
	$Q{ $(CC) -MP -MM -MT $(@:.d=.o) $(CFLAGS) $< > $@ \
	&& $(RM) $@.tmp; } \
	|| { $(RM) $@.tmp && false; }

$(BUILD)/%.S.i: %.S | $(BUILD)
	$(LOG)
	$Qmkdir -p $(dir $@)
	$Q$(CC) -E $(CFLAGS) $< > $@

$(BUILD)/%.S.o: $(BUILD)/%.S.i | $(BUILD)
	$(LOG)
	$Qmkdir -p $(dir $@)
	$Q$(AS) -c $(SFLAGS) $< -o $@
	

###############################################################################
# Assembly listing rules

# Rule to make assembly listing.
PHONY += list
list  : $(BIN)/resident.list

$(BIN)/resident.list : $(BUILD)/resident.elf | $(BIN)
	$(LOG)
	$Q$(OBJDUMP) -d $(BUILD)/resident.elf > $@

###############################################################################
# Clean rule

# Rule to clean files.
PHONY += clean
clean :
	$Qrm -rf $(wildcard $(BUILD) $(BIN) binaries) rmce.BAK rmcj.BAK rmck.BAK
		

###############################################################################
# Phony targets

.PHONY : $(PHONY)
