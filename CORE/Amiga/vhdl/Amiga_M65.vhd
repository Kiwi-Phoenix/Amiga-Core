-- Amiga Core Module
-- 
-- Encapsulates the CPU, MiniMig, and RAM modules, etc.  
-- Essentially the Core of the Amiga.  All other modules either feed into or receive output
-- from this module.    
--
-- The CPU and MiniMig (Custom Chip) orginated / ported from MiSTer minimig.
--
-- August 2026      - David Raynor (Kiwi) - Initial version for Mega65 Amiga Core
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;   

library work;
use work.amiga_globals.all;
use work.amiga_debug_pkg.all;

entity Amiga_M65 is
    port (
        main_clk            : in std_logic;                                          -- Main clock input (28.375 MHz)
        amiga_reset         : in std_logic;                                          -- Reset input (active high)  

        clk7_en             : out std_logic;                                         -- 7 MHz clock enable output (active high)
        clk7n_en            : out std_logic;                                         -- Neg 7 MHz clock enable output (active high)

        -- LEDs
        pwr_led             : out std_logic;                                         -- power LED (active high) 
        fdd_led             : out std_logic;                                         -- floppy LED (active high)
        hdd_led             : out std_logic;                                         -- hard disk LED (active high)        

        -- Audio
        audio_l             : out std_logic_vector(14 downto 0);                     -- left channel audio output (signed 16-bit)
        audio_r             : out std_logic_vector(14 downto 0);                     -- right channel audio output (signed 16-bit)
        ldata_okk           : out std_logic_vector(8 downto 0);                      -- left channel audio output (9-bit) for OKK audio DAC
        rdata_okk           : out std_logic_vector(8 downto 0);                      -- right channel audio output (9-bit) for OKK audio DAC
        aud_mix             : out std_logic_vector(1 downto 0);                    -- audio mix output (2-bit) for OKK audio DAC
        
        -- Video
        vga_r               : out std_logic_vector(7 downto 0);                      -- VGA red output (8-bit)
        vga_g               : out std_logic_vector(7 downto 0);                      -- VGA green output (8-bit)
        vga_b               : out std_logic_vector(7 downto 0);                      -- VGA blue output (8-bit)
        vga_hsync           : out std_logic;                                         -- VGA horizontal sync output (active low)
        vga_vsync           : out std_logic;                                         -- VGA vertical sync output (active low)
        vga_csync           : out std_logic;                                         -- VGA composite sync output (active low)
        hblank              : out std_logic;                                         -- Horizontal blanking (active high)
        vblank              : out std_logic;                                         -- Vertical blanking (active high) 
        vid_res             : out std_logic_vector(1 downto 0);                      -- Video resolution output (00=320x256, 01=640x256, 10=320x512, 11=640x512)
        field1              : out std_logic;                                         -- Video field output (active high for field 1, active low for field 0)
        ce_pix              : out std_logic;                                         -- Pixel clock output (active high)
        lace                : out std_logic;                                         -- Video interlace output (active high for interlace, active low for non-interlace)

        -- Keyboard / Mouse Input
        kbd_mouse_type      : in std_logic_vector(1 downto 0);                       -- Keyboard / Mouse type input (00=none, 01=PS/2, 10=USB, 11=reserved)
        kbd_mouse_data      : in std_logic_vector(7 downto 0);                       -- Keyboard / Mouse data input (8-bit)
        kms_level           : in std_logic;                                          -- Keyboard / Mouse level input (active high for PS/2, active low for USB)
        mouse_btn           : in std_logic_vector(2 downto 0);                       -- Mouse button input (active high for left, middle, right buttons)
        kbd_ack             : out std_logic;                                          -- Keyboard / Mouse acknowledge output (active high)

        -- Joystick Input
        joy1_n              : in std_logic_vector(15 downto 0);                      -- Joystick 1 input (active low, 16-bit)
        joy2_n              : in std_logic_vector(15 downto 0);                      -- Joystick 2 input (active low, 16-bit)
        
        -- RTC
        rtc                 : in std_logic_vector(64 downto 0);                      -- Real-time clock input (65-bit)

        -- User I/O - lives inside the minimig module
        io_uio              : in std_logic;                                          -- User I/O input (active high)
        io_strobe           : in std_logic;                                          -- User I/O strobe input (active high)
        io_din              : in std_logic_vector(15 downto 0);                      -- User I/O data input (16-bit)
        io_wait             : out std_logic;                                         -- User I/O wait output (active high)
        io_fpga             : in  std_logic;                                         -- User I/O FPGA input (active high) (Paula)
        io_dout             : out std_logic_vector(15 downto 0);                     -- User I/O data output (16-bit)

        -- RAM  
        -- ram_addr_o         : out std_logic_vector(22 downto 1);                     -- RAM address output (22-bit)
        -- ram_bhe_n_o        : out std_logic;                                         -- RAM byte high enable output (active low)
        -- ram_ble_n_o        : out std_logic;                                         -- RAM byte low enable output (active low)
        -- ram_data_o         : out std_logic_vector(15 downto 0);                     -- RAM data output (16-bit)
        -- ram_we_n_o         : out std_logic;                                         -- RAM write enable output (active low)
        -- ram_oe_n_o         : out std_logic;                                         -- RAM output enable output (active low)
        -- ram_data_i         : in std_logic_vector(15 downto 0)                       -- RAM data input (16-bit)

        -- Amiga Cold Reset Signals
        amiga_chip_scrub      : in std_logic;                                         -- Amiga Chip RAM scrub input (active high)
        amiga_chip_scrub_addr : in std_logic_vector(17 downto 0);                     -- Amiga Chip RAM scrub address input (22-bit)
        -- QNICE
         qnice_clk_i         : in std_logic;                                         -- QNICE clock input (active high)
         qnice_dev_id_i      : in std_logic_vector(15 downto 0);                     -- QNICE device ID input (16-bit)
         qnice_dev_ce_i      : in std_logic;                                         -- QNICE device chip enable input (active high)
         qnice_dev_we_i      : in std_logic;                                         -- QNICE device write enable input (active high)
         qnice_dev_addr_i    : in std_logic_vector(27 downto 0);                     -- QNICE device address input (28-bit)
         qnice_dev_data_i    : in std_logic_vector(15 downto 0);                     -- QNICE device data input (16-bit)
         qnice_dev_data_o    : out std_logic_vector(15 downto 0)                     -- QNICE device data output (16-bit)

    );

