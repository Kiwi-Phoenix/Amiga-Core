-- Wrapper for the RAM.
-- Brings the different instantiation of dualport_2clk_ram and logic together in one module.
-- Once working in CORE it will then be wrapped up into the Amiga Core module.
-- Once there, it will eventually be replaced by a new RAM Controller module.
--
-- Aug 2026 - David Raynor (Kiwi) - Initial version.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;   

library work;
use work.Amiga_Globals.all;
use work.Amiga_Debug_pkg.all;
use work.globals.all;

entity amiga_ram is
   port (
        main_clk                : in std_logic;
        main_ram_addr           : in std_logic_vector(22 downto 1);
        main_ram_wrdata         : in std_logic_vector(15 downto 0);
        main_ram_we_n           : in std_logic;
        main_ram_bhe_n          : in std_logic;
        main_ram_ble_n          : in std_logic;
        main_ram_rddata         : out std_logic_vector(15 downto 0);

        amiga_chip_scrub_addr   : in std_logic_vector(17 downto 0);
        amiga_chip_scrub        : in std_logic;

        qnice_clk_i             : in std_logic;
        qnice_dev_ce_i          : in std_logic;
        qnice_dev_we_i          : in std_logic;
        qnice_dev_id_i          : in std_logic_vector(15 downto 0);
        qnice_dev_addr_i        : in std_logic_vector(27 downto 0);
        qnice_dev_data_o        : out std_logic_vector(15 downto 0);
        qnice_dev_data_i        : in std_logic_vector(15 downto 0)


   );
end entity;

architecture rtl of amiga_ram is

    signal chip_ram_u_we : std_logic;
    signal chip_ram_l_we : std_logic;
    signal slow_ram_u_we : std_logic;
    signal slow_ram_l_we : std_logic;

    signal main_chip_q_u : std_logic_vector(7 downto 0);
    signal main_chip_q_l : std_logic_vector(7 downto 0);
    signal main_slow_q_u : std_logic_vector(7 downto 0);
    signal main_slow_q_l : std_logic_vector(7 downto 0);    
    signal main_kick_q_u : std_logic_vector(7 downto 0);
    signal main_kick_q_l : std_logic_vector(7 downto 0);

    signal main_rd_sel : std_logic_vector(1 downto 0);  -- 00=chip, 01=slow, 10=kick, 11=none

    signal main_chip_sel : std_logic;
    signal main_slow_sel : std_logic;   
    signal main_kick_sel : std_logic;

    --signal ram_addr : std_logic_vector(22 downto 1);

    signal qnice_kick_we_u : std_logic;
    signal qnice_kick_we_l : std_logic;
    --signal qnice_dev_data_o : std_logic_vector(15 downto 0);

    signal qnice_kick_q_u : std_logic_vector(7 downto 0);
    signal qnice_kick_q_l : std_logic_vector(7 downto 0);

    signal main_chip_addr           : std_logic_vector(17 downto 0);
    signal main_chip_data_u         : std_logic_vector(7 downto 0);
    signal main_chip_data_l         : std_logic_vector(7 downto 0);
    signal main_chip_wren_u         : std_logic;
    signal main_chip_wren_l         : std_logic;

    signal wren_a_h : std_logic;
    signal wren_a_l : std_logic;


