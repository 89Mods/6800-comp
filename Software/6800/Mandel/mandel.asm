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

M_WIDTH equ 60
M_HEIGHT equ 28
W_D2 equ 7680
H_D2 equ 3584

ZOOM equ 16700000
RE equ ~5353728
IMAG equ 0
MAX_ITERS equ 128

	org 512
boot:
	nop
	jsr F_TERM_CLEAR
	jsr F_CURSOR_ON
	clr a
	clr b
	jsr F_CURSOR_SET
	lda #TERM_DEFAULT_COLOR
	sta V_CURR_COLOR
mandel_calc_constants_c1:
	; res = 2 / width
	clr arith_buff
	lda #2
	sta arith_buff+1
	clr arith_buff+2
	clr arith_buff+3
	clr arith_buff+4
	lda #M_WIDTH
	sta arith_buff+5
	clr arith_buff+6
	clr arith_buff+7
	ldx #arith_buff
	jsr F_DIV_FIXED
	inx
	; C1 = res * ZOOM
	lda 0,X
	sta arith_buff
	lda 1,X
	sta arith_buff+1
	lda 2,X
	sta arith_buff+2
	clr arith_buff+3
	lda #(ZOOM>>24)&255
	sta arith_buff+4
	lda #(ZOOM>>16)&255
	sta arith_buff+5
	lda #(ZOOM>>8)&255
	sta arith_buff+6
	lda #ZOOM&255
	sta arith_buff+7
	ldx #arith_buff
	jsr mul_fixed_unsigned
	lda 0,X
	sta C1
	sta strbuff+1
	sta arith_buff
	lda 1,X
	sta C1+1
	sta strbuff+2
	sta arith_buff+1
	lda 2,X
	sta C1+2
	sta strbuff+3
	sta arith_buff+2
	lda 3,X
	sta C1+3
	clr strbuff
	sta arith_buff+3
	lda #'C'
	jsr F_PUTCHAR
	lda #'1'
	jsr F_PUTCHAR
	lda #':'
	jsr F_PUTCHAR
	lda #' '
	jsr F_PUTCHAR
	ldx #strbuff
	jsr F_FITOA
	jsr F_PUTSTR
	jsr F_NEWL
	; C2 = W_D2 * C1
	lda #W_D2>>8
	sta arith_buff+4
	lda #W_D2&255
	sta arith_buff+5
	clr arith_buff+6
	clr arith_buff+7
	ldx #arith_buff
	jsr mul_fixed_unsigned
	lda 0,X
	sta C2
	sta strbuff+1
	lda 1,X
	sta C2+1
	sta strbuff+2
	lda 2,X
	sta C2+2
	sta strbuff+3
	lda 3,X
	sta C2+3
	clr strbuff
	lda #'C'
	jsr F_PUTCHAR
	lda #'2'
	jsr F_PUTCHAR
	lda #':'
	jsr F_PUTCHAR
	lda #' '
	jsr F_PUTCHAR
	ldx #strbuff
	jsr F_FITOA
	jsr F_PUTSTR
	jsr F_NEWL
mandel_calc_constants_c3:
	; res = 2 / height
	clr arith_buff
	lda #2
	sta arith_buff+1
	clr arith_buff+2
	clr arith_buff+3
	clr arith_buff+4
	lda #M_HEIGHT
	sta arith_buff+5
	clr arith_buff+6
	clr arith_buff+7
	ldx #arith_buff
	jsr F_DIV_FIXED
	inx
	; C3 = res * ZOOM
	lda 0,X
	sta arith_buff
	lda 1,X
	sta arith_buff+1
	lda 2,X
	sta arith_buff+2
	clr arith_buff+3
	lda #(ZOOM>>24)&255
	sta arith_buff+4
	lda #(ZOOM>>16)&255
	sta arith_buff+5
	lda #(ZOOM>>8)&255
	sta arith_buff+6
	lda #ZOOM&255
	sta arith_buff+7
	ldx #arith_buff
	jsr mul_fixed_unsigned
	lda 0,X
	sta C3
	sta strbuff+1
	sta arith_buff
	lda 1,X
	sta C3+1
	sta strbuff+2
	sta arith_buff+1
	lda 2,X
	sta C3+2
	sta strbuff+3
	sta arith_buff+2
	lda 3,X
	sta C3+3
	clr strbuff
	sta arith_buff+3
	lda #'C'
	jsr F_PUTCHAR
	lda #'3'
	jsr F_PUTCHAR
	lda #':'
	jsr F_PUTCHAR
	lda #' '
	jsr F_PUTCHAR
	ldx #strbuff
	jsr F_FITOA
	jsr F_PUTSTR
	jsr F_NEWL
	; C4 = H_D2 * C3
	lda #H_D2>>8
	sta arith_buff+4
	lda #H_D2&255
	sta arith_buff+5
	clr arith_buff+6
	clr arith_buff+7
	ldx #arith_buff
	jsr mul_fixed_unsigned
	lda 0,X
	sta C4
	sta strbuff+1
	lda 1,X
	sta C4+1
	sta strbuff+2
	lda 2,X
	sta C4+2
	sta strbuff+3
	lda 3,X
	sta C4+3
	clr strbuff
	lda #'C'
	jsr F_PUTCHAR
	lda #'4'
	jsr F_PUTCHAR
	lda #':'
	jsr F_PUTCHAR
	lda #' '
	jsr F_PUTCHAR
	ldx #strbuff
	jsr F_FITOA
	jsr F_PUTSTR
	jsr F_NEWL
	
	clr COUNTER
	lda #M_HEIGHT-1
