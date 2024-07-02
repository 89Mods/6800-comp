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

pshx macro
	sta PSHX2
	stx PSHX0
	lda PSHX0
	psh a
	lda PSHX1
	psh a
	lda PSHX2
	endm

popx macro
	sta PSHX2
	pul a
	sta PSHX1
	pul a
	sta PSHX0
	ldx PSHX0
	lda PSHX2
	endm

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
	psh a
	lda KB_PORTA
	and a,#254
	sta KB_PORTA
	ora a,#1
	nop
	sta KB_PORTA
	pul a
	and b,#$0C
	cmp b,#4
	beq kb_valid_data
	jmp kb_invalid_data
kb_valid_data:
	ldx KB_BUFF_WR_PTR
	inx
	cpx KB_BUFF_RD_PTR
	beq kb_buffer_overflow
	dex
	sta 0,X
	inx
	cpx #KB_BUFF_END
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
	and a,#254
	sta KB_PORTA
	ora a,#1
	nop
	sta KB_PORTA
kb_buffer_overflow:
	rti
sint:
	nop
	nop
	rti
begin:
	sei
	sei
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
	
	clr a
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
	cli
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
	bit a,#1
	beq ps2_tx_loop_zero
	jsr ps2_tx_one
	bra ps2_tx_loop_one
ps2_tx_loop_zero:
	jsr ps2_tx_zero
ps2_tx_loop_one:
	ror a
	dec PRINTHEX_TEMP1
	bne ps2_tx_loop
	jsr ps2_tx_one
	jsr ps2_tx_one
	lda KB_PORTA
	ora a,#96
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
	clr a
	jsr spi_tx
	jsr spi_tx
	jsr spi_tx
	jsr rom_desel
	lda #$90
	jsr spi_tx
	clr a
	jsr spi_tx
	jsr spi_tx
	jsr spi_tx
	; Manufacturer ID (should be $EF)
	jsr spi_rx
	tab
	; Device ID (should be $15)
	jsr spi_rx
	psh a
	psh b
	jsr rom_desel
	tsx
	lda #2
	jsr printhex_str
	lda #'\r'
	jsr putchar
	lda #'\n'
	jsr putchar
	jsr advance_cursor
	pul a
	cmp a,#$EF
	beq dev_id_correct
	jmp flash_init_fail
dev_id_correct:
	pul b
	cmp b,#$15
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
	clr a
	jsr spi_tx
	jsr spi_tx
	jsr spi_tx
	ldx #header_text
	jmp check_header
header_text:
	db "CHIRP!"
	db 0
check_header:
	jsr spi_rx
	cmp a,0,X
	bne check_header_fail
	inx
	cmp a,#0
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
	cmp a,#64
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
	and a,#254
	sta KB_PORTA
	ora a,#1
	nop
	sta KB_PORTA
	lda #'\n'
	jsr putchar
	jsr advance_cursor
	;jsr loooong_delay
	lda PRINTHEX_TEMP0
	add a,#$02
	sta PRINTHEX_TEMP0
	ldx #$0200
copy_loop:
	jsr spi_rx
	sta 0,X
	inx
	cpx PRINTHEX_TEMP0
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
	wai
	jmp loop

ps2_tx_one:
	lda KB_PORTA
	and a,#%10011111
	ora a,#32
	sta KB_PORTA
	jsr ps2_wait
	ora a,#64
	sta KB_PORTA
	jsr ps2_wait
	rts

ps2_tx_zero:
	lda KB_PORTA
	and a,#%10011111
	sta KB_PORTA
	jsr ps2_wait
	ora a,#64
	sta KB_PORTA
	jsr ps2_wait
	rts

loooong_delay:
	psh a
	psh b
	lda #255
delay_outer:
	ldb #255
delay_inner:
	nop
	nop
	nop
	dec b
	bne delay_inner
	dec a
	bne delay_outer
	pul b
	pul a
	rts

arith_init:
	lda #%00101100
	sta ARITH_CTRL
	lda #(ARITH_CLOCKDIV | ARITH_RST_SEQ | ARITH_RST_Z | ARITH_RST_Y | ARITH_OP_NOP)
	sta ARITH_CTRL
	rts

gpu_init:
	; Write two 0s = master reset
	clr a
	sta SCN_CMD_W
	jsr uart_wait
	clr a
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
	psh a
	lda #111
uart_wait_loop:
	dec a
	bne uart_wait_loop
	pul a
	rts

ps2_wait:
	psh a
	lda #20
ps2_wait_loop:
	dec a
	bne ps2_wait_loop
	pul a
	rts

gpu_wait_vblank:
	psh a
gpu_wait_vblank_l:
	lda SCN_STATUS_R
	and a, #16
	beq gpu_wait_vblank_l
	pul a
	rts

gpu_wait_ready:
	psh a
gpu_wait_ready_l:
	lda SCN_STATUS_R
	and a,#34
	cmp a,#34
	bne gpu_wait_ready_l
	pul a
	rts
	
gpu_write_verify:
	psh b
