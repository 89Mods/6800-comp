F_TBL_START  equ 32768
F_PUTCHAR    equ 21+F_TBL_START
V_CURR_COLOR equ $0005
TERM_DEFAULT_COLOR equ $1C
	org $0500
	;org 512
start:
	lda #$08
	sta V_CURR_COLOR
	ldx #text
	lda 0,X
loop:
	inx
	jsr F_PUTCHAR
	lda 0,X
	bne loop
	lda #TERM_DEFAULT_COLOR
	sta V_CURR_COLOR
	rts
	;bra start
text:
	db "Hellorld!\r\n"
	db 0