begin

    --ram_addr <= main_ram_addr;

    chip_ram_u_we <= main_chip_sel and not main_ram_we_n and not main_ram_bhe_n;
    chip_ram_l_we <= main_chip_sel and not main_ram_we_n and not main_ram_ble_n;
    slow_ram_u_we <= main_slow_sel and not main_ram_we_n and not main_ram_bhe_n;
    slow_ram_l_we <= main_slow_sel and not main_ram_we_n and not main_ram_ble_n;

    main_ram_rddata <= main_kick_q_u & main_kick_q_l when main_rd_sel = "10" else
                       main_slow_q_u & main_slow_q_l when main_rd_sel = "01" else
                       main_chip_q_u & main_chip_q_l 
                       ;

    -- bank decode of the banked word address space 
    -- main_chip_sel <= '1' when ram_addr(22 downto 19) = "0000" else '0';
    -- main_slow_sel <= '1' when ram_addr(22 downto 19) = "1000" else '0';
    -- main_kick_sel <= '1' when ram_addr(22 downto 19) = "1111" else '0'; 
    main_chip_sel <= '1' when main_ram_addr(22 downto 19) = "0000" else '0';
    main_slow_sel <= '1' when main_ram_addr(22 downto 19) = "1000" else '0';
    main_kick_sel <= '1' when main_ram_addr(22 downto 19) = "1111" else '0';

    wren_a_h <= main_slow_sel and not main_ram_we_n and not main_ram_bhe_n;
    wren_a_l <= main_slow_sel and not main_ram_we_n and not main_ram_ble_n;        

    read_mux_sel_proc : process(main_clk)
    begin
        if rising_edge(main_clk) then
            if main_kick_sel = '1' then
                main_rd_sel <= "10";
            elsif main_slow_sel = '1' then
                main_rd_sel <= "01";
            elsif main_chip_sel = '1' then
                main_rd_sel <= "00";
            --else
            --    main_rd_sel <= "11";
            end if;
        end if;
    end process;

    -- DJR - It would appear that this is not atually required, however 
    -- if qnice_dev_data_o is not sent back to QNICE, it results in clock stability issues.  Best to leave it in for now.
    -- ONly a short time until this module is replaced with the new RAM Controller.
     core_specific_devices : process(qnice_dev_id_i, qnice_dev_ce_i, qnice_dev_we_i 
                                     , qnice_dev_addr_i, qnice_kick_q_u, qnice_kick_q_l)
    --core_specific_devices : process(all)
    begin
        -- make sure that this is x"EEEE" by default and avoid a register here by having this default value
        qnice_dev_data_o <= x"EEEE";
        qnice_kick_we_u <= '0';
        qnice_kick_we_l <= '0';
        
        case qnice_dev_id_i is
            when C_DEV_AMIGA_KICK =>
                qnice_kick_we_u <= qnice_dev_ce_i and qnice_dev_we_i and not qnice_dev_addr_i(0);
                qnice_kick_we_l <= qnice_dev_ce_i and qnice_dev_we_i and     qnice_dev_addr_i(0);
                if qnice_dev_addr_i(0) = '0' then
                    qnice_dev_data_o <= x"00" & qnice_kick_q_u;
                else
                    qnice_dev_data_o <= x"00" & qnice_kick_q_l;
                end if;
            when others =>
                null;
        end case;
    end process;

    -- Chip and Slow RAM: single-ported from the QNICE perspective (port B
    -- completely tied off, so no QNICE-domain routing reaches these 256 BRAM 
    -- tiles - see teh timing note at teh qnice signal declarations).
    -- During an Amiga-local cold boot only, the existing Chip RAM port is
    -- overridden for two clocks to clear $000004-$000007. Both byte lanes are
    -- written together; the 68000 and chipset are held in reset throughout.

    main_chip_addr   <= amiga_chip_scrub_addr when amiga_chip_scrub = '1' else main_ram_addr(18 downto 1);
    main_chip_data_u <= (others => '0') when amiga_chip_scrub = '1' else main_ram_wrdata(15 downto 8);
    main_chip_data_l <= (others => '0') when amiga_chip_scrub = '1' else main_ram_wrdata(7 downto 0);
    main_chip_wren_u <= '1' when amiga_chip_scrub = '1' else 
                        main_chip_sel and not main_ram_we_n and not main_ram_bhe_n;
    main_chip_wren_l <= '1' when amiga_chip_scrub = '1' else 
                        main_chip_sel and not main_ram_we_n and not main_ram_ble_n;
                      
    chip_ram_u : entity work.dualport_2clk_ram
        generic map (
            ADDR_WIDTH => 18,
            DATA_WIDTH => 8
        )
        port map (
             clock_a    => main_clk
            ,address_a  => main_chip_addr
            ,data_a     => main_chip_data_u
            ,wren_a     => main_chip_wren_u
            ,q_a        => main_chip_q_u

            ,clock_b    => '0'
            ,address_b  => (others => '0')
            ,data_b     => (others => '0')
            ,wren_b     => '0'
            ,q_b        => open
       );

    chip_ram_l : entity work.dualport_2clk_ram
        generic map (
            ADDR_WIDTH => 18,
            DATA_WIDTH => 8
        )
        port map (
             clock_a    => main_clk
            ,address_a  => main_chip_addr
            ,data_a     => main_chip_data_l
            ,wren_a     => main_chip_wren_l
            ,q_a        => main_chip_q_l

            ,clock_b    => '0'
            ,address_b  => (others => '0')
            ,data_b     => (others => '0')
            ,wren_b     => '0'
            ,q_b        => open
       );

    slow_ram_u : entity work.dualport_2clk_ram
        generic map (
            ADDR_WIDTH => 18,
            DATA_WIDTH => 8
        )
        port map (
             clock_a    => main_clk
            ,address_a  => main_ram_addr(18 downto 1)
            ,data_a     => main_ram_wrdata(15 downto 8)
            --,wren_a     => main_slow_sel and not main_ram_we_n and not main_ram_bhe_n
            ,wren_a     => wren_a_h
            ,q_a        => main_slow_q_u        

            ,clock_b    => '0'
            ,address_b  => (others => '0')
            ,data_b     => (others => '0')
            ,wren_b     => '0'
            ,q_b        => open
       );

    slow_ram_l : entity work.dualport_2clk_ram
        generic map (
            ADDR_WIDTH => 18,
            DATA_WIDTH => 8
        )
        port map (
             clock_a    => main_clk
            ,address_a  => main_ram_addr(18 downto 1)
            ,data_a     => main_ram_wrdata(7 downto 0)
            --,wren_a     => main_slow_sel and not main_ram_we_n and not main_ram_ble_n
            ,wren_a     => wren_a_l 
            ,q_a        => main_slow_q_l      

            ,clock_b    => '0'
            ,address_b  => (others => '0')
            ,data_b     => (others => '0')
            ,wren_b     => '0'
            ,q_b        => open
       );

    -- Kickstart: read-only from the Amiga side (wren_a fixed '0'); written only
    -- by teh QNICE Shell during the mandatory auto-load.  The core-side address
    -- ignores bit 18, mirroring the 256 ROM at $F80000 and $FC0000.
    kick_rom_u : entity work.dualport_2clk_ram
        generic map (
            ADDR_WIDTH => 17,
            DATA_WIDTH => 8
        )
        port map (
             clock_a    => main_clk
            ,address_a  => main_ram_addr(17 downto 1)
            ,data_a     => (others => '0')
            ,wren_a     => '0'
            ,q_a        => main_kick_q_u           -- Read ROM data from the Amiga side.

            ,clock_b    => qnice_clk_i
            ,address_b  => qnice_dev_addr_i(17 downto 1)
            ,data_b     => qnice_dev_data_i(7 downto 0)
            ,wren_b     => qnice_kick_we_u
            ,q_b        => qnice_kick_q_u       -- Even though this signal goes nowhere, it is required to avoid a synthesis error in the dualport_2clk_ram entity.
       );

    kick_rom_l : entity work.dualport_2clk_ram
        generic map (
            ADDR_WIDTH => 17,
            DATA_WIDTH => 8
        )
        port map (
             clock_a    => main_clk
            ,address_a  => main_ram_addr(17 downto 1)
            ,data_a     => (others => '0')
            ,wren_a     => '0'
            ,q_a        => main_kick_q_l           -- Read ROM data from the Amiga side.

            ,clock_b    => qnice_clk_i
            ,address_b  => qnice_dev_addr_i(17 downto 1)
            ,data_b     => qnice_dev_data_i(7 downto 0)
            ,wren_b     => qnice_kick_we_l
            ,q_b        => qnice_kick_q_l   -- Even though this signal goes nowhere, it is required to avoid a synthesis error in the dualport_2clk_ram entity.
       );



end architecture;    
