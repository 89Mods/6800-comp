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
F_XORSHIFT         equ 96+F_TBL_START

V_CURR_COLOR equ $0005
V_CURSOR_X equ $000B
v_CURSOR_Y equ $000C
V_LAST_PRESSED  equ $000E
V_LAST_RELEASED equ $000F
V_SHIFT_DOWN    equ $0010
v_ALT_CTRL_DOWN equ $0011
V_XORSHIFT0 equ $0015
V_XORSHIFT1 equ $0016
V_XORSHIFT2 equ $0017
V_XORSHIFT3 equ $0018

TERM_DEFAULT_COLOR equ $1C
BALL_COLOR equ $E0
LPAD_COLOR equ $E0
RPAD_COLOR equ $E0
PAD_HEIGHT equ 5

BALL_X equ $0080
BALL_Y equ $0082
BALL_XI equ $0080
BALL_YI equ $0082
LAST_BALL_XI equ $0084
LAST_BALL_YI equ $0085
LSCORE equ $0086
RSCORE equ $0089
BALL_VX equ $008C
BALL_VY equ $008E
LPAD_Y equ $0090
RPAD_Y equ $0091
LAST_LPAD_Y equ $0092
LAST_RPAD_Y equ $0093
TEMP equ $0094

XOFFSET equ 2
WIDTH equ 62-XOFFSET
HEIGHT equ 30
FIELD_XOFFSET equ XOFFSET+1
FIELD_YOFFSET equ 3
FIELD_WIDTH equ WIDTH-XOFFSET
FIELD_HEIGHT equ HEIGHT - FIELD_YOFFSET - 1

	org 512
boot:
	nop
	clr LAST_LPAD_Y
	clr LAST_RPAD_Y
	clr LSCORE
	clr LSCORE+1
	clr LSCORE+2
	clr RSCORE
	clr RSCORE+1
	clr RSCORE+2
	clr LAST_BALL_XI
	clr LAST_BALL_YI
	clr BALL_VX
	clr BALL_VY
	lda #$80
	sta BALL_VX+1
	sta BALL_VY+1
	jsr F_CURSOR_OFF
	jsr F_TERM_CLEAR
reset_game:
	lda #(FIELD_HEIGHT>>1)+(PAD_HEIGHT>>1)+FIELD_YOFFSET
	sta LPAD_Y
	sta RPAD_Y
	clr BALL_X+1
	clr BALL_Y+1
	lda #FIELD_XOFFSET+(FIELD_WIDTH>>1)
	ldb #FIELD_YOFFSET+(FIELD_HEIGHT>>1)
	sta BALL_X
	stb BALL_Y
wait_for_game_start:
	jsr draw_screen
wait_for_kb:
	jsr F_KB_PARSE
	beq wait_for_kb
	lda V_LAST_PRESSED
	cmp a,#'\r'
	bne wait_for_game_start

game_loop:
	; Game logic
	lda BALL_X+1
	add a,BALL_VX+1
	sta BALL_X+1
	lda BALL_X
	adc a,BALL_VX
	sta BALL_X
	lda BALL_Y+1
	add a,BALL_VY+1
	sta BALL_Y+1
	lda BALL_Y
	adc a,BALL_VY
	sta BALL_Y
	jsr draw_screen
	jsr frame_delay

	; Top of field collision
	lda BALL_YI
	cmp a,#FIELD_YOFFSET
	bgt no_top_coll
	lda BALL_VY+1
	neg a
	sta BALL_VY+1
	lda #0
	sbc a,BALL_VY
	sta BALL_VY
no_top_coll:

	; Bottom of field collission
	lda BALL_YI
	cmp a,#HEIGHT-1
	blt no_bottom_coll
	lda BALL_VY+1
	neg a
	sta BALL_VY+1
	lda #0
	sbc a,BALL_VY
	sta BALL_VY
no_bottom_coll:

	; Left end of field collission (point for right)

	; Right end of field collission (point for left)

	jmp game_loop

frame_delay:
	psh a
	lda #100
frame_delay_loop:
	nop
	nop
	nop
	nop
	nop
	dec a
	bne frame_delay_loop
	pul a
	rts

draw_screen:
	lda #TERM_DEFAULT_COLOR
	sta V_CURR_COLOR
	lda #XOFFSET+1
	clr b
	jsr F_CURSOR_SET
	lda LSCORE+2
	add a,#'0'
	jsr F_PUTCHAR
	lda LSCORE+1
	add a,#'0'
	jsr F_PUTCHAR
	lda LSCORE
	add a,#'0'
	jsr F_PUTCHAR
	lda #WIDTH-4
	clr b
	jsr F_CURSOR_SET
	lda RSCORE+2
	add a,#'0'
	jsr F_PUTCHAR
	lda RSCORE+1
	add a,#'0'
	jsr F_PUTCHAR
	lda RSCORE
	add a,#'0'
	jsr F_PUTCHAR
	lda #XOFFSET
	ldb #1
	jsr F_CURSOR_SET
	ldb #WIDTH-XOFFSET
	lda #TERM_DEFAULT_COLOR|2
	sta V_CURR_COLOR
	lda #' '
spaces_loop:
	jsr F_PUTCHAR
	dec b
	bne spaces_loop

	lda #TERM_DEFAULT_COLOR
	sta V_CURR_COLOR
	lda LAST_BALL_XI
	ldb LAST_BALL_YI
	cmp a,BALL_XI
	bne draw_ball
	cmp b,BALL_YI
	beq no_draw_ball
draw_ball:
	jsr F_CURSOR_SET
	lda #' '
	jsr F_PUTCHAR
	lda BALL_XI
	ldb BALL_YI
	sta LAST_BALL_XI
	stb LAST_BALL_YI
	jsr F_CURSOR_SET
	lda #BALL_COLOR
	sta V_CURR_COLOR
	lda #' '
	jsr F_PUTCHAR
no_draw_ball:

	; LPAD
	lda LAST_LPAD_Y
	cmp a,LPAD_Y
	beq no_draw_lpad
	ldb #FIELD_YOFFSET
lpad_loop:
	lda #XOFFSET+1
	jsr F_CURSOR_SET
	clr a
	sta V_CURR_COLOR
	cmp b,LPAD_Y
	bgt lpad_not_there
	lda LPAD_Y
	sub a,#PAD_HEIGHT
	cba
	bgt lpad_not_there
	lda #LPAD_COLOR
	sta V_CURR_COLOR
lpad_not_there:
	lda #' '
	jsr F_PUTCHAR

	inc b
	cmp b,#HEIGHT
	bne lpad_loop
	lda LPAD_Y
	sta LAST_LPAD_Y
no_draw_lpad:

	; RPAD
	lda LAST_RPAD_Y
	cmp a,RPAD_Y
	beq no_draw_rpad
	ldb #FIELD_YOFFSET
rpad_loop:
	lda #WIDTH-2
	jsr F_CURSOR_SET
	clr a
	sta V_CURR_COLOR
	cmp b,RPAD_Y
	bgt rpad_not_there
	lda RPAD_Y
	sub a,#PAD_HEIGHT
	cba
	bgt rpad_not_there
	lda #RPAD_COLOR
	sta V_CURR_COLOR
rpad_not_there:
	lda #' '
	jsr F_PUTCHAR

	inc b
	cmp b,#HEIGHT
	bne rpad_loop
	lda RPAD_Y
	sta LAST_RPAD_Y
no_draw_rpad:

	rts