mandel_row_loop:
	sta CURR_ROW
	sta arith_buff
	clr arith_buff+1
	clr arith_buff+2
	clr arith_buff+3
	lda COUNTER
	add a,#16
	sta COUNTER
	cmp a,#$A0
	bne counter_no_reset
	clr COUNTER
counter_no_reset:
	lda KB_PORTC
	and a,#$0F
	ora a,COUNTER
	sta KB_PORTC
	; res = row * C3
	ldx #arith_buff
	lda C3
	ldb C3+1
	sta arith_buff+4
	stb arith_buff+5
	lda C3+2
	ldb C3+3
	sta arith_buff+6
	stb arith_buff+7
	jsr mul_fixed
	; C_IM = res + IMAG
	ldb 3,X
	add b,#IMAG&255
	stb C_IM+3
	ldb 2,X
	adc b,#(IMAG>>8)&255
	stb C_IM+2
	ldb 1,X
	adc b,#(IMAG>>16)&255
	stb C_IM+1
	ldb 0,X
	adc b,#(IMAG>>24)&255
	stb C_IM
	; C_IM = C_IM - C4
	ldb C_IM+3
	sub b,C4+3
	stb C_IM+3
	ldb C_IM+2
	sbc b,C4+2
	stb C_IM+2
	ldb C_IM+1
	sbc b,C4+1
	stb C_IM+1
	ldb C_IM
	sbc b,C4
	stb C_IM
	
	clr a
mandel_col_loop:
	; res = col * C1
	sta CURR_COL
	sta arith_buff
	clr arith_buff+1
	clr arith_buff+2
	clr arith_buff+3
	jsr F_ADVANCE_CURSOR
	jsr F_KB_PARSE
	ldx #arith_buff
	lda C1
	ldb C1+1
	sta arith_buff+4
	stb arith_buff+5
	lda C1+2
	ldb C1+3
	sta arith_buff+6
	stb arith_buff+7
	jsr mul_fixed
	; C_RE = res + RE
	ldb 3,X
	add b,#RE&255
	stb C_RE+3
	ldb 2,X
	adc b,#(RE>>8)&255
	stb C_RE+2
	ldb 1,X
	adc b,#(RE>>16)&255
	stb C_RE+1
	ldb 0,X
	adc b,#(RE>>24)&255
	stb C_RE
	; C_RE = C_RE - C2
	ldb C_RE+3
	sub b,C2+3
	stb C_RE+3
	ldb C_RE+2
	sbc b,C2+2
	stb C_RE+2
	ldb C_RE+1
	sbc b,C2+1
	stb C_RE+1
	ldb C_RE
	sbc b,C2
	stb C_RE
	
	; X = C_RE, Y = C_IM
	lda C_RE
	ldb C_IM
	sta MAN_X
	stb MAN_Y
	lda C_RE+1
	ldb C_IM+1
	sta MAN_X+1
	stb MAN_Y+1
	lda C_RE+2
	ldb C_IM+2
	sta MAN_X+2
	stb MAN_Y+2
	lda C_RE+3
	ldb C_IM+3
	sta MAN_X+3
	stb MAN_Y+3
	
	; iteration = 0
	clr ITERATION
	clr ITERATION+1
