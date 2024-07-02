class Computer;
class IOBoard {
public:
	IOBoard(Computer& c);
	void reset();
	void write(uint8_t addr, uint8_t val);
	uint8_t read(uint8_t addr);
	void step();
	uint8_t pending_interrupt();
	void set_ps2_val(uint8_t val);
private:
	Computer& comp;
	Spiflash flash;
	uint8_t ctrl_word;
	uint8_t porta_setting;
	uint8_t porta_out;
	uint8_t portb_setting;
	uint8_t portb_in;
	uint8_t portc_setting;
	uint8_t portc_in;
	uint8_t bcd_val;
	uint8_t curr_sdi;
	uint8_t led_state;
	uint8_t interrupt_latch;
};
