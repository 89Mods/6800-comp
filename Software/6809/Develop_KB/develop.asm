; Jump table locations
F_TBL_START      equ 32768
F_LONG_DELAY     equ 0+F_TBL_START
F_SPI_TX         equ 3+F_TBL_START
F_SPI_RX         equ 6+F_TBL_START
F_ROM_DESEL      equ 9+F_TBL_START
F_UART_WAIT      equ 12+F_TBL_START
F_WAIT_VBLANK    equ 15+F_TBL_START
F_GPU_WAIT_READY equ 18+F_TBL_START
F_PUTCHAR        equ 21+F_TBL_START
F_CURSOR_SET     equ 24+F_TBL_START
F_PUTSTR         equ 27+F_TBL_START
F_PRINTHEX       equ 30+F_TBL_START
F_TERM_CLEAR     equ 33+F_TBL_START
F_CURSOR_ON      equ 36+F_TBL_START
F_CURSOR_OFF     equ 39+F_TBL_START
F_KB_PARSE       equ 42+F_TBL_START
F_ADVANCE_CURSOR equ 45+F_TBL_START
F_CURSOR_RETURN  equ 48+F_TBL_START

V_CURSOR_X equ $000B
v_CURSOR_Y equ $000C
V_LAST_PRESSED  equ $000E
V_LAST_RELEASED equ $000F
V_SHIFT_DOWN    equ $0010
v_ALT_CTRL_DOWN equ $0011

CHARS_BUFF_START equ 32768-1920-1920
KB_BUFF_END equ CHARS_BUFF_START-3
KB_BUFF_START equ KB_BUFF_END-32
KB_BUFF_WR_PTR equ KB_BUFF_START-2
KB_BUFF_RD_PTR equ KB_BUFF_START-4

kbadvance macro
	leax 1,X
	cmpx #KB_BUFF_END
	bne *+5
	ldx #KB_BUFF_START
	stx KB_BUFF_RD_PTR
	endm

	org 512
boot:
	jsr F_CURSOR_OFF
	lda #1
	tfr a,b
	jsr F_CURSOR_SET
	lda #' '
	jsr F_PUTCHAR
	lda #1
	ldx #V_LAST_PRESSED
	jsr F_PRINTHEX
	lda #' '
	jsr F_PUTCHAR
	lda #1
	ldx #V_LAST_RELEASED
	jsr F_PRINTHEX
	lda #' '
	jsr F_PUTCHAR
	lda #1
	ldx #V_SHIFT_DOWN
	jsr F_PRINTHEX
	lda #' '
	jsr F_PUTCHAR
	ldx #v_ALT_CTRL_DOWN
	lda #1
	jsr F_PRINTHEX
	lda #2
	tfr a,b
	jsr F_CURSOR_SET
	ldx #ram_start
	lda #1
	jsr F_PRINTHEX
	inc ram_start
	nop
	lda orig_cursor
	ldb orig_cursor+1
	jsr F_CURSOR_SET
	jsr F_ADVANCE_CURSOR
	jsr F_CURSOR_ON
wait_for_kb:
	jsr F_KB_PARSE
	beq wait_for_kb
	
	lda V_LAST_PRESSED
	beq not_ascii
	bita #128
	bne not_ascii
	cmpa #' '
	bmi not_ascii
	lda orig_cursor
	ldb orig_cursor+1
	jsr F_CURSOR_SET
	lda V_LAST_PRESSED
	jsr F_PUTCHAR
	lda V_CURSOR_X
	sta orig_cursor
	lda v_CURSOR_Y
	sta orig_cursor+1
	lda #' '
	jsr F_PUTCHAR
not_ascii:
	jmp boot
just_print_the_codes:
	ldx KB_BUFF_RD_PTR
	cmpx KB_BUFF_WR_PTR
	beq just_print_the_codes
	lda 0,X
	kbadvance
	ldb #8
	stb ram_start
	clrb
kb_inverse_loop_1:
	rola
	rorb
	dec ram_start
	bne kb_inverse_loop_1
	stb ram_start
	lda #'\r'
	jsr F_PUTCHAR
	lda #'\n'
	jsr F_PUTCHAR
	ldx #ram_start
	lda #1
	jsr F_PRINTHEX
	lda #' '
	jsr F_PUTCHAR
	jmp just_print_the_codes
ram_start:
	db 0
	db 0,0,0,0,0,0,0,0
orig_cursor:
	db 1,5
