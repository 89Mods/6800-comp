#include <gtkmm.h>

#include "spiflash.h"
#include "IOBoard.h"
#include "cdp1855.h"
#include "6800.h"
#include "gpu.h"
#include "computer.h"

class VGAPanel : public Gtk::DrawingArea {
	public:
		VGAPanel() {
			set_content_width(640);
			set_content_height(480);
			set_draw_func(sigc::mem_fun(*this, &VGAPanel::on_draw));
			m_image = Gdk::Pixbuf::create(Gdk::Colorspace::RGB, false, 8, 640, 480);
			m_image->fill(0);
		}
		virtual ~VGAPanel() {}
		
		void set_pixel(int x, int y, int r, int g, int b) {
			if(!m_image) return;
			int offset = y * m_image->get_rowstride() + x * m_image->get_n_channels();
			guchar * pixel = &m_image->get_pixels()[offset];
			if(!pixel) return;
			pixel[0] = r;
			pixel[1] = g;
			pixel[2] = b;
		}
	protected:
		void on_draw(const Cairo::RefPtr<Cairo::Context>& cr, int width, int height) {
			Gdk::Cairo::set_source_pixbuf(cr, m_image, 0, 0);
			cr->paint();
		}
		Glib::RefPtr<Gdk::Pixbuf> m_image;
};

class MainWindow : public Gtk::Window {
	public:
		MainWindow() {
			set_title("6800 computer emu");
			set_default_size(640, 480);
			set_child(m_vgapanel);
			
			auto controller = Gtk::EventControllerKey::create();
			controller->signal_key_pressed().connect(sigc::mem_fun(*this, &MainWindow::on_key_pressed), false);
			controller->signal_key_released().connect(sigc::mem_fun(*this, &MainWindow::on_key_released), false);
			add_controller(controller);
			sigc::slot<bool()> my_slot = sigc::bind(sigc::mem_fun(*this, &MainWindow::on_timeout), 0);
			Glib::signal_timeout().connect(my_slot, 25);
		}
		virtual ~MainWindow() {}
		