end entity;    


architecture rtl of Amiga_M65 is
    
    -- Define the Signal Record types -------------------------------------------------------------------------------------------------------------

    type IP_TYPE is record
        -- IN ports record type
        main_clk            : std_logic;                                          -- Main clock input (28.375 MHz)
        amiga_reset         : std_logic;                                          -- Reset input (active high)
        kbd_mouse_type      : std_logic_vector(1 downto 0);                       -- Keyboard / Mouse type input (00=none, 01=PS/2, 10=USB, 11=reserved)
        kbd_mouse_data      : std_logic_vector(7 downto 0);                       -- Keyboard / Mouse data input (8-bit)
        kms_level           : std_logic;                                          -- Keyboard / Mouse level input (active high for PS/2, active low for USB)    
        mouse_btn           : std_logic_vector(2 downto 0);                       -- Mouse button input (active high for left, middle, right buttons)
        joy1_n              : std_logic_vector(15 downto 0);                      -- Joystick 1 input (active low, 16-bit)
        joy2_n              : std_logic_vector(15 downto 0);                      -- Joystick 2 input (active low, 16-bit)
        rtc                 : std_logic_vector(64 downto 0);                      -- Real-time clock input (65-bit)
        io_uio              : std_logic;                                          -- User I/O input (active high)
        io_strobe           : std_logic;                                          -- User I/O strobe input (active high)
        io_din              : std_logic_vector(15 downto 0);                      -- User I/O data input (16-bit)
        io_fpga             : std_logic;                                          -- User I/O FPGA input (active high) (Paula)
        
        --ram_data_i         : std_logic_vector(15 downto 0);                      -- RAM data input (16-bit)
        
        qnice_clk_i         : std_logic;                                          -- QNICE clock input (active high)
        qnice_dev_id_i      : std_logic_vector(15 downto 0);                      -- QNICE device ID input (16-bit)
        qnice_dev_ce_i      : std_logic;                                          -- QNICE device chip enable input (active high)
        qnice_dev_we_i      : std_logic;                                          -- QNICE device write enable input (active high)
        qnice_dev_addr_i    : std_logic_vector(27 downto 0);                      -- QNICE device address input (28-bit)
        qnice_dev_data_i    : std_logic_vector(15 downto 0);                      -- QNICE device data input (16-bit)

        amiga_chip_scrub      : std_logic;                                          -- Amiga Chip RAM scrub input (active high)
        amiga_chip_scrub_addr : std_logic_vector(17 downto 0);                      -- Amiga Chip RAM scrub address input (22-bit)

    end record;
    attribute description of IP_TYPE : type is "IN Ports for Amiga_M65 module";
    
    type OP_TYPE is record
        -- OUT ports record type
        clk7_en             : std_logic;                                          -- 7 MHz clock enable output (active high)
        clk7n_en            : std_logic;                                          -- Neg 7 MHz clock enable output (active high)
        pwr_led             : std_logic;                                          -- power LED (active high) 
        fdd_led             : std_logic;                                          -- floppy LED (active high)
        hdd_led             : std_logic;                                          -- hard disk LED (active high)
        audio_l             : std_logic_vector(14 downto 0);                      -- left channel audio output (signed 15-bit)
        audio_r             : std_logic_vector(14 downto 0);                      -- right channel audio output (signed 15-bit)
        ldata_okk           : std_logic_vector(8 downto 0);                       -- left channel audio output (9-bit) for OKK audio DAC    
        rdata_okk           : std_logic_vector(8 downto 0);                       -- right channel audio output (9-bit) for OKK audio DAC   
        aud_mix             : std_logic_vector(1 downto 0);                       -- audio mix output (2-bit) for OKK audio DAC
        vga_r               : std_logic_vector(7 downto 0);                       -- VGA red output (8-bit)
        vga_g               : std_logic_vector(7 downto 0);                       -- VGA green output (8-bit)
        vga_b               : std_logic_vector(7 downto 0);                       -- VGA blue output (8-bit)
        vga_hsync           : std_logic;                                          -- VGA horizontal sync output (active low)
        vga_vsync           : std_logic;                                          -- VGA vertical sync output (active low)
        vga_csync           : std_logic;                                          -- VGA composite sync output (active low)
        hblank              : std_logic;                                          -- Horizontal blanking (active high)
        vblank              : std_logic;                                          -- Vertical blanking (active high) 
        vid_res             : std_logic_vector(1 downto 0);                       -- Video resolution output (00=320x256, 01=640x256, 10=320x512, 11=640x512)
        field1              : std_logic;                                          -- Video field output (active high for field 1, active low for field 0)
        ce_pix              : std_logic;                                          -- Pixel clock output (active high)
        lace                : std_logic;                                          -- Video interlace output (active high for interlace, active low for non-interlace)
        kbd_ack             : std_logic;                                          -- Keyboard / Mouse acknowledge output (active high)
        io_wait             : std_logic;                                          -- User I/O wait output (active high)
        io_dout             : std_logic_vector(15 downto 0);                      -- User I/O data output (16-bit)

        -- ram_addr_o         : std_logic_vector(22 downto 1);                      -- RAM address output (22-bit)
        -- ram_bhe_n_o        : std_logic;                                          -- RAM byte high enable output (active low)
        -- ram_ble_n_o        : std_logic;                                          -- RAM byte low enable output (active low)
        -- ram_we_n_o         : std_logic;                                          -- RAM write enable output (active low)
        -- ram_oe_n_o         : std_logic;                                          -- RAM output enable output (active low)
        -- ram_data_o         : std_logic_vector(15 downto 0);                      -- RAM data output (16-bit)
        qnice_dev_data_o   : std_logic_vector(15 downto 0);                      -- QNICE device data output (16-bit)

    end record;
    attribute description of OP_TYPE : type is "OUT Ports for Amiga_M65 module";

    type INTERNAL_TYPE is record
        -- Internal signals record type
        -- Reset
        amiga_rst_n      : std_logic;

        -- one clk28 wide each, 7.09 MHz rate, 180 degrees apart, aligned to c1/c3
        cpu_ph1          : std_logic;
        cpu_ph2          : std_logic;

        --RAM
        ram_data_o        : std_logic_vector(15 downto 0);
        ram_cs            : std_logic;
        div_reg, div_next : unsigned(3 downto 0);
        c1d_reg, c1d_next : std_logic;
        cyc_i             : std_logic;
        ram_ready         : std_logic;
        cpu_type          : std_logic;
        ram_ctrl_addr     : std_logic_vector(28 downto 1);

        ramdata_out       : std_logic_vector(15 downto 0);

        -- Fastchip
        cyc                : std_logic;
        lds_n              : std_logic;
        uds_n              : std_logic;
        ide_ena            : std_logic;


    end record;
    attribute description of INTERNAL_TYPE : type is "Internal signals for Amiga_M65 module";


    type AMIGA_CLK_TYPE is record
        clk7_en          : std_logic;
        clk7n_en         : std_logic;
        c1               : std_logic;
        c3               : std_logic;
        cck              : std_logic;
        eclk             : std_logic_vector(9 downto 0);
    end record;
    attribute description of AMIGA_CLK_TYPE : type is "Output Amiga clock signals";

    type CPU_WRAPPER_TYPE is record
        -- CPU Wrapper output signals
        reset_out       : std_logic;
        chip_addr       : std_logic_vector(23 downto 1);
        chip_din        : std_logic_vector(15 downto 0);
        chip_as         : std_logic;
        chip_uds        : std_logic;
        chip_lds        : std_logic;
        chip_rw         : std_logic;
        fastchip_sel    : std_logic;
        fastchip_lds    : std_logic;
        fastchip_uds    : std_logic;
        fastchip_rnw    : std_logic;
        fastchip_lw     : std_logic;
        ramsel          : std_logic;
        ramaddr         : std_logic_vector(28 downto 1);
        ramdin          : std_logic_vector(15 downto 0);
        ramlds          : std_logic;
        ramuds          : std_logic;
        ramshared       : std_logic;
        toccata_ena     : std_logic;
        toccata_base    : std_logic_vector(7 downto 0);
        cpustate        : std_logic_vector(1 downto 0);
        cacr            : std_logic_vector(3 downto 0);
        nmi_addr        : std_logic_vector(31 downto 0);
    end record;
    attribute description of CPU_WRAPPER_TYPE : type is "Output CPU Wrapper signals";

    type MINIMIG_TYPE is record
        -- Minimig output signals
        -- m68k CPU Interface signals
        cpu_data            : std_logic_vector(15 downto 0);
        cpu_ipl_n           : std_logic_vector(2 downto 0);
        cpu_dtack_n         : std_logic;
        cpu_reset_n         : std_logic;
        ovr                 : std_logic;
        -- SRAM-style memory interface signals
        ram_address         : std_logic_vector(22 downto 1);
        ram_data            : std_logic_vector(15 downto 0);
        ram_bhe_n           : std_logic;
        ram_ble_n           : std_logic;
        ram_we_n            : std_logic;
        ram_oe_n            : std_logic;
        -- System
        rst_out             : std_logic;
        -- RS232 interface signals
        txd                 : std_logic;
        rts                 : std_logic;
        dtr                 : std_logic;
        -- Input Devices
        kbd_ack             : std_logic;
        -- LEDS
        pwr_led             : std_logic;
        fdd_led             : std_logic;
        hdd_led             : std_logic;
        -- User I/O
        io_wait             : std_logic;
        io_dout             : std_logic_vector(15 downto 0);
        -- Video
        hsync_n             : std_logic;
        vsync_n             : std_logic;
        csync_n             : std_logic;
        field1              : std_logic;
        lace                : std_logic;
        hblank              : std_logic;
        vblank              : std_logic;
        red                 : std_logic_vector(7 downto 0);
        green               : std_logic_vector(7 downto 0);
        blue                : std_logic_vector(7 downto 0); 
        ar                  : std_logic_vector(1 downto 0);
        scanline            : std_logic_vector(2 downto 0);
        ce_pix              : std_logic;
        res                 : std_logic_vector(1 downto 0);
        ntsc                : std_logic;
        -- Audio
        ldata               : std_logic_vector(14 downto 0);
        rdata               : std_logic_vector(14 downto 0);
        ldata_okk           : std_logic_vector(8 downto 0);
        rdata_okk           : std_logic_vector(8 downto 0);
        aud_mix             : std_logic_vector(1 downto 0);
        -- Toccata Audio
        toccata_aud_left    : std_logic_vector(15 downto 0);
        toccata_aud_right   : std_logic_vector(15 downto 0);
        -- Configuration
        cpucfg              : std_logic_vector(1 downto 0);
        cachecfg            : std_logic_vector(2 downto 0);
        memcfg              : std_logic_vector(6 downto 0);
        bootrom             : std_logic;
        -- IDE Interface
        ide_ena             : std_logic;
        ide_fast            : std_logic;
        ide_req             : std_logic_vector(5 downto 0);
        ide_readdata        : std_logic_vector(15 downto 0);      
    end record;
    attribute description of MINIMIG_TYPE : type is "Output Minimig signals";

    type FASTCHIP_TYPE is record
        sel_ack         : std_logic;
        ready           : std_logic;
        dout            : std_logic_vector(15 downto 0);
        rtg_ena         : std_logic;
        rtg_hsize       : std_logic_vector(11 downto 0);
        rtg_vsize       : std_logic_vector(11 downto 0);
        rtg_format      : std_logic_vector(4 downto 0);
        rtg_base        : std_logic_vector(31 downto 0);
        rtg_stride      : std_logic_vector(13 downto 0);
        rtg_pal_clk     : std_logic;
        rtg_pal_dw      : std_logic_vector(23 downto 0);
        rtg_pal_a       : std_logic_vector(7 downto 0);
        rtg_pal_wr      : std_logic;
        ide_irq         : std_logic;
        ide_req         : std_logic_vector(5 downto 0);
        ide_readdata    : std_logic_vector(15 downto 0);
        ide_led         : std_logic;
    end record;
    attribute description of FASTCHIP_TYPE : type is "Output Fastchip signals";

    type RAMCS_TYPE is record
        cyc             : std_logic;
        cpu_ph1         : std_logic; 
        cpu_ph2         : std_logic; 
        ram_cs          : std_logic;
    end record;
    attribute description of RAMCS_TYPE : type is "Output RAM CS signals";

    signal ip        : IP_TYPE;
    signal op        : OP_TYPE;
    signal int       : INTERNAL_TYPE;
    signal amiga_clk : AMIGA_CLK_TYPE; 
    signal cpuwrap   : CPU_WRAPPER_TYPE;
    signal mini      : MINIMIG_TYPE;
    signal fast      : FASTCHIP_TYPE;
    signal ramcs     : RAMCS_TYPE;


