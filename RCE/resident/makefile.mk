WD     := $(dir $(lastword $(MAKEFILE_LIST)))
WD_RESI := $(WD)

SRC_RESI += $(WD)RCE_main.c
SRC_RESI += $(WD)RCE_wrapper.S
