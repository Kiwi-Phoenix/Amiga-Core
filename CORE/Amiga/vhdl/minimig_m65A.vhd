    -- Refactored version of Minimig.v module into VHDL.
    -- Re-written in VHDL to make it easier for debugging purposes.
    -- This module is the top-level entity for the Minimig core, which is an FPGA implementation of the classic Amiga computer.
    --
    -- Refactored by: David Raynor (Kiwi) - July 2026
    --
    -- Original Minimig core by: Dennis van Weeren (Dennis) - 2005-2007
    -- Original Minimig core VHDL port by: David Raynor (Kiwi) - 2026
    -- Original Minimig.v copyright notice:
    -- Copyright 2006, 2007 Dennis van Weeren
    --
    -- This file is part of Minimig
    --
    -- Minimig is free software; you can redistribute it and/or modify
    -- it under the terms of the GNU General Public License as published by
    -- the Free Software Foundation; either version 3 of the License, or
    -- (at your option) any later version.
    -- 
    -- Minimig is distributed in the hope that it will be useful,
    -- but WITHOUT ANY WARRANTY; without even the implied warranty of
    -- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    -- GNU General Public License for more details.
    --
    -- You should have received a copy of the GNU General Public License
    -- along with this program.  If not, see <http://www.gnu.org/licenses/>.
    --
    -- Refer to orginal Minimig documentation for more information about the core and its functionality.
    -- Refer to the original Minimig source code for more information about the change history and the original authorship of the core.

    library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use ieee.numeric_std.all;

    library work;
    use work.Amiga_Globals.all;
    use work.Amiga_Debug_pkg.all;


    entity minimig_m65A is
        Port ( 
            -- m68k CPU interface
            cpu_address         : in std_logic_vector(23 downto 1);                     -- m68k address bus
            cpu_data            : out std_logic_vector(15 downto 0);                    -- m68k data bus (read data to CPU)
            cpudata_in          : in std_logic_vector(15 downto 0);                     -- m68k data bus (write data from CPU)
            cpu_ipl_n           : out std_logic_vector(2 downto 0);                     -- m68k interrupt request, active low
            cpu_as_n            : in std_logic;                                         -- m68k address strobe, active low
            cpu_uds_n           : in std_logic;                                         -- m68k upper data strobe, active low
            cpu_lds_n           : in std_logic;                                         -- m68k lower data strobe, active low
            cpu_r_w             : in std_logic;                                         -- m68k read / write (1=read)
            cpu_dtack_n         : out std_logic;                                        -- m68k data acknowledge, active low
            cpu_reset_n         : out std_logic;                                        -- m68k reset (to CPU), active low
            cpu_reset_in_n      : in std_logic;                                         -- m68k reset feedback (RESET instruction), active low
            nmi_addr            : in std_logic_vector(31 downto 0);                     -- m68k NMI vector address (from cpu_wrapper)
            ovr                 : out std_logic;                                        -- m68k NMI address decoding override

            -- SRAM-style memory interface
            ram_data            : out std_logic_vector(15 downto 0);                    -- RAM write data
            ramdata_in          : in std_logic_vector(15 downto 0);                     -- RAM read data    
            ram_address         : out std_logic_vector(22 downto 1);                    -- BANKED word address (see minimig_sram_bridge.v);
            --ram_address         : out std_logic_vector(23 downto 1);                    -- BANKED word address (see minimig_sram_bridge.v);            
            ram_bhe_n           : out std_logic;                                        -- upper byte enable (bits 15:8), active low
            ram_ble_n           : out std_logic;                                        -- lower byte enable (bits 7:0), active low
            ram_we_n            : out std_logic;                                        -- write enable, active low
            ram_oe_n            : out std_logic;                                        -- output enable, active low    
            chip48              : in std_logic_vector(47 downto 0);                     -- 48-bit chip RAM data bus     

            -- System
            rst_ext             : in std_logic;                                         -- external reset input (active high)
            rst_out             : out std_logic;                                        -- minimig reset status
            clk                 : in std_logic;                                         -- 28.375 MHz master clock
            clk7_en             : in std_logic;                                         -- 7.09 MHz posedge clock enable (1=enable)
            clk7n_en            : in std_logic;                                         -- 7.09 MHz negedge clock enable (1=enable)
            c1                  : in std_logic;                                         -- quadrature phase 1
            c3                  : in std_logic;                                         -- quadrature phase 3
            cck                 : in std_logic;                                         -- colour clock enable (3.55 MHz)
            eclk                : in std_logic_vector(9 downto 0);                      -- E-clock one-hot ring (709 kHz)

            -- RS232 Pins
            rxd                : in std_logic;                                         -- rs232 receive
            txd                : out std_logic;                                        -- rs232 transmit
            cts                : in std_logic;                                         -- rs232 clear to send
            rts                : out std_logic;                                        -- rs232 request to send
            dtr                : out std_logic;                                        -- rs232 data terminal ready
            dsr                : in std_logic;                                         -- rs232 data set ready
            cd                 : in std_logic;                                          -- rs232 carrier detect
            ri                 : in std_logic;                                          -- rs232 ring indicator

            -- Input Devices
            joy1_n              : in std_logic_vector(15 downto 0);                     -- mouse port,    active low {...,fire2,fire,up,down,left,right}
            joy2_n              : in std_logic_vector(15 downto 0);                     -- joystick port, active low
            joy3_n              : in std_logic_vector(15 downto 0);                     -- joystick port, active low
            joy4_n              : in std_logic_vector(15 downto 0);                     -- joystick port, active low
            joya1               : in std_logic_vector(15 downto 0);                     -- joystick port, active low
            joya2               : in std_logic_vector(15 downto 0);                     -- joystick port, active low
            mouse_btn           : in std_logic_vector(2 downto 0);                      -- mouse buttons {M,R,L}, active high
            kms_level           : in std_logic;                                         -- keyboard/mouse event toggle strobe 
            kbd_mouse_type      : in std_logic_vector(1 downto 0);                      -- 2 = raw Amiga keyboard scancode
            kbd_mouse_data      : in std_logic_vector(7 downto 0);                      -- keyboard/mouse data - scancode (bit 7 = release)
            kbd_ack             : out std_logic;                                        -- keyboard/mouse acknowledge (active high) while the CPU reads the keyboard SDR

            -- LEDs
            pwr_led             : out std_logic;                                         -- power LED (active high) 
            fdd_led             : out std_logic;                                         -- floppy LED (active high)
            hdd_led             : out std_logic;                                         -- hard disk LED (active high)

            -- MEGA65 battery-backed RTC (issue #13): MiSTer-format 65-bit conduit,
            -- [63:0] = MSM6242B BCD nibbles, [64] = "new value" toggle. Driven by the
            -- M2M framework from the board RTC; decoded by minimig.v at $DC0000.
            rtc                : in std_logic_vector(64 downto 0);                      -- Real-Time Clock 

            -- host controller interface, shared IO_STROBE/IO_DIN bus with two frame
            -- enables: io_uio selects userio.v (config FSM amiga_config.vhd), io_fpga
            -- selects paula_floppy.v (ADF track engine adf_track_engine.vhd)
            io_uio              : in std_logic;                                         -- user IO Command Channel frame enable (active high)
            io_fpga             : in std_logic;                                         -- FPGA IO Floppy Channel frame enable (active high)
            io_strobe           : in std_logic;                                         -- IO strobe (active high) Word strobe, 1 clk wide 
            io_wait             : out std_logic;                                        -- IO wait (active high)
            io_din              : in std_logic_vector(15 downto 0);                     -- IO Data
            io_dout             : out std_logic_vector(15 downto 0);                    -- response data (paula_floppy only; userio has none)

            -- video (28.375 MHz domain)
            hsync_n             : out std_logic;                                         -- horizontal sync, active low
            vsync_n             : out std_logic;                                         -- vertical sync, active low
            csync_n             : out std_logic;                                         -- composite sync, active low
            field1              : out std_logic;                                         -- 1=field 1, 0=field 0 (for interlaced video)
            lace                : out std_logic;                                         -- 1=interlaced, 0=non-interlaced  
            hblank              : out std_logic;                                         -- horizontal blanking active high (Agnus hbl with blver=0)
            vblank              : out std_logic;                                         -- vertical blanking active high 
            red                 : out std_logic_vector(7 downto 0);                      -- red video output (8-bit)
            green               : out std_logic_vector(7 downto 0);                      -- green video output (8-bit)
            blue                : out std_logic_vector(7 downto 0);                      -- blue video output (8-bit)
            ar                  : out std_logic_vector(1 downto 0);                      -- Action Replay video output (2-bit)
            scanline            : out std_logic_vector(2 downto 0);                      -- scanline video output (3-bit)
            ce_pix              : out std_logic;                                         -- minimig's own pixel CE (7.09/14.19 MHz; info)
            res                 : out std_logic_vector(1 downto 0);                      --{shres, hires} resolution flags for the frame-locked CE
            ntsc                : out std_logic;                                         -- NTSC signal
            
            -- audio (28.375 MHz domain) (P{aula, 15-bit signed)
            ldata               : out std_logic_vector(14 downto 0);                     -- left audio channel
            rdata               : out std_logic_vector(14 downto 0);                     -- right audio channel
            ldata_okk           : out std_logic_vector(8 downto 0);                      -- left audio channel OK signal (active high)
            rdata_okk           : out std_logic_vector(8 downto 0);                      -- right audio channel OK signal (active high)
            aud_mix             : out std_logic_vector(1 downto 0);                      -- User IO audio mix control
            
            -- Toccata audio
            toccata_ena         : in std_logic;                                          -- enables toccata interface
            toccata_base        : in std_logic_vector(7 downto 0);                       -- toccata data bus
            toccata_aud_left    : out std_logic_vector(15 downto 0);                     -- toccata left audio channel
            toccata_aud_right   : out std_logic_vector(15 downto 0);                     -- toccata right audio channel

            -- User I/O
            cpucfg              : out std_logic_vector(1 downto 0);                      -- User I/O CPU configuration control    
            cachecfg            : out std_logic_vector(2 downto 0);                      -- User I/O cache configuration control
            memcfg              : out std_logic_vector(6 downto 0);
            bootrom             : out std_logic;                                         -- User I/O bootrom configuration control - do the A1000 bootrom magic in gary.v
                    
            ide_ena             : out std_logic;                                         -- User I/O IDE configuration control               
            ide_fast            : out std_logic;                                         -- User I/O IDE configuration control
            ide_ext_irq         : in std_logic;                                          -- User I/O IDE configuration contro
            ide_req             : out std_logic_vector(5 downto 0);                      -- User I/O IDE configuration control
            ide_address         : in std_logic_vector(4 downto 0);  
            ide_write           : in std_logic;                                          -- User I/O IDE configuration control
            ide_writedata       : in std_logic_vector(15 downto 0);
            ide_read            : in std_logic;                                          -- User I/O IDE configuration control    
            ide_readdata        : out std_logic_vector(15 downto 0)                      -- User I/O IDE configuration contro            
            );

    attribute description of cpu_address            : signal is "m68k address bus";
    attribute description of cpu_data               : signal is "m68k data bus (read data to CPU)";
    attribute description of cpudata_in             : signal is "m68k data bus (write data from CPU)";
    attribute description of cpu_ipl_n              : signal is "m68k interrupt request, active low";
    attribute description of cpu_as_n               : signal is "m68k address strobe, active low";
    attribute description of cpu_uds_n              : signal is "m68k upper data strobe, active low";
    attribute description of cpu_lds_n              : signal is "m68k lower data strobe, active low";
    attribute description of cpu_r_w                : signal is "m68k read / write (1=read)";
    attribute description of cpu_dtack_n            : signal is "m68k data acknowledge, active low";
    attribute description of cpu_reset_n            : signal is "m68k reset (to CPU), active low";
    attribute description of cpu_reset_in_n         : signal is "m68k reset feedback (RESET instruction), active low";
    attribute description of nmi_addr               : signal is "m68k NMI vector address (from cpu_wrapper)";
    attribute description of ovr                    : signal is "m68k NMI address decoding override";
    attribute description of ram_data               : signal is "RAM write data";
    attribute description of ramdata_in             : signal is "RAM read data";
    attribute description of ram_address            : signal is "BANKED word address (see minimig_sram_bridge.v)";
    attribute description of ram_bhe_n              : signal is "upper byte enable (bits 15:8), active low";
    attribute description of ram_ble_n              : signal is "lower byte enable (bits 7:0), active low";
    attribute description of ram_we_n               : signal is "write enable, active low";
    attribute description of ram_oe_n               : signal is "output enable, active low";
    attribute description of chip48                 : signal is "48-bit chip RAM data bus";
    attribute description of rst_ext                : signal is "external reset input (active high)";
    attribute description of rst_out                : signal is "minimig reset status";
    attribute description of clk                    : signal is "28.375 MHz master clock";
    attribute description of clk7_en                : signal is "7.09 MHz posedge clock enable (1=enable)";
    attribute description of clk7n_en               : signal is "7.09 MHz negedge clock enable (1=enable)";
    attribute description of c1                     : signal is "quadrature phase 1";
    attribute description of c3                     : signal is "quadrature phase 3";
    attribute description of cck                    : signal is "colour clock enable (3.55 MHz)";
    attribute description of eclk                   : signal is "E-clock one-hot ring (709 kHz)";
    attribute description of rxd                    : signal is "rs232 receive";
    attribute description of txd                    : signal is "rs232 transmit";
    attribute description of cts                    : signal is "rs232 clear to send";
    attribute description of rts                    : signal is "rs232 request to send";
    attribute description of dtr                    : signal is "rs232 data terminal ready";
    attribute description of dsr                    : signal is "rs232 data set ready";
    attribute description of cd                     : signal is "rs232 carrier detect";
    attribute description of ri                     : signal is "rs232 ring indicator";
    attribute description of joy1_n                 : signal is "mouse port,    active low {...,fire2,fire,up,down,left,right}";
    attribute description of joy2_n                 : signal is "joystick port, active low";
    attribute description of joy3_n                 : signal is "joystick port, active low";
    attribute description of joy4_n                 : signal is "joystick port, active low";
    attribute description of joya1                  : signal is "joystick port, active low";
    attribute description of joya2                  : signal is "joystick port, active low";
    attribute description of mouse_btn              : signal is "mouse buttons {M,R,L}, active high";
    attribute description of kms_level              : signal is "keyboard/mouse event toggle strobe";
    attribute description of kbd_mouse_type         : signal is "2 = raw Amiga keyboard scancode";
    attribute description of kbd_mouse_data         : signal is "keyboard/mouse data - scancode (bit 7 = release)";
    attribute description of kbd_ack                : signal is "keyboard/mouse acknowledge (active high) while the CPU reads the keyboard SDR";
    attribute description of pwr_led                : signal is "power LED (active high)";
    attribute description of fdd_led                : signal is "floppy LED (active high)";
    attribute description of hdd_led                : signal is "hard disk LED (active high)";
    attribute description of rtc                    : signal is "Real-Time Clock";
    attribute description of io_uio                 : signal is "user IO Command Channel frame enable (active high)";
    attribute description of io_fpga                : signal is "FPGA IO Floppy Channel frame enable (active high)";
    attribute description of io_strobe              : signal is "IO strobe (active high) Word strobe, 1 clk wide";
    attribute description of io_wait                : signal is "IO wait (active high)";
    attribute description of io_din                 : signal is "IO Data";
    attribute description of io_dout                : signal is "response data (paula_floppy only; userio has none)";
    attribute description of hsync_n                : signal is "horizontal sync, active low";
    attribute description of vsync_n                : signal is "vertical sync, active low";
    attribute description of csync_n                : signal is "composite sync, active low";
    attribute description of field1                 : signal is "1=field 1, 0=field 0 (for interlaced video)";
    attribute description of lace                   : signal is "1=interlaced, 0=non-interlaced";
    attribute description of hblank                 : signal is "horizontal blanking active high (Agnus hbl with blver=0)";
    attribute description of vblank                 : signal is "vertical blanking active high";
    attribute description of red                    : signal is "red video output (8-bit)";
    attribute description of green                  : signal is "green video output (8-bit)";
    attribute description of blue                   : signal is "blue video output (8-bit)";
    attribute description of ar                     : signal is "Action Replay video output (2-bit)";
    attribute description of scanline               : signal is "scanline video output (3-bit)";
    attribute description of ce_pix                 : signal is "minimig's own pixel CE (7.09/14.19 MHz; info)";
    attribute description of res                    : signal is "{shres, hires} resolution flags for the frame-locked CE";
    attribute description of ntsc                   : signal is "NTSC signal";
    attribute description of ldata                  : signal is "left audio channel";
    attribute description of rdata                  : signal is "right audio channel";
    attribute description of ldata_okk              : signal is "left audio channel OK signal (active high)";
    attribute description of rdata_okk              : signal is "right audio channel OK signal (active high)";
    attribute description of aud_mix                : signal is "User IO audio mix control";
    attribute description of toccata_ena            : signal is "enables toccata interface";
    attribute description of toccata_base           : signal is "toccata data bus";
    attribute description of toccata_aud_left       : signal is "toccata left audio channel";
    attribute description of toccata_aud_right      : signal is "toccata right audio channel";
    attribute description of cpucfg                 : signal is "User I/O CPU configuration control";
    attribute description of cachecfg               : signal is "User I/O cache configuration control";
    attribute description of memcfg                 : signal is "User I/O memory configuration control";
    attribute description of bootrom                : signal is "User I/O bootrom configuration control - do the A1000 bootrom magic in gary.v";
    attribute description of ide_ena                : signal is "User I/O IDE configuration control";
    attribute description of ide_fast               : signal is "User I/O IDE configuration control";
    attribute description of ide_ext_irq            : signal is "User I/O IDE configuration control";
    attribute description of ide_req                : signal is "User I/O IDE configuration control";
    attribute description of ide_address            : signal is "User I/O IDE configuration control";
    attribute description of ide_write              : signal is "User I/O IDE configuration control";
    attribute description of ide_writedata          : signal is "User I/O IDE configuration control";
    attribute description of ide_read               : signal is "User I/O IDE configuration control";
    attribute description of ide_readdata           : signal is "User I/O IDE configuration control";
        
    end entity;


    architecture rtl of minimig_m65A is 

    -- Define the Signal Record types -------------------------------------------------------------------------------------------------------------
    -- Record type for In Ports of the entity. This is used to group all input signals into a single record for easier handling and passing to submodules.    
    type ip_type is record 
        -- M68k CPU Interface
        cpu_address         : std_logic_vector(23 downto 1);                     -- m68k address bus
        cpudata_in          : std_logic_vector(15 downto 0);                     -- m68k data bus (write data from CPU)
        cpu_as_n            : std_logic;                                         -- m68k address strobe, active low
        cpu_uds_n           : std_logic;                                         -- m68k upper data strobe, active low
        cpu_lds_n           : std_logic;                                         -- m68k lower data strobe, active low
        cpu_r_w             : std_logic;                                         -- m68k read / write (1=read)
        cpu_reset_in_n      : std_logic;                                         -- m68k reset feedback (RESET instruction), active low
        nmi_addr            : std_logic_vector(31 downto 0);                     -- m68k NMI vector address (from cpu_wrapper)
        -- SRAM-style memory interface
        ramdata_in          : std_logic_vector(15 downto 0);                     -- RAM read data     
        chip48              : std_logic_vector(47 downto 0);                     -- 48-bit chip RAM data bus
        -- System Reset and Clocks
        rst_ext             : std_logic;                                         -- external reset input (active high)
        clk                 : std_logic;                                         -- 28.375 MHz master clock
        clk7_en             : std_logic;                                         -- 7.09 MHz posedge clock enable (1=enable)
        clk7n_en            : std_logic;                                         -- 7.09 MHz negedge clock enable (1=enable)
        c1                  : std_logic;                                         -- quadrature phase 1
        c3                  : std_logic;                                         -- quadrature phase 3
        cck                 : std_logic;                                         -- colour clock enable (3.55 MHz)
        eclk                : std_logic_vector(9 downto 0);                       -- E-clock one-hot ring (709 kHz)
        -- RS232 Pins
        rxd                 : std_logic;                                         -- rs232 receive
        cts                 : std_logic;                                         -- rs232 clear to send
        dsr                 : std_logic;                                         -- rs232 data set ready
        cd                  : std_logic;                                          -- rs232 carrier detect
        ri                  : std_logic;                                          -- rs232 ring indicator
        -- Input devices
        joy1_n              : std_logic_vector(15 downto 0);                     -- mouse port,    active low {...,fire2,fire,up,down,left,right}
        joy2_n              : std_logic_vector(15 downto 0);                     -- joystick port, active low
        joy3_n              : std_logic_vector(15 downto 0);                     -- joystick port, active low
        joy4_n              : std_logic_vector(15 downto 0);                     -- joystick port, active low
        joya1               : std_logic_vector(15 downto 0);                     -- joystick port, active low
        joya2               : std_logic_vector(15 downto 0);                     -- joystick port, active low
        mouse_btn           : std_logic_vector(2 downto 0);                      -- mouse buttons {M,R,L}, active high
        kms_level           : std_logic;                                         -- keyboard/mouse event toggle strobe
        kbd_mouse_type      : std_logic_vector(1 downto 0);                      -- 2 = raw Amiga keyboard scancode
        kbd_mouse_data      : std_logic_vector(7 downto 0);                      -- keyboard/mouse data - scancode (bit 7 = release)
        -- Real-Time Clock (RTC) interface
        rtc                 : std_logic_vector(64 downto 0);                      -- Real-Time Clock 
        --Host controller interface 
        io_uio              : std_logic;                                         -- user IO Command Channel frame enable (active high)
        io_fpga             : std_logic;                                         -- FPGA IO Floppy Channel frame enable (active high)
        io_strobe           : std_logic;                                         -- IO strobe (active high) Word strobe, 1 clk wide 
        io_din              : std_logic_vector(15 downto 0);                     -- IO Data 
        -- Toccata audio
        toccata_ena         : std_logic;                                         -- enables toccata interface
        toccata_base        : std_logic_vector(7 downto 0);                      -- toccata data bus        
        -- IDE interface signals
        ide_ext_irq         : std_logic;                                        -- User I/O IDE configuration contro        
        ide_address         : std_logic_vector(4 downto 0);  
        ide_write           : std_logic;                                        -- User I/O IDE configuration control
        ide_writedata       : std_logic_vector(15 downto 0);
        ide_read            : std_logic;                                        -- User I/O IDE configuration control
        
    end record;

    -- Record type for Out Ports of the entity. This is used to group all output signals into a single record for easier handling and passing to submodules.
    type op_type is record 
        -- M68k CPU Interface
        cpu_data            : std_logic_vector(15 downto 0);                    -- m68k data bus (read data to CPU)
        cpu_ipl_n           : std_logic_vector(2 downto 0);                     -- m68k interrupt request, active low
        cpu_dtack_n         : std_logic;                                        -- m68k data acknowledge, active low
        cpu_reset_n         : std_logic;     
        ovr                 : std_logic;                                        -- m68k overflow (to CPU), active low
        -- SRAM-style memory interface
        ram_data            : std_logic_vector(15 downto 0);                    -- RAM write data
        ram_address         : std_logic_vector(22 downto 1);                    -- BANKED word address (see minimig_sram_bridge.v);
        --ram_address         : std_logic_vector(23 downto 1);                    -- BANKED word address (see minimig_sram_bridge.v);
        ram_bhe_n           : std_logic;                                        -- upper byte enable (bits 15:8), active low
        ram_ble_n           : std_logic;                                        -- lower byte enable (bits 7:0), active low
        ram_we_n            : std_logic;                                        -- write enable, active low
        ram_oe_n            : std_logic;                                        -- output enable, active low    
        -- System
        rst_out             : std_logic;                                        -- minimig reset status
        -- RS232 Pins
        txd                 : std_logic;                                        -- rs232 transmit
        rts                 : std_logic;                                        -- rs232 request to send
        dtr                 : std_logic;                                        -- rs232 data terminal ready    
        -- Input Devices
        kbd_ack             : std_logic;                                        -- keyboard/mouse acknowledge (active high) while the CPU reads the keyboard SDR
        -- LEDs
        pwr_led             : std_logic;                                        -- power LED (active high)
        fdd_led             : std_logic;                                        -- floppy LED (active high)
        hdd_led             : std_logic;                                        -- hard disk LED (active high)
        -- Host controller interface
        io_wait             : std_logic;                                        -- IO wait (active high)
        io_dout             : std_logic_vector(15 downto 0);                    -- response data (paula_floppy only; userio has none)
        -- Video 
        hsync_n             : std_logic;                                        -- horizontal sync, active low
        vsync_n             : std_logic;                                        -- vertical sync, active low
        csync_n             : std_logic;                                        -- composite sync, active low
        field1              : std_logic;                                        -- 1=field 1, 0=field 0 (for interlaced video)
        lace                : std_logic;                                        -- 1=interlaced, 0=non-interlaced  
        hblank              : std_logic;                                        -- horizontal blanking active high (Agnus hbl with blver=0)
        vblank              : std_logic;                                        -- vertical blanking active high 
        red                 : std_logic_vector(7 downto 0);                     -- red video output (8-bit)
        green               : std_logic_vector(7 downto 0);                     -- green video output (8-bit)
        blue                : std_logic_vector(7 downto 0);                     -- blue video output (8-bit)
        ar                  : std_logic_vector(1 downto 0);                      -- Action Replay video output (2-bit)
        scanline            : std_logic_vector(2 downto 0);                     -- scanline video output (3-bit)               
        ce_pix              : std_logic;                                        -- minimig's own pixel CE (7.09/14.19 MHz; info)
        res                 : std_logic_vector(1 downto 0);                     -- {shres, hires} resolution flags for the frame-locked CE
        ntsc                : std_logic;                                        -- NTSC signal
        -- Audio    
        aud_mix             : std_logic_vector(1 downto 0);                     -- User IO audio mix control
        ldata               : std_logic_vector(14 downto 0);                    -- left audio channel
        rdata               : std_logic_vector(14 downto 0);                    -- right audio channel
        ldata_okk           : std_logic_vector(8 downto 0);                     -- left audio channel OK signal (active high)
        rdata_okk           : std_logic_vector(8 downto 0);                     -- right audio channel OK signal (active high)
        -- Toccata audio
        toccata_aud_left    : std_logic_vector(15 downto 0);                    -- toccata left audio channel  
        toccata_aud_right   : std_logic_vector(15 downto 0);                    -- toccata right audio channel 
        --User I/O
        cpucfg              : std_logic_vector(1 downto 0);                     -- User I/O CPU configuration control    
        cachecfg            : std_logic_vector(2 downto 0);                     -- User I/O cache configuration control
        memcfg              : std_logic_vector(6 downto 0);
        bootrom             : std_logic;                                        -- User I/O bootrom configuration control - do the A1000 bootrom magic in gary.v
        -- IDE interface signals
        ide_ena             : std_logic;                                        -- User I/O IDE configuration control   
        ide_fast            : std_logic;                                        -- User I/O IDE configuration control
        ide_req             : std_logic_vector(5 downto 0);                     -- User I/O IDE configuration control
        ide_readdata        : std_logic_vector(15 downto 0);     
    end record;

    -- Record type for internal signals of the architecture. This is used to group all internal signals into a single record for easier handling and passing to submodules.
    type internal_signals_type is record
        reset               : std_logic;       
        sys_reset           : std_logic;       
        r                   : std_logic; 
        rst                 : std_logic;
        cpu_reset           : std_logic;
        cpu_reset_n         : std_logic;

        -- Local signals for data bus
        cpu_data_in              : std_logic_vector(15 downto 0);           -- cpu data bus in
        cpu_data_out             : std_logic_vector(15 downto 0);           -- cpu data bus out
        ram_data_in              : std_logic_vector(15 downto 0);           -- ram data bus in
        ram_data_out             : std_logic_vector(15 downto 0);           -- ram data bus out
        custom_data_in           : std_logic_vector(15 downto 0);           -- custom chips data bus in
        custom_data_out          : std_logic_vector(15 downto 0);           -- custom chips data bus out    
        agnus_data_out           : std_logic_vector(15 downto 0);           -- agnus data bus out
        paula_data_out           : std_logic_vector(15 downto 0);           -- paula data bus out
        denise_data_out          : std_logic_vector(15 downto 0);           -- denise data bus out
        user_data_out            : std_logic_vector(15 downto 0);           -- user data bus out
        gary_data_out            : std_logic_vector(15 downto 0);           -- gary data bus out
        gayle_data_out           : std_logic_vector(15 downto 0);           -- gayle data bus out
        cia_data_out             : std_logic_vector(15 downto 0);           -- cia A+B data bus out
        ar3_data_out             : std_logic_vector(15 downto 0);           -- Action Replay data bus out

        -- Local signals for address bus
        cpu_address_out           : std_logic_vector(23 downto 1);          -- cpu address bus out
        dma_address_out           : std_logic_vector(20 downto 1);          -- dma address bus out   
        ram_address_out           : std_logic_vector(23 downto 1);          -- ram address bus out

        a1k                     : std_logic;                                        -- A1000 signal
        ecs                     : std_logic;                                        -- ECS signal
        aga                     : std_logic;                                        -- AGA signal

        ntsc                    : std_logic;                                        -- NTSC signal
        int2                    : std_logic;                                        -- interrupt 2 signal
        int2_x                  : std_logic;                                        
        int6                    : std_logic;                                        -- interrupt 6 signal
        ide_fast                : std_logic;                                        -- IDE fast signal
        cpu_ipl               : std_logic_vector(2 downto 0);                     -- cpu interrupt request, active low
        
        data_out                : std_logic_vector(15 downto 0);                    -- data output bus        
        hdc_ena                 : std_logic;                                        -- hard disk controller enable

        -- Video signals
        hblank                  : std_logic;                                        -- horizontal blanking active high
        blank                   : std_logic;                                        -- Video blanking signal

        -- Kickstart signals
        ovl                     : std_logic;                                        -- Kickstart overlay signal

        bridge_wr               : std_logic;      
        
        ciaa_porta_in       : std_logic_vector(7 downto 2);                     -- CIA A port A input
        ciaa_portb_in       : std_logic_vector(7 downto 0);                     -- CIA A port B input
        ciab_porta_in       : std_logic_vector(5 downto 0);                     -- CIA B port A input
        fire0_dat           : std_logic;                                        -- fire button 0 data
        fire1_dat           : std_logic;                                        -- fire button 1 data

        nrdy                   : std_logic;                                        -- not ready signal
        data_in                : std_logic_vector(15 downto 0);                    -- data input bus

        mrst                   : std_logic;                                        -- minimig reset signal
        rst_out                : std_logic;                                        -- minimig reset status

        pot_cnt_en           : std_logic;                                        -- potentiometer counter enable

        -- Bank Manager
        chip0                  : std_logic;                                        -- chip RAM bank 0 select

        ramdata_in            : std_logic_vector(15 downto 0);                    -- RAM bank 0 data bus in

        -- RTC
        rtc_out                 : std_logic_vector(15 downto 0);                   


    end record;

    -- Record type for User IO signals. This is used to group all User IO signals into a single record for easier handling and passing to submodules.
    type userio_signals_type is record
            io_wait                     : std_logic;                                        -- IO wait (active high)
            data_out                    : std_logic_vector(15 downto 0);                    -- User IO data output
            fire0                       : std_logic;                                        -- User IO fire button 0
            fire1                       : std_logic;                                        -- User IO fire button 1
            aud_mix                     : std_logic_vector(1 downto 0);                     -- User IO audio mix control
            memory_config               : std_logic_vector(7 downto 0);                     -- User IO memory configuration control   
            chipset_config              : std_logic_vector(4 downto 0);                     -- User IO chipset configuration control
            floppy_config               : std_logic_vector(3 downto 0);                     -- User IO floppy configuration control
            scanline                    : std_logic_vector(2 downto 0);                     -- User IO scanline
            ar                          : std_logic_vector(1 downto 0);              
            blver                       : std_logic_vector(1 downto 0);
            ide_config                  : std_logic_vector(5 downto 0);                     -- User IO IDE configuration control
            cpu_config                  : std_logic_vector(1 downto 0);                     -- User IO CPU configuration control
            cache_config                : std_logic_vector(2 downto 0);                     -- User IO cache configuration control
            bootrom                     : std_logic;                                        -- User IO bootrom configuration control - do the A1000 bootrom magic in gary.v
            usrrst                      : std_logic; 
            cpurst                      : std_logic; 
            cpuhlt                      : std_logic;
            host_cs                     : std_logic;
            host_adr                    : std_logic_vector(23 downto 0);
            host_we                     : std_logic;
            host_bs                     : std_logic_vector(1 downto 0);
            host_wdat                   : std_logic_vector(15 downto 0);
    end record;

    -- Record type for Agnus output signals. This is used to group all Agnus output signals into a single record for easier handling and passing to submodules.
    type agnus_out_type is record
            data_out            : std_logic_vector(15 downto 0);                    -- Agnus data output
            address_out         : std_logic_vector(20 downto 1);                    -- Agnus address output
            reg_address_out     : std_logic_vector(8 downto 1);                     -- Agnus register address output
            cpu_custom          : std_logic;                                        -- CPU has access to custom chipset (registers and chipRAM / slowRAM)
            dbr                 : std_logic;                                        -- Agnus requests data bus
            dbwe                : std_logic;                                        -- Agnus does a memory write cycle (only disk and blitter dma channels may do this)
            hsync               : std_logic;                                        -- horizontal sync signal    
            vsync               : std_logic;                                        -- vertical sync signal
            csync               : std_logic;                                        -- composite sync signal
            field1              : std_logic;                                        -- 1=field 1, 0=field 0 (for interlaced video)
            lace                : std_logic;                                        -- 1=interlaced, 0=non-interlaced
            hblank              : std_logic;                                        -- horizontal blanking active high (Agnus hbl with blver=0)
            vblank              : std_logic;                                        -- vertical blanking active high 
            hde                 : std_logic;                                        -- video horizontal data enable
            sol                 : std_logic;                                        -- start of video line (active during last pixel of previous line)
            sof                 : std_logic;                                        -- start of video frame (active during last pixel of previous frame)
            vbl_int             : std_logic;                                        -- vertical blanking interrupt (active high) for Paula  
            strhor_denise       : std_logic;                                        -- horizontal data enable for Denise (active high) (due to not cycle exact implementation of Denise it must be delayed by one CCK)
            strhor_paula        : std_logic;                                        -- horizontal data enable for Paula (active high) 
            htotal              : std_logic_vector(8 downto 0);                     -- video line length
            harddis             : std_logic;                                        -- hard disk 
            varbeamen           : std_logic;                                        
            int3                : std_logic;                                        -- blitter finished interrupt (to Paula)
    end record;

    -- Record type for Paula output signals. This is used to group all Paula output signals into a single record for easier handling and passing to submodules.
    type paula_out_type is record
        data_out            : std_logic_vector(15 downto 0);                    -- Paula data output
        txd                 : std_logic;                                        -- Paula serial transmit data
        ipl                 : std_logic_vector(2 downto 0);                     -- Paula interrupt request, active low  
        audio_dmal          : std_logic_vector(3 downto 0);                     -- audio dma data transfer request (to Agnus)
        audio_dmas          : std_logic_vector(3 downto 0);                     -- audio dma location pointer restart (to Agnus)
        disk_dmal           : std_logic;                                        -- disk dma data transfer request (to Agnus)
        disk_dmas           : std_logic;                                        -- disk dma special request (to Agnus)
        track0              : std_logic;                                        -- track zero detect (to Agnus)
        change              : std_logic;                                        -- disk has been removed from drive
        ready               : std_logic;                                        -- disk is ready to be accessed
        wprot               : std_logic;                                        -- disk is write protected
        index               : std_logic;                                        -- disk index pulse
        fdd_led             : std_logic;                                        -- floppy disk drive LED (active high) active when DMA is on
        io_wait             : std_logic;                                        -- IO wait (active high) for Paula  
        io_dout             : std_logic_vector(15 downto 0);                    -- response data (paula_floppy only; userio has none)
        ldata               : std_logic_vector(14 downto 0);                    -- left audio channel
        rdata               : std_logic_vector(14 downto 0);                    -- right audio channel
        ldata_okk           : std_logic_vector(8 downto 0);                     -- left audio channel OK signal (active high)
        rdata_okk           : std_logic_vector(8 downto 0);                     -- right audio channel OK signal (active high)
        trackdisp           : std_logic_vector(7 downto 0);                     -- disk track display (for userio)
        secdisp             : std_logic_vector(13 downto 0);                    -- disk sector display (for userio)    
        floppy_fwr          : std_logic;                                        -- floppy drive motor frequency (for userio)
        floppy_frd          : std_logic;                                        -- floppy drive motor direction (for userio)
    end record;

    -- Record type for Denise output signals. This is used to group all Denise output signals into a single record for easier handling and passing to submodules.
    type denise_out_type is record
        data_out            : std_logic_vector(15 downto 0);                    -- Denise data output
        red                 : std_logic_vector(7 downto 0);                     -- red video output (8-bit)
        green               : std_logic_vector(7 downto 0);                     -- green video output (8-bit)  
        blue                : std_logic_vector(7 downto 0);                     -- blue video output (8-bit)
        hires               : std_logic;                                        -- high resolution mode (1=hires, 0=lores)
        shres               : std_logic;                                        -- super high resolution mode (1=shres, 0=lores/hires)
    end record; 

    -- Record type for Gary output signals. This is used to group all Gary output signals into a single record for easier handling and passing to submodules.
    type gary_out_type is record
        ram_address_out     : std_logic_vector(23 downto 1);                    -- full ram address output to make memory mapping easier
        data_out            : std_logic_vector(15 downto 0);                    -- Data Out to CPU
        custom_data_in      : std_logic_vector(15 downto 0);                    -- Data Out to Custom Chips
        ram_data_in         : std_logic_vector(15 downto 0);                    -- Data Out to RAM
        dbs                 : std_logic;                                        -- Data Bus slow down (1=slow, 0=fast) for Gary to control the speed of the data bus
        xbs                 : std_logic;                                        -- cross bridge select, active dbr prevents access to the cross bridge (1=select, 0=not selected)
        ram_rd              : std_logic;                                        -- RAM read strobe (active high)
        ram_hwr             : std_logic;                                        -- RAM high byte write strobe (active high)
        ram_lwr             : std_logic;                                        -- RAM low byte write strobe (active high)
        sel_reg             : std_logic;                                        -- register select (active high) for Gary to control the selection of the registers    
        sel_chip            : std_logic_vector(3 downto 0);                     -- select chip memory
        sel_slow            : std_logic_vector(2 downto 0);                     -- select slowfast memory ($C0000)
        sel_kick            : std_logic;                                        -- select kickstart rom ($F80000)
        sel_kick1mb         : std_logic;                                        -- select 1MB kickstart rom 'upper' half
        sel_kick256kmirror  : std_logic;                                        -- mirror $fc-$ff to $f8, when rom_readonly and bootrom 
        sel_cia             : std_logic;                                        -- select CIA registers ($BFE001)
        sel_cia_a           : std_logic;                                        -- select CIA A ($BFE001)
        sel_cia_b           : std_logic;                                        -- select CIA B ($BFD000)
        sel_rtg             : std_logic;                                        -- select RTG registers ($DFF000)
        sel_rtc             : std_logic;                                        -- select RTC registers ($DC0000)
        sel_ide             : std_logic;                                        -- select IDE registers ($DA0000)
        sel_gayle           : std_logic;                                        -- select GAYLE registers ($DE0000)  
        sel_toccata         : std_logic;                                        -- select TOCCATE registers ($E90000) (or whatever's specified by toccata_base)
        rom_readonly        : std_logic;                                        -- select ROM read-only mode (1=read-only, 0=read/write) for Gary to control the ROM access - when zero allows to write to $fc-$ff, blocks effect of kick256kmirror.
    end record;

    -- Record type for Gayle output signals. This is used to group all Gayle output signals into a single record for easier handling and passing to submodules.
    type gayle_out_type is record
        data_out            : std_logic_vector(15 downto 0);                    -- Gayle data output
        irq                 : std_logic;                                        -- Gayle interrupt request, active high
        nrdy                : std_logic;                                        -- Gayle not ready signal, active high -  fifo is not ready for reading 
        ide_req             : std_logic_vector(5 downto 0);                     -- Gayle IDE request signals    
        ide_readdata        : std_logic_vector(15 downto 0);                    -- Gayle IDE read data bus
        hdd_led             : std_logic;                                        -- Gayle LED (active high) - 1=IDE activity, 0=no activity
    end record;    

    -- Record type for ciaa output signals. This is used to group all ciaa output signals into a single record for easier handling and passing to submodules.
    type ciaa_out_type is record
        -- data_out            : std_logic_vector(7 downto 0);                     -- CIA A data output
        irq                 : std_logic;                                        -- CIA A interrupt request to CPU, active high 
        porta_out           : std_logic_vector(3 downto 0);                     -- CIA A port A output
        kbd_ack             : std_logic;                                        -- CIA A keyboard acknowledge (active high) while the CPU reads the keyboard SDR
        freeze              : std_logic;                                        -- CIA A freeze signal (active high) to freeze the CPU when the keyboard FIFO is full        
    end record;    

    -- Record type for ciab output signals. This is used to group all ciab output signals into a single record for easier handling and passing to submodules.
    type ciab_out_type is record
        -- data_out            : std_logic_vector(7 downto 0);                    -- CIA B data output
        -- data_out            : std_logic_vector(15 downto 0);                    -- CIA B data output
        irq                 : std_logic;                                       -- CIA B interrupt request to CPU, active high  
        porta_out            : std_logic_vector(7 downto 6);                    -- CIA B port A output
        portb_out            : std_logic_vector(7 downto 0);                    -- CIA B port B output
    end record;

    -- Record type for m68k Bridge output signals. This is used to group all m68k Bridge output signals into a single record for easier handling and passing to submodules.
    type m68k_bridge_out_type is record
        bls         : std_logic;                                        -- blitter slowdown, tells the blitter that CPU wants the bus
        dtack       : std_logic;                                        -- data acknowledge, tells the CPU that the bus is ready
        rd          : std_logic;                                        -- read strobe, tells the memory that the CPU wants to read
        hwr         : std_logic;                                        -- high byte write strobe, tells the memory that the CPU wants to write to the high byte
        lwr         : std_logic;                                        -- low byte write strobe, tells the memory that the CPU wants to write to the low byte
        address_out : std_logic_vector(23 downto 1);                    -- internal cpu address bus output
        data        : std_logic_vector(15 downto 0);                    -- external cpu data bus
        data_out    : std_logic_vector(15 downto 0);                    -- internal cpu data bus output
        rd_cyc      : std_logic;                                        -- early rd signal can be used to delay DTACK
        host_rdat   : std_logic_vector(15 downto 0);                    -- host read data bus
        host_ack    : std_logic;                                        -- host acknowledge signal
    end record;

    -- Record type for bank_mapper output signals. This is used to group all bank_mapper output signals into a single record for easier handling and passing to submodules.
    type bank_mapper_out_type is record
        bank    : std_logic_vector(7 downto 0);                                        -- bank select output
    end record;    

    -- Record type for ram bridge output signals. This is used to group all ram bridge output signals into a single record for easier handling and passing to submodules.
    type ram_bridge_out_type is record
        data_out            : std_logic_vector(15 downto 0);                    -- ram bridge bus data output
        bhe                 : std_logic;                                        -- ram bridge bus sram upper byte enable, active low
        ble                 : std_logic;                                        -- ram bridge bus sram lower byte enable, active low
        we                  : std_logic;                                        -- ram bridge bus sram write enable, active low
        oe                  : std_logic;                                        -- ram bridge bus sram  output enable, active low
        --address             : std_logic_vector(22 downto 1);                    -- ram bridge bus sram address output
        address             : std_logic_vector(23 downto 1);                    -- ram bridge bus sram address output
        data                : std_logic_vector(15 downto 0);                    -- ram bridge sram data bus
    end record;

    -- Record type for Cart output signals. This is used to group all Cart output signals into a single record for easier handling and passing to submodules.   
    type cart_out_type is record
        data_out             : std_logic_vector(15 downto 0);                    -- cart data output
        int7                 : std_logic;                                        -- cart interrupt request to CPU, active high
        sel_cart             : std_logic;                                        -- cart select, active high   
        ovr                  : std_logic;                                        -- cart overrun, active high
    end record;

    -- Record type for System Control output signals. This is used to group all System Control output signals into a single record for easier handling and passing to submodules.
    type system_control_out_type is record
        reset             : std_logic;                                        -- global synchronous system reset
    end record;

    -- Record type for Floppy.  Internal signals for the floppy drive interface. This is used to group all floppy drive interface signals into a single record for easier handling and passing to submodules.
    type floppy_out_type is record
        motor          : std_logic;                                        -- floppy motor control, active high
        sel            : std_logic_vector(3 downto 0);                     -- floppy drive select, active high
        sel3           : std_logic;                                        -- floppy drive select 3, active high
        sel2           : std_logic;                                        -- floppy drive select 2, active high
        sel1           : std_logic;                                        -- floppy drive select 1, active high    
        sel0           : std_logic;                                        -- floppy drive select 0, active high
        side           : std_logic;                                        -- floppy drive side select, active high
        direc          : std_logic;                                        -- floppy drive direction select, active high
        step           : std_logic;                                        -- floppy drive step select, active high
        track0         : std_logic;                                        -- floppy drive track 0 detect, active high
        change         : std_logic;                                        -- floppy drive change detect, active high
        ready          : std_logic;                                        -- floppy drive ready detect, active high
        wprot          : std_logic;                                        -- floppy drive write protect detect, active high    
        --index          : std_logic;                                        -- floppy drive index pulse, active high
        fdd_led        : std_logic;                                        -- floppy disk drive LED (active high)

        -- FIFO / Track Display
        -- Note: The trackdisp and secdisp signals are used for displaying the current track and sector of the floppy drive, respectively. These signals are typically used for user interface purposes, such as showing the user which track and sector are currently being accessed on the floppy disk.
        -- Note: Not connected, something that maybe useful for later on Screen overlays or for debugging purposes. The trackdisp and secdisp signals are not connected to any external pins or modules in the current design, but they could be used in the future for displaying the current track and sector information on a user interface or for debugging purposes.
        trackdisp      : std_logic_vector(7 downto 0);                     -- floppy drive track display (for userio)
        secdisp        : std_logic_vector(13 downto 0);                    -- floppy drive sector display (for userio)    
        floppy_fwr     : std_logic;                                       -- floppy drive motor frequency (for userio)
        floppy_frd     : std_logic;                                       -- floppy drive motor direction (for userio)
    end record;

    -- Record type for Toccata Sound Card Output Signals.  
    -- NOTE: The Toccata Sound Card is an optional sound card for the Amiga computer that provides high-quality audio output. The Toccata Sound Card Output Signals record type is used to group all Toccata Sound Card output signals into a single record for easier handling and passing to submodules.
    -- NOte Toccata Sound Card is not implemented in the current design, but the record type is defined for future use.
    type toccata_out_type is record
        data_out        : std_logic_vector(15 downto 0);                    -- Toccata Sound Card data output
        toc_int         : std_logic;                                        -- Toccata Sound Card interrupt request to CPU, active high
        out_left        : std_logic_vector(15 downto 0);                    -- Toccata Sound Card left audio channel output
        out_right       : std_logic_vector(15 downto 0);                    -- Toccata Sound Card right audio channel output
    end record;


    signal ip          : ip_type;
    signal op          : op_type;    
    signal int         : internal_signals_type;
    signal userio      : userio_signals_type;
    signal agnus       : agnus_out_type;
    signal paula       : paula_out_type;
    signal denise      : denise_out_type;
    signal gary        : gary_out_type;
    signal gayle       : gayle_out_type;
    signal ciaa        : ciaa_out_type;
    signal ciab        : ciab_out_type;
    signal bridge      : m68k_bridge_out_type;
    signal banks       : bank_mapper_out_type;
    signal ram_bridge  : ram_bridge_out_type;
    signal cart        : cart_out_type;
    signal sysctrl     : system_control_out_type;
    signal floppy      : floppy_out_type;
    signal toccata     : toccata_out_type;

    begin
    -- Map the entity ports to the input and output records for easier handling in the architecture.
    -- IN Ports Mapping
        -- M68k CPU Interface
        ip.cpu_address         <= cpu_address;
        ip.cpudata_in          <= cpudata_in;
        ip.cpu_as_n            <= cpu_as_n;
        ip.cpu_uds_n           <= cpu_uds_n;
        ip.cpu_lds_n           <= cpu_lds_n;
        ip.cpu_r_w             <= cpu_r_w;
        ip.cpu_reset_in_n      <= cpu_reset_in_n;
        ip.nmi_addr            <= nmi_addr;
        -- SRAM-style RAM interface
        ip.ramdata_in          <= ramdata_in;
        ip.chip48              <= chip48;
        -- System Reset and Clocks
        ip.rst_ext             <= rst_ext;
        ip.clk                 <= clk;
        ip.clk7_en             <= clk7_en;
        ip.clk7n_en            <= clk7n_en;
        ip.c1                  <= c1;
        ip.c3                  <= c3;
        ip.cck                 <= cck;
        ip.eclk                <= eclk;
        -- RS232 Pins
        ip.rxd                 <= rxd;
        ip.cts                 <= cts;
        ip.dsr                 <= dsr;
        ip.cd                  <= cd;
        ip.ri                  <= ri;
        -- Input Devices
        ip.joy1_n              <= joy1_n;
        ip.joy2_n              <= joy2_n;
        ip.joy3_n              <= joy3_n;
        ip.joy4_n              <= joy4_n;
        ip.joya1               <= joya1;
        ip.joya2               <= joya2;
        ip.mouse_btn           <= mouse_btn;    
        ip.kms_level           <= kms_level;
        ip.kbd_mouse_type      <= kbd_mouse_type;
        ip.kbd_mouse_data      <= kbd_mouse_data;
        -- Real-Time Clock 
        ip.rtc                 <= rtc;
        -- Host Interface
        ip.io_uio              <= io_uio;
        ip.io_fpga             <= io_fpga;
        ip.io_strobe           <= io_strobe;
        ip.io_din              <= io_din;
        -- Toccata Audio Interface
        ip.toccata_ena          <= toccata_ena;
        ip.toccata_base         <= toccata_base;
        -- IDE Interface
        ip.ide_ext_irq         <= ide_ext_irq;
        ip.ide_address         <= ide_address;
        ip.ide_write           <= ide_write;
        ip.ide_writedata       <= ide_writedata;
        ip.ide_read            <= ide_read;   

    -- OUT Ports Mapping
        -- M68k CPU Interface
        cpu_data            <= op.cpu_data;
        cpu_ipl_n           <= op.cpu_ipl_n;
        cpu_dtack_n         <= op.cpu_dtack_n;
        cpu_reset_n         <= op.cpu_reset_n;
        ovr                 <= op.ovr;
        --SRAM-style RAM interface
        ram_data            <= op.ram_data;
        ram_address         <= op.ram_address;
        ram_bhe_n           <= op.ram_bhe_n;
        ram_ble_n           <= op.ram_ble_n;
        ram_we_n            <= op.ram_we_n;
        ram_oe_n            <= op.ram_oe_n;
        -- System Reset 
        rst_out             <= op.rst_out;
        -- RS232 Pins
        txd                 <= op.txd;
        rts                 <= op.rts;
        dtr                 <= op.dtr;
        -- Input Devices
        kbd_ack             <= op.kbd_ack;
        -- LEDs
        pwr_led             <= op.pwr_led;
        fdd_led             <= op.fdd_led;
        hdd_led             <= op.hdd_led;
        -- Host Controller Interface       
        io_wait             <= op.io_wait;
        io_dout             <= op.io_dout;
        -- Video Output
        hsync_n             <= op.hsync_n;
        vsync_n             <= op.vsync_n;
        csync_n             <= op.csync_n;
        field1              <= op.field1;
        lace                <= op.lace;        
        hblank              <= op.hblank;
        vblank              <= op.vblank;
        red                 <= op.red;
        green               <= op.green;
        blue                <= op.blue;
        ar                  <= op.ar;
        scanline            <= op.scanline;
        ce_pix              <= op.ce_pix;
        res                 <= op.res;
        ntsc                <= op.ntsc;
        -- Audio Output
        aud_mix             <= op.aud_mix;
        ldata               <= op.ldata;
        rdata               <= op.rdata;
        ldata_okk           <= op.ldata_okk;
        rdata_okk           <= op.rdata_okk;
        toccata_aud_left    <= op.toccata_aud_left;
        toccata_aud_right   <= op.toccata_aud_right;
        -- User I/O Interface
        cpucfg              <= op.cpucfg;
        cachecfg            <= op.cachecfg;
        memcfg              <= op.memcfg;
        bootrom             <= op.bootrom;
        -- IDE Interface
        ide_ena             <= op.ide_ena;
        ide_fast            <= op.ide_fast;
        ide_req             <= op.ide_req;
        ide_readdata        <= op.ide_readdata;

           

    -- Drive the top-level output record fields 
    op.cpu_data        <= bridge.data;
    op.cpu_dtack_n     <= bridge.dtack;
    op.cpu_reset_n     <= int.cpu_reset_n;
    op.ovr             <= cart.ovr;
    op.ram_data        <= ram_bridge.data;
    op.ram_address     <= ram_bridge.address(22 downto 1);
    op.ram_bhe_n       <= ram_bridge.bhe;
    op.ram_ble_n       <= ram_bridge.ble;
    op.ram_we_n        <= ram_bridge.we;
    op.ram_oe_n        <= ram_bridge.oe;
    op.txd             <= paula.txd;
    op.kbd_ack         <= ciaa.kbd_ack;
    op.aud_mix         <= userio.aud_mix;
    op.ldata           <= paula.ldata;
    op.rdata           <= paula.rdata;
    op.ldata_okk       <= paula.ldata_okk;
    op.rdata_okk       <= paula.rdata_okk;
    op.cpucfg          <= userio.cpu_config;
    op.bootrom         <= userio.bootrom;
    op.ide_req         <= gayle.ide_req;
    op.ide_readdata    <= gayle.ide_readdata;
    op.toccata_aud_left  <= toccata.out_left;
    op.toccata_aud_right <= toccata.out_right;       
    op.ar                <= userio.ar;
    op.hsync_n           <= agnus.hsync;
    op.vsync_n           <= agnus.vsync;
    op.csync_n           <= agnus.csync;
    op.vblank            <= agnus.vblank;
    op.field1            <= agnus.field1;
    op.lace              <= agnus.lace; 
    op.red               <= denise.red;
    op.green             <= denise.green;
    op.blue              <= denise.blue;

    
    -- Reset
       int.mrst        <= userio.usrrst or ip.rst_ext;                  -- request to syscontrol  
       int.sys_reset   <= sysctrl.reset;                                -- stretched/synchronous reset from syscontrol
       int.reset       <= int.sys_reset or (not ip.cpu_reset_in_n);     -- global core reset (active high)  

       int.cpu_reset   <= int.reset or userio.cpurst;                   -- cpu reset request (active high)
       int.cpu_reset_n <= not int.cpu_reset;                            -- cpu reset request (active low)
       op.rst_out      <= int.reset;                                    -- Map to out port for external reset signal



    -- Chipset Configuration
    int.a1k <= userio.chipset_config(2);                                -- A1000 chipset configuration is set based on userio.chipset_config bit 2.
    int.ecs <= userio.chipset_config(4) or userio.chipset_config(3);
    int.aga <= userio.chipset_config(4);                                -- AGA chipset configuration is set based on userio.chipset_config bit 4.
    int.chip0 <= ((not cart.ovr) or (not bridge.rd) or agnus.dbr or userio.cpuhlt) and gary.sel_chip(0);  -- Chip select for chip memory

    -- Memory Configuration
    op.memcfg   <= userio.memory_config(7) & userio.memory_config(5 downto 0);  -- Memory configuration is set based on userio.memory_config bits. Bit 7 is used for a specific memory configuration, and bits 5 downto 0 are used for other memory settings.
    op.cachecfg <= userio.cache_config(2) & (not int.ovl) & (not int.ovl);    

    -- LED Control
    op.pwr_led <= not ciaa.porta_out(1);  -- Power LED control is mapped to CIA A port bit 1. Active low means the LED is on.
    op.fdd_led <= floppy.fdd_led;  -- Floppy disk drive LED control is mapped to the internal floppy.fdd_led signal. Active high means the LED is on.
    op.hdd_led <= gayle.hdd_led;   -- Hard disk drive LED control is mapped to the internal gayle.hdd_led signal. Active high means the LED is on.

    -- Video Output Control
    int.hblank  <= (not agnus.hde) when userio.blver /= "00" else agnus.hblank;   -- Horizontal blanking signal is determined by Agnus hde signal when blver is not "00", otherwise it uses Agnus hbl signal.
    op.hblank   <= int.hblank;                                               -- Map the internal horizontal blanking signal to the output port for external use.
    int.blank   <= (not agnus.hsync) or agnus.vblank;                        -- Video blanking signal.  Used by Denise.
    op.ntsc     <= int.ntsc;                                                 -- Map the internal NTSC signal to the output port for external use.
    op.ce_pix   <= (denise.shres and (userio.chipset_config(4) or userio.chipset_config(3))) or (denise.hires and ip.clk7n_en) or ip.clk7_en;  -- Pixel clock enable signal is determined by Denise shres and hires signals, as well as the chipset configuration and clock enables.
    op.res      <= (denise.shres and (userio.chipset_config(4) or userio.chipset_config(3))) & denise.hires;  -- Resolution signal is determined by Denise shres and hires signals, as well as the chipset configuration.
    op.scanline <= userio.scanline;                                          -- Map the internal scanline signal to the output port for external use.

    -- IDE Control Signal Mapping
    op.ide_ena   <= userio.ide_config(5);                                -- IDE enable signal is mapped to userio.ide_config bit 5. Active high means IDE is enabled.
    int.ide_fast <= (not userio.ide_config(5)) and userio.cpu_config(1);   -- IDE fast mode signal. Active high means IDE is in fast mode.        
    op.ide_fast  <= int.ide_fast;                                        -- Map the internal IDE fast mode signal to the output port for external use.
    int.hdc_ena  <= op.ide_ena and (not int.ide_fast);                   -- IDE hard disk controller enable signal. Active high means the IDE controller is enabled and not in fast mode.

    -- Paula Control Signal Mapping
    op.io_dout <= paula.io_dout;                    -- Paula IO data output is mapped to the output port for external use.
    op.io_wait <= paula.io_wait or userio.io_wait;  -- Paula IO wait signal is combined with userio IO wait signal for external use.
    --int.int2   <= ciaa.irq or (int.ide_fast when ip.ide_ext_irq = '1' else gayle.irq);  -- Interrupt signal mapping. If IDE external IRQ is enabled, the interrupt signal is determined by CIA A IRQ or IDE fast mode. Otherwise, it is determined by Gayle IRQ.
    int.int2_x   <= int.ide_fast when ip.ide_ext_irq = '1' else gayle.irq;   
    int.int2    <= ciaa.irq or int.int2_x;       
    int.int6   <= ciab.irq or toccata.toc_int;  -- Interrupt signal mapping. If CIA B IRQ is enabled, the interrupt signal is determined by CIA B IRQ or Toccata interrupt.
    int.cpu_ipl <= "000" when cart.int7 = '1' else paula.ipl;  -- CPU interrupt priority level is determined by cart interrupt and Paula interrupt signals.
    op.cpu_ipl_n <= int.cpu_ipl;  -- Map the internal CPU interrupt priority level signal to the output port for external use.

  
    -- Toccata Control Signal Mapping
    -- Note: Toccata Sound Card is not implemented in the current design, but the control signals are defined for future use.
    toccata.data_out <= (others => '0');  -- Toccata data output is set to all zeros for now.
    toccata.toc_int  <= '0';  -- Toccata interrupt signal is set to '0' for now.
    toccata.out_left <= (others => '0');  -- Toccata left audio channel output is set to all zeros for now.
    toccata.out_right <= (others => '0');  -- Toccata right audio channel output is set to all zeros for now.

    -- CIA Control Signal Mapping
    int.ciaa_porta_in <= userio.fire1 & userio.fire0 & floppy.ready & floppy.track0 & floppy.wprot & floppy.change;  -- CIA A port A input is mapped to a combination of userio fire buttons and floppy drive signals.
    int.ciaa_portb_in <= ip.joy4_n(0) & ip.joy4_n(1) & ip.joy4_n(2) & ip.joy4_n(3) & ip.joy3_n(0) & ip.joy3_n(1) & ip.joy3_n(2) & ip.joy3_n(3);  -- CIA A port B input is mapped to joystick signals.
    int.bridge_wr     <= bridge.hwr or bridge.lwr;      
    int.ciab_porta_in <= ip.cd & ip.cts & ip.dsr & (ip.ri and ip.joy3_n(4)) & '1' & ip.joy4_n(4);
    op.dtr            <= ciab.porta_out(7);  -- DTR signal is mapped to CIA B port A bit 7. Active high means DTR is asserted.
    op.rts            <= ciab.porta_out(6);  -- RTS signal is mapped to CIA B port A bit 6. Active high means RTS is asserted.

    -- Joystick Fire Button Mapping Data
    int.fire1_dat <= ciaa.porta_out(3);  -- Joystick fire button 1 data is mapped to CIA A port A bit 3.
    int.fire0_dat <= ciaa.porta_out(2);  -- Joystick fire button 0 data is mapped to CIA A port A bit 2.

    -- CPU Bridge Control Signal Mapping
    int.nrdy <= gayle.nrdy and bridge.rd_cyc;  -- Not ready signal is determined by Gayle NRDY and bridge read cycle signals. Active high means the CPU is not ready for data transfer.

    -- Userio Control Signal Mapping
    int.pot_cnt_en <= (agnus.sol and (not ip.c1) and (not ip.c3));

        -- Floppy Drive Control Signal Mapping 
    floppy.motor <= ciab.portb_out(7);  -- Floppy motor control signal is mapped to CIA B port bit 7. Active high means the motor is on.
    floppy.sel3  <= ciab.portb_out(6);  -- Floppy drive select 3 signal is mapped to CIA B port bit 6. Active high means drive 3 is selected.
    floppy.sel2  <= ciab.portb_out(5);  -- Floppy drive select 2 signal is mapped to CIA B port bit 5. Active high means drive 2 is selected.
    floppy.sel1  <= ciab.portb_out(4);  -- Floppy drive select 1 signal is mapped to CIA B port bit 4. Active high means drive 1 is selected.
    floppy.sel0  <= ciab.portb_out(3);  -- Floppy drive select 0 signal is mapped to CIA B port bit 3. Active high means drive 0 is selected.
    floppy.side  <= ciab.portb_out(2);  -- Floppy drive side select signal is mapped to CIA B port bit 2. Active high means side 1 is selected.
    floppy.direc <= ciab.portb_out(1);  -- Floppy drive direction select signal is mapped to CIA B port bit 1. Active high means the direction is set to a specific direction (e.g., forward).      
    floppy.step  <= ciab.portb_out(0);  -- Floppy drive step select signal is mapped to CIA B port bit 0. Active high means a step command is issued to the drive.  
    floppy.sel   <= ciab.portb_out(6 downto 3);  -- Floppy drive select signals are mapped to CIA B port bits 6 to 3.

    -- Data Multiplexing
    -- CPU Bridge receives the CPU data from the other custom chips and userio
    int.cpu_data_in <= gary.data_out
                    or int.cia_data_out
                    or gayle.data_out
                    or cart.data_out
                    or int.rtc_out
                    or toccata.data_out
                    ;
    -- Gary gets the data from the other custom chips and userio
    int.custom_data_out <= agnus.data_out
                       or paula.data_out
                       or denise.data_out  
                       or userio.data_out
                    ;                       
                

    -- Processes
    ntsc_proc: process (ip.clk)
    begin
        if rising_edge(ip.clk) then
            if (ip.clk7_en = '1') and (int.reset = '1') then
                int.ntsc <= userio.chipset_config(1);
            end if;
        end if;
    end process;

    -- Kickstart Overlay Control Process
    kickstart_overlay_proc: process (ip.clk)
    begin
        if rising_edge(ip.clk) then
            if int.cpu_reset = '1' then
                int.ovl <= '1';
            elsif gary.sel_cia_a = '1' and (bridge.lwr = '1' or bridge.hwr = '1') then
                int.ovl <= '0';
            end if;
        end if;
    end process;

    --Instantiate Custom Chips-----------------------------------------------------------------------------------------------------------------

    -- Instantiate User IO
    USERIO_inst : entity work.userio_wrapper
        -- Need wrapper for userio to pass all signals as a record type
        port map (
             clk                => ip.clk
            ,clk7_en            => ip.clk7_en
            ,reset              => int.reset

            -- Input Signals            
            ,io_din             => ip.io_din
            ,io_ena             => ip.io_uio
            ,io_strobe          => ip.io_strobe
            ,fire0_dat          => int.fire0_dat
            ,fire1_dat          => int.fire1_dat
            ,joy1               => ip.joy1_n  
            ,joy2               => ip.joy2_n
            ,joy_ana1           => ip.joya1
            ,joy_ana2           => ip.joya2
            ,data_in            => gary.custom_data_in
            ,host_ack           => bridge.host_ack
            ,host_rdat          => bridge.host_rdat

            ,kbd_mouse_data     => ip.kbd_mouse_data
            ,kbd_mouse_type     => ip.kbd_mouse_type
            ,kms_level          => ip.kms_level
            ,mouse_btn          => ip.mouse_btn
            ,pot_cnt_en         => int.pot_cnt_en  
            ,reg_address_in     => agnus.reg_address_out

            -- output Signals
            ,io_wait         => userio.io_wait
            ,data_out        => userio.data_out
            ,fire0           => userio.fire0
            ,fire1           => userio.fire1
            ,aud_mix         => userio.aud_mix
            ,memory_config   => userio.memory_config
            ,chipset_config  => userio.chipset_config
            ,floppy_config   => userio.floppy_config
            ,scanline        => userio.scanline
            ,ar              => userio.ar
            ,blver           => userio.blver
            ,ide_config      => userio.ide_config
            ,cpu_config      => userio.cpu_config
            ,cache_config    => userio.cache_config
            ,bootrom         => userio.bootrom
            ,usrrst          => userio.usrrst
            ,cpurst          => userio.cpurst
            ,cpuhlt          => userio.cpuhlt
            ,host_cs         => userio.host_cs
            ,host_adr        => userio.host_adr
            ,host_we         => userio.host_we
            ,host_bs         => userio.host_bs
            ,host_wdat       => userio.host_wdat
        );


    -- Instantiate Agnus
    AGNUS_inst : entity work.agnus_wrapper
        -- Need a wrapper for agnus to pass all signals as a record type
        port map (
             clk             => ip.clk
            ,clk7_en         => ip.clk7_en
            ,cck             => ip.cck
            ,reset           => int.reset
            ,aen             => gary.sel_reg    
            ,rd              => bridge.rd
            ,hwr             => bridge.hwr
            ,lwr             => bridge.lwr
            ,data_in         => gary.custom_data_in
            ,data_out        => agnus.data_out
            ,address_in      => bridge.address_out 
            ,address_out     => agnus.address_out
            ,reg_address_out => agnus.reg_address_out
            ,cpu_custom      => agnus.cpu_custom
            ,dbr             => agnus.dbr
            ,dbwe            => agnus.dbwe
            ,hsync           => agnus.hsync
            ,vsync           => agnus.vsync
            ,csync           => agnus.csync
            ,hde             => agnus.hde
            ,field1          => agnus.field1
            ,lace            => agnus.lace
            ,hblank          => agnus.hblank
            ,vblank          => agnus.vblank
            ,sol             => agnus.sol
            ,sof             => agnus.sof
            ,vbl_int         => agnus.vbl_int
            ,strhor_denise   => agnus.strhor_denise
            ,strhor_paula    => agnus.strhor_paula
            ,htotal          => agnus.htotal
            ,harddis         => agnus.harddis
            ,varbeamen       => agnus.varbeamen
            ,int3            => agnus.int3
            ,audio_dmal      => paula.audio_dmal
            ,audio_dmas      => paula.audio_dmas
            ,disk_dmal       => paula.disk_dmal
            ,disk_dmas       => paula.disk_dmas
            ,bls             => bridge.bls
            ,ntsc            => int.ntsc            
            ,a1k             => int.a1k
            ,ecs             => int.ecs            
            ,aga             => int.aga
            ,floppy_speed    => userio.floppy_config(0)        
        );

    -- Instantiate Paula
    PAULA_inst : entity work.paula_wrapper
        port map (
             clk                => ip.clk
            ,clk7_en            => ip.clk7_en
            ,clk7n_en           => ip.clk7n_en
            ,cck                => ip.cck
            ,reset              => int.reset
            ,reg_address_in     => agnus.reg_address_out
            ,data_in            => gary.custom_data_in
            ,data_out           => paula.data_out
            ,txd                => paula.txd
            ,rxd                => ip.rxd
            ,ntsc               => int.ntsc
            ,sof                => agnus.sof
            ,strhor             => agnus.strhor_paula
            ,vblint             => agnus.vbl_int
            ,int2               => int.int2
            ,int3               => agnus.int3
            ,int6               => int.int6
            ,ipl                => paula.ipl
            ,audio_dmal         => paula.audio_dmal
            ,audio_dmas         => paula.audio_dmas
            ,disk_dmal          => paula.disk_dmal
            ,disk_dmas          => paula.disk_dmas 
            ,step               => floppy.step
            ,direc              => floppy.direc
            ,sel                => floppy.sel
            ,side               => floppy.side
            ,motor              => floppy.motor
            ,track0             => floppy.track0
            ,ready              => floppy.ready
            ,change             => floppy.change
            ,wprot              => floppy.wprot            
            ,fdd_led            => floppy.fdd_led
            ,floppy_drives      => userio.floppy_config(3 downto 2)
            ,index              => paula.index
            ,io_ena             => ip.io_fpga
            ,io_strobe          => ip.io_strobe
            ,io_wait            => paula.io_wait            
            ,io_din             => ip.io_din
            ,io_dout            => paula.io_dout
            ,ldata              => paula.ldata
            ,rdata              => paula.rdata
            ,ldata_okk          => paula.ldata_okk
            ,rdata_okk          => paula.rdata_okk
            ,trackdisp          => paula.trackdisp
            ,secdisp            => paula.secdisp
            ,floppy_fwr         => paula.floppy_fwr
            ,floppy_frd         => paula.floppy_frd
        );        

    -- Instantiate Denise
    DENISE_inst : entity work.denise_M65
        port map (
             clk             => ip.clk
            ,clk7_en         => ip.clk7_en
            ,c1              => ip.c1
            ,c3              => ip.c3   
            ,cck             => ip.cck
            ,reset           => int.reset              
            ,strhor          => agnus.strhor_denise
            ,reg_address_in  => agnus.reg_address_out
            ,data_in         => gary.custom_data_in
            ,chip48          => ip.chip48
            ,data_out        => denise.data_out                        
            ,blank           => int.blank   
            ,red             => denise.red
            ,green           => denise.green
            ,blue            => denise.blue
            ,a1k             => int.a1k
            ,ecs             => int.ecs
            ,aga             => int.aga
            ,hires           => denise.hires        
            ,shres           => denise.shres
        );

    -- Instantiate Gary
    GARY_inst : entity work.gary
        port map (
             cpu_address_in     => bridge.address_out
            ,dma_address_in     => agnus.address_out             
            ,ram_address_out    => gary.ram_address_out
            ,cpu_data_out       => bridge.data_out  -- TBD
            ,cpu_data_in        => gary.data_out  
            ,custom_data_out    => int.custom_data_out
            ,custom_data_in     => gary.custom_data_in
            ,ram_data_out       => ram_bridge.data_out   --- Check if this is correct !!!
            ,ram_data_in        => gary.ram_data_in
            ,cpu_rd             => bridge.rd
            ,cpu_hwr            => bridge.hwr
            ,cpu_lwr            => bridge.lwr
            ,cpu_hlt            => userio.cpuhlt
            ,ovl                => int.ovl         
            ,dbr                => agnus.dbr
            ,dbwe               => agnus.dbwe
            ,dbs                => gary.dbs
            ,xbs                => gary.xbs
            ,memory_config      => userio.memory_config(3 downto 0)
            ,hdc_ena            => int.hdc_ena      -- enables hdd interface
            ,toccata_ena        => ip.toccata_ena   -- enables toccata interface
            ,toccata_base       => ip.toccata_base  -- base address for toccata interface
            ,ram_rd             => gary.ram_rd
            ,ram_hwr            => gary.ram_hwr
            ,ram_lwr            => gary.ram_lwr
            ,ecs                => int.ecs
            ,a1k                => int.a1k
            ,sel_chip           => gary.sel_chip
            ,sel_slow           => gary.sel_slow
            ,sel_kick           => gary.sel_kick
            ,sel_kick1mb        => gary.sel_kick1mb
            ,sel_kick256kmirror => gary.sel_kick256kmirror
            ,sel_cia            => gary.sel_cia
            ,sel_reg            => gary.sel_reg
            ,sel_cia_a          => gary.sel_cia_a
            ,sel_cia_b          => gary.sel_cia_b
            ,sel_ide            => gary.sel_ide
            ,sel_gayle          => gary.sel_gayle
            ,sel_rtc            => gary.sel_rtc
            ,sel_toccata        => gary.sel_toccata
            ,sel_rtg            => gary.sel_rtg                    
            ,reset              => int.reset       
            ,clk                => ip.clk
            ,rom_readonly       => gary.rom_readonly            
            ,bootrom         => userio.bootrom
        );  

    -- Instantiate Gayle
    GAYLE_inst : entity work.gayle
        port map (
             clk             => ip.clk  
            ,reset           => int.reset   
            ,addr            => bridge.address_out
            ,data_in         => bridge.data_out
            ,data_out        => gayle.data_out            
            ,rd              => bridge.rd
            ,wr              => bridge.hwr
            ,sel_ide         => gary.sel_ide
            ,sel_gayle       => gary.sel_gayle
            ,irq             => gayle.irq
            ,nrdy            => gayle.nrdy
            ,longword         => '0'  -- TBD  Need to check what the Original Minimig does with this signal. It might be used for IDE access, but it is not clear from the current design. For now, it is set to '0' as a placeholder.
            ,ide_req         => gayle.ide_req                        
            ,ide_address      => ip.ide_address
            ,ide_write        => ip.ide_write
            ,ide_writedata    => ip.ide_writedata
            ,ide_read         => ip.ide_read
            ,ide_readdata    => gayle.ide_readdata            
            ,led             => gayle.hdd_led           

        );  

    -- Instantiate CIA A
    CIAA_inst : entity work.ciaa
        port map (
             clk             => ip.clk
            ,clk7_en         => ip.clk7_en
            ,clk7n_en        => ip.clk7n_en
            ,aen             => gary.sel_cia_a                      -- Address enable (chip select)
            ,rd              => bridge.rd                           -- Read enable
            ,wr              => int.bridge_wr                       -- Write enable
            ,reset           => int.reset  
            ,rs              => bridge.address_out(11 downto 8)     -- Register select (address lines A11-A8)
            ,data_in         => bridge.data_out(7 downto 0)         -- Data input (lower byte of CPU data bus)
            ,data_out        => int.cia_data_out(7 downto 0)
            ,tick            => agnus.vsync                         -- Tick signal from Agnus for timing purposes                            
            ,eclk            => ip.eclk
            ,irq             => ciaa.irq
            ,porta_in        => int.ciaa_porta_in  
            ,porta_out       => ciaa.porta_out
            ,portb_in        => int.ciaa_portb_in
            ,kbd_mouse_type  => ip.kbd_mouse_type
            ,kms_level       => ip.kms_level
            ,kbd_mouse_data  => ip.kbd_mouse_data                     
            ,kbd_ack         => ciaa.kbd_ack            
            ,freeze          => ciaa.freeze
            ,hrtmon_en       => userio.memory_config(6)             -- Heartbeat monitor enable (from user I/O memory configuration)
        );  

    -- Instantiate CIA B
    CIAB_inst : entity work.ciab
        port map (
             clk             => ip.clk
            ,clk7_en         => ip.clk7_en
            ,aen             => gary.sel_cia_b
            ,rd              => bridge.rd
            ,wr              => int.bridge_wr
            ,reset           => int.reset
            ,rs              => bridge.address_out(11 downto 8)
            ,data_in         => bridge.data_out(15 downto 8)
            ,data_out        => int.cia_data_out(15 downto 8)
            ,tick            => agnus.hsync
            ,eclk            => ip.eclk(8)
            ,irq             => ciab.irq        -- INT6
            ,flag            => paula.index
            ,porta_in        => int.ciab_porta_in  
            ,porta_out       => ciab.porta_out  
            ,portb_out       => ciab.portb_out  
        );
            
    -- Instantiate m68k Bridge
    M68K_BRIDGE_inst : entity work.minimig_m68k_bridge_wrapper
    
        port map (
             clk             => ip.clk
            ,clk7_en         => ip.clk7_en
            ,clk7n_en        => ip.clk7n_en
            ,c1              => ip.c1
            ,c3              => ip.c3
            ,cck             => ip.cck
            ,eclk            => ip.eclk                        
            ,vpa             => gary.sel_cia
            ,dbr             => agnus.dbr
            ,dbs             => gary.dbs
            ,xbs             => gary.xbs
            ,nrdy            => int.nrdy     
            ,bls             => bridge.bls
            ,memory_config   => userio.memory_config(3 downto 0)
            ,as              => ip.cpu_as_n
            ,lds             => ip.cpu_lds_n
            ,uds             => ip.cpu_uds_n
            ,r_w             => ip.cpu_r_w
            ,dtack           => bridge.dtack
            ,rd              => bridge.rd
            ,rd_cyc          => bridge.rd_cyc
            ,hwr             => bridge.hwr
            ,lwr             => bridge.lwr
            ,address         => ip.cpu_address
            ,address_out     => bridge.address_out            
            ,cpudatain       => ip.cpudata_in
            ,data            => bridge.data
            ,data_out        => bridge.data_out
            ,data_in         => int.cpu_data_in
            ,cpu_reset       => int.cpu_reset 
            ,cpu_halt        => userio.cpuhlt
            ,host_cs         => userio.host_cs
            ,host_adr        => userio.host_adr(23 downto 1)
            ,host_we         => userio.host_we
            ,host_bs         => userio.host_bs
            ,host_wdat       => userio.host_wdat
            ,host_rdat       => bridge.host_rdat
            ,host_ack        => bridge.host_ack
        );

    --- Instantiate bank_mapper
    BANK_MAPPER_inst : entity work.minimig_bankmapper
        port map (
             chip0          => int.chip0         -- Chip RAM select signal from Mix signals
            ,chip1          => gary.sel_chip(1)  -- Chip RAM select signal from Gary
            ,chip2          => gary.sel_chip(2)  -- Chip RAM select signal from Gary
            ,chip3          => gary.sel_chip(3)  -- Chip RAM select signal from Gary
            ,slow0          => gary.sel_slow(0)  -- Slow RAM select signal from Gary
            ,slow1          => gary.sel_slow(1)  -- Slow RAM select signal from Gary
            ,slow2          => gary.sel_slow(2)  -- Slow RAM select signal from Gary
            ,kick           => gary.sel_kick
            ,kick1mb        => gary.sel_kick1mb
            ,kick256kmirror => gary.sel_kick256kmirror    
            ,cart           => cart.sel_cart
            ,memory_config  => userio.memory_config(3 downto 0)
            ,bank           => banks.bank
        );

    -- Instantiate ram_bridge
    RAM_BRIDGE_inst : entity work.minimig_sram_bridge_wrapper
        port map (
             clk             => ip.clk
            ,c1              => ip.c1
            ,c3              => ip.c3
            ,bank           => banks.bank                        
            ,address_in     => gary.ram_address_out
            ,data_in        => gary.ram_data_in
            ,data_out       => ram_bridge.data_out
            ,rd             => gary.ram_rd
            ,hwr            => gary.ram_hwr
            ,lwr            => gary.ram_lwr
            ,bhe            => ram_bridge.bhe
            ,ble            => ram_bridge.ble
            ,we             => ram_bridge.we
            ,oe             => ram_bridge.oe
            ,address        => ram_bridge.address(22 downto 1)
            ,data           => ram_bridge.data
            ,ramdata_in     => ip.ramdata_in                        
        );
    -- minimig_sram_bridge_wrapper is designed to handle 16MB of addressing space, which requires 24 address lines. 
    -- However, the current implementation only uses 23 address lines (address(22 downto 1)). 
    -- To ensure proper addressing for the 16MB range, we need to set the highest address bit (address(23)) to '0'. 
    -- This effectively limits the addressable range to 16MB, as the highest bit being '0' means that addresses from 0x000000 to 0xFFFFFF are valid.
    -- Plus, not setting address(23) to '0' results in bit 23 being undriven, which can lead to unpredictable behavior in the memory addressing.
    ram_bridge.address(23) <= '0';  -- Set the highest address bit to '0' for 16MB addressing


    -- Instantiate cart
    CART_inst : entity work.cart_wrapper    
        port map (    
                 clk             => ip.clk
                ,clk7_en         => ip.clk7_en
                ,clk7n_en        => ip.clk7n_en                        
                ,cpu_rst         => int.cpu_reset_n
                ,cpu_address_in  => bridge.address_out
                ,cpu_as          => ip.cpu_as_n
                ,cpu_rd          => bridge.rd
                ,cpu_hwr         => bridge.hwr  
                ,cpu_lwr         => bridge.lwr  
                ,nmi_addr        => ip.nmi_addr
                ,reg_address_in  => agnus.reg_address_out
                ,reg_data_in     => gary.custom_data_in
                ,dbr             => agnus.dbr
                ,ovl             => int.ovl      
                ,freeze          => ciaa.freeze
                ,cart_data_out   => cart.data_out
                ,int7            => cart.int7
                ,sel_cart        => cart.sel_cart
                ,ovr             => cart.ovr
                ,cpuhlt          => userio.cpuhlt                      
            );

    -- instantiate system control
    SYSTEM_CONTROL_inst : entity work.minimig_syscontrol
        port map (
             clk             => ip.clk
            ,clk7_en         => ip.clk7_en            
            ,cnt             => agnus.sof
            ,mrst            => int.mrst 
            ,reset           => sysctrl.reset
        );
    -- RTC
    RTC_inst : entity work.rtc
        port map (
             clk                => ip.clk
            ,rtc                => ip.rtc
            ,sel_rtc            => gary.sel_rtc
            ,cpu_rd             => bridge.rd
            ,cpu_address_out    => bridge.address_out
            ,rtc_out            => int.rtc_out
        );


    end architecture;    