begin

  -- Map the IN Ports signals  
  ip.main_clk           <= main_clk;
  ip.amiga_reset        <= amiga_reset;
  ip.kbd_mouse_type     <= kbd_mouse_type;
  ip.kbd_mouse_data     <= kbd_mouse_data;
  ip.kms_level          <= kms_level;
  ip.mouse_btn          <= mouse_btn;
  ip.joy1_n             <= joy1_n;
  ip.joy2_n             <= joy2_n;
  ip.rtc                <= rtc;
  ip.io_uio             <= io_uio;
  ip.io_strobe          <= io_strobe;
  ip.io_din             <= io_din;
  ip.io_fpga            <= io_fpga;

  ip.qnice_clk_i        <= qnice_clk_i;
  ip.qnice_dev_id_i     <= qnice_dev_id_i;
  ip.qnice_dev_ce_i     <= qnice_dev_ce_i;
  ip.qnice_dev_we_i     <= qnice_dev_we_i;
  ip.qnice_dev_addr_i   <= qnice_dev_addr_i;
  ip.qnice_dev_data_i   <= qnice_dev_data_i;

  ip.amiga_chip_scrub      <= amiga_chip_scrub;
  ip.amiga_chip_scrub_addr <= amiga_chip_scrub_addr;

  --ip.ram_data_i          <= ram_data_i;

  -- Map the OUT Ports signals
  clk7_en             <= op.clk7_en;
  clk7n_en            <= op.clk7n_en;
  pwr_led             <= op.pwr_led;
  fdd_led             <= op.fdd_led;
  hdd_led             <= op.hdd_led;
  audio_l             <= op.audio_l;
  audio_r             <= op.audio_r;
  rdata_okk           <= op.rdata_okk;
  ldata_okk           <= op.ldata_okk;
  aud_mix             <= op.aud_mix;
  vga_r               <= op.vga_r;
  vga_g               <= op.vga_g;
  vga_b               <= op.vga_b;
  vga_hsync           <= op.vga_hsync;
  vga_vsync           <= op.vga_vsync;
  vga_csync           <= op.vga_csync;
  hblank              <= op.hblank;
  vblank              <= op.vblank;
  vid_res             <= op.vid_res;
  field1              <= op.field1;
  kbd_ack             <= op.kbd_ack;
  ce_pix              <= op.ce_pix;
  io_wait             <= op.io_wait;
  io_dout             <= op.io_dout;