gpu_write_verify_l:
	cmp a,0,X
	beq gpu_write_verify_success
	sta 0,X
	bra gpu_write_verify_l
gpu_write_verify_success:
	pul b
	rts

term_reset_cursor:
	psh a
	clr CURSOR_X
	clr CURSOR_Y
	clr DISP_PTR_LOC+0
	clr DISP_PTR_LOC+1
	ldx #SCN_CURSOR_ADDR_LOW_RW
	clr a
	jsr gpu_write_verify
	ldx #SCN_CURSOR_ADDR_HI_RW
	jsr gpu_write_verify
	pul a
	rts

gpu_clear_all:
	psh a
	psh b
	
	jsr term_reset_cursor
	
	lda #0
	sta CTR0
	sta CTR1
gpu_clear_all_loop:
	lda #' '
	add a, #128
	sta VIDEO_BASE
	lda #TERM_DEFAULT_COLOR
	sta VIDEO_BASE+8
	lda #SCN_CMD_WRITE_CURSOR_INCR
	sta SCN_CMD_W
	jsr gpu_wait_ready
	lda #SCN_CMD_GFX_OFF
	sta SCN_CMD_W
	
	lda CTR0
	add a, #1
	sta CTR0
	lda CTR1
	adc a, #0
	sta CTR1
	cmp a, #$40
	bne gpu_clear_all_loop
	
	ldx #CHARS_BUFF_START
	lda #' '
	add a, #128
gpu_clear_buffer_1:
	sta 0,X
	inx
	cpx #CHARS_BUFF_END
	bne gpu_clear_buffer_1
	ldx #COLORS_BUFF_START
	lda #TERM_DEFAULT_COLOR
gpu_clear_buffer_2:
	sta 0,X
	inx
	cpx #COLORS_BUFF_END
	bne gpu_clear_buffer_2
	
	lda #TERM_DEFAULT_COLOR
	sta CURR_COLOR
	clr b
	tba
	jsr term_cursor_set
	pul b
	pul a
	rts

term_clear:
	jsr term_reset_cursor
	psh a
	psh b
	lda #SCN_CMD_CURSOR_OFF
	sta SCN_CMD_W

	ldx #CHARS_BUFF_START
term_clear_loop:
	lda #' '
	add a, #128
	sta 0,X
	sta VIDEO_BASE
	lda #TERM_DEFAULT_COLOR
	sta VIDEO_BASE+8
	lda #SCN_CMD_WRITE_CURSOR_INCR
	sta SCN_CMD_W
	jsr gpu_wait_ready

	inx
	cpx #CHARS_BUFF_END
	bne term_clear_loop

	lda #TERM_DEFAULT_COLOR
	ldx #COLORS_BUFF_START
term_clear_loop2:
	sta 0,X
	inx
	cpx #COLORS_BUFF_END
	bne term_clear_loop2

	lda CURSOR_ON
	beq term_clear_no_cursor
	lda #SCN_CMD_CURSOR_ON
	sta SCN_CMD_W
term_clear_no_cursor:
	lda #TERM_DEFAULT_COLOR
	sta CURR_COLOR
	clr b
	tba
	jsr term_cursor_set
	pul b
	pul a
	rts

term_blink_off:
	psh a
	lda #SCN_CMD_CURSOR_OFF
	sta SCN_CMD_W
	clr CURSOR_ON
	pul a
	rts

term_blink_on:
	psh a
	lda #SCN_CMD_CURSOR_ON
	sta SCN_CMD_W
	lda #33
	sta CURSOR_ON
	pul a
	rts

return_cursor:
	psh b
	psh a
	dec CURSOR_X
	lda #255
	cmp a,CURSOR_X
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
	dex
	stx DISP_PTR_LOC
	lda DISP_PTR_LOC+1
	ldx #SCN_CURSOR_ADDR_LOW_RW
	jsr gpu_write_verify
	ldx #SCN_CURSOR_ADDR_HI_RW
	lda DISP_PTR_LOC+0
	jsr gpu_write_verify
	ldx PSHX0
return_end:
	pul a
	pul b
	rts
return_impossible:
	lda #1
	clr b
	jsr term_cursor_set
	bra return_end

advance_cursor:
	psh b
	psh a
advance_cursor_a:
	inc CURSOR_X
	ldb CURSOR_X
	cmp b, #TERM_WIDTH-4
	bmi advance_cursor_done
	clr b
	stb CURSOR_X
	jmp putchar_is_nl
advance_cursor_done:
	stx PSHX0
	ldx DISP_PTR_LOC
	inx
	stx DISP_PTR_LOC
	lda DISP_PTR_LOC+1
	ldx #SCN_CURSOR_ADDR_LOW_RW
	jsr gpu_write_verify
	ldx #SCN_CURSOR_ADDR_HI_RW
	lda DISP_PTR_LOC+0
	jsr gpu_write_verify
	ldx PSHX0
	pul a
	pul b
	rts
	
