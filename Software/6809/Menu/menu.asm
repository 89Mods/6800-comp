; Jump table locations
F_TBL_START        equ 32768
F_LONG_DELAY       equ 0+F_TBL_START
F_SPI_TX           equ 3+F_TBL_START
F_SPI_RX           equ 6+F_TBL_START
F_ROM_DESEL        equ 9+F_TBL_START
F_UART_WAIT        equ 12+F_TBL_START
F_WAIT_VBLANK      equ 15+F_TBL_START
F_GPU_WAIT_READY   equ 18+F_TBL_START
F_PUTCHAR          equ 21+F_TBL_START
F_CURSOR_SET       equ 24+F_TBL_START
F_PUTSTR           equ 27+F_TBL_START
F_PRINTHEX_STR     equ 30+F_TBL_START
F_TERM_CLEAR       equ 33+F_TBL_START
F_CURSOR_ON        equ 36+F_TBL_START
F_CURSOR_OFF       equ 39+F_TBL_START
F_KB_PARSE         equ 42+F_TBL_START
F_ADVANCE_CURSOR   equ 45+F_TBL_START
F_CURSOR_RETURN    equ 48+F_TBL_START
F_PRINTHEX         equ 51+F_TBL_START
F_NEWL             equ 54+F_TBL_START
F_MUL1616_UNSIGNED equ 57+F_TBL_START
F_MUL1616_SIGNED   equ 60+F_TBL_START
F_MODDIV_1616_UNSIGNED equ 63+F_TBL_START
F_ITOA16           equ 66+F_TBL_START
F_MODDIV_3216_UNSIGNED equ 69+F_TBL_START
F_MODDIV_3232_UNSIGNED equ 72+F_TBL_START
F_ITOA32           equ 75+F_TBL_START
F_MUL3232_UNSIGNED equ 78+F_TBL_START
F_MUL3232_SIGNED   equ 81+F_TBL_START
F_MUL_FIXED        equ 84+F_TBL_START
F_MODDIV_3232_SIGNED equ 87+F_TBL_START
F_DIV_FIXED        equ 90+F_TBL_START
F_FITOA            equ 93+F_TBL_START

KB_BASE equ $0140
KB_PORTC equ KB_BASE+2

V_CURSOR_X equ $000B
v_CURSOR_Y equ $000C
V_LAST_PRESSED  equ $000E
V_LAST_RELEASED equ $000F
V_SHIFT_DOWN    equ $0010
v_ALT_CTRL_DOWN equ $0011
V_CURR_COLOR equ $0005
TERM_DEFAULT_COLOR equ $1C

KEY_UP equ $B5
KEY_DOWN equ $B2

ENDPOS equ $0030
COUNTER equ $0032

	org 512
boot:
	nop
	clr COUNTER
	clr COUNTER+1
	jsr get_menu_entries
	jsr render_menu

idle:
	jsr F_KB_PARSE
	beq idle
	lda V_LAST_PRESSED
	cmpa #KEY_DOWN
	beq key_down_pressed
	cmpa #KEY_UP
	beq key_up_pressed
	cmpa #'\r'
	beq boot_selected
	bra idle
key_down_pressed:
	inc selection
	lda num_entries
	cmpa selection
	bgt no_overflow
	deca
	sta selection
no_overflow:
	jsr render_menu
	bra idle

key_up_pressed:
	dec selection
	bpl no_underflow
	clr selection
no_underflow:
	jsr render_menu
	bra idle

boot_selected:
	jsr F_TERM_CLEAR
	jsr F_CURSOR_ON
	ldx #entry_buffer
	clr curr_e
seek_to_selected:
	leax 1,X
skip_name_loop:
	lda 0,X
	beq skip_name_over
	leax 1,X
	bra skip_name_loop
skip_name_over:
	leax 1,X
	lda curr_e
	cmpa selection
	beq selected_found
	inca
	sta curr_e
	leax 5,X
	bra seek_to_selected
selected_found:
	lda 1,X
	sta ENDPOS
	lda 0,X
	sta ENDPOS+1
	leax 2,X
	lda #3
	jsr F_SPI_TX
	lda 2,X
	jsr F_SPI_TX
	lda 1,X
	jsr F_SPI_TX
	lda 0,X
	jsr F_SPI_TX
	ldx #32768-256
	stx backup
	ldx #copy_loop
	ldb #copy_loop_end-copy_loop
copy_the_copy_loop:
	lda 0,X
	stx backup+2
	ldx backup
	sta 0,X
	leax 1,X
	stx backup
	ldx backup+2
	leax 1,X
	decb
	bne copy_the_copy_loop
	ldx #512
	jmp 32768-256