--   ram_addr_o         <= op.ram_addr_o;
--   ram_bhe_n_o        <= op.ram_bhe_n_o;
--   ram_ble_n_o        <= op.ram_ble_n_o;
--   ram_we_n_o         <= op.ram_we_n_o;
--   ram_oe_n_o         <= op.ram_oe_n_o;
--   ram_data_o         <= op.ram_data_o;
  qnice_dev_data_o   <= op.qnice_dev_data_o;

  -- Assignments -------------------------------------------------------------------------------
  -- Output signals from the Amiga/minimig module to the top-level outputs
  op.clk7_en          <= amiga_clk.clk7_en;
  op.clk7n_en         <= amiga_clk.clk7n_en;
  op.pwr_led          <= mini.pwr_led;
  op.fdd_led          <= mini.fdd_led;
  op.hdd_led          <= mini.hdd_led or fast.ide_led;  -- Combine minimig and fastchip IDE LED signals (gayle is in both minimig and fastchip, so we OR them together)
  op.audio_l          <= mini.ldata;
  op.audio_r          <= mini.rdata;
  op.rdata_okk        <= mini.rdata_okk;
  op.ldata_okk        <= mini.ldata_okk;
  op.aud_mix          <= mini.aud_mix;
  op.vga_r            <= mini.red;
  op.vga_g            <= mini.green;
  op.vga_b            <= mini.blue;
  op.vga_hsync        <= mini.hsync_n;
  op.vga_vsync        <= mini.vsync_n;
  op.vga_csync        <= mini.csync_n;
  op.hblank           <= mini.hblank;
  op.vblank           <= mini.vblank;
  op.vid_res          <= mini.res;
  op.field1           <= mini.field1;
  op.ce_pix           <= mini.ce_pix;
  op.lace             <= mini.lace;
  op.kbd_ack          <= mini.kbd_ack;
  op.io_wait          <= mini.io_wait;
  op.io_dout          <= mini.io_dout;  
  -- RAM Interface
