class Spiflash {
public:
	Spiflash();
	void reset();
	uint8_t update(uint8_t sck, uint8_t di);
private:
	uint8_t ROM[4*1024*1024];
	uint8_t step_counter;
	uint8_t curr_sdo;
	uint8_t prev_clk;
	uint8_t data_in;
	uint8_t data_out;
	uint8_t cmd;
	uint8_t address_step;
	uint32_t address;
};
