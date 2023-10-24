SECTIONS {
	.data : {
		_resident_start = .;
		*(.text*)
		*(.data*)
		*(.sdata*)
		*(.rodata*)
		*(.bss*)
		*(.sbss*)
		. = ALIGN(32);
		_resident_end = .;
	}
	/DISCARD/ : {
		*(*)
	}
}