--   op.ram_addr_o       <= mini.ram_address;
--   op.ram_bhe_n_o      <= mini.ram_bhe_n;
--   op.ram_ble_n_o      <= mini.ram_ble_n;
--   op.ram_we_n_o       <= mini.ram_we_n;
--   op.ram_oe_n_o       <= mini.ram_oe_n;
--   op.ram_data_o       <= mini.ram_data;
  

  
  -- Reset
  int.amiga_rst_n <= not ip.amiga_reset;

  -- CPU Config / Type
  int.cpu_type    <= mini.cpucfg(1);

    -- Fastchip internal signals
    int.lds_n   <= not cpuwrap.fastchip_lds;
    int.uds_n   <= not cpuwrap.fastchip_uds;
    int.ide_ena <= mini.ide_ena and mini.ide_fast;
    

  -- Processes ---------------------------------------------------------------------------------

   cpu_phase_proc : process (ip.main_clk)
   begin
      if rising_edge(ip.main_clk) then
         if mini.cpu_reset_n = '0' then
            int.cpu_ph1 <= '0';
            int.cpu_ph2 <= '0';
         else
            int.cpu_ph2 <= (not amiga_clk.c1) and (not amiga_clk.c3);
            int.cpu_ph1 <= amiga_clk.c1 and amiga_clk.c3;
         end if;
      end if;
   end process cpu_phase_proc;




  -- Instantiate Modules ----------------------------------------------------------------------- 