newl:
	psh a
	lda #'\r'
	bsr putchar
	lda #'\n'
	bsr putchar
	pul a
	rts
	
	; Puts character in 'a'
putchar:
	psh b
	psh a
	cmp a, #0
	beq putchar_return
	cmp a, #'\r'
	bne putchar_not_cr
	clr a
	ldb CURSOR_Y
	jsr term_cursor_set
	jmp putchar_return
putchar_not_cr:
	cmp a, #'\n'
	bne putchar_not_nl
putchar_is_nl:
	ldb CURSOR_Y
	inc b
	stb CURSOR_Y
	cmp b, #TERM_HEIGHT-1
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
	pul a
	pul b
	rts

	; Puts character in 'a'
putchar_raw:
	psh b
	psh a
	pshx
	
	ldb CURR_COLOR
	and b, #1
	bne putchar_raw_is_graphics
	ora a, #128
putchar_raw_is_graphics:
	sta VIDEO_BASE
	
	ldb DISP_PTR_LOC+1
	add b,#CHARS_BUFF_START&255
	stb TEMP1
	ldb DISP_PTR_LOC+0
	adc b,#CHARS_BUFF_START>>8
	stb TEMP0
	ldx TEMP0
	sta 0,X
	lda 1,X
	psh a

	ldb DISP_PTR_LOC+1
	add b,#COLORS_BUFF_START&255
	stb TEMP1
	ldb DISP_PTR_LOC+0
	adc b,#COLORS_BUFF_START>>8
	stb TEMP0
	ldx TEMP0
	lda 0,X
	and a,#254
	ldb CURR_COLOR
	and b,#1
	aba
	sta 0,X
	sta VIDEO_BASE+8
	ldb #SCN_CMD_WRITE_CURSOR_INCR
	stb SCN_CMD_W
	jsr gpu_wait_ready
	lda 1,X
	and a,#1
	ldb CURR_COLOR
	and b,#254
	aba
	sta 1,X
	sta VIDEO_BASE+8
	pul a
	sta VIDEO_BASE
	ldb #SCN_CMD_WRITE_CURSOR
	stb SCN_CMD_W
	jsr gpu_wait_ready

	popx
	pul a
	pul b
	rts

term_scroll_up:
	psh a
	psh b
	pshx
	lda #SCN_CMD_CURSOR_OFF
	sta SCN_CMD_W
	; Move up character buffer by one line
	ldx #CHARS_BUFF_START
term_scroll_l1:
	lda TERM_WIDTH,X
	sta 0,X
	inx
	cpx #CHARS_BUFF_END-TERM_WIDTH
	bne term_scroll_l1
	; Clear last line
	lda #' '
	ora a,#128
term_scroll_l2:
	sta 0,X
	inx
	cpx #CHARS_BUFF_END
	bne term_scroll_l2
	; Move up colors buffer by one line
	ldx #COLORS_BUFF_START
term_scroll_l3:
	lda TERM_WIDTH,X
	sta 0,X
	inx
	cpx #COLORS_BUFF_END-TERM_WIDTH
	bne term_scroll_l3
	; Last line to default color
	lda #TERM_DEFAULT_COLOR
term_scroll_l4:
	sta 0,X
	inx
	cpx #COLORS_BUFF_END
	bne term_scroll_l4

	; Copy buffers into VRAM
	clr a
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
	inx
	stx CTR0
	sta VIDEO_BASE
	ldx PSHX0
	lda 0,X
	inx
	stx PSHX0
	sta VIDEO_BASE+8
	ldb #SCN_CMD_WRITE_CURSOR_INCR
	stb SCN_CMD_W
	jsr gpu_wait_ready
	cpx #COLORS_BUFF_END
	bne term_scroll_l5

	lda CURSOR_X
	ldb CURSOR_Y
	dec b
	jsr term_cursor_set
	popx
	pul b
	lda CURSOR_ON
	beq term_scroll_no_cursor
	lda #SCN_CMD_CURSOR_ON
	sta SCN_CMD_W
term_scroll_no_cursor:
	pul a
	rts

	; X loc in 'a', Y loc in 'b'
term_cursor_set:
	pshx
	psh b
	psh a
	; Width is exactly 64, so X is a 6-bit value
	; Do some shifting to make the bytes go 00YYYYYY YYXXXXX
	clr a
	sta CTR0
	stb CTR1
	clc
	lda CTR1
	ror a
	sta CTR1
	lda CTR0
	ror a
	sta CTR0
	lda CTR1
	ror a
	sta CTR1
	lda CTR0
	ror a
	sta CTR0
	pul a
	psh a
	inc a
	add a, CTR0
	sta CTR0
	lda CTR1
	adc a, #0
	sta CTR1
	ldx #SCN_CURSOR_ADDR_LOW_RW
	lda CTR0
	sta DISP_PTR_LOC+1
	jsr gpu_write_verify
	ldx #SCN_CURSOR_ADDR_HI_RW
	lda CTR1
	sta DISP_PTR_LOC+0
	jsr gpu_write_verify
	pul a
	sta CURSOR_X
	pul b
	stb CURSOR_Y
	popx
	rts

	; Prints null-terminated string pointed at by X
