class CDP1855 {
public:
	CDP1855();
	void reset();
	void write(uint8_t addr, uint8_t val);
	uint8_t read(uint8_t addr);
	void step();
private:
	uint16_t x, z, y;
	uint8_t control;
	uint8_t x_seq, z_seq, y_seq;
	uint8_t cooldown;
	uint8_t op;
	uint8_t broken;
	uint8_t overflow;
};