-- DJR TODO: Need to tie in additional signals, e.h. cpu_ph1 and cpu_ph2, etc.  Also need to review the CPU wrapper and minimig modules to see if any additional signals are needed for the Mega65 Amiga core.  For now, just use the cpu_wrapper to get the CPU working with the minimig module.
  i_ram_cs : entity work.compute_ram_cs
    port map (
        clk             => ip.main_clk
       ,c1              => amiga_clk.c1
       ,cpu_rst         => mini.cpu_reset_n
       ,ram_sel         => cpuwrap.ramsel
       ,cyc             => ramcs.cyc      
       ,cpu_ph1         => open 
       ,cpu_ph2         => open
    );


  amiga_clk_inst : entity work.Amiga_Clk
    port map (
        clk_28      => ip.main_clk
       ,reset_n     => int.amiga_rst_n
       ,clk7_en     => amiga_clk.clk7_en
       ,clk7n_en    => amiga_clk.clk7n_en
       ,c1          => amiga_clk.c1
       ,c3          => amiga_clk.c3
       ,cck         => amiga_clk.cck
       ,eclk        => amiga_clk.eclk
    );
-- DJR: NOTE: will need to review mappings when fastchip is included, plus full wrapper.
-- For now, just use the cpu_wrapper to get the CPU working with the minimig module.
i_cpu_wrapper : entity work.cpu_wrapper
      port map (
         reset            => mini.cpu_reset_n      -- active low, from minimig
        ,reset_out       => cpuwrap.reset_out     -- fx68k RESET instruction feedback,

        ,clk             => ip.main_clk
        ,ph1             => int.cpu_ph1
        ,ph2             => int.cpu_ph2

        ,cpucfg          => "00"                -- 68000; MUST be constant so the
                                                 -- removed-TG68K muxes constant-fold
        --,cpucfg          => mini.cpucfg       -- Should come thu from userio config 
        ,fastramcfg      => "000"               -- no Zorro fast RAM
        ,cachecfg        => "000"               -- no caches
        ,bootrom         => '0'                 -- normal A500 memory map

        ,chip_addr       => cpuwrap.chip_addr(23 downto 1)
        ,chip_dout       => mini.cpu_data
        ,chip_din        => cpuwrap.chip_din
        ,chip_as         => cpuwrap.chip_as
        ,chip_uds        => cpuwrap.chip_uds
        ,chip_lds        => cpuwrap.chip_lds
        ,chip_rw         => cpuwrap.chip_rw
        ,chip_dtack      => mini.cpu_dtack_n
        ,chip_ipl        => mini.cpu_ipl_n

        -- ,fastchip_dout   => x"0000"
        -- ,fastchip_sel    => open
        -- ,fastchip_lds    => open
        -- ,fastchip_uds    => open
        -- ,fastchip_rnw    => open
        -- ,fastchip_lw     => open
        -- ,fastchip_selack => '0'
        -- ,fastchip_ready  => '0'
        ,fastchip_dout   => fast.dout
        ,fastchip_sel    => cpuwrap.fastchip_sel
        ,fastchip_lds    => cpuwrap.fastchip_lds
        ,fastchip_uds    => cpuwrap.fastchip_uds
        ,fastchip_rnw    => cpuwrap.fastchip_rnw
        ,fastchip_lw     => cpuwrap.fastchip_lw
        ,fastchip_selack => fast.sel_ack
        ,fastchip_ready  => fast.ready
         
        --,ramsel          => open  -- TBC to be mapped to compute ram_CS module
        ,ramsel          => cpuwrap.ramsel
        ,ramaddr         => open        -- TBC to map to new ram controller for cpu address bus
        ,ramdin          => open
        ,ramdout         => x"0000"
        ,ramready        => '0'
         
        ,ramlds          => open
        ,ramuds          => open
        ,ramshared       => open

        --,toccata_ena     => open
        --,toccata_base    => open
        ,toccata_ena     => cpuwrap.toccata_ena
        ,toccata_base    => cpuwrap.toccata_base

        ,cpustate        => open        -- TBC to map to new ram controller
        ,cacr            => open
        ,nmi_addr        => cpuwrap.nmi_addr
      );

