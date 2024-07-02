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

V_CURSOR_X equ $000B
v_CURSOR_Y equ $000C
V_LAST_PRESSED  equ $000E
V_LAST_RELEASED equ $000F
V_SHIFT_DOWN    equ $0010
v_ALT_CTRL_DOWN equ $0011

	org 512
boot:
	nop
	ldx #ram_start
	lda #$0C
	sta ram_start
	jsr F_PRINTHEX
	lda #$33
	sta ram_start+1
	jsr F_PRINTHEX
	lda #'*'
	jsr F_PUTCHAR
	lda #$11
	sta ram_start+2
	jsr F_PRINTHEX
	lda #$6D
	sta ram_start+3
	jsr F_PRINTHEX
	lda #'='
	jsr F_PUTCHAR
	jsr F_MUL1616_UNSIGNED
	lda #4
	jsr F_PRINTHEX_STR
	jsr F_NEWL
	
	ldx #ram_start
	lda #$0C
	sta ram_start
	jsr F_PRINTHEX
	lda #$33
	sta ram_start+1
	jsr F_PRINTHEX
	lda #'/'
	jsr F_PUTCHAR
	clra
	sta ram_start+2
	jsr F_PRINTHEX
	lda #$0B
	sta ram_start+3
	jsr F_PRINTHEX
	lda #'='
	jsr F_PUTCHAR
	jsr F_MODDIV_1616_UNSIGNED
	lda #2
	jsr F_PRINTHEX_STR
	jsr rem
	lda #2
	jsr F_PRINTHEX_STR
	
	jsr F_NEWL
	ldx #ram_start
	lda #$0C
	sta ram_start
	jsr F_PRINTHEX
	lda #$33
	sta ram_start+1
	jsr F_PRINTHEX
	lda #'='
	jsr F_PUTCHAR
	jsr F_ITOA16
	jsr F_PUTSTR
	
	ldx #ram_start
	jsr F_NEWL
	lda #$F3
	sta ram_start
	jsr F_PRINTHEX
	lda #$CD
	sta ram_start+1
	jsr F_PRINTHEX
	lda #'='
	jsr F_PUTCHAR
	jsr F_ITOA16
	jsr F_PUTSTR
	jsr F_NEWL
	
	ldx #ram_start
	lda #$01
	sta ram_start
	jsr F_PRINTHEX
	lda #$19
	sta ram_start+1
	jsr F_PRINTHEX
	lda #$A6
	sta ram_start+2
	jsr F_PRINTHEX
	lda #$7D
	sta ram_start+3
	jsr F_PRINTHEX
	lda #'/'
	jsr F_PUTCHAR
	lda #$37
	sta ram_start+4
	jsr F_PRINTHEX
	lda #$AA
	sta ram_start+5
	jsr F_PRINTHEX
	lda #'='
	jsr F_PUTCHAR
	jsr F_MODDIV_3216_UNSIGNED
	lda #4
	jsr F_PRINTHEX_STR
	jsr rem
	lda #2
	jsr F_PRINTHEX_STR
	jsr F_NEWL
	
	ldx #ram_start
	lda #$07
	sta ram_start
	jsr F_PRINTHEX
	lda #$19
	sta ram_start+1
	jsr F_PRINTHEX
	lda #$A6
	sta ram_start+2
	jsr F_PRINTHEX
	lda #$7D
	sta ram_start+3
	jsr F_PRINTHEX
	lda #'/'
	jsr F_PUTCHAR
	lda #$00
	sta ram_start+4
	jsr F_PRINTHEX
	lda #$13
	sta ram_start+5
	jsr F_PRINTHEX
	lda #$BC
	sta ram_start+6
	jsr F_PRINTHEX
	lda #$8A
	sta ram_start+7
	jsr F_PRINTHEX
	lda #'='
	jsr F_PUTCHAR
	jsr F_MODDIV_3232_UNSIGNED
	lda #4
	jsr F_PRINTHEX_STR
	jsr rem
	lda #4
	jsr F_PRINTHEX_STR
	jsr F_NEWL
	
	ldx #ram_start
	lda #$07
	sta ram_start
	jsr F_PRINTHEX
	lda #$19
	sta ram_start+1
	jsr F_PRINTHEX
	lda #$A6
	sta ram_start+2
	jsr F_PRINTHEX
	lda #$7D
	sta ram_start+3
	jsr F_PRINTHEX
	lda #'='
	jsr F_PUTCHAR
	jsr F_ITOA32
	jsr F_PUTSTR
	jsr F_NEWL
	
	ldx #ram_start
	lda #$07
	sta ram_start
	jsr F_PRINTHEX
	lda #$19
	sta ram_start+1
	jsr F_PRINTHEX
	lda #$A6
	sta ram_start+2
	jsr F_PRINTHEX
	lda #$7D
	sta ram_start+3
	jsr F_PRINTHEX
	lda #'*'
	jsr F_PUTCHAR
	lda #$3E
	sta ram_start+4
	jsr F_PRINTHEX
	lda #$89
	sta ram_start+5
	jsr F_PRINTHEX
	lda #$A5
	sta ram_start+6
	jsr F_PRINTHEX
	lda #$0D
	sta ram_start+7
	jsr F_PRINTHEX
	lda #'='
	jsr F_PUTCHAR
	jsr F_MUL3232_UNSIGNED
	lda #8
	jsr F_PRINTHEX_STR
	jsr F_NEWL
	
	ldx #ram_start
	lda #$00
	sta ram_start
	jsr F_PRINTHEX
	lda #$00
	sta ram_start+1
	jsr F_PRINTHEX
	lda #$63
	sta ram_start+2
	jsr F_PRINTHEX
	lda #$AC
	sta ram_start+3
	jsr F_PRINTHEX
	lda #'*'
	jsr F_PUTCHAR
	lda #$00
	sta ram_start+4
	jsr F_PRINTHEX
	lda #$0A
	sta ram_start+5
	jsr F_PRINTHEX
	lda #$00
	sta ram_start+6
	jsr F_PRINTHEX
	lda #$00
	sta ram_start+7
	jsr F_PRINTHEX
	lda #'='
	jsr F_PUTCHAR
	jsr F_MUL3232_SIGNED
	lda #8
	jsr F_PRINTHEX_STR
	jsr F_NEWL
	
	ldx #ram_start
	lda #$01
	sta ram_start
	jsr F_PRINTHEX
	lda #$3C
	sta ram_start+1
	jsr F_PRINTHEX
	lda #'.'
	jsr F_PUTCHAR
	lda #$63
	sta ram_start+2
	jsr F_PRINTHEX
	lda #$AC
	sta ram_start+3
	jsr F_PRINTHEX
	lda #'='
	jsr F_PUTCHAR
	jsr F_FITOA
	jsr F_PUTSTR
	
	jsr F_NEWL
	jsr F_ADVANCE_CURSOR
wait_for_kb:
	jsr F_KB_PARSE
	beq wait_for_kb
	lda V_LAST_PRESSED
	cmpa #'\r'
	bne wait_for_kb
	jsr F_TERM_CLEAR
	jmp boot
rem:
	lda #' '
	jsr F_PUTCHAR
	lda #'R'
	jsr F_PUTCHAR
	lda #':'
	jsr F_PUTCHAR
	rts
ram_start:
	db 0
