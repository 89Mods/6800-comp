class Computer {
public:
	Computer();
	void reset();
	uint8_t memory_read(uint16_t address);
	void memory_write(uint16_t address, uint8_t value);
	void cycles(int count);
	uint8_t* gpu_render(uint16_t* width, uint16_t* height);
	void ps2_int(uint8_t val);
private:
	MC6800 cpu;
	CDP1855 cdp1855;
	IOBoard ioBoard;
	GPU gpu;
	uint8_t ROM[32768];
	uint8_t RAM[32768];
	uint8_t pendingPS2[256];
	uint8_t ps2_wp, ps2_rp;
	uint8_t ps2_cooldown;
	uint8_t last_nmi;
};