minimig : entity work.minimig_m65A
      port map (                                
          cpu_address           => cpuwrap.chip_addr
         ,cpu_data              => mini.cpu_data
         ,cpudata_in            => cpuwrap.chip_din
         ,cpu_ipl_n             => mini.cpu_ipl_n
         ,cpu_as_n              => cpuwrap.chip_as
         ,cpu_uds_n             => cpuwrap.chip_uds
         ,cpu_lds_n             => cpuwrap.chip_lds
         ,cpu_r_w               => cpuwrap.chip_rw
         ,cpu_dtack_n           => mini.cpu_dtack_n
         ,cpu_reset_n           => mini.cpu_reset_n
         ,cpu_reset_in_n        => cpuwrap.reset_out
         ,nmi_addr              => cpuwrap.nmi_addr
         ,ovr                   => mini.ovr                    
        
         -- RAM interface
         ,ram_data              => mini.ram_data
        --  ,ramdata_in            => ip.ram_data_i
         ,ramdata_in            => int.ramdata_out
         ,ram_address           => mini.ram_address
         ,ram_bhe_n             => mini.ram_bhe_n
         ,ram_ble_n             => mini.ram_ble_n
         ,ram_we_n              => mini.ram_we_n
         ,ram_oe_n              => mini.ram_oe_n   

         ,chip48                => (others => '0') 

         ,rst_ext               => ip.amiga_reset 
         ,rst_out               => open
         ,clk                   => ip.main_clk
         ,clk7_en               => amiga_clk.clk7_en
         ,clk7n_en              => amiga_clk.clk7n_en
         ,c1                    => amiga_clk.c1
         ,c3                    => amiga_clk.c3
         ,cck                   => amiga_clk.cck
         ,eclk                  => amiga_clk.eclk

         ,rxd                   => '1'                 -- no serial port
         ,txd                   => open                 -- no serial port
         ,cts                   => '1'                 -- no serial port
         ,rts                   => open                 -- no serial port
         ,dtr                   => open                 -- no serial port
         ,dsr                   => '1'                 -- no serial port
         ,cd                    => '1'                 -- no serial port
         ,ri                    => '1'                 -- no serial port

         ,joy1_n                => ip.joy1_n
         ,joy2_n                => ip.joy2_n
         ,joy3_n                => (others => '1')       -- no joystick 3
         ,joy4_n                => (others => '1')       -- no joystick 4
         ,joya1                 => (others => '0')       -- no joystick 1 analog
         ,joya2                 => (others => '0')       -- no joystick 2 analog
         ,mouse_btn             => ip.mouse_btn
         ,kms_level             => ip.kms_level
         ,kbd_mouse_type        => ip.kbd_mouse_type
         ,kbd_mouse_data        => ip.kbd_mouse_data
         ,kbd_ack               => mini.kbd_ack

         ,pwr_led               => mini.pwr_led
         ,fdd_led               => mini.fdd_led
         ,hdd_led               => mini.hdd_led
         
         ,rtc                   => ip.rtc

         ,io_uio                => ip.io_uio
         ,io_fpga               => ip.io_fpga
         ,io_strobe             => ip.io_strobe
         ,io_wait               => mini.io_wait
         ,io_din                => ip.io_din
         ,io_dout               => mini.io_dout
                  
         ,hsync_n               => mini.hsync_n
         ,vsync_n               => mini.vsync_n
         ,csync_n               => mini.csync_n        -- not used in MEGA65
         ,hblank                => mini.hblank
         ,vblank                => mini.vblank
         ,red                   => mini.red
         ,green                 => mini.green
         ,blue                  => mini.blue
         ,ce_pix                => mini.ce_pix
         ,res                   => mini.res
         ,lace                  => mini.lace
         ,field1                => mini.field1           -- field identity for ascal's weave deinterlacer
                                                         -- (as MiSTer: assign VGA_F1 = field1)
         ,ldata                 => mini.ldata
         ,rdata                 => mini.rdata
         ,ldata_okk             => mini.ldata_okk
         ,rdata_okk             => mini.rdata_okk
         ,aud_mix               => mini.aud_mix
        --  ,toccata_ena           => '0'                 -- Not exposed outside of Amiga Core Module. connect to configurable register in future if needed
        --  ,toccata_base          => (others=>'0')       -- Not Exposed outside of Amiga Core Module. connect to configurable register in future if needed
        --  ,toccata_aud_left      => open                -- Not Exposed outside of Amiga Core Module, if used likely to be  combined with audio mixer module in future, so not exposed outside of Amiga Core Module
        --  ,toccata_aud_right     => open                -- Not Exposed outside of Amiga Core Module, if used likely to be  combined with audio mixer module in future, so not exposed outside of Amiga Core Module
         ,toccata_ena           => cpuwrap.toccata_ena
         ,toccata_base          => cpuwrap.toccata_base
         ,toccata_aud_left      => mini.toccata_aud_left    -- TBC to go to module to combine audio from Toccata and Paula,  then to outside of Amiga Core Module
         ,toccata_aud_right     => mini.toccata_aud_right  -- TBC to go to module to combine audio from Toccata and Paula,  then to outside of Amiga Core Module
         
         
         ,cpucfg                => mini.cpucfg
         ,cachecfg              => mini.cachecfg
         ,memcfg                => mini.memcfg
         ,bootrom               => mini.bootrom

        --  ,ide_ena               => open
        --  ,ide_fast              => open
        --  ,ide_ext_irq           => '0'
        --  ,ide_req               => open
        --  ,ide_address           => (others => '0')
        --  ,ide_write             => '0'
        --  ,ide_writedata         => (others => '0')
        --  ,ide_read              => '0'
        --  ,ide_readdata          => open
         
         ,ide_ena               => mini.ide_ena
         ,ide_fast              => mini.ide_fast
         ,ide_ext_irq           => fast.ide_irq
         ,ide_req               => mini.ide_req
         ,ide_address           => (others => '0')      -- TBC connect to new IDE module, same conenction as fastchip, but will need to be connected to new IDE module
         ,ide_write             => '0'
         ,ide_writedata         => (others => '0')
         ,ide_read              => '0'
         ,ide_readdata          => open
          

      );