	protected:
		Computer comp;
		VGAPanel m_vgapanel;
		bool on_timeout(int timer_number) {
			comp.cycles(6000);
			uint16_t width = 0;
			uint16_t height = 0;
			uint8_t* pixbuff = comp.gpu_render(&width, &height);
			if(!pixbuff) return true;
			
			for(int i = 0; i < 640; i++) {
				uint16_t x = (uint16_t)((float)i / 640.0f * (float)width);
				for(int j = 0; j < 480; j++) {
					uint16_t y = (uint16_t)((float)j / 480.0f * (float)height);
					uint8_t pixel = pixbuff[y * width + x];
					m_vgapanel.set_pixel(i, j, (pixel & 1) ? 255 : 0, ((pixel >> 1) & 1) ? 255 : 0, (pixel >> 2) ? 255 : 0);
				}
			}
			
			//m_vgapanel.set_pixel(rand() % 640, rand() % 480, rand() % 256, rand() % 256, rand() % 256);
			m_vgapanel.queue_draw();
			return true;
		}
		void ps2_key(guint keyval, bool release) {
			//if(!release) printf("%04x\r\n", keyval);
			uint8_t ps2code = 0;
			bool extended = false;
			if(keyval == 0xff1b) ps2code = 0x76;
			else if(keyval == 0xff08) ps2code = 0x66;
			else if(keyval == 0x20) ps2code = 0x29;
			else if(keyval == 0xffe3) ps2code = 0x14;
			else if(keyval == 0xffe4) {
				ps2code = 0x14;
				extended = true;
			}else if(keyval == 0xffe9) ps2code = 0x11;
			else if(keyval == 0xff52) {
				extended = true;
				ps2code = 0x75;
			}else if(keyval == 0xff54) {
				extended = true;
				ps2code = 0x72;
			}else if(keyval == 0xff51) {
				extended = true;
				ps2code = 0x6B;
			}else if(keyval == 0xff53) {
				extended = true;
				ps2code = 0x74;
			}else if(keyval == 0xdf || keyval == 0x3f) ps2code = 0x4E;
			else if(keyval == 0xfe51 || keyval == 0xfe50) ps2code = 0x55;
			else if(keyval == 0xfe52 || keyval == 0xb0) ps2code = 0x0E;
			//else if(keyval == 0x3c || keyval == 0x3e) ps2code = 0x56;
			else if(keyval == 0xffe1) ps2code = 0x12;
			else if(keyval == 0xffe2) ps2code = 0x59;
			else if(keyval == 0xff09) ps2code = 0x0D;
			else if(keyval == 0x2c || keyval == 0x3b) ps2code = 0x41;
			else if(keyval == 0x2e || keyval == 0x3a) ps2code = 0x49;
			else if(keyval == 0x2d || keyval == 0x5f) ps2code = 0x4A;
			else if(keyval == 0xf6 || keyval == 0xd6) ps2code = 0x4C;
			else if(keyval == 0xe4 || keyval == 0xc4) ps2code = 0x52;
			else if(keyval == 0x23 || keyval == 0x27) ps2code = 0x5D;
			else if(keyval == 0xfc || keyval == 0xdc) ps2code = 0x54;
			else if(keyval == 0x2b || keyval == 0x2a) ps2code = 0x5B;
			else if(keyval == 'Q' || keyval == 'q') ps2code = 0x15;
			else if(keyval == 'W' || keyval == 'w') ps2code = 0x1D;
			else if(keyval == 'E' || keyval == 'e') ps2code = 0x24;
			else if(keyval == 'R' || keyval == 'r') ps2code = 0x2D;
			else if(keyval == 'T' || keyval == 't') ps2code = 0x2C;
			else if(keyval == 'Z' || keyval == 'z') ps2code = 0x35;
			else if(keyval == 'U' || keyval == 'u') ps2code = 0x3C;
			else if(keyval == 'I' || keyval == 'i') ps2code = 0x43;
			else if(keyval == 'O' || keyval == 'o') ps2code = 0x44;
			else if(keyval == 'P' || keyval == 'p') ps2code = 0x4D;
			else if(keyval == 'A' || keyval == 'a') ps2code = 0x1C;
			else if(keyval == 'S' || keyval == 's') ps2code = 0x1B;
			else if(keyval == 'D' || keyval == 'd') ps2code = 0x23;
			else if(keyval == 'F' || keyval == 'f') ps2code = 0x2B;
			else if(keyval == 'G' || keyval == 'g') ps2code = 0x34;
			else if(keyval == 'H' || keyval == 'h') ps2code = 0x33;
			else if(keyval == 'J' || keyval == 'j') ps2code = 0x3B;
			else if(keyval == 'K' || keyval == 'k') ps2code = 0x42;
			else if(keyval == 'L' || keyval == 'l') ps2code = 0x4B;
			else if(keyval == 'Y' || keyval == 'y') ps2code = 0x1A;
			else if(keyval == 'X' || keyval == 'x') ps2code = 0x22;
			else if(keyval == 'C' || keyval == 'c') ps2code = 0x21;
			else if(keyval == 'V' || keyval == 'v') ps2code = 0x2A;
			else if(keyval == 'B' || keyval == 'b') ps2code = 0x32;
			else if(keyval == 'N' || keyval == 'n') ps2code = 0x31;
			else if(keyval == 'M' || keyval == 'm') ps2code = 0x3A;
			else if(keyval == 0xff0d) ps2code = 0x5A;
			else if(keyval == 0x21) ps2code = 0x16;
			else if(keyval == 0x22) ps2code = 0x1E;
			else if(keyval == 0xa7) ps2code = 0x26;
			else if(keyval == 0x24) ps2code = 0x25;
			else if(keyval == 0x25) ps2code = 0x2E;
			else if(keyval == 0x26) ps2code = 0x36;
			else if(keyval == 0x2f) ps2code = 0x3D;
			else if(keyval == 0x28) ps2code = 0x3E;
			else if(keyval == 0x29) ps2code = 0x46;
			else if(keyval == 0x3d) ps2code = 0x45;
			else if(keyval == '1') ps2code = 0x16;
			else if(keyval == '2') ps2code = 0x1E;
			else if(keyval == '3') ps2code = 0x26;
			else if(keyval == '4') ps2code = 0x25;
			else if(keyval == '5') ps2code = 0x2E;
			else if(keyval == '6') ps2code = 0x36;
			else if(keyval == '7') ps2code = 0x3D;
			else if(keyval == '8') ps2code = 0x3E;
			else if(keyval == '9') ps2code = 0x46;
			else if(keyval == '0') ps2code = 0x45;
			else if(keyval == 0xffbe) ps2code = 0x05;
			else if(keyval == 0xffbf) ps2code = 0x06;
			else if(keyval == 0xffc0) ps2code = 0x04;
			else if(keyval == 0xffc1) ps2code = 0x0C;
			else if(keyval == 0xffc2) ps2code = 0x03;
			else if(keyval == 0xffc3) ps2code = 0x0B;
			else if(keyval == 0xffc4) ps2code = 0x83;
			else if(keyval == 0xffc5) ps2code = 0x0A;
			else if(keyval == 0xffc6) ps2code = 0x01;
			else if(keyval == 0xffc7) ps2code = 0x09;
			else if(keyval == 0xffc8) ps2code = 0x78;
			else if(keyval == 0xffc9) ps2code = 0x07;
			//if(!release) printf("%02x\r\n", ps2code);
			
			if(ps2code == 0) return;
			if(extended) comp.ps2_int(0xE0);
			if(release) comp.ps2_int(0xF0);
			comp.ps2_int(ps2code);
		}
		bool on_key_pressed(guint keyval, guint, Gdk::ModifierType state) {
			ps2_key(keyval, false);
			return true;
		}
		void on_key_released(guint keyval, guint, Gdk::ModifierType state) {
			ps2_key(keyval, true);
		}
};

int main(int argc, char** argv, char** env) {
	auto app = Gtk::Application::create("net.tholin.6800emu");
	return app->make_window_and_run<MainWindow>(argc, argv);
}