putstr:
	psh a
putstr_loop:
	lda 0,X
	beq putstr_end
	jsr putchar
	inx
	jmp putstr_loop
putstr_end:
	pul a
	rts

printhex:
	psh a
	psh b
	pshx
	psh a
	ror a
	lsr a
	ror a
	ror a
	and a,#15
	add a,#hexchars&255
	sta PRINTHEX_TEMP1
	lda #0
	adc a,#hexchars>>8
	sta PRINTHEX_TEMP0
	ldx PRINTHEX_TEMP0
	lda 0,X
	jsr putchar
	pul a
	and a,#15
	add a,#hexchars&255
	sta PRINTHEX_TEMP1
	lda #0
	adc a,#hexchars>>8
	sta PRINTHEX_TEMP0
	ldx PRINTHEX_TEMP0
	lda 0,X
	jsr putchar
	popx
	pul b
	pul a
	rts

	; Prints data as hex, X points to MSB, A contains length
printhex_str:
	psh b
	clr b
	stb PRINTHEX_TEMP0
	sta PRINTHEX_TEMP1
printhex_loop:
	lda 0,X
	inx
	psh a
	lsr a
	lsr a
	lsr a
	lsr a
	cmp a, #10
	bpl printhex_gt9_1
	add a, #'0'
	jmp printhex_continue_1
printhex_gt9_1:
	add a, #('A'-10)
printhex_continue_1:
	jsr putchar
	pul a
	and a, #15
	cmp a, #10
	bpl printhex_gt9_2
	add a, #'0'
	jmp printhex_continue_2
printhex_gt9_2:
	add a, #('A'-10)
printhex_continue_2:
	jsr putchar

	ldb PRINTHEX_TEMP0
	inc b
	stb PRINTHEX_TEMP0
	cmp b, PRINTHEX_TEMP1
	bne printhex_loop

	lda PRINTHEX_TEMP1
	pul b
	rts

	; Select spiflash and TX value in a
spi_tx:
	psh a
	psh b
	ldb KB_PORTA
	and b,#%11110001
	stb KB_PORTA
	nop
	nop
	ldb #8
	stb PSHX0
spi_tx_loop:
	ldb KB_PORTA
	bit a,#128
	beq spi_tx_zero
	ora b,#2
spi_tx_zero:
	stb KB_PORTA
	ora b,#4
	stb KB_PORTA
	and b,#%11111001
	stb KB_PORTA
	rol a
	dec PSHX0
	bne spi_tx_loop
	and b,#%11110001
	stb KB_PORTA
	pul b
	pul a
	rts

	; Receive value from spiflash and return in a
spi_rx:
	psh b
	ldb #8
	stb PSHX0
	clr a
spi_rx_loop:
	clc
	rol a
	ldb KB_PORTA
	ora b,#4
	stb KB_PORTA
	ldb KB_PORTC
	bit b,#1
	beq spi_rx_zero
	ora a,#1
spi_rx_zero:
	ldb KB_PORTA
	and b,#%11111011
	stb KB_PORTA
	dec PSHX0
	bne spi_rx_loop
	pul b
	rts

	; CS high to spiflash
rom_desel:
	psh a
	lda KB_PORTA
	and a,#%11111001
	ora a,#8
	sta KB_PORTA
	pul a
	rts

	; Advance the KB buffer read pointer (in X) by one
kbadvance macro
	inx
	cpx #KB_BUFF_END
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
	psh b
	pshx
	clr LAST_PRESSED
	clr LAST_RELEASED
	lda ALT_CTRL_DOWN
	bit a,#128
	beq kb_parse_normal
	jmp kb_parse_extended
kb_parse_normal:
	; See if there is another byte in the buffer
	ldx KB_BUFF_RD_PTR
	cpx KB_BUFF_WR_PTR
	bne kb_parse_buffer_not_end ; No? Return.
	jmp kb_parse_buffer_end
kb_parse_buffer_not_end:
	; Yes! Read the byte
	lda 0,X
	kbadvance
	; Inverse the order of the bits in the byte, because I messed up
	ldb #8
	stb PRINTHEX_TEMP0
	clr b
kb_inverse_loop_1:
	rol a
	ror b
	dec PRINTHEX_TEMP0
	bne kb_inverse_loop_1
	tba
	
	cmp a,#$E0 ; Is this an extended code?
	bne kb_not_extended
	jmp kb_parse_extended
kb_not_extended:
	cmp a,#$F0
	bne kb_not_release
	; Its a key being released. Set release flag and try again
	ldb ALT_CTRL_DOWN
	ora b,#64
	stb ALT_CTRL_DOWN
	jmp kb_parse_normal
kb_not_release:
	cmp a,#$14
	bne kb_not_ctrl
	jmp kb_ctrl_key
kb_not_ctrl:
	cmp a,#$11
	bne kb_not_alt
	jmp kb_alt_key
