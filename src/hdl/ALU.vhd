--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
--|
--|  Instruction | Opcode | Function    |
--| ------------ | ------ | ----------- |
--| ADD          | 000    | A + B       |
--| SUB          | 001    | A-B         |
--| Or           | 010    | A or B      |
--| And          | 011    | A and B     |
--| Left Shift   | 100    | A << B(2:0) |
--| Right Shift  | 101    | A >> B(2:0) |
--|
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use IEEE.numeric_std.ALL;
entity ALU is
    port(
    -- inputs
    i_A     :   in std_logic_vector(7 downto 0); 
    i_op      :   in std_logic_vector(3 downto 0);
    i_B    :   in std_logic_vector(7 downto 0); 
    
    -- outputs
    o_result :   out std_logic_vector(7 downto 0);
    o_flags :   out std_logic_vector(2 downto 0)
    );
end ALU;

architecture behavioral of ALU is 
  
  signal w_sum: std_logic_vector(7 downto 0);
  signal w_shift: std_logic_vector(7 downto 0);
  signal w_and: std_logic_vector(7 downto 0);
  signal w_or: std_logic_vector(7 downto 0);
  signal w_check: std_logic_vector(7downto 0);
  
  
begin


	-- PORT MAPS ----------------------------------------
	
	-- CONCURRENT STATEMENTS ----------------------------
	w_sum <= std_logic_vector(signed(i_A) + signed(i_B)) when i_op(3) = '0' else
	         std_logic_vector(signed(i_A) - signed(i_B)) when i_op(3) = '1';
	w_and <= i_A and i_B;
	w_or <= i_A or i_B;
	w_shift <= std_logic_vector(shift_left(unsigned(i_A), to_integer(unsigned(i_B(2 downto 0))))) when i_op(3) = '0' else
	           std_logic_vector(shift_right(unsigned(i_A), to_integer(unsigned(i_B(2 downto 0))))) when i_op(3) = '1';
	o_result <= w_sum when i_op(2 downto 0) = "000" else
	           w_and when i_op(2 downto 0) = "001" else
	            w_or when i_op(2 downto 0) = "010" else
	           w_shift when i_op(2 downto 0) = "100";
    w_check <= w_sum when i_op(2 downto 0) = "000" else
                              w_and when i_op(2 downto 0) = "001" else
                               w_or when i_op(2 downto 0) = "010" else
                              w_shift when i_op(2 downto 0) = "100";
	o_flags(0) <= not (i_A(7) xor i_B(7)) when i_op = "0000";
	o_flags(1) <= '1' when (i_A = i_B) and i_op = "1000";
	o_flags(3) <= '1' when (w_check(7) = '1');
	
	
	
end behavioral;
