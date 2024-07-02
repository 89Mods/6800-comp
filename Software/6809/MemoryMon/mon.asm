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
F_PRINTHEX_STR   equ 30+F_TBL_START
F_TERM_CLEAR     equ 33+F_TBL_START
F_CURSOR_ON      equ 36+F_TBL_START
F_CURSOR_OFF     equ 39+F_TBL_START
F_KB_PARSE       equ 42+F_TBL_START
F_ADVANCE_CURSOR equ 45+F_TBL_START
F_CURSOR_RETURN  equ 48+F_TBL_START
F_PRINTHEX       equ 51+F_TBL_START
F_NEWL           equ 54+F_TBL_START

V_CURSOR_X equ $000B
v_CURSOR_Y equ $000C
V_LAST_PRESSED  equ $000E
V_LAST_RELEASED equ $000F
V_SHIFT_DOWN    equ $0010
v_ALT_CTRL_DOWN equ $0011

sev macro
	andcc #$FD
	endm

clv macro
	orcc #$02
	endm

	org 512
boot:
	lda #'?'
	jsr F_PUTCHAR
	lda #' '
	jsr F_PUTCHAR
	;jsr F_ADVANCE_CURSOR
input_wait:
	clr buff_count
	ldb #201
	ldx #text_buff
buff_clr_loop:
	clr 0,X
	leax 1,X
	decb
	bne buff_clr_loop
	ldx #text_buff
wait_for_kb:
	jsr F_KB_PARSE
	beq wait_for_kb
	lda V_LAST_PRESSED
	beq wait_for_kb
	cmpa #'\r'
	beq input_done
	bita #128
	bne wait_for_kb
	cmpa #' '
	bmi wait_for_kb
to_upper:
	cmpa #$61
	blt to_upper_done
	cmpa #$7A
	bgt to_upper_done
	suba #$20
to_upper_done:
	ldb buff_count
	cmpb #200
	beq wait_for_kb
	sta 0,X
	;jsr F_CURSOR_RETURN
	jsr F_PUTCHAR
	;jsr F_ADVANCE_CURSOR
	leax 1,X
	inc buff_count
	bra wait_for_kb
input_done:
	jsr F_PUTCHAR
	jsr F_NEWL
	ldx #text_buff
	lda 0,X
	cmpa #'C'
	bne not_clear
	jsr F_TERM_CLEAR
	jmp boot
not_clear:
	jsr parse_addr
	bvc error
	lda temp_addr
	sta start_addr
	lda temp_addr+1
	sta start_addr+1
	lda 0,X
	beq single_byte
	leax 1,X
	cmpa #':'
	bne not_write_memory
	jmp write_memory
not_write_memory:
	cmpa #'R'
	bne not_exec
	jmp exec
not_exec:
	cmpa #'.'
	bne error
	jsr parse_addr
	bvc error
	lda 0,X
	bne error
	lda temp_addr
	sta end_addr
	lda temp_addr+1
	sta end_addr+1
	jmp dump_memory
single_byte:
	lda temp_addr
	sta end_addr
	lda temp_addr+1
	sta end_addr+1
	jmp dump_memory
error:
	lda #'E'
	jsr F_PUTCHAR
	jsr F_NEWL
	lda #'\n'
	jsr F_PUTCHAR
	jmp boot
dump_memory:
	jsr F_CURSOR_OFF
	ldx start_addr
	clr buff_count
dump_memory_loop:
	lda buff_count
	bita #15
	bne dump_no_print_addr
	bsr dump_print_addr
dump_no_print_addr:
	inc buff_count
	lda 0,X
	jsr F_PRINTHEX
	lda #' '
	jsr F_PUTCHAR
	cmpx end_addr
	beq dump_end
	leax 1,X
	bra dump_memory_loop
dump_end:
	jsr F_NEWL
	lda #'\n'
	jsr F_PUTCHAR
	jsr F_CURSOR_ON
	jmp boot
	
dump_print_addr:
	jsr F_NEWL
	stx temp_addr
	lda temp_addr
	jsr F_PRINTHEX
	lda temp_addr+1
	jsr F_PRINTHEX
	lda #':'
	jsr F_PUTCHAR
	lda #' '
	jsr F_PUTCHAR
	rts
write_memory:
write_memory_loop:
	lda 0,X
	bsr parse_hex
	bvc error
	rola
	rola
	rola
	rola
	anda #$F0
	sta buff_count
	bsr parse_hex
	bvc error
	ora buff_count
	stx temp_addr
	ldx start_addr
	sta 0,X
	leax 1,X
	stx start_addr
	ldx temp_addr
	lda 0,X
	beq dump_end
	leax 1,X
	bra write_memory_loop

exec:
	lda 0,X
	beq exec_no_error
	jmp error
exec_no_error:
	lda start_addr
	sta the_branch+1
	lda start_addr+1
	sta the_branch+2
the_branch:
	jsr 0
	bra dump_end

parse_addr:
	jsr parse_hex
	bvc parse_addr_fail
	rola
	rola
	rola
	rola
	anda #$F0
	sta temp_addr
	jsr parse_hex
	bvc parse_addr_fail
	ora temp_addr
	sta temp_addr
	jsr parse_hex
	bvc parse_addr_fail
	rola
	rola
	rola
	rola
	anda #$F0
	sta temp_addr+1
	jsr parse_hex
	bvc parse_addr_fail
	ora temp_addr+1
	sta temp_addr+1
	sev
	rts
parse_addr_fail:
	clv
	rts
parse_hex:
	lda 0,X
	leax 1,X
	cmpa #$30
	blt parse_hex_fail
	cmpa #$39
	bgt parse_hex_letter
	suba #$30
	sev
	rts
parse_hex_letter:
	cmpa #$41
	blt parse_hex_fail
	cmpa #$46
	bgt parse_hex_fail
	suba #55
	sev
	rts
parse_hex_fail:
	clv
	rts
	
ram_start:
buff_count:
	db 0
start_addr:
	db 0,0
temp_addr:
	db 0,0
end_addr:
	db 0,0
text_buff:
	db 0
