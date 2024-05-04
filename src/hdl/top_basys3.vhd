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
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
    -- inputs
    clk     :   in std_logic; -- native 100MHz FPGA clock
    sw      :   in std_logic_vector(7 downto 0);
    btnU    :   in std_logic; -- master_reset
    btnC    :   in std_logic; -- clk_reset
    
    -- outputs
    led :   out std_logic_vector(15 downto 0);
    seg :   out std_logic_vector(6 downto 0)
    -- 7-segment display segments (active-low cathodes)
);
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
component sevenSegDecoder is
                    port (
                    i_D : in std_logic_vector (3 downto 0);
                    o_S : out std_logic_vector (6 downto 0)     
        
        );
              end component sevenSegDecoder;
              
component clock_divider is
                            generic ( constant k_DIV : natural := 2    ); -- How many clk cycles until slow clock toggles
                                                                       -- Effectively, you divide the clk double this 
                                                                       -- number (e.g., k_DIV := 2 --> clock divider of 4)
                            port (     i_clk    : in std_logic;
                                    i_reset  : in std_logic;           -- asynchronous
                                    o_clk    : out std_logic           -- divided (slow) clock
                            );
                        end component clock_divider;
component controller_fsm is
                                      Port ( i_reset   : in  STD_LOGIC;
                                             i_adv    : in  STD_LOGIC;
                                             o_cycle   : out STD_LOGIC_VECTOR (3 downto 0)           
                                           );
                                  end component controller_fsm;
 component ALU is
                                      port(
                                      -- inputs
                                      i_A     :   in std_logic_vector(7 downto 0); 
                                      i_op      :   in std_logic_vector(3 downto 0);
                                      i_B    :   in std_logic_vector(7 downto 0); 
                                      
                                      -- outputs
                                      o_result :   out std_logic_vector(7 downto 0);
                                      o_flags :   out std_logic_vector(2 downto 0)
                                      );
                                  end component ALU;
                                  
                                  
                                  
component twoscomp_decimal is
                                      port (
                                          i_binary: in std_logic_vector(7 downto 0);
                                          o_negative: out std_logic_vector(3 downto 0);
                                          o_hundreds: out std_logic_vector(3 downto 0);
                                          o_tens: out std_logic_vector(3 downto 0);
                                          o_ones: out std_logic_vector(3 downto 0)
                                      );
                                  end component twoscomp_decimal;
                                  
component TDM4 is
                                      generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
                                      Port ( i_clk        : in  STD_LOGIC;
                                             i_reset        : in  STD_LOGIC; -- asynchronous
                                             i_D3         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
                                             i_D2         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
                                             i_D1         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
                                             i_D0         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
                                             o_data        : out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
                                             o_sel        : out STD_LOGIC_VECTOR (3 downto 0)    -- selected data line (one-cold)
                                      );
                                  end component TDM4;

  signal w_7SD_EN_n : std_logic;
            
  signal w_clk : std_logic;
  signal w_cycle : std_logic_vector(3 downto 0);
  signal w_ones : std_logic_vector(3 downto 0);
  signal w_tens : std_logic_vector(3 downto 0);
  signal w_hundreds : std_logic_vector(3 downto 0);
  signal w_negative : std_logic;
  signal w_bin : std_logic_vector(7 downto 0);
  signal w_sign : std_logic_vector(3 downto 0);
  signal w_regA : std_logic_vector(7 downto 0);
  signal w_regB : std_logic_vector(7 downto 0);
  signal w_result : std_logic_vector(7 downto 0);
  signal w_flags : std_logic_vector(2 downto 0);
  signal w_seg : std_logic_vector(3 downto 0);
  signal w_float : std_logic_vector(3 downto 0);
  
  -- 50 MHz clock
  constant k_clk_period : time := 20 ns;
  
begin
	-- PORT MAPS ----------------------------------------
        clkdiv_inst : clock_divider         --instantiation of clock_divider to take 
    generic map ( k_DIV => 50000000 ) -- 1 Hz clock from 100 MHz
    port map (                          
        i_clk   => clk,
        i_reset => btnU,
        o_clk   => w_clk
    );
      ALU_inst : ALU         --instantiation of clock_divider to take 
           port map (                          
        i_A   => w_regA,
        i_B   => w_regB,
        i_op => sw(3 downto 0),
        o_flags   => w_flags,
        o_result   => w_result
);
      TDM4_inst : TDM4         --instantiation of clock_divider to take 
     port map (                          
        i_clk   => w_clk,
        i_reset   => btnU,
        i_D0 => w_sign,
        i_D1 => w_hundreds,
        i_D2 => w_tens,
        i_D3 => w_ones,
        o_data   => w_seg,
        o_sel   => w_float
);
      twoscomp_decimal_inst : twoscomp_decimal         --instantiation of clock_divider to take 
     port map (                          
          i_binary   => w_bin,
          o_negative   => w_sign,
          o_ones => w_ones,
          o_tens   => w_tens,
          o_hundreds   => w_hundreds
);
    sevenSegDecoder_inst : sevenSegDecoder
    port map(
        i_D(0) => w_seg(0),
        i_D(1) => w_seg(1),
        i_D(2) => w_seg(2),
        i_D(3) => w_seg(3),
        o_S(0) => seg(0),
        o_S(1) => seg(1),
        o_S(2) => seg(2),
        o_S(3) => seg(3),
        o_S(4) => seg(4),
        o_S(5) => seg(5),
        o_S(6) => seg(6)
    ); 
  	uut_inst : controller_fsm port map (
                i_reset   => btnU,
                i_adv    => btnC,
                o_cycle   => w_cycle
            );
            

	
	
	-- CONCURRENT STATEMENTS ----------------------------
        w_regA <= sw(7 downto 0) when w_cycle = "0010";
        w_regB <= sw(7 downto 0) when w_cycle = "0100";
        led(15 downto 13) <= w_flags;
        led(3 downto 0) <= w_cycle;
        led(12 downto 4) <= (others => '0');
        w_bin <= w_regA when w_cycle = "0010" else
                 w_regB when w_cycle = "0100" else
                 w_result when w_cycle = "1000" else
                 "00000000";
                
        
	
	
end top_basys3_arch;