kb_not_alt:
	cmp a,#$12
	beq kb_yes_is_shift_indeed
	cmp a,#$59
	beq kb_yes_is_shift_indeed
	bra kb_not_shift
kb_yes_is_shift_indeed:
	jmp kb_shift_key
kb_not_shift:
	cmp a,#$76
	bne kb_not_esc
	ldb #KEY_ESCAPE
	jmp kb_write_exit
kb_not_esc:
	cmp a,#$66
	bne kb_not_backspace
	ldb #127
	jmp kb_write_exit
kb_not_backspace:
	cmp a,#$5E
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
	add a,PRINTHEX_TEMP1
	sta PRINTHEX_TEMP1
	lda #0
	adc a,PRINTHEX_TEMP0
	sta PRINTHEX_TEMP0
	ldx PRINTHEX_TEMP0
	ldb 0,X
	jmp kb_write_exit

kb_ctrl_key:
	lda ALT_CTRL_DOWN
	and a,#253
	bit a,#64
	bne kb_ctrl_released
	ora a,#2
kb_ctrl_released:
	and a,#%10111111
	sta ALT_CTRL_DOWN
	; Alt key handled
	popx
	pul b
	lda #1
	rts

kb_alt_key:
	lda ALT_CTRL_DOWN
	and a,#254
	bit a,#64
	bne kb_alt_released
	ora a,#1
kb_alt_released:
	and a,#%10111111
	sta ALT_CTRL_DOWN
	; Alt key handled
	popx
	pul b
	lda #1
	rts

kb_shift_key:
	clr SHIFT_DOWN
	lda ALT_CTRL_DOWN
	bit a,#64
	bne kb_shift_released
	lda #1
	sta SHIFT_DOWN
kb_shift_released:
	ldb ALT_CTRL_DOWN
	and b,#%10111111
	stb ALT_CTRL_DOWN
	; Shift key handled
	popx
	pul b
	lda #1
	rts
	
	; Some key was either pressed or released, so update LAST_PRESSED or LAST_RELEASED and return
	; Key character/code in B
kb_write_exit:
	lda ALT_CTRL_DOWN
	bit a,#64
	bne kb_key_released
	stb LAST_PRESSED
	bra kb_key_pressed
kb_key_released:
	stb LAST_RELEASED
kb_key_pressed:
	and a,#%10111111
	sta ALT_CTRL_DOWN
	popx
	pul b
	lda #1
	rts
kb_parse_extended:
	; Set extended flag
	lda ALT_CTRL_DOWN
	ora a,#128
	sta ALT_CTRL_DOWN
	; See if there is another byte in the buffer
	ldx KB_BUFF_RD_PTR
	cpx KB_BUFF_WR_PTR
	beq kb_parse_buffer_end ; No? Leave extended flag set and return
	; Yes! Clear extended flag again and read the byte
	and a,#127
	sta ALT_CTRL_DOWN
	tab
	lda 0,X
	kbadvance
	; Inverse the order of the bits in the byte, because I messed up
	ldb #8
	stb PRINTHEX_TEMP0
	clr b
kb_inverse_loop_2:
	rol a
	ror b
	dec PRINTHEX_TEMP0
	bne kb_inverse_loop_2
	tba
	
	cmp a,#$F0 ; Its an extended key being released
	bne kb_ext_no_release
	; Set release flag and try again
	ora b,#64
	stb ALT_CTRL_DOWN
	jmp kb_parse_extended
kb_ext_no_release:
	cmp a,#$4A ; That one key on the numpad that is an extended code for some reason
	bne kb_ext_not_numpad
	ldb #'/'
	jmp kb_write_exit
kb_ext_not_numpad:
	; Is this a direction key?
	; Individual cmps because the codes are all over the place
	cmp a,#$72
	beq kb_ext_direction_key
	cmp a,#$6B
	beq kb_ext_direction_key
	cmp a,#$75
	beq kb_ext_direction_key
	cmp a,#$74
	beq kb_ext_direction_key
	bra kb_ext_not_direction_key
kb_ext_direction_key:
	; It is. Add $40 to get the internal code for it.
	add a,#$40
	tab
	jmp kb_write_exit
kb_ext_not_direction_key:
	cmp a,#$14
	bne kb_ext_not_ctrl
	; Its the right control key
	jmp kb_ctrl_key
kb_ext_not_ctrl:
	cmp a,#$11
	bne kb_ext_not_altgr
	; Its AltGr, which will just be treated like regular Alt for now
	jmp kb_alt_key
kb_ext_not_altgr:
	cmp a, #$5A ; Its numpad enter, which we're just gonna treat like normal enter
	bne kb_ext_not_enter
	ldb #'\r'
	jmp kb_write_exit
kb_ext_not_enter:
	; I don’t know what this is
	ldb #UNKNOW_KEY
	jmp kb_write_exit
	
	; Hit the end of the buffer early (i.e. key-release code but no next elem in buffer)
kb_parse_buffer_end:
	popx
	pul b
	clr a
	rts