mandel_calc_loop:
	; YY = Y * Y
	lda MAN_Y
	sta arith_buff
	sta arith_buff+4
	lda MAN_Y+1
	sta arith_buff+1
	sta arith_buff+5
	lda MAN_Y+2
	sta arith_buff+2
	sta arith_buff+6
	lda MAN_Y+3
	sta arith_buff+3
	sta arith_buff+7
	ldx #arith_buff
	jsr mul_fixed
	lda 0,X
	sta MAN_YY
	lda 1,X
	sta MAN_YY+1
	lda 2,X
	sta MAN_YY+2
	lda 3,X
	sta MAN_YY+3
	; res = X * Y
	lda MAN_Y
	sta arith_buff
	lda MAN_Y+1
	sta arith_buff+1
	lda MAN_Y+2
	sta arith_buff+2
	lda MAN_Y+3
	sta arith_buff+3
	lda MAN_X
	sta arith_buff+4
	lda MAN_X+1
	sta arith_buff+5
	lda MAN_X+2
	sta arith_buff+6
	lda MAN_X+3
	sta arith_buff+7
	ldx #arith_buff
	jsr mul_fixed
	; res = res << 1
	clc
	rol 3,X
	rol 2,X
	rol 1,X
	rol 0,X
	; Y = res + C_IM
	lda C_IM+3
	add a,3,X
	sta MAN_Y+3
	lda C_IM+2
	adc a,2,X
	sta MAN_Y+2
	lda C_IM+1
	adc a,1,X
	sta MAN_Y+1
	lda C_IM
	adc a,0,X
	sta MAN_Y
	; XX = res = X * X
	lda MAN_X
	sta arith_buff
	sta arith_buff+4
	lda MAN_X+1
	sta arith_buff+1
	sta arith_buff+5
	lda MAN_X+2
	sta arith_buff+2
	sta arith_buff+6
	lda MAN_X+3
	sta arith_buff+3
	sta arith_buff+7
	ldx #arith_buff
	jsr mul_fixed
	lda 0,X
	sta MAN_XX
	lda 1,X
	sta MAN_XX+1
	lda 2,X
	sta MAN_XX+2
	lda 3,X
	sta MAN_XX+3
	; res = res - YY
	ldb 3,X
	sub b,MAN_YY+3
	stb 3,X
	ldb 2,X
	sbc b,MAN_YY+2
	stb 2,X
	ldb 1,X
	sbc b,MAN_YY+1
	stb 1,X
	ldb 0,X
	sbc b,MAN_YY
	stb 0,X
	; X = res + C_RE
	ldb 3,X
	add b,C_RE+3
	stb MAN_X+3
	ldb 2,X
	adc b,C_RE+2
	stb MAN_X+2
	ldb 1,X
	adc b,C_RE+1
	stb MAN_X+1
	ldb 0,X
	adc b,C_RE
	stb MAN_X
	; check if XX + YY <= 4
	lda MAN_XX+3
	add a,MAN_YY+3
	lda MAN_XX+2
	adc a,MAN_YY+2
	lda MAN_XX+1
	adc a,MAN_YY+1
	ldb MAN_XX
	adc b,MAN_YY
	cmp b,#4
	bgt mandel_calc_loop_overflow
	
	; iteration++
	lda ITERATION
	ldb ITERATION+1
	add a,#1
	adc b,#0
	sta ITERATION
	stb ITERATION+1
	cmp a,#MAX_ITERS&255
	bne mandel_calc_loop_continue
	cmp b,#MAX_ITERS>>8
	bne mandel_calc_loop_continue
	bra mandel_calc_loop_max_iters
mandel_calc_loop_continue:
	jmp mandel_calc_loop
	
mandel_calc_loop_max_iters:
	jsr F_CURSOR_RETURN
	lda #TERM_DEFAULT_COLOR
	sta V_CURR_COLOR
	lda #' '
	jsr F_PUTCHAR
	jmp mandel_calc_loop_exit
mandel_calc_loop_overflow:
	jsr F_CURSOR_RETURN
	lda ITERATION
	and a,#7
	cmp a,#0
	bne no_inc
	inc a
no_inc:
	clc
	rol a
	rol a
	rol a
	rol a
	rol a
	sta V_CURR_COLOR
	lda #' '
	jsr F_PUTCHAR
mandel_calc_loop_exit:
	; Col loop end
	lda CURR_COL
	inc a
	cmp a,#M_WIDTH
	beq mandel_col_loop_over
	jmp mandel_col_loop
mandel_col_loop_over:
	; Row loop end
	;jsr F_NEWL
	lda CURR_ROW
	dec a
	cmp a,#255
	beq mandel_row_loop_over
	jmp mandel_row_loop
mandel_row_loop_over:
	
	jsr F_CURSOR_OFF
mandel_done:
	;wai
	jmp mandel_done
mul_fixed:
	jsr F_MUL3232_SIGNED
	inx
	rts
mul_fixed_unsigned:
	jsr F_MUL3232_UNSIGNED
	inx
	rts
ram_start:
C1:
	db 0,0,0,0
C2:
	db 0,0,0,0
C3:
	db 0,0,0,0
C4:
	db 0,0,0,0
CURR_ROW:
	db 0
CURR_COL:
	db 0
C_IM:
	db 0,0,0,0
C_RE:
	db 0,0,0,0
MAN_X:
	db 0,0,0,0
MAN_Y:
	db 0,0,0,0
MAN_XX:
	db 0,0,0,0
MAN_YY:
	db 0,0,0,0
ITERATION:
	db 0,0
arith_buff:
	db 0,0,0,0
	db 0,0,0,0
	db 0,0,0,0
	db 0,0,0,0
COUNTER:
	db 0
strbuff:
	db 0
