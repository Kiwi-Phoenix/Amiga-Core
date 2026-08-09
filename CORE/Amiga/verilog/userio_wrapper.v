`timescale 1ns / 1ps
// Wrapper for UserIO module. This wrapper is required so that it can be instantated within a VHDL architecture.


module userio_wrapper(
	 input             clk        // bus clock
	,input             reset      // reset
	,input             clk7_en

	,input       [8:1] reg_address_in // register adress inputs
	,input      [15:0] data_in    // bus data in
	,output     [15:0] data_out   // bus data out
	,input             pot_cnt_en // one count / scanline
	,output            fire0     // joystick 0 fire output (to CIA)
	,output            fire1     // joystick 1 fire output (to CIA)
	,input             fire0_dat
	,input             fire1_dat
	,input      [15:0] joy1      // joystick 1 in (default mouse port)
	,input      [15:0] joy2      // joystick 2 in (default joystick port)
	,input      [15:0] joy_ana1
	,input      [15:0] joy_ana2
	,input       [2:0] mouse_btn
	,input             kms_level
	,input       [1:0] kbd_mouse_type
	,input       [7:0] kbd_mouse_data
	,output      [1:0] aud_mix
	,input             IO_ENA
	,input             IO_STROBE
	,output            IO_WAIT
	,input      [15:0] IO_DIN

	,output      [7:0] memory_config
	,output      [4:0] chipset_config
	,output      [3:0] floppy_config
	,output      [2:0] scanline
	,output      [1:0] ar
	,output      [1:0] blver
	,output      [5:0] ide_config
	,output      [1:0] cpu_config
	,output      [2:0] cache_config
	,output            bootrom    // do the A1000 bootrom magic in gary.v
	,output            usrrst     // user reset from osd module
	,output            cpurst
	,output            cpuhlt
	// host
	,output            host_cs
	,output      [23:0] host_adr
	,output            host_we
	,output      [1:0] host_bs
	,output      [15:0] host_wdat
	,input      [15:0] host_rdat
	,input             host_ack
    );

// Instantiate UserIO
userio userio_inst (
	.clk             (clk)
	,.reset          (reset)
	,.clk7_en        (clk7_en)
	,.reg_address_in (reg_address_in)
	,.data_in        (data_in)
	,.data_out       (data_out)
	,.pot_cnt_en     (pot_cnt_en)
	,._fire0         (fire0)
	,._fire1         (fire1)
	,._fire0_dat     (fire0_dat)
	,._fire1_dat     (fire1_dat)
	,._joy1          (joy1)
	,._joy2          (joy2)
	,.joy_ana1       (joy_ana1)
	,.joy_ana2       (joy_ana2)
	,.mouse_btn      (mouse_btn)
	,.kms_level      (kms_level)
	,.kbd_mouse_type (kbd_mouse_type)
	,.kbd_mouse_data (kbd_mouse_data)
	,.aud_mix        (aud_mix)
	,.IO_ENA         (IO_ENA)
	,.IO_STROBE      (IO_STROBE)
	,.IO_WAIT        (IO_WAIT)
	,.IO_DIN         (IO_DIN)
	,.memory_config  (memory_config)
	,.chipset_config (chipset_config)
	,.floppy_config  (floppy_config)
	,.scanline       (scanline)
	,.ar             (ar)
	,.blver          (blver)
	,.ide_config     (ide_config)
	,.cpu_config     (cpu_config)
	,.cache_config   (cache_config)
	,.bootrom        (bootrom)
	,.usrrst         (usrrst)
	,.cpurst         (cpurst)
	,.cpuhlt         (cpuhlt)
	,.host_cs        (host_cs)
	,.host_adr       (host_adr)
	,.host_we        (host_we)
	,.host_bs        (host_bs)
	,.host_wdat      (host_wdat)
	,.host_rdat      (host_rdat)
	,.host_ack       (host_ack)
);

endmodule