; Arith routines
mul_16x16_unsigned:
	psh a
	psh b
	clr PRINTHEX_TEMP0
	bra mul_16x16_begin

mul_16x16_signed:
	psh a
	psh b
	clr PRINTHEX_TEMP0
	tst 0,X
	bpl mul_16x16_not_neg_1
	neg 1,X
	lda #0
	sbc a,0,X
	sta 0,X
	inc PRINTHEX_TEMP0
mul_16x16_not_neg_1:
	tst 2,X
	bpl mul_16x16_not_neg_2
	neg 3,X
	lda #0
	sbc a,2,X
	sta 2,X
	lda #1
	eor a,PRINTHEX_TEMP0
	sta PRINTHEX_TEMP0
mul_16x16_not_neg_2:
	
mul_16x16_begin:
	lda #(ARITH_CLOCKDIV | ARITH_RST_SEQ | ARITH_RST_Z | ARITH_RST_Y)
	sta ARITH_CTRL
	lda 0,X
	sta ARITH_X
	inx
	lda 0,X
	sta ARITH_X
	inx
	lda 0,X
	sta ARITH_Z
	inx
	lda 0,X
	inx
	sta ARITH_Z
	lda #(ARITH_CLOCKDIV | ARITH_OP_MUL | ARITH_RST_SEQ)
	sta ARITH_CTRL
	lda #5
arith_delay0:
	dec a
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
	sbc a,2,X
	sta 2,X
	lda #0
	sbc a,1,X
	sta 1,X
	ldb #0
	sbc b,0,X
	sta 0,X
mul_16x16_not_neg_res:
	pul b
	pul a
	rts

mul_32x32_signed:
	psh b
	psh a
	clr PSHX2
	tst 0,X
	bpl mul_32x32_not_neg_a
	neg 3,X
	lda #0
	sbc a,2,X
	sta 2,X
	lda #0
	sbc a,1,X
	sta 1,X
	lda #0
	sbc a,0,X
	sta 0,X
	inc PSHX2
mul_32x32_not_neg_a:
	tst 4,X
	bpl mul_32x32_not_neg_b
	neg 7,X
	ldb #0
	sbc b,6,X
	stb 6,X
	ldb #0
	sbc b,5,X
	stb 5,X
	ldb #0
	sbc b,4,X
	stb 4,X
	lda #1
	eor a,PSHX2
	sta PSHX2
mul_32x32_not_neg_b:
	bra mul_32x32_begin
mul_32x32_unsigned:
	psh b
	psh a
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
	dec a
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
	dec a
	bne arith_delay6
	clr PSHX0
	lda ARITH_Y
	sta MDIV_T0
	lda ARITH_Y
	sta MDIV_T1
	lda ARITH_Z
	sta MDIV_T2
	lda ARITH_Z
	add a,13,X
	sta 13,X
	lda MDIV_T2
	adc a,12,X
	sta 12,X
	lda #0
	adc a,MDIV_T1
	sta 11,X
	lda #0
	adc a,MDIV_T0
	sta 10,X
	lda #0
	adc a,PSHX0
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
	dec a
	bne arith_delay7
	lda ARITH_Y
	sta MDIV_T0
	lda ARITH_Y
	sta MDIV_T1
	lda ARITH_Z
	sta MDIV_T2
	lda ARITH_Z
	add a,13,X
	sta 13,X
	lda MDIV_T2
	adc a,12,X
	sta 12,X
	lda 11,X
	adc a,MDIV_T1
	sta 11,X
	lda 10,X
	adc a,MDIV_T0
	sta 10,X
	lda 9,X
	adc a,PSHX0
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
	dec a
	bne arith_delay8
	lda ARITH_Y
	sta MDIV_T0
	lda ARITH_Y
	sta MDIV_T1
	lda ARITH_Z
	sta MDIV_T2
	lda ARITH_Z
	add a,11,X
	sta 11,X
	lda MDIV_T2
	adc a,10,X
	sta 10,X
	lda MDIV_T1
	adc a,9,X
	sta 9,X
	lda #0
	adc a,MDIV_T0
	sta 8,X
	
	inx
	inx
	inx
	inx
	inx
	inx
	inx
	inx
	tst PSHX2
	beq mul_32x32_not_neg_res
	clr b
	neg 7,X
	lda #0
	sbc a,6,X
	sta 6,X
	lda #0
	sbc a,5,X
	sta 5,X
	sbc b,4,X
	stb 4,X
	ldb #0
	sbc b,3,X
	stb 3,X
	ldb #0
	sbc b,2,X
	stb 2,X
	ldb #0
	sbc b,1,X
	stb 1,X
	lda #0
	sbc a,0,X
	sta 0,X
mul_32x32_not_neg_res:
	pul a
	pul b
	rts

mul_fixed:
	jsr mul_32x32_signed
	inx
	inx
	rts

