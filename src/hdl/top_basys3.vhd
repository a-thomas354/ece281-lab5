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
-- TODO
    port(
    clk : in std_logic;
    
    sw : in std_logic_vector(15 downto 0);
    
    led : out std_logic_vector(15 downto 0);
    
    btnU : in std_logic;
    
    btnC: in std_logic;
    
    -- 7-segment display segments (cathodes CG ... CA)
    seg : out std_logic_vector(6 downto 0);  -- seg(6) = CG, seg(0) = CA

    -- 7-segment display active-low enables (anodes)
    an  :  out std_logic_vector(3 downto 0)
    
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
--Components
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
     
     
component clock_divider is
	generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
                                           -- Effectively, you divide the clk double this 
                                           -- number (e.g., k_DIV := 2 --> clock divider of 4)
    port (i_clk    : in std_logic;
        i_reset  : in std_logic;           -- asynchronous
        o_clk    : out std_logic           -- divided (slow) clock
     );
     end component clock_divider;
     
component twoscomp_decimal is
    port(i_binary: in std_logic_vector(7 downto 0);
        o_negative: out std_logic_vector(3 downto 0);
        o_hundreds: out std_logic_vector(3 downto 0);
        o_tens: out std_logic_vector(3 downto 0);
        o_ones: out std_logic_vector(3 downto 0)
    );
    end component twoscomp_decimal;
    
component sevenSegDecoder is
    Port ( i_D : in STD_LOGIC_VECTOR (3 downto 0);
       o_S : out STD_LOGIC_VECTOR (6 downto 0));
    end component sevenSegDecoder;    

component regA is
    Port(i_load: in std_logic;
    i_D1 : in STD_LOGIC_VECTOR(7 downto 0);
    o_Q1 : out STD_LOGIC_VECTOR(7 downto 0));
    end component regA;
    
 component regB is
    Port(i_load:in std_logic;
    i_D2 : in STD_LOGIC_VECTOR(7 downto 0);
    o_Q2 : out STD_LOGIC_VECTOR(7 downto 0));
    end component regB;
    
  component ALU is
      port( i_Op: in std_logic_vector(2 downto 0);
        i_A: in std_logic_vector(7 downto 0);
        i_B: in std_logic_vector(7 downto 0);
        o_flag : out std_logic_vector(2 downto 0);
        o_result : out std_logic_vector(7 downto 0)
        );
     end component ALU;
   component controller_fsm is 
   port(
   i_reset: in std_logic;
   i_adv : in std_logic;
   o_cycle: out std_logic_vector (3 downto 0)
   ); 
   end component controller_fsm;      
--Signals 
 signal  w_cycle : std_logic_vector(3 downto 0);
 signal w_A : std_logic_vector(7 downto 0);
 signal w_B : std_logic_vector(7 downto 0);
 signal w_result : std_logic_vector(7 downto 0);
 signal w_Y : std_logic_vector(7 downto 0);
 signal w_sign : std_logic_vector(3 downto 0);
 signal w_hund : std_logic_vector(3 downto 0);
 signal w_tens : std_logic_vector(3 downto 0);
 signal w_ones : std_logic_vector(3 downto 0);
 signal w_DATA : std_logic_vector(3 downto 0);
 signal w_clk : std_logic; 
 signal w_reset: std_logic;
 signal w_neg: std_logic;
 signal w_sel: std_logic_vector(3 downto 0);
begin
	-- PORT MAPS ----------------------------------------
twoscomp_decimal_inst: twoscomp_decimal
Port map(
i_binary => w_Y,
o_negative => w_sign,
o_hundreds => w_hund,
o_tens => w_tens,
o_ones => w_ones
);
sevenSegDecoder_inst : sevenSegDecoder
Port map(
i_D => w_DATA,
o_S => seg
);
clock_divider_inst: clock_divider
generic map (k_DIV => 12500000)
port map(
i_clk => clk,
i_reset=> w_reset,
o_clk => w_clk
);
TDM4_inst: TDM4
generic map (k_WIDTH => 4)
port map(
i_D0(0) => '0',
i_D0(1)=> w_neg,
i_D0(2)=> '0',
i_D0(3)=> w_neg,
i_D1 => w_hund,
i_D2 => w_tens,
i_D3 => w_ones,
i_clk => w_clk,
i_reset => '0',
o_DATA => w_DATA,
o_sel => w_sel
);
regA_inst: regA
port map(
i_load => w_cycle(0),
i_D1 => sw (7 downto 0),
o_Q1 => w_A
);
regB_inst: regB
port map(
i_load=> w_cycle(1),
i_D2 => sw (7 downto 0),
o_Q2 => w_B
);
ALU_inst: ALU
port map(
   i_Op => sw(3 downto 0),
   i_A => w_A,
   i_B => w_B,
   o_flag => led(15 downto 13),
   o_result => w_result
      );
controller_inst: controller_fsm
port map(
i_reset => btnU,
i_adv => btnC,
o_cycle => w_cycle
);

	-- CONCURRENT STATEMENTS ----------------------------
	an(3 downto 0) <= x"F" when w_cycle = "0001" else
	                  w_sel;
	led(12 downto 4) <= (others => '0');
	led (3 downto 0) <= w_cycle;
	
	w_Y <= w_result when w_cycle = "1000" else
	       w_A when w_cycle = "0010" else
	       w_B when w_cycle = "0100" else
	       "00000000";
	       
end top_basys3_arch;
