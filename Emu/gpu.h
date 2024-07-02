class GPU {
public:
	GPU();
	void reset();
	void step();
	void write(uint8_t addr, uint8_t val);
	uint8_t read(uint8_t addr);
	uint8_t* render(uint16_t* width, uint16_t* height);
private:
	void allocate_pixbuff();
	long int curr_time_millis();
	uint8_t ascii_chars[256][16][10];
	uint8_t graphics_chars[256][16][10];
	uint8_t* pixbuff;
	uint8_t char_latch, color_latch;
	uint8_t curr_ir;
	uint8_t busy;
	uint8_t initializing;
	uint8_t rows;
	uint8_t blink_rate;
	uint16_t columns;
	uint8_t cursor_blinking, cursor_blink_rate;
	uint8_t ul_position;
	uint16_t display_start_addr, display_end_addr;
	uint8_t character_buffer[32768];
	uint8_t color_buffer[32768];
	uint16_t start_1, start_2, cursor_addr;
	uint8_t cursor_start_line, cursor_end_line;
	uint8_t cursor_enabled;
	uint8_t cooldown_cycles;
	uint16_t write_targ;
	uint16_t pointer_addr;
	uint8_t display_on;
	uint8_t is_blanking;
	uint32_t step_counter;
	uint8_t cursor_blink_state;
	long int last_blink;
};