moddiv_16x16_unsigned:
	psh b
	psh a
	
	lda #(ARITH_CLOCKDIV | ARITH_RST_SEQ | ARITH_RST_Z | ARITH_RST_Y)
	sta ARITH_CTRL
	clr b
	stb ARITH_Y
	stb ARITH_Y
	lda 0,X
	inx
	sta ARITH_Z
	lda 0,X
	inx
	sta ARITH_Z
	ldb 0,X
	inx
	stb ARITH_X
	lda 0,X
	inx
	sta ARITH_X
	lda #(ARITH_CLOCKDIV | ARITH_OP_DIV | ARITH_RST_SEQ)
	sta ARITH_CTRL
	lda #5
arith_delay1:
	dec a
	bne arith_delay1
	lda ARITH_Z
	sta 0,X
	lda ARITH_Z
	sta 1,X
	lda ARITH_Y
	sta 2,X
	lda ARITH_Y
	sta 3,X
	
	pul a
	pul b
	rts

moddiv_32x16_unsigned:
	psh a
	
	lda #(ARITH_CLOCKDIV | ARITH_RST_SEQ | ARITH_RST_Z | ARITH_RST_Y)
	sta ARITH_CTRL
	clr a
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
	dec a
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
	inx
	inx
	inx
	inx
	inx 
	lda #3
arith_delay3:
	dec a
	bne arith_delay3
	inx
	lda ARITH_Z
	sta 2,X
	lda ARITH_Z
	sta 3,X
	lda ARITH_Y
	sta 4,X
	lda ARITH_Y
	sta 5,X
	
	pul a
	rts

moddiv_32x32_signed:
	psh a
	psh b
	lda #32
	sta TEMP
moddiv_32x32_signed_skip:
	clr MDIV_T0
	clr MDIV_T1
	tst 0,X
	bpl moddiv_32x32_not_neg_a
	neg 3,X
	lda #0
	sbc a,2,X
	sta 2,X
	lda #0
	sbc a,1,X
	sta 1,X
	lda #0
	sbc a,0,X
	sta 0,X
	inc MDIV_T0
	inc MDIV_T1
moddiv_32x32_not_neg_a:
	tst 4,X
	bpl moddiv_32x32_not_neg_b
	neg 7,X
	lda #0
	sbc a,6,X
	sta 6,X
	lda #0
	sbc a,5,X
	sta 5,X
	lda #0
	sbc a,4,X
	sta 4,X
	lda #1
	eor a,MDIV_T1
	sta MDIV_T1
moddiv_32x32_not_neg_b:
	bra moddiv_32x32_begin
moddiv_32x32_unsigned:
	psh a
	psh b
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
	sub a,7,X
	psh a
	lda 14,X
	sbc a,6,X
	psh a
	lda 13,X
	sbc a,5,X
	psh a
	lda 12,X
	sbc a,4,X
	bmi moddiv_32x32_is_neg
	sta 12,X
	pul a
	sta 13,X
	pul a
	sta 14,X
	pul a
	sta 15,X
	inc 11,X
	bra moddiv_32x32_continue
moddiv_32x32_is_neg:
	ins
	ins
	ins
moddiv_32x32_continue:
	dec PSHX2
	bne moddiv_32x32_loop
	inx
	inx
	inx
	inx
	inx
	inx
	inx
	inx
	tst MDIV_T1
	beq moddiv_32x32_not_neg_res
	neg 3,X
	lda #0
	sbc a,2,X
	sta 2,X
	lda #0
	sbc a,1,X
	sta 1,X
	lda #0
	sbc a,0,X
	sta 0,X
moddiv_32x32_not_neg_res:
	tst MDIV_T0
	beq moddiv_32x32_not_neg_mod
	neg 7,X
	lda #0
	sbc a,6,X
	sta 6,X
	lda #0
	sbc a,5,X
	sta 5,X
	lda #0
	sbc a,4,X
	sta 4,X
moddiv_32x32_not_neg_mod:
	pul b
	pul a
	rts

div_fixed:
	psh a
	psh b
	lda #48
	sta TEMP
	jmp moddiv_32x32_signed_skip

	; X stores location of output buffer AND number to be converted
	; First two bytes of buffer are pre-loaded with the number
	; Output string will be null-terminated
itoa16:
	clr TEMP
itoa16_int:
	psh a
	psh b
	pshx
	ldb 0,X
	stb TEMP_BUFF
	lda 1,X
	sta TEMP_BUFF+1
	bit b,#128
	beq itoa16_not_neg
itoa16_neg:
	neg a
	sta TEMP_BUFF+1
	lda #0
	sbc a,TEMP_BUFF
	sta TEMP_BUFF
itoa16_insert_minus:
	lda #'-'
	sta 0,X
	inx
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
	dec a
	clc
	rol a
	add a,#itoa16_divs&255
	sta CTR1
	lda #0
	adc a,#itoa16_divs>>8
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
	tst a
	bne itoa16_put_char
	tst PRINTHEX_TEMP1
	bne itoa16_put_char
	ldb PRINTHEX_TEMP0
	cmp b,#1
	bne itoa16_skip_char