copy_loop:
	jsr F_SPI_RX
	sta 0,X
	leax 1,X
	lda COUNTER+1
	adda #1
	sta COUNTER+1
	lda COUNTER
	adca #0
	sta COUNTER
	cmpa ENDPOS
	bne copy_loop
	lda COUNTER+1
	cmpa ENDPOS+1
	bne copy_loop
	jsr F_ROM_DESEL
	jmp 512
copy_loop_end:

render_menu:
	clr curr_e
	jsr F_CURSOR_OFF
	jsr F_TERM_CLEAR
	ldb #12
	lda #' '
spaces_loop:
	jsr F_PUTCHAR
	decb
	bne spaces_loop
	lda #TERM_DEFAULT_COLOR+2
	sta V_CURR_COLOR
	ldx #text
	jsr F_PUTSTR
	lda #TERM_DEFAULT_COLOR
	sta V_CURR_COLOR
	jsr F_NEWL

	ldx #entry_buffer
entry_render_loop:
	jsr F_NEWL
	jsr F_ADVANCE_CURSOR
	lda curr_e
	cmpa selection
	bne entry_not_selected
	lda #$E0
	sta V_CURR_COLOR
entry_not_selected:
	jsr F_ADVANCE_CURSOR
	lda 0,X
	beq entry_render_loop_over
	leax 1,X
	clrb
entry_print_name_loop:
	lda 0,X
	beq entry_print_name_loop_over
	jsr F_PUTCHAR
	incb
	leax 1,X
	bra entry_print_name_loop
entry_print_name_loop_over:
	leax 1,X
	lda 1,X
	sta tmp_size
	lda 0,X
	sta tmp_size+1
	leax 5,X
	lda #' '
spaces_loop2:
	jsr F_PUTCHAR
	incb
	cmpb #33
	blt spaces_loop2
	stx backup
	ldx #tmp_size
	clra
	sta 2,X
	sta 3,X
	sta 4,X
	sta 5,X
	sta 6,X
	sta 7,X
	sta 8,X
	jsr F_ITOA16
put_number_loop:
	lda 0,X
	beq put_number_loop_over
	jsr F_PUTCHAR
	leax 1,X
	incb
	bra put_number_loop
put_number_loop_over:
	ldx backup
	lda #' '
spaces_loop3:
	jsr F_PUTCHAR
	incb
	cmpb #39
	blt spaces_loop3

	lda #TERM_DEFAULT_COLOR
	sta V_CURR_COLOR
	inc curr_e
	jmp entry_render_loop
entry_render_loop_over:

	rts

get_menu_entries:
	lda #3
	jsr F_SPI_TX
	clra
	jsr F_SPI_TX
	jsr F_SPI_TX
	lda #7
	jsr F_SPI_TX
	jsr F_SPI_RX
	sta romptr
	jsr F_SPI_RX
	sta romptr+1
	clr romptr+2
	clr num_entries
	jsr F_ROM_DESEL
	lda #9
	adda romptr
	sta romptr
	lda #0
	adca romptr+1
	sta romptr+1
	lda #0
	adca romptr+2
	sta romptr+2
	ldx #entry_buffer
get_entries_loop:
	lda #3
	jsr F_SPI_TX
	lda romptr+2
	jsr F_SPI_TX
	lda romptr+1
	jsr F_SPI_TX
	lda romptr
	jsr F_SPI_TX
	jsr F_SPI_RX
	sta 0,X
	leax 1,X
	tsta
	beq get_entries_loop_done
	inc num_entries
get_name_loop:
	jsr F_SPI_RX
	sta 0,X
	leax 1,X
	ldb romptr
	addb #1
	stb romptr
	ldb romptr+1
	adcb #0
	stb romptr+1
	ldb romptr+2
	adcb #0
	stb romptr+2
	tsta
	bne get_name_loop
get_name_loop_over:
	jsr F_SPI_RX
	sta 0,X
	jsr F_SPI_RX
	sta 1,X
	jsr F_ROM_DESEL

	lda romptr
	adda #3
	sta romptr
	sta 2,X
	lda romptr+1
	adca #0
	sta romptr+1
	sta 3,X
	lda romptr+2
	adca #0
	sta romptr+2
	sta 4,X

	lda romptr
	adda 0,X
	sta romptr
	lda romptr+1
	adca 1,X
	sta romptr+1
	lda romptr+2
	adca #0
	sta romptr+2
	leax 5,X

	jmp get_entries_loop

get_entries_loop_done:
	jsr F_ROM_DESEL
	rts

ram_start:
romptr:
	db 0,0,0
num_entries:
	db 0
text:
	db "Program Selection"
	db 0
tmp_size:
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0
backup:
	db 0,0,0,0
selection:
	db 0
curr_e:
	db 0
entry_buffer:
