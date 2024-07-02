UART_BASE equ $0160
UART_CTRL equ UART_BASE
UART_DATA equ UART_BASE+1

KB_BASE equ $0140
KB_PORTA equ KB_BASE
KB_PORTB equ KB_BASE+1
KB_PORTC equ KB_BASE+2
KB_CTRL equ KB_BASE+3

VIDEO_BASE equ $0120
SCN_BASE equ VIDEO_BASE+16
SCN_INIT_W equ SCN_BASE
SCN_CMD_W equ SCN_BASE+1
SCN_START1_LOW_RW equ SCN_BASE+2
SCN_START1_HI_RW equ SCN_BASE+3
SCN_CURSOR_ADDR_LOW_RW equ SCN_BASE+4
SCN_CURSOR_ADDR_HI_RW equ SCN_BASE+5
SCN_START2_LOW_RW equ SCN_BASE+6
SCN_START2_HI_RW equ SCN_BASE+7
SCN_INTR_R equ SCN_BASE
SCN_STATUS_R equ SCN_BASE+1

SCN_CMD_GFX_OFF      equ %00100010
SCN_CMD_GFX_ON       equ %00100111
SCN_CMD_DISP_OFF     equ %00101000
SCN_CMD_DISP_ON      equ %00101001
SCN_CMD_CURSOR_OFF   equ %00110100
SCN_CMD_CURSOR_ON    equ %00110101
SCN_CMD_CLR_INT_STAT equ %01000000
SCN_CMD_INTR_DIS     equ %10000000
SCN_CMD_INTR_EN      equ %01100000

SCN_CMD_READ_POINTER equ %10100100
SCN_CMD_WRITE_POINTER equ %10100010
SCN_CMD_INCR_CURSOR equ %10101001
SCN_CMD_READ_CURSOR equ %10101100
SCN_CMD_WRITE_CURSOR equ %10101010
SCN_CMD_READ_CURSOR_INCR equ %10101101
SCN_CMD_WRITE_CURSOR_INCR equ %10101011
SCN_CMD_FROM_CURSOR_TO_POINTER equ %10111011
SCN_CMD_FROM_POINTER_TO_CURSOR equ %10111101

ARITH_BASE equ $0100
ARITH_X equ ARITH_BASE+4
ARITH_Z equ ARITH_BASE+5
ARITH_Y equ ARITH_BASE+6
ARITH_CTRL equ ARITH_BASE+7

ARITH_CLOCKDIV equ %10100000
ARITH_OP_NOP equ %00000000
ARITH_OP_MUL equ %00000001
ARITH_OP_DIV equ %00000010
ARITH_RST_SEQ equ 64
ARITH_RST_Z equ 4
ARITH_RST_Y equ 8

TERM_WIDTH equ 64
TERM_HEIGHT equ 30
TERM_WxH equ 2048

CTR0 equ $0000
CTR1 equ $0001
PRINTHEX_TEMP0 equ $0002
PRINTHEX_TEMP1 equ $0003
TEMP equ $0004

; Terminal stuff
TERM_DEFAULT_COLOR equ $1C
CURR_COLOR equ $0005
TEMP0 equ $0006
TEMP1 equ $0007
PSHX0 equ $0008
PSHX1 equ $0009
PSHX2 equ $000A
CURSOR_X equ $000B
CURSOR_Y equ $000C
CURSOR_ON equ $000D

CHARS_BUFF_START equ 32768-1920-1920
CHARS_BUFF_END equ 32768-1920
COLORS_BUFF_START equ 32768-1920
COLORS_BUFF_END equ 32768
DISP_PTR_LOC equ CHARS_BUFF_START-2

; Keyboard stuff
KB_BUFF_END equ CHARS_BUFF_START-3
KB_BUFF_START equ KB_BUFF_END-32
KB_BUFF_WR_PTR equ KB_BUFF_START-2
KB_BUFF_RD_PTR equ KB_BUFF_START-4
TEMP_BUFF equ KB_BUFF_START-20
LAST_PRESSED equ $000E
LAST_RELEASED equ $000F
SHIFT_DOWN equ $0010
ALT_CTRL_DOWN equ $0011
MDIV_T0 equ $0012
MDIV_T1 equ $0013
MDIV_T2 equ $0014

XORSHIFT0 equ $0015
XORSHIFT1 equ $0016
XORSHIFT2 equ $0017
XORSHIFT3 equ $0018
ABA_TEMP equ $0019

aba macro
	stb ABA_TEMP
	adda ABA_TEMP
	endm

clc macro
	andcc #$FE
	endm

; Misc
STACK_LOC equ KB_BUFF_START-21

FG_RED equ 4
FG_GREEN equ 8
FG_BLUE equ 16
BG_RED equ 32
BG_GREEN equ 64
BG_BLUE equ 128

	org 32768
funct_table:
	jmp loooong_delay
	jmp spi_tx
	jmp spi_rx
	jmp rom_desel
	jmp uart_wait
	jmp gpu_wait_vblank
	jmp gpu_wait_ready
	jmp putchar
	jmp term_cursor_set
	jmp putstr
	jmp printhex_str
	jmp term_clear
	jmp term_blink_on
	jmp term_blink_off
	jmp kb_parse
	jmp advance_cursor
	jmp return_cursor
	jmp printhex
	jmp newl
	jmp mul_16x16_unsigned
	jmp mul_16x16_signed
	jmp moddiv_16x16_unsigned
	jmp itoa16
	jmp moddiv_32x16_unsigned
	jmp moddiv_32x32_unsigned
	jmp itoa32
	jmp mul_32x32_unsigned
	jmp mul_32x32_signed
	jmp mul_fixed
	jmp moddiv_32x32_signed
	jmp div_fixed
	jmp fitoa
	jmp xorshift
int:
	nop
nmi:
	nop
	lda KB_PORTB
	ldb KB_PORTC
	pshs a
	lda KB_PORTA
	anda #254
	sta KB_PORTA
	ora #1
	nop
	sta KB_PORTA
	puls a
	andb #$0C
	cmpb #4
	beq kb_valid_data
	jmp kb_invalid_data
kb_valid_data:
	ldx KB_BUFF_WR_PTR
	leax 1,X
	cmpx KB_BUFF_RD_PTR
	beq kb_buffer_overflow
	leax -1,X
	sta 0,X
	leax 1,X
	cmpx #KB_BUFF_END
	bne kb_ptr_no_rewind
kb_ptr_rewind:
	ldx #KB_BUFF_START
kb_ptr_no_rewind:
	stx KB_BUFF_WR_PTR

	rti
kb_invalid_data:
	jsr uart_wait
	jsr uart_wait
	lda KB_PORTA
	anda #254
	sta KB_PORTA
	ora #1
	nop
	sta KB_PORTA
kb_buffer_overflow:
	rti
sint:
	nop
	nop
	rti
fint:
	nop
	rti
begin:
	orcc #$10
	clra
	tfr a, dpr
	clr LAST_PRESSED
	clr LAST_RELEASED
	clr SHIFT_DOWN
	clr ALT_CTRL_DOWN
	lds #STACK_LOC
	jsr arith_init
	
	lda #$52
	sta XORSHIFT0
	lda #$3A
	sta XORSHIFT1
	lda #$F9
	sta XORSHIFT2
	lda #$33
	sta XORSHIFT3
	
	lda #21 ; div 16, 8 bits + 1 stop bit, tx int disabled, rx int disabled
	sta UART_CTRL
	jsr uart_wait
	
	clra
	sta TEMP
	
	ldx #KB_BUFF_START
	stx KB_BUFF_WR_PTR
	stx KB_BUFF_RD_PTR
	lda #$78
	sta KB_PORTA
	lda #$83
	sta KB_CTRL
	lda #$79
	nop
	sta KB_PORTA
	lda #0
	sta KB_PORTB
	sta KB_PORTC
	jsr gpu_init
	jsr uart_wait
	jsr gpu_wait_vblank
	jsr term_blink_on
	lda #SCN_CMD_GFX_OFF
	sta SCN_CMD_W
	jsr uart_wait
	jsr gpu_clear_all
	andcc #$AF
	clr SCN_START1_HI_RW
	clr SCN_START1_LOW_RW
	clr SCN_START2_HI_RW
	clr SCN_START2_LOW_RW
	; Set keyboard mode
	; Data frames sent:
	; 0: 0 11110110 1 1
	jsr ps2_tx_zero
	ldb #8
	sta PRINTHEX_TEMP1
	ldb #%11110110
ps2_tx_loop:
	bita #1
	beq ps2_tx_loop_zero
	jsr ps2_tx_one
	bra ps2_tx_loop_one
ps2_tx_loop_zero:
	jsr ps2_tx_zero
ps2_tx_loop_one:
	rora
	dec PRINTHEX_TEMP1
	bne ps2_tx_loop
	jsr ps2_tx_one
	jsr ps2_tx_one
	lda KB_PORTA
	ora #96
	sta KB_PORTA
	
	bra cont_0
spiflash_text:
	db "Spiflash ID: "
	db 0
cont_0:
	ldx #spiflash_text
	jsr putstr
	
	lda #$FF
	jsr spi_tx
	jsr rom_desel
	lda #$AB
	jsr spi_tx
	clra
	jsr spi_tx
	jsr spi_tx
	jsr spi_tx
	jsr rom_desel
	lda #$90
	jsr spi_tx
	clra
	jsr spi_tx
	jsr spi_tx
	jsr spi_tx
	; Manufacturer ID (should be $EF)
	jsr spi_rx
	tfr a,b
	; Device ID (should be $15)
	jsr spi_rx
	pshs a
	pshs b
	jsr rom_desel
	tfr s,x
	lda #2
	jsr printhex_str
	lda #'\r'
	jsr putchar
	lda #'\n'
	jsr putchar
	jsr advance_cursor
	puls a
	cmpa #$EF
	beq dev_id_correct
	jmp flash_init_fail
dev_id_correct:
	puls b
	cmpb #$15
	beq mf_id_correct
	jmp flash_init_fail
mf_id_correct:
	
;	clr CURR_COLOR
;	clr 100
;	clr 101
;	lda #0
;	ldb #0
;	jsr term_cursor_set
;	jmp loop
;string:
;	db "Hellorld! "
;	db 0
;loop:
;	lda CURR_COLOR
;	psh a
;	lda #TERM_DEFAULT_COLOR
;	sta CURR_COLOR
;	lda 100
;	bne loop_do_nl
;	lda 101
;	bne loop_do_nl
;	bra loop_no_nl
;loop_do_nl:
;	lda #'\r'
;	jsr putchar
;	lda #'\n'
;	jsr putchar
;loop_no_nl:
;	lda #' '
;	jsr putchar
;	pul a
;	add a,#4
;	sta CURR_COLOR
;	ldx #string
;	jsr putstr
;	lda 100
;	add a,#4
;	sta 100
;	lda 101
;	adc a,#0
;	sta 101
;	ldx #101
;	lda #2
;	jsr printhex_str
;	jsr loooong_delay
;	jmp loop
	
;	jsr term_blink_off
;loop:
;	lda #'\r'
;	jsr putchar
;	lda #' '
;	jsr putchar
;	lda #' '
;	jsr putchar
;	lda #' '
;	jsr putchar
;	
;	lda #(ARITH_CLOCKDIV | ARITH_RST_SEQ | ARITH_RST_Z | ARITH_RST_Y)
;	sta ARITH_CTRL
;	lda #$67
;	sta ARITH_X
;	lda #$39
;	sta ARITH_X
;	lda #$12
;	sta ARITH_Z
;	sta ARITH_Z
;	lda #(ARITH_CLOCKDIV | ARITH_OP_MUL | ARITH_RST_SEQ)
;	sta ARITH_CTRL
;	jsr uart_wait
;	lda ARITH_Y
;	sta MEM_START+40
;	lda ARITH_Y
;	sta MEM_START+39
;	lda ARITH_Z
;	sta MEM_START+38
;	lda ARITH_Z
;	sta MEM_START+37
;	ldx #(MEM_START+40)
;	lda #4
;	jsr printhex_str
;	
;	lda #' '
;	jsr putchar
;
;	jmp loop

	jsr loooong_delay
	lda #3
	jsr spi_tx
	lda #$20
	jsr spi_tx
	clra
	jsr spi_tx
	jsr spi_tx
	ldx #header_text
	jmp check_header
header_text:
	db "CHIRP!"
	db 0
check_header:
	jsr spi_rx
	cmpa 0,X
	bne check_header_fail
	leax 1,X
	cmpa #0
	bne check_header
	jmp check_header_success
check_header_fail_text:
	db "ROM header has wrong magic no.\r"
	db 0
check_header_fail:
	jsr rom_desel
	ldx #check_header_fail_text
	jsr putstr
	lda #'\n'
	jsr putchar
	jmp boot_fail
check_header_success:
	jsr uart_wait
	jsr uart_wait
	jsr uart_wait
	jsr uart_wait
	jsr spi_rx
	sta PRINTHEX_TEMP1
	jsr spi_rx
	sta PRINTHEX_TEMP0
	cmpa #64
	blt size_good
	bra size_bad
size_bad_string:
	db "Binary image too large to boot (limit is 16KiB)"
	db 0
size_bad:
	ldx #size_bad_string
	jsr putstr
	lda #'\n'
	jsr putchar
	bra boot_fail
booting_text:
	db "Booting...\r"
	db 0
size_good:
	jsr return_cursor
	ldx #booting_text
	jsr putstr
	lda KB_PORTA
	anda #254
	sta KB_PORTA
	ora #1
	nop
	sta KB_PORTA
	lda #'\n'
	jsr putchar
	jsr advance_cursor
	;jsr loooong_delay
	lda PRINTHEX_TEMP0
	adda #$02
	sta PRINTHEX_TEMP0
	ldx #$0200
copy_loop:
	jsr spi_rx
	sta 0,X
	leax 1,X
	cmpx PRINTHEX_TEMP0
	bne copy_loop
	jsr rom_desel
	jsr term_clear
	jsr term_blink_on
	jmp $0200

	jmp boot_fail
flash_init_fail:
	lda #TERM_DEFAULT_COLOR
	sta CURR_COLOR
	jmp flash_fail_prt
flash_fail_string:
	db "Bad spiflash IDs\r"
	db 0
flash_fail_prt:
	ldx #flash_fail_string
	jsr putstr
	lda #'\n'
	jsr putchar
boot_fail:
	lda #FG_RED
	sta CURR_COLOR
	jmp boot_err
boot_err_string:
	db "Boot Fail "
	db 0
boot_err:
	ldx #boot_err_string
	jsr putstr
loop:
	sync
	jmp loop

ps2_tx_one:
	lda KB_PORTA
	anda #%10011111
	ora #32
	sta KB_PORTA
	jsr ps2_wait
	ora #64
	sta KB_PORTA
	jsr ps2_wait
	rts

ps2_tx_zero:
	lda KB_PORTA
	anda #%10011111
	sta KB_PORTA
	jsr ps2_wait
	ora #64
	sta KB_PORTA
	jsr ps2_wait
	rts

loooong_delay:
	pshs a,b
	lda #255
delay_outer:
	ldb #255
delay_inner:
	nop
	nop
	nop
	decb
	bne delay_inner
	deca
	bne delay_outer
	puls a,b
	rts

arith_init:
	lda #%00101100
	sta ARITH_CTRL
	lda #(ARITH_CLOCKDIV | ARITH_RST_SEQ | ARITH_RST_Z | ARITH_RST_Y | ARITH_OP_NOP)
	sta ARITH_CTRL
	rts

gpu_init:
	; Write two 0s = master reset
	clra
	sta SCN_CMD_W
	jsr uart_wait
	clra
	sta SCN_CMD_W
	jsr uart_wait
	
	; TODO: Document this
	lda #120
	sta SCN_INIT_W
	lda #$13
	sta SCN_INIT_W
	lda #$21
	sta SCN_INIT_W
	lda #$6D
	sta SCN_INIT_W
	lda #TERM_HEIGHT-1
	sta SCN_INIT_W
	lda #TERM_WIDTH-1
	sta SCN_INIT_W
	lda #$DE
	sta SCN_INIT_W
	lda #$2F
	sta SCN_INIT_W
	lda #0
	sta SCN_INIT_W
	lda #$F0
	sta SCN_INIT_W
	lda #0
	sta SCN_INIT_W
	nop
	sta SCN_INIT_W
	nop
	sta SCN_INIT_W
	nop
	sta SCN_INIT_W
	nop
	sta SCN_INIT_W
	jsr uart_wait
	
	lda #SCN_CMD_DISP_ON
	sta SCN_CMD_W
	jsr uart_wait
	lda #0
	sta SCN_START1_LOW_RW
	lda #0
	sta SCN_START1_HI_RW
	lda #0
	sta SCN_START2_LOW_RW
	lda #0
	sta SCN_START2_HI_RW
	jsr uart_wait
	lda #$9F
	sta SCN_CMD_W
	jmp uart_wait

uart_wait:
	pshs a
	lda #111
uart_wait_loop:
	deca
	bne uart_wait_loop
	puls a
	rts

ps2_wait:
	pshs a
	lda #20
ps2_wait_loop:
	deca
	bne ps2_wait_loop
	puls a
	rts

gpu_wait_vblank:
	pshs a
gpu_wait_vblank_l:
	lda SCN_STATUS_R
	anda #16
	beq gpu_wait_vblank_l
	puls a
	rts

gpu_wait_ready:
	pshs a
gpu_wait_ready_l:
	lda SCN_STATUS_R
	anda #34
	cmpa #34
	bne gpu_wait_ready_l
	puls a
	rts
	
gpu_write_verify:
	pshs b
gpu_write_verify_l:
	cmpa 0,X
	beq gpu_write_verify_success
	sta 0,X
	bra gpu_write_verify_l
gpu_write_verify_success:
	puls b
	rts

term_reset_cursor:
	pshs a
	clr CURSOR_X
	clr CURSOR_Y
	clr DISP_PTR_LOC+0
	clr DISP_PTR_LOC+1
	ldx #SCN_CURSOR_ADDR_LOW_RW
	clra
	jsr gpu_write_verify
	ldx #SCN_CURSOR_ADDR_HI_RW
	jsr gpu_write_verify
	puls a
	rts

gpu_clear_all:
	pshs a,b
	
	jsr term_reset_cursor
	
	lda #0
	sta CTR0
	sta CTR1
gpu_clear_all_loop:
	lda #' '
	adda #128
	sta VIDEO_BASE
	lda #TERM_DEFAULT_COLOR
	sta VIDEO_BASE+8
	lda #SCN_CMD_WRITE_CURSOR_INCR
	sta SCN_CMD_W
	jsr gpu_wait_ready
	lda #SCN_CMD_GFX_OFF
	sta SCN_CMD_W
	
	lda CTR0
	adda #1
	sta CTR0
	lda CTR1
	adca #0
	sta CTR1
	cmpa #$40
	bne gpu_clear_all_loop
	
	ldx #CHARS_BUFF_START
	lda #' '
	adda #128
gpu_clear_buffer_1:
	sta 0,X
	leax 1,X
	cmpx #CHARS_BUFF_END
	bne gpu_clear_buffer_1
	ldx #COLORS_BUFF_START
	lda #TERM_DEFAULT_COLOR
gpu_clear_buffer_2:
	sta 0,X
	leax 1,X
	cmpx #COLORS_BUFF_END
	bne gpu_clear_buffer_2
	
	lda #TERM_DEFAULT_COLOR
	sta CURR_COLOR
	clrb
	tfr b,a
	jsr term_cursor_set
	puls a,b
	rts

term_clear:
	jsr term_reset_cursor
	pshs a,b
	lda #SCN_CMD_CURSOR_OFF
	sta SCN_CMD_W

	ldx #CHARS_BUFF_START
term_clear_loop:
	lda #' '
	adda #128
	sta 0,X
	sta VIDEO_BASE
	lda #TERM_DEFAULT_COLOR
	sta VIDEO_BASE+8
	lda #SCN_CMD_WRITE_CURSOR_INCR
	sta SCN_CMD_W
	jsr gpu_wait_ready

	leax 1,X
	cmpx #CHARS_BUFF_END
	bne term_clear_loop

	lda #TERM_DEFAULT_COLOR
	ldx #COLORS_BUFF_START
term_clear_loop2:
	sta 0,X
	leax 1,X
	cmpx #COLORS_BUFF_END
	bne term_clear_loop2

	lda CURSOR_ON
	beq term_clear_no_cursor
	lda #SCN_CMD_CURSOR_ON
	sta SCN_CMD_W
term_clear_no_cursor:
	lda #TERM_DEFAULT_COLOR
	sta CURR_COLOR
	clrb
	tfr b,a
	jsr term_cursor_set
	puls a,b
	rts

term_blink_off:
	pshs a
	lda #SCN_CMD_CURSOR_OFF
	sta SCN_CMD_W
	clr CURSOR_ON
	puls a
	rts

term_blink_on:
	pshs a
	lda #SCN_CMD_CURSOR_ON
	sta SCN_CMD_W
	lda #33
	sta CURSOR_ON
	puls a
	rts

return_cursor:
	pshs a,b
	dec CURSOR_X
	lda #255
	cmpa CURSOR_X
	bne return_same_line
	tst CURSOR_Y
	beq return_impossible
	lda #TERM_WIDTH-5
	sta CURSOR_X
	dec CURSOR_Y
	ldb CURSOR_Y
	jsr term_cursor_set
	bra return_end
return_same_line:
	stx PSHX0
	ldx DISP_PTR_LOC
	leax -1,X
	stx DISP_PTR_LOC
	lda DISP_PTR_LOC+1
	ldx #SCN_CURSOR_ADDR_LOW_RW
	jsr gpu_write_verify
	ldx #SCN_CURSOR_ADDR_HI_RW
	lda DISP_PTR_LOC+0
	jsr gpu_write_verify
	ldx PSHX0
return_end:
	puls a,b
	rts
return_impossible:
	lda #1
	clrb
	jsr term_cursor_set
	bra return_end

advance_cursor:
	pshs a,b
advance_cursor_a:
	inc CURSOR_X
	ldb CURSOR_X
	cmpb #TERM_WIDTH-4
	bmi advance_cursor_done
	clrb
	stb CURSOR_X
	jmp putchar_is_nl
advance_cursor_done:
	stx PSHX0
	ldx DISP_PTR_LOC
	leax 1,X
	stx DISP_PTR_LOC
	lda DISP_PTR_LOC+1
	ldx #SCN_CURSOR_ADDR_LOW_RW
	jsr gpu_write_verify
	ldx #SCN_CURSOR_ADDR_HI_RW
	lda DISP_PTR_LOC+0
	jsr gpu_write_verify
	ldx PSHX0
	puls a,b
	rts
	
newl:
	pshs a
	lda #'\r'
	bsr putchar
	lda #'\n'
	bsr putchar
	puls a
	rts
	
	; Puts character in 'a'
putchar:
	pshs a,b
	cmpa #0
	beq putchar_return
	cmpa #'\r'
	bne putchar_not_cr
	clra
	ldb CURSOR_Y
	jsr term_cursor_set
	jmp putchar_return
putchar_not_cr:
	cmpa #'\n'
	bne putchar_not_nl
putchar_is_nl:
	ldb CURSOR_Y
	incb
	stb CURSOR_Y
	cmpb #TERM_HEIGHT-1
	bmi putchar_no_scroll_up
	jsr term_scroll_up
putchar_no_scroll_up:
	lda CURSOR_X
	ldb CURSOR_Y
	jsr term_cursor_set
	jmp putchar_return
putchar_not_nl:
	jsr putchar_raw
	jmp advance_cursor_a
putchar_return:
	puls a,b
	rts

	; Puts character in 'a'
putchar_raw:
	pshs a,b,x
	
	ldb CURR_COLOR
	andb #1
	bne putchar_raw_is_graphics
	ora #128
putchar_raw_is_graphics:
	sta VIDEO_BASE
	
	ldb DISP_PTR_LOC+1
	addb #CHARS_BUFF_START&255
	stb TEMP1
	ldb DISP_PTR_LOC+0
	adcb #CHARS_BUFF_START>>8
	stb TEMP0
	ldx TEMP0
	sta 0,X
	lda 1,X
	pshs a

	ldb DISP_PTR_LOC+1
	addb #COLORS_BUFF_START&255
	stb TEMP1
	ldb DISP_PTR_LOC+0
	adcb #COLORS_BUFF_START>>8
	stb TEMP0
	ldx TEMP0
	lda 0,X
	anda #254
	ldb CURR_COLOR
	andb #1
	aba
	sta 0,X
	sta VIDEO_BASE+8
	ldb #SCN_CMD_WRITE_CURSOR_INCR
	stb SCN_CMD_W
	jsr gpu_wait_ready
	lda 1,X
	anda #1
	ldb CURR_COLOR
	andb #254
	aba
	sta 1,X
	sta VIDEO_BASE+8
	puls a
	sta VIDEO_BASE
	ldb #SCN_CMD_WRITE_CURSOR
	stb SCN_CMD_W
	jsr gpu_wait_ready

	puls a,b,x
	rts

term_scroll_up:
	pshs a,b,x
	lda #SCN_CMD_CURSOR_OFF
	sta SCN_CMD_W
	; Move up character buffer by one line
	ldx #CHARS_BUFF_START
term_scroll_l1:
	lda TERM_WIDTH,X
	sta 0,X
	leax 1,X
	cmpx #CHARS_BUFF_END-TERM_WIDTH
	bne term_scroll_l1
	; Clear last line
	lda #' '
	ora #128
term_scroll_l2:
	sta 0,X
	leax 1,X
	cmpx #CHARS_BUFF_END
	bne term_scroll_l2
	; Move up colors buffer by one line
	ldx #COLORS_BUFF_START
term_scroll_l3:
	lda TERM_WIDTH,X
	sta 0,X
	leax 1,X
	cmpx #COLORS_BUFF_END-TERM_WIDTH
	bne term_scroll_l3
	; Last line to default color
	lda #TERM_DEFAULT_COLOR
term_scroll_l4:
	sta 0,X
	leax 1,X
	cmpx #COLORS_BUFF_END
	bne term_scroll_l4

	; Copy buffers into VRAM
	clra
	ldx #SCN_CURSOR_ADDR_LOW_RW
	jsr gpu_write_verify
	ldx #SCN_CURSOR_ADDR_HI_RW
	jsr gpu_write_verify
	ldx #CHARS_BUFF_START
	stx CTR0
	ldx #COLORS_BUFF_START
	stx PSHX0
term_scroll_l5:
	ldx CTR0
	lda 0,X
	leax 1,X
	stx CTR0
	sta VIDEO_BASE
	ldx PSHX0
	lda 0,X
	leax 1,X
	stx PSHX0
	sta VIDEO_BASE+8
	ldb #SCN_CMD_WRITE_CURSOR_INCR
	stb SCN_CMD_W
	jsr gpu_wait_ready
	cmpx #COLORS_BUFF_END
	bne term_scroll_l5

	lda CURSOR_X
	ldb CURSOR_Y
	decb
	jsr term_cursor_set
	puls a,b,x
	pshs a
	lda CURSOR_ON
	beq term_scroll_no_cursor
	lda #SCN_CMD_CURSOR_ON
	sta SCN_CMD_W
term_scroll_no_cursor:
	puls a
	rts

	; X loc in 'a', Y loc in 'b'
term_cursor_set:
	pshs b,x
	pshs a
	; Width is exactly 64, so X is a 6-bit value
	; Do some shifting to make the bytes go 00YYYYYY YYXXXXX
	clra
	sta CTR0
	stb CTR1
	clc
	lda CTR1
	rora
	sta CTR1
	lda CTR0
	rora
	sta CTR0
	lda CTR1
	rora
	sta CTR1
	lda CTR0
	rora
	sta CTR0
	puls a
	pshs a
	inca
	adda CTR0
	sta CTR0
	lda CTR1
	adca #0
	sta CTR1
	ldx #SCN_CURSOR_ADDR_LOW_RW
	lda CTR0
	sta DISP_PTR_LOC+1
	jsr gpu_write_verify
	ldx #SCN_CURSOR_ADDR_HI_RW
	lda CTR1
	sta DISP_PTR_LOC+0
	jsr gpu_write_verify
	puls a
	puls b,x
	sta CURSOR_X
	stb CURSOR_Y
	rts

	; Prints null-terminated string pointed at by X
putstr:
	pshs a
putstr_loop:
	lda 0,X
	beq putstr_end
	jsr putchar
	leax 1,X
	jmp putstr_loop
putstr_end:
	puls a
	rts

printhex:
	pshs a,b,x
	pshs a
	rora
	lsra
	rora
	rora
	anda #15
	adda #hexchars&255
	sta PRINTHEX_TEMP1
	lda #0
	adca #hexchars>>8
	sta PRINTHEX_TEMP0
	ldx PRINTHEX_TEMP0
	lda 0,X
	jsr putchar
	puls a
	anda #15
	adda #hexchars&255
	sta PRINTHEX_TEMP1
	lda #0
	adca #hexchars>>8
	sta PRINTHEX_TEMP0
	ldx PRINTHEX_TEMP0
	lda 0,X
	jsr putchar
	puls a,b,x
	rts

	; Prints data as hex, X points to MSB, A contains length
printhex_str:
	pshs b,x
	clrb
	stb PRINTHEX_TEMP0
	sta PRINTHEX_TEMP1
printhex_loop:
	lda 0,X
	leax 1,X
	pshs a
	lsra
	lsra
	lsra
	lsra
	cmpa #10
	bpl printhex_gt9_1
	adda #'0'
	jmp printhex_continue_1
printhex_gt9_1:
	adda #('A'-10)
printhex_continue_1:
	jsr putchar
	puls a
	anda #15
	cmpa #10
	bpl printhex_gt9_2
	adda #'0'
	jmp printhex_continue_2
printhex_gt9_2:
	adda #('A'-10)
printhex_continue_2:
	jsr putchar

	ldb PRINTHEX_TEMP0
	incb
	stb PRINTHEX_TEMP0
	cmpb PRINTHEX_TEMP1
	bne printhex_loop

	lda PRINTHEX_TEMP1
	puls b,x
	rts

	; Select spiflash and TX value in a
spi_tx:
	pshs a,b
	ldb KB_PORTA
	andb #%11110001
	stb KB_PORTA
	nop
	nop
	ldb #8
	stb PSHX0
spi_tx_loop:
	ldb KB_PORTA
	bita #128
	beq spi_tx_zero
	orb #2
spi_tx_zero:
	stb KB_PORTA
	orb #4
	stb KB_PORTA
	andb #%11111001
	stb KB_PORTA
	rola
	dec PSHX0
	bne spi_tx_loop
	andb #%11110001
	stb KB_PORTA
	puls a,b
	rts

	; Receive value from spiflash and return in a
spi_rx:
	pshs b
	ldb #8
	stb PSHX0
	clra
spi_rx_loop:
	clc
	rola
	ldb KB_PORTA
	orb #4
	stb KB_PORTA
	ldb KB_PORTC
	bitb #1
	beq spi_rx_zero
	ora #1
spi_rx_zero:
	ldb KB_PORTA
	andb #%11111011
	stb KB_PORTA
	dec PSHX0
	bne spi_rx_loop
	puls b
	rts

	; CS high to spiflash
rom_desel:
	pshs a
	lda KB_PORTA
	anda #%11111001
	ora #8
	sta KB_PORTA
	puls a
	rts

	; Advance the KB buffer read pointer (in X) by one
kbadvance macro
	leax 1,X
	cmpx #KB_BUFF_END
	bne *+5
	ldx #KB_BUFF_START
	stx KB_BUFF_RD_PTR
	endm

KEY_ESCAPE equ $01
KEY_UP equ $B5
KEY_DOWN equ $B2
KEY_LEFT equ $AB
KEY_RIGHT equ $B4
UNKNOW_KEY equ $FF
KEY_F1 equ $85
KEY_F2 equ $86
KEY_F3 equ $84
KEY_F4 equ $8C
KEY_F5 equ $83
KEY_F6 equ $8B
KEY_F7 equ $F3
KEY_F8 equ $8A
KEY_F9 equ $81
KEY_F10 equ $89
KEY_F11 equ $F8
KEY_F12 equ $87

	; Parse keyboard buffer entries. Updates LAST_PRESSED, LAST_RELEASED, SHIFT_DOWN, ALT_CTRL_DOWN
	; Loads A with non-zero value if values were updated
	; Loads A with zero if nothing was updated
kb_parse:
	pshs b,x
	clr LAST_PRESSED
	clr LAST_RELEASED
	lda ALT_CTRL_DOWN
	bita #128
	beq kb_parse_normal
	jmp kb_parse_extended
kb_parse_normal:
	; See if there is another byte in the buffer
	ldx KB_BUFF_RD_PTR
	cmpx KB_BUFF_WR_PTR
	bne kb_parse_buffer_not_end ; No? Return.
	jmp kb_parse_buffer_end
kb_parse_buffer_not_end:
	; Yes! Read the byte
	lda 0,X
	kbadvance
	; Inverse the order of the bits in the byte, because I messed up
	ldb #8
	stb PRINTHEX_TEMP0
	clrb
kb_inverse_loop_1:
	rola
	rorb
	dec PRINTHEX_TEMP0
	bne kb_inverse_loop_1
	tfr b,a
	
	cmpa #$E0 ; Is this an extended code?
	bne kb_not_extended
	jmp kb_parse_extended
kb_not_extended:
	cmpa #$F0
	bne kb_not_release
	; Its a key being released. Set release flag and try again
	ldb ALT_CTRL_DOWN
	orb #64
	stb ALT_CTRL_DOWN
	jmp kb_parse_normal
kb_not_release:
	cmpa #$14
	bne kb_not_ctrl
	jmp kb_ctrl_key
kb_not_ctrl:
	cmpa #$11
	bne kb_not_alt
	jmp kb_alt_key
kb_not_alt:
	cmpa #$12
	beq kb_yes_is_shift_indeed
	cmpa #$59
	beq kb_yes_is_shift_indeed
	bra kb_not_shift
kb_yes_is_shift_indeed:
	jmp kb_shift_key
kb_not_shift:
	cmpa #$76
	bne kb_not_esc
	ldb #KEY_ESCAPE
	jmp kb_write_exit
kb_not_esc:
	cmpa #$66
	bne kb_not_backspace
	ldb #127
	jmp kb_write_exit
kb_not_backspace:
	cmpa #$5E
	bmi kb_in_lut
	ldb #UNKNOW_KEY
	jmp kb_write_exit
kb_in_lut:
	ldb #keymap>>8
	stb PRINTHEX_TEMP0
	ldb #keymap&255
	stb PRINTHEX_TEMP1
	tst SHIFT_DOWN
	beq kb_not_shifted
	ldb #keymap_shifted>>8
	stb PRINTHEX_TEMP0
	ldb #keymap_shifted&255
	stb PRINTHEX_TEMP1
kb_not_shifted:
	adda PRINTHEX_TEMP1
	sta PRINTHEX_TEMP1
	lda #0
	adca PRINTHEX_TEMP0
	sta PRINTHEX_TEMP0
	ldx PRINTHEX_TEMP0
	ldb 0,X
	jmp kb_write_exit

kb_ctrl_key:
	lda ALT_CTRL_DOWN
	anda #253
	bita #64
	bne kb_ctrl_released
	ora #2
kb_ctrl_released:
	anda #%10111111
	sta ALT_CTRL_DOWN
	; Alt key handled
	puls b,x
	lda #1
	rts

kb_alt_key:
	lda ALT_CTRL_DOWN
	anda #254
	bita #64
	bne kb_alt_released
	ora #1
kb_alt_released:
	anda #%10111111
	sta ALT_CTRL_DOWN
	; Alt key handled
	puls b,x
	lda #1
	rts

kb_shift_key:
	clr SHIFT_DOWN
	lda ALT_CTRL_DOWN
	bita #64
	bne kb_shift_released
	lda #1
	sta SHIFT_DOWN
kb_shift_released:
	ldb ALT_CTRL_DOWN
	andb #%10111111
	stb ALT_CTRL_DOWN
	; Shift key handled
	puls b,x
	lda #1
	rts
	
	; Some key was either pressed or released, so update LAST_PRESSED or LAST_RELEASED and return
	; Key character/code in B
kb_write_exit:
	lda ALT_CTRL_DOWN
	bita #64
	bne kb_key_released
	stb LAST_PRESSED
	bra kb_key_pressed
kb_key_released:
	stb LAST_RELEASED
kb_key_pressed:
	anda #%10111111
	sta ALT_CTRL_DOWN
	puls b,x
	lda #1
	rts
kb_parse_extended:
	; Set extended flag
	lda ALT_CTRL_DOWN
	ora #128
	sta ALT_CTRL_DOWN
	; See if there is another byte in the buffer
	ldx KB_BUFF_RD_PTR
	cmpx KB_BUFF_WR_PTR
	beq kb_parse_buffer_end ; No? Leave extended flag set and return
	; Yes! Clear extended flag again and read the byte
	anda #127
	sta ALT_CTRL_DOWN
	tfr a,b
	lda 0,X
	kbadvance
	; Inverse the order of the bits in the byte, because I messed up
	ldb #8
	stb PRINTHEX_TEMP0
	clrb
kb_inverse_loop_2:
	rola
	rorb
	dec PRINTHEX_TEMP0
	bne kb_inverse_loop_2
	tfr b,a
	
	cmpa #$F0 ; Its an extended key being released
	bne kb_ext_no_release
	; Set release flag and try again
	orb #64
	stb ALT_CTRL_DOWN
	jmp kb_parse_extended
kb_ext_no_release:
	cmpa #$4A ; That one key on the numpad that is an extended code for some reason
	bne kb_ext_not_numpad
	ldb #'/'
	jmp kb_write_exit
kb_ext_not_numpad:
	; Is this a direction key?
	; Individual cmps because the codes are all over the place
	cmpa #$72
	beq kb_ext_direction_key
	cmpa #$6B
	beq kb_ext_direction_key
	cmpa #$75
	beq kb_ext_direction_key
	cmpa #$74
	beq kb_ext_direction_key
	bra kb_ext_not_direction_key
kb_ext_direction_key:
	; It is. Add $40 to get the internal code for it.
	adda #$40
	tfr a,b
	jmp kb_write_exit
kb_ext_not_direction_key:
	cmpa #$14
	bne kb_ext_not_ctrl
	; Its the right control key
	jmp kb_ctrl_key
kb_ext_not_ctrl:
	cmpa #$11
	bne kb_ext_not_altgr
	; Its AltGr, which will just be treated like regular Alt for now
	jmp kb_alt_key
kb_ext_not_altgr:
	cmpa #$5A ; Its numpad enter, which we're just gonna treat like normal enter
	bne kb_ext_not_enter
	ldb #'\r'
	jmp kb_write_exit
kb_ext_not_enter:
	; I don’t know what this is
	ldb #UNKNOW_KEY
	jmp kb_write_exit
	
	; Hit the end of the buffer early (i.e. key-release code but no next elem in buffer)
kb_parse_buffer_end:
	puls b,x
	clra
	rts

; Arith routines
mul_16x16_unsigned:
	pshs a,b
	clr PRINTHEX_TEMP0
	bra mul_16x16_begin

mul_16x16_signed:
	pshs a,b
	clr PRINTHEX_TEMP0
	tst 0,X
	bpl mul_16x16_not_neg_1
	neg 1,X
	lda #0
	sbca 0,X
	sta 0,X
	inc PRINTHEX_TEMP0
mul_16x16_not_neg_1:
	tst 2,X
	bpl mul_16x16_not_neg_2
	neg 3,X
	lda #0
	sbca 2,X
	sta 2,X
	lda #1
	eora PRINTHEX_TEMP0
	sta PRINTHEX_TEMP0
mul_16x16_not_neg_2:
	
mul_16x16_begin:
	lda #(ARITH_CLOCKDIV | ARITH_RST_SEQ | ARITH_RST_Z | ARITH_RST_Y)
	sta ARITH_CTRL
	lda 0,X
	sta ARITH_X
	leax 1,X
	lda 0,X
	sta ARITH_X
	leax 1,X
	lda 0,X
	sta ARITH_Z
	leax 1,X
	lda 0,X
	leax 1,X
	sta ARITH_Z
	lda #(ARITH_CLOCKDIV | ARITH_OP_MUL | ARITH_RST_SEQ)
	sta ARITH_CTRL
	lda #5
arith_delay0:
	deca
	bne arith_delay0
	lda ARITH_Y
	sta 0,X
	lda ARITH_Y
	sta 1,X
	lda ARITH_Z
	sta 2,X
	lda ARITH_Z
	sta 3,X
	
	tst PRINTHEX_TEMP0
	beq mul_16x16_not_neg_res
	neg 3,X
	lda #0
	sbca 2,X
	sta 2,X
	lda #0
	sbca 1,X
	sta 1,X
	ldb #0
	sbcb 0,X
	sta 0,X
mul_16x16_not_neg_res:
	puls a,b
	rts

mul_32x32_signed:
	pshs a,b
	clr PSHX2
	tst 0,X
	bpl mul_32x32_not_neg_a
	neg 3,X
	lda #0
	sbca 2,X
	sta 2,X
	lda #0
	sbca 1,X
	sta 1,X
	lda #0
	sbca 0,X
	sta 0,X
	inc PSHX2
mul_32x32_not_neg_a:
	tst 4,X
	bpl mul_32x32_not_neg_b
	neg 7,X
	ldb #0
	sbcb 6,X
	stb 6,X
	ldb #0
	sbcb 5,X
	stb 5,X
	ldb #0
	sbcb 4,X
	stb 4,X
	lda #1
	eora PSHX2
	sta PSHX2
mul_32x32_not_neg_b:
	bra mul_32x32_begin
mul_32x32_unsigned:
	pshs a,b
	clr PSHX2
	
mul_32x32_begin:
	; First multiplication
	lda #(ARITH_CLOCKDIV | ARITH_RST_SEQ | ARITH_RST_Z | ARITH_RST_Y)
	sta ARITH_CTRL
	lda 2,X
	sta ARITH_X
	lda 3,X
	sta ARITH_X
	lda 6,X
	sta ARITH_Z
	lda 7,X
	sta ARITH_Z
	lda #(ARITH_CLOCKDIV | ARITH_OP_MUL | ARITH_RST_SEQ)
	sta ARITH_CTRL
	lda #5
arith_delay5:
	deca
	bne arith_delay5
	lda ARITH_Y
	sta 12,X
	lda ARITH_Y
	sta 13,X
	lda ARITH_Z
	sta 14,X
	lda ARITH_Z
	sta 15,X
	
	; Second multiplication
	lda #(ARITH_CLOCKDIV | ARITH_RST_SEQ | ARITH_RST_Z | ARITH_RST_Y)
	sta ARITH_CTRL
	lda 0,X
	sta ARITH_X
	lda 1,X
	sta ARITH_X
	lda 6,X
	sta ARITH_Z
	lda 7,X
	sta ARITH_Z
	lda #(ARITH_CLOCKDIV | ARITH_OP_MUL | ARITH_RST_SEQ)
	sta ARITH_CTRL
	lda #5
arith_delay6:
	deca
	bne arith_delay6
	clr PSHX0
	lda ARITH_Y
	sta MDIV_T0
	lda ARITH_Y
	sta MDIV_T1
	lda ARITH_Z
	sta MDIV_T2
	lda ARITH_Z
	adda 13,X
	sta 13,X
	lda MDIV_T2
	adca 12,X
	sta 12,X
	lda #0
	adca MDIV_T1
	sta 11,X
	lda #0
	adca MDIV_T0
	sta 10,X
	lda #0
	adca PSHX0
	sta 9,X
	
	; Third multiplication
	lda #(ARITH_CLOCKDIV | ARITH_RST_SEQ | ARITH_RST_Z | ARITH_RST_Y)
	sta ARITH_CTRL
	lda 2,X
	sta ARITH_X
	lda 3,X
	sta ARITH_X
	lda 4,X
	sta ARITH_Z
	lda 5,X
	sta ARITH_Z
	lda #(ARITH_CLOCKDIV | ARITH_OP_MUL | ARITH_RST_SEQ)
	sta ARITH_CTRL
	lda #5
arith_delay7:
	deca
	bne arith_delay7
	lda ARITH_Y
	sta MDIV_T0
	lda ARITH_Y
	sta MDIV_T1
	lda ARITH_Z
	sta MDIV_T2
	lda ARITH_Z
	adda 13,X
	sta 13,X
	lda MDIV_T2
	adca 12,X
	sta 12,X
	lda 11,X
	adca MDIV_T1
	sta 11,X
	lda 10,X
	adca MDIV_T0
	sta 10,X
	lda 9,X
	adca PSHX0
	sta 9,X
	
	; Fourth multiplication
	lda #(ARITH_CLOCKDIV | ARITH_RST_SEQ | ARITH_RST_Z | ARITH_RST_Y)
	sta ARITH_CTRL
	lda 0,X
	sta ARITH_X
	lda 1,X
	sta ARITH_X
	lda 4,X
	sta ARITH_Z
	lda 5,X
	sta ARITH_Z
	lda #(ARITH_CLOCKDIV | ARITH_OP_MUL | ARITH_RST_SEQ)
	sta ARITH_CTRL
	lda #5
arith_delay8:
	deca
	bne arith_delay8
	lda ARITH_Y
	sta MDIV_T0
	lda ARITH_Y
	sta MDIV_T1
	lda ARITH_Z
	sta MDIV_T2
	lda ARITH_Z
	adda 11,X
	sta 11,X
	lda MDIV_T2
	adca 10,X
	sta 10,X
	lda MDIV_T1
	adca 9,X
	sta 9,X
	lda #0
	adca MDIV_T0
	sta 8,X
	
	leax 8,X
	tst PSHX2
	beq mul_32x32_not_neg_res
	clrb
	neg 7,X
	lda #0
	sbca 6,X
	sta 6,X
	lda #0
	sbca 5,X
	sta 5,X
	sbcb 4,X
	stb 4,X
	ldb #0
	sbcb 3,X
	stb 3,X
	ldb #0
	sbcb 2,X
	stb 2,X
	ldb #0
	sbcb 1,X
	stb 1,X
	lda #0
	sbca 0,X
	sta 0,X
mul_32x32_not_neg_res:
	puls a,b
	rts

mul_fixed:
	jsr mul_32x32_signed
	leax 2,X
	rts

moddiv_16x16_unsigned:
	pshs a,b
	
	lda #(ARITH_CLOCKDIV | ARITH_RST_SEQ | ARITH_RST_Z | ARITH_RST_Y)
	sta ARITH_CTRL
	clrb
	stb ARITH_Y
	stb ARITH_Y
	lda 0,X
	sta ARITH_Z
	lda 1,X
	sta ARITH_Z
	ldb 2,X
	stb ARITH_X
	lda 3,X
	leax 4,X
	sta ARITH_X
	lda #(ARITH_CLOCKDIV | ARITH_OP_DIV | ARITH_RST_SEQ)
	sta ARITH_CTRL
	lda #5
arith_delay1:
	deca
	bne arith_delay1
	lda ARITH_Z
	sta 0,X
	lda ARITH_Z
	sta 1,X
	lda ARITH_Y
	sta 2,X
	lda ARITH_Y
	sta 3,X
	
	puls a,b
	rts

moddiv_32x16_unsigned:
	pshs a
	
	lda #(ARITH_CLOCKDIV | ARITH_RST_SEQ | ARITH_RST_Z | ARITH_RST_Y)
	sta ARITH_CTRL
	clra
	sta ARITH_Y
	sta ARITH_Y
	lda 0,X
	sta ARITH_Z
	lda 1,X
	sta ARITH_Z
	lda 4,X
	sta ARITH_X
	lda 5,X
	sta ARITH_X
	lda #(ARITH_CLOCKDIV | ARITH_OP_DIV | ARITH_RST_SEQ)
	sta ARITH_CTRL
	lda #5
arith_delay2:
	deca
	bne arith_delay2
	lda ARITH_Z
	sta 6,X
	lda ARITH_Z
	sta 7,X
	lda #(ARITH_CLOCKDIV | ARITH_RST_SEQ | ARITH_RST_Z)
	sta ARITH_CTRL
	lda 2,X
	sta ARITH_Z
	lda 3,X
	sta ARITH_Z
	lda #(ARITH_CLOCKDIV | ARITH_OP_DIV | ARITH_RST_SEQ)
	sta ARITH_CTRL
	leax 5,X 
	lda #3
arith_delay3:
	deca
	bne arith_delay3
	leax 1,X
	lda ARITH_Z
	sta 2,X
	lda ARITH_Z
	sta 3,X
	lda ARITH_Y
	sta 4,X
	lda ARITH_Y
	sta 5,X
	
	puls a
	rts

moddiv_32x32_signed:
	pshs a,b
	lda #32
	sta TEMP
moddiv_32x32_signed_skip:
	clr MDIV_T0
	clr MDIV_T1
	tst 0,X
	bpl moddiv_32x32_not_neg_a
	neg 3,X
	lda #0
	sbca 2,X
	sta 2,X
	lda #0
	sbca 1,X
	sta 1,X
	lda #0
	sbca 0,X
	sta 0,X
	inc MDIV_T0
	inc MDIV_T1
moddiv_32x32_not_neg_a:
	tst 4,X
	bpl moddiv_32x32_not_neg_b
	neg 7,X
	lda #0
	sbca 6,X
	sta 6,X
	lda #0
	sbca 5,X
	sta 5,X
	lda #0
	sbca 4,X
	sta 4,X
	lda #1
	eora MDIV_T1
	sta MDIV_T1
moddiv_32x32_not_neg_b:
	bra moddiv_32x32_begin
moddiv_32x32_unsigned:
	pshs a,b
	lda #32
	sta TEMP
	clr MDIV_T0
	clr MDIV_T1
moddiv_32x32_begin:
	clr 8,X
	clr 9,X
	clr 10,X
	clr 11,X
	clr 12,X
	clr 13,X
	clr 14,X
	clr 15,X
	lda TEMP
	sta PSHX2
moddiv_32x32_loop:
	clc
	rol 11,X
	rol 10,X
	rol 9,X
	rol 8,X
	clc
	rol 3,X
	rol 2,X
	rol 1,X
	rol 0,X
	rol 15,X
	rol 14,X
	rol 13,X
	rol 12,X
	lda 15,X
	suba 7,X
	pshs a
	lda 14,X
	sbca 6,X
	pshs a
	lda 13,X
	sbca 5,X
	pshs a
	lda 12,X
	sbca 4,X
	bmi moddiv_32x32_is_neg
	sta 12,X
	puls a
	sta 13,X
	puls a
	sta 14,X
	puls a
	sta 15,X
	inc 11,X
	bra moddiv_32x32_continue
moddiv_32x32_is_neg:
	leas 3,S
moddiv_32x32_continue:
	dec PSHX2
	bne moddiv_32x32_loop
	leax 8,X
	tst MDIV_T1
	beq moddiv_32x32_not_neg_res
	neg 3,X
	lda #0
	sbca 2,X
	sta 2,X
	lda #0
	sbca 1,X
	sta 1,X
	lda #0
	sbca 0,X
	sta 0,X
moddiv_32x32_not_neg_res:
	tst MDIV_T0
	beq moddiv_32x32_not_neg_mod
	neg 7,X
	lda #0
	sbca 6,X
	sta 6,X
	lda #0
	sbca 5,X
	sta 5,X
	lda #0
	sbca 4,X
	sta 4,X
moddiv_32x32_not_neg_mod:
	puls a,b
	rts

div_fixed:
	pshs a,b
	lda #48
	sta TEMP
	jmp moddiv_32x32_signed_skip

	; X stores location of output buffer AND number to be converted
	; First two bytes of buffer are pre-loaded with the number
	; Output string will be null-terminated
itoa16:
	clr TEMP
itoa16_int:
	pshs a,b,x
	ldb 0,X
	stb TEMP_BUFF
	lda 1,X
	sta TEMP_BUFF+1
	bitb #128
	beq itoa16_not_neg
itoa16_neg:
	nega
	sta TEMP_BUFF+1
	lda #0
	sbca TEMP_BUFF
	sta TEMP_BUFF
itoa16_insert_minus:
	lda #'-'
	sta 0,X
	leax 1,X
	clr TEMP
itoa16_not_neg:
	tst TEMP
	bne itoa16_insert_minus
	clr PRINTHEX_TEMP1
	ldb #5
	stb PRINTHEX_TEMP0
itoa16_loop:
	stx PSHX0
	lda PRINTHEX_TEMP0
	deca
	clc
	rola
	adda #itoa16_divs&255
	sta CTR1
	lda #0
	adca #itoa16_divs>>8
	sta CTR0
	ldx CTR0
	ldb 0,X
	stb TEMP_BUFF+2
	ldb 1,X
	stb TEMP_BUFF+3
	ldx #TEMP_BUFF
	jsr moddiv_16x16_unsigned
	lda 2,X
	sta TEMP_BUFF
	lda 3,X
	sta TEMP_BUFF+1
	lda 1,X
	ldx PSHX0
	tsta
	bne itoa16_put_char
	tst PRINTHEX_TEMP1
	bne itoa16_put_char
	ldb PRINTHEX_TEMP0
	cmpb #1
	bne itoa16_skip_char
itoa16_put_char:
	inc PRINTHEX_TEMP1
	adda #'0'
	sta 0,X
	leax 1,X
itoa16_skip_char:
	dec PRINTHEX_TEMP0
	bne itoa16_loop
	clr 0,X
	puls a,b,x
	rts

	; X stores location of output buffer AND number to be converted
	; First four bytes of buffer are pre-loaded with the number
	; Output string will be null-terminated
itoa32:
	pshs a,b,x
	ldb 0,X
	stb TEMP_BUFF
	lda 1,X
	sta TEMP_BUFF+1
	lda 2,X
	sta TEMP_BUFF+2
	lda 3,X
	sta TEMP_BUFF+3
	bitb #128
	beq itoa32_not_neg
itoa32_neg:
	nega
	sta TEMP_BUFF+3
	lda #0
	sbca TEMP_BUFF+2
	sta TEMP_BUFF+2
	lda #0
	sbca TEMP_BUFF+1
	sta TEMP_BUFF+1
	lda #0
	sbca TEMP_BUFF
	sta TEMP_BUFF
	lda #'-'
	sta 0,X
	leax 1,X
itoa32_not_neg:
	clr PRINTHEX_TEMP1
	ldb #10
	stb PRINTHEX_TEMP0
itoa32_loop:
	stx PSHX0
	lda PRINTHEX_TEMP0
	deca
	clc
	rola
	clc
	rola
	adda #itoa32_divs&255
	sta CTR1
	lda #0
	adca #itoa32_divs>>8
	sta CTR0
	ldx CTR0
	ldb 0,X
	stb TEMP_BUFF+4
	ldb 1,X
	stb TEMP_BUFF+5
	ldb 2,X
	stb TEMP_BUFF+6
	ldb 3,X
	stb TEMP_BUFF+7
	ldx #TEMP_BUFF
	jsr moddiv_32x32_unsigned
	lda 4,X
	sta TEMP_BUFF
	lda 5,X
	sta TEMP_BUFF+1
	lda 6,X
	sta TEMP_BUFF+2
	lda 7,X
	sta TEMP_BUFF+3
	lda 3,X
	ldx PSHX0
	tsta
	bne itoa32_put_char
	tst PRINTHEX_TEMP1
	bne itoa32_put_char
	ldb PRINTHEX_TEMP0
	cmpb #1
	bne itoa32_skip_char
itoa32_put_char:
	inc PRINTHEX_TEMP1
	adda #'0'
	sta 0,X
	leax 1,X
