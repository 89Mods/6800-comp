class Computer;
class MC6800 {
public:
	MC6800(Computer& c);
	void reset();
	void step();
	void interrupt(uint8_t which);
	void print_regs();
private:
	uint8_t A;
	uint8_t B;
	uint16_t SP;
	uint16_t X;
	uint16_t PC;
	uint8_t SR;
	Computer& comp;
	void set_conditions_for8(int8_t val);
	void set_conditions_for16(int16_t val);
	void branch();
	uint8_t add(uint8_t a, uint8_t b, uint8_t carry_in);
	uint8_t subtract(uint8_t a, uint8_t b, uint8_t borrow_in);
	uint8_t trace_on;
};