itoa16_put_char:
	inc PRINTHEX_TEMP1
	add a,#'0'
	sta 0,X
	inx
itoa16_skip_char:
	dec PRINTHEX_TEMP0
	bne itoa16_loop
	clr 0,X
	popx
	pul b
	pul a
	rts

	; X stores location of output buffer AND number to be converted
	; First four bytes of buffer are pre-loaded with the number
	; Output string will be null-terminated
itoa32:
	pshx
	psh b
	psh a
	ldb 0,X
	stb TEMP_BUFF
	lda 1,X
	sta TEMP_BUFF+1
	lda 2,X
	sta TEMP_BUFF+2
	lda 3,X
	sta TEMP_BUFF+3
	bit b,#128
	beq itoa32_not_neg
itoa32_neg:
	neg a
	sta TEMP_BUFF+3
	lda #0
	sbc a,TEMP_BUFF+2
	sta TEMP_BUFF+2
	lda #0
	sbc a,TEMP_BUFF+1
	sta TEMP_BUFF+1
	lda #0
	sbc a,TEMP_BUFF
	sta TEMP_BUFF
	lda #'-'
	sta 0,X
	inx
itoa32_not_neg:
	clr PRINTHEX_TEMP1
	ldb #10
	stb PRINTHEX_TEMP0
itoa32_loop:
	stx PSHX0
	lda PRINTHEX_TEMP0
	dec a
	clc
	rol a
	clc
	rol a
	add a,#itoa32_divs&255
	sta CTR1
	lda #0
	adc a,#itoa32_divs>>8
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
	tst a
	bne itoa32_put_char
	tst PRINTHEX_TEMP1
	bne itoa32_put_char
	ldb PRINTHEX_TEMP0
	cmp b,#1
	bne itoa32_skip_char
itoa32_put_char:
	inc PRINTHEX_TEMP1
	add a,#'0'
	sta 0,X
	inx
itoa32_skip_char:
	dec PRINTHEX_TEMP0
	bne itoa32_loop
	pul a
	pul b
	popx
	rts

fitoa:
	pshx
	psh b
	psh a
	ldb 0,X
	and b,#128
	stb TEMP
	tst b
	bpl fitoa_not_neg
	neg 3,X
	lda #0
	sbc a,2,X
	sta 2,X
	lda #0
	sbc a,1,X
	sta 1,X
	lda #0
	sbc a,0,X
	sta 0,X
fitoa_not_neg:
	lda 0,X
	ldb 1,X
	inx
	inx
	inx
	inx
	sta 0,X
	stb 1,X
	jsr itoa16_int
	dex
	dex
	lda 0,X
	psh a
	lda 1,X
	psh a
	inx
	inx
fitoa_seek_to_end:
	tst 0,X
	beq fitoa_seek_to_end_end
	inx
	bra fitoa_seek_to_end
fitoa_seek_to_end_end:
	lda #'.'
	sta 0,X
	inx
	
	clr TEMP_BUFF+4
	clr TEMP_BUFF+7
	clr TEMP_BUFF+6
	lda #10
	sta TEMP_BUFF+5
	clr TEMP_BUFF
	clr TEMP_BUFF+1
	pul a
	sta TEMP_BUFF+3
	pul b
	stb TEMP_BUFF+2
	lda #5
	sta PRINTHEX_TEMP0
fitoa_loop:
	pshx
	ldx #TEMP_BUFF
	jsr mul_fixed
	lda 1,X
	add a,#'0'
	ldb 2,X
	stb TEMP_BUFF+2
	ldb 3,X
	stb TEMP_BUFF+3
	popx
	sta 0,X
	inx
	dec PRINTHEX_TEMP0
	bne fitoa_loop
	clr 0,X
	inx
	pul a
	pul b
	popx
	inx
	inx
	inx
	inx
	rts

xorshift:
	psh a
	psh b
	
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
	dec b
	bne xorshift_loop_1
	lda PRINTHEX_TEMP0
	eor a,XORSHIFT1
	sta XORSHIFT1
	lda PRINTHEX_TEMP1
	eor a,XORSHIFT2
	sta XORSHIFT2
	lda TEMP
	eor a,XORSHIFT3
	sta XORSHIFT3
	
	lda XORSHIFT3
	ldb XORSHIFT2
	clc
	ror a
	ror b
	eor a,XORSHIFT1
	sta XORSHIFT1
	eor b,XORSHIFT0
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
	dec b
	bne xorshift_loop_2
	
	lda PRINTHEX_TEMP0
	eor a,XORSHIFT0
	sta XORSHIFT0
	lda XORSHIFT1
	eor a,PRINTHEX_TEMP1
	sta XORSHIFT1
	lda TEMP
	eor a,XORSHIFT2
	sta XORSHIFT2
	lda CTR0
	eor a,XORSHIFT3
	sta XORSHIFT3
	
	pul b
	pul a
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
	org $FFF8
	db int>>8
	db int&255
	db sint>>8
	db sint&255
	db nmi>>8
	db nmi&255
	db begin>>8
	db begin&255