itoa32_skip_char:
	dec PRINTHEX_TEMP0
	bne itoa32_loop
	puls a,b,x
	rts

fitoa:
	pshs a,b,x
	ldb 0,X
	andb #128
	stb TEMP
	tstb
	bpl fitoa_not_neg
	neg 3,X
	lda #0
	sbca 2,X
	sta 2,X
	lda #0
	sbca 1,X
	sta 1,X
	lda #0
	sbca 0,X
	sta 0,X
fitoa_not_neg:
	lda 0,X
	ldb 1,X
	leax 4,X
	sta 0,X
	stb 1,X
	jsr itoa16_int
	leax -2,X
	lda 0,X
	pshs a
	lda 1,X
	pshs a
	leax 2,X
fitoa_seek_to_end:
	tst 0,X
	beq fitoa_seek_to_end_end
	leax 1,X
	bra fitoa_seek_to_end
fitoa_seek_to_end_end:
	lda #'.'
	sta 0,X
	leax 1,X
	
	clr TEMP_BUFF+4
	clr TEMP_BUFF+7
	clr TEMP_BUFF+6
	lda #10
	sta TEMP_BUFF+5
	clr TEMP_BUFF
	clr TEMP_BUFF+1
	puls a
	sta TEMP_BUFF+3
	puls b
	stb TEMP_BUFF+2
	lda #5
	sta PRINTHEX_TEMP0
fitoa_loop:
	pshs x
	ldx #TEMP_BUFF
	jsr mul_fixed
	lda 1,X
	adda #'0'
	ldb 2,X
	stb TEMP_BUFF+2
	ldb 3,X
	stb TEMP_BUFF+3
	puls x
	sta 0,X
	leax 1,X
	dec PRINTHEX_TEMP0
	bne fitoa_loop
	clr 0,X
	leax 1,X
	puls a,b,x
	leax 4,X
	rts

xorshift:
	pshs a,b
	
	lda XORSHIFT0
	sta PRINTHEX_TEMP0
	lda XORSHIFT1
	sta PRINTHEX_TEMP1
	lda XORSHIFT2
	sta TEMP
	ldb #5
xorshift_loop_1:
	clc
	rol PRINTHEX_TEMP0
	rol PRINTHEX_TEMP1
	rol TEMP
	decb
	bne xorshift_loop_1
	lda PRINTHEX_TEMP0
	eora XORSHIFT1
	sta XORSHIFT1
	lda PRINTHEX_TEMP1
	eora XORSHIFT2
	sta XORSHIFT2
	lda TEMP
	eora XORSHIFT3
	sta XORSHIFT3
	
	lda XORSHIFT3
	ldb XORSHIFT2
	clc
	rora
	rorb
	eora XORSHIFT1
	sta XORSHIFT1
	eorb XORSHIFT0
	stb XORSHIFT0
	
	lda XORSHIFT0
	sta PRINTHEX_TEMP0
	lda XORSHIFT1
	sta PRINTHEX_TEMP1
	lda XORSHIFT2
	sta TEMP
	lda XORSHIFT3
	sta CTR0
	ldb #5
xorshift_loop_2:
	clc
	rol PRINTHEX_TEMP0
	rol PRINTHEX_TEMP1
	rol TEMP
	rol CTR0
	decb
	bne xorshift_loop_2
	
	lda PRINTHEX_TEMP0
	eora XORSHIFT0
	sta XORSHIFT0
	lda XORSHIFT1
	eora PRINTHEX_TEMP1
	sta XORSHIFT1
	lda TEMP
	eora XORSHIFT2
	sta XORSHIFT2
	lda CTR0
	eora XORSHIFT3
	sta XORSHIFT3
	
	puls a,b
	rts

	; LUTS here
luts_start:
	db "Here be LUTs"
	db 0
itoa32_divs:
	db $00,$00,$00,$01
	db $00,$00,$00,$0A
	db $00,$00,$00,$64
	db $00,$00,$03,$E8
	db $00,$00,$27,$10
	db $00,$01,$86,$A0
	db $00,$0F,$42,$40
	db $00,$98,$96,$80
	db $05,$F5,$E1,$00
	db $3B,$9A,$CA,$00
hexchars:
	db "0123456789ABCDEF"
itoa16_divs:
	dw 1
	dw 10
	dw 100
	dw 1000
	dw 10000
	; For a german QWERTZ keyboard
	; Tries to map to ASCII values but will return codes outside the ASCII range for non-printable keys (e.g. Escape)
	; Created with the help of https://kbdlayout.info/kbdusx/scancodes+text?arrangement=ISO105
keymap:
	db UNKNOW_KEY
	db KEY_F9
	db UNKNOW_KEY
	db KEY_F5
	db KEY_F3
	db KEY_F1
	db KEY_F2
	db KEY_F12
	db UNKNOW_KEY
	db KEY_F10
	db KEY_F8
	db KEY_F6
	db KEY_F4
	db '\t'
	db '^'
	db UNKNOW_KEY
	db UNKNOW_KEY
	db UNKNOW_KEY
	db UNKNOW_KEY
	db UNKNOW_KEY
	db UNKNOW_KEY
	db "q1"
	db UNKNOW_KEY
	db UNKNOW_KEY
	db UNKNOW_KEY
	db "ysaw2"
	db UNKNOW_KEY
	db UNKNOW_KEY
	db "cxde43"
	db UNKNOW_KEY
	db UNKNOW_KEY
	db " vftr5"
	db UNKNOW_KEY
	db UNKNOW_KEY
	db "nbhgz6"
	db UNKNOW_KEY
	db UNKNOW_KEY
	db UNKNOW_KEY
	db "mju78"
	db UNKNOW_KEY
	db UNKNOW_KEY
	db ",kio09"
	db UNKNOW_KEY
	db UNKNOW_KEY
	db ".-lops"
	db UNKNOW_KEY
	db UNKNOW_KEY
	db UNKNOW_KEY
	db 'a'
	db UNKNOW_KEY
	db "u'"
	db UNKNOW_KEY
	db UNKNOW_KEY
	db UNKNOW_KEY
	db UNKNOW_KEY
	db '\r'
	db '+'
	db UNKNOW_KEY
	db '#'
	; End, Length: $5E

keymap_shifted:
	db UNKNOW_KEY
	db KEY_F9
	db UNKNOW_KEY
	db KEY_F5
	db KEY_F3
	db KEY_F1
	db KEY_F2
	db KEY_F12
	db UNKNOW_KEY
	db KEY_F10
	db KEY_F8
	db KEY_F6
	db KEY_F4
	db '\t'
	db '^'
	db UNKNOW_KEY
	db UNKNOW_KEY
	db UNKNOW_KEY
	db UNKNOW_KEY
	db UNKNOW_KEY
	db UNKNOW_KEY
	db "Q!"
	db UNKNOW_KEY
	db UNKNOW_KEY
	db UNKNOW_KEY
	db "YSAW\""
	db UNKNOW_KEY
	db UNKNOW_KEY
	db "CXDE$@"
	db UNKNOW_KEY
	db UNKNOW_KEY
	db " VFTR%"
	db UNKNOW_KEY
	db UNKNOW_KEY
	db "NBHGZ&"
	db UNKNOW_KEY
	db UNKNOW_KEY
	db UNKNOW_KEY
	db "MJU/("
	db UNKNOW_KEY
	db UNKNOW_KEY
	db ";KIO=)"
	db UNKNOW_KEY
	db UNKNOW_KEY
	db ":_LOPS"
	db UNKNOW_KEY
	db UNKNOW_KEY
	db UNKNOW_KEY
	db 'A'
	db UNKNOW_KEY
	db "U`"
	db UNKNOW_KEY
	db UNKNOW_KEY
	db UNKNOW_KEY
	db UNKNOW_KEY
	db '\r'
	db '*'
	db UNKNOW_KEY
	db '\''
	; End, Length: $5E

	; VECTORS HERE
	org $FFF2
	db 0
	db 0
	db 0
	db 0
	db fint>>8
	db fint&255
	db int>>8
	db int&255
	db 0
	db 0
	db nmi>>8
	db nmi&255
	db begin>>8
	db begin&255
