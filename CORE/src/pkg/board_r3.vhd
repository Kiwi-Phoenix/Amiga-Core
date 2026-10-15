----------------------------------------------------------------------------------
-- MEGA65 R3 board package
-- Contains board-specific constants and definitions
-- Used to determine the board model at compile time
--
-- Note: The file defines the board model for the R3 revision of the MEGA65
-- and is included in the generation of the xpr project file.
-- The script will select the required file for the board model at compile time.
-- Oct 2026 - Initial creation of the R3 board package
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package board_pkg is    
    constant BOARD_MODEL : string := "MEGA65_R3";
end package board_pkg;