-- Amiga RAM  
    amiga_ram : entity work.amiga_ram
        port map (
          main_clk              => ip.main_clk
         ,main_ram_addr         => mini.ram_address
         ,main_ram_wrdata       => mini.ram_data
         ,main_ram_we_n         => mini.ram_we_n
         ,main_ram_bhe_n        => mini.ram_bhe_n
         ,main_ram_ble_n        => mini.ram_ble_n
         ,main_ram_rddata       => int.ramdata_out
         ,amiga_chip_scrub      => ip.amiga_chip_scrub
         ,amiga_chip_scrub_addr => ip.amiga_chip_scrub_addr
         --QNIICE Interface - for ROM load data
        ,qnice_clk_i            => ip.qnice_clk_i
        ,qnice_dev_id_i         => ip.qnice_dev_id_i
        ,qnice_dev_ce_i         => ip.qnice_dev_ce_i
        ,qnice_dev_we_i         => ip.qnice_dev_we_i
        ,qnice_dev_addr_i       => ip.qnice_dev_addr_i
        ,qnice_dev_data_i       => ip.qnice_dev_data_i
        ,qnice_dev_data_o       => op.qnice_dev_data_o
        );      

-- FastChip
    fastchip : entity work.fastchip
        port map (
          clk                   => ip.main_clk
         ,clk_sys               => ip.main_clk
         ,cyc                   => ramcs.cyc
         ,reset                 => int.amiga_rst_n  -- TBC
         ,sel                   => cpuwrap.fastchip_sel
         ,sel_ack               => fast.sel_ack
         ,ready                 => fast.ready
         ,addr                  => cpuwrap.chip_addr
         ,din                   => cpuwrap.chip_din
         ,dout                  => fast.dout
         ,lds                   => int.lds_n  -- (not cpuwrap.fastchip_lds)
         ,uds                   => int.uds_n  -- (not cpuwrap.fastchip_uds)
         ,rnw                   => cpuwrap.fastchip_rnw
         ,longword              => cpuwrap.fastchip_lw

        --  ,rtg_ena               => fast.rtg_ena
        --  ,rtg_hsize             => fast.rtg_hsize
        --  ,rtg_vsize             => fast.rtg_vsize
        --  ,rtg_format            => fast.rtg_format
        --  ,rtg_base              => fast.rtg_base
        --  ,rtg_stride            => fast.rtg_stride
        --  ,rtg_pal_clk           => fast.rtg_pal_clk
        --  ,rtg_pal_dw            => fast.rtg_pal_dw
        --  ,rtg_pal_dr            => '0'              -- TBC
        --  ,rtg_pal_a             => fast.rtg_pal_a
        --  ,rtg_pal_wr            => fast.rtg_pal_wr
        -- No RTG implementated for now.
         ,rtg_ena               => open
         ,rtg_hsize             => open
         ,rtg_vsize             => open
         ,rtg_format            => open
         ,rtg_base              => open
         ,rtg_stride            => open
         ,rtg_pal_clk           => open
         ,rtg_pal_dw            => open
         ,rtg_pal_dr            => (others => '0')              
         ,rtg_pal_a             => open
         ,rtg_pal_wr            => open

         ,ide_ena               => int.ide_ena
         ,ide_irq               => fast.ide_irq
         ,ide_req               => fast.ide_req  -- TBC
         ,ide_address           => (others => '0')  -- TBC External, will need to be conencted to new IDE module
         ,ide_write             => '0'              -- TBC External, will need to be conencted to new IDE module
         ,ide_writedata         => (others => '0')  -- TBC External, will need to be conencted to new IDE module
         ,ide_read              => '0'              -- TBC External, will need to be conencted to new IDE module
         ,ide_readdata          => fast.ide_readdata
         
         ,ide_led               => fast.ide_led
         
        );


end architecture;    
