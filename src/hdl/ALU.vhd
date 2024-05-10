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
--| ALU OPCODES:
--|
--|     ADD     000
--|
--|
--|
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity ALU is
-- TODO
    port( i_Op: in std_logic_vector(2 downto 0);
          i_A: in std_logic_vector(7 downto 0);
          i_B: in std_logic_vector(7 downto 0);
          o_flag : out std_logic_vector(2 downto 0);
          o_result : out std_logic_vector(7 downto 0)
          );
end ALU;

architecture behavioral of ALU is 
  
	-- declare components and signals
--Signals
signal w_result : std_logic_vector (7 downto 0);
signal w_carry: std_logic := '0';
signal w_zero : std_logic := '0';
signal w_sign: std_logic := '0';
signal w_and: std_logic_vector (7 downto 0);
signal w_or: std_logic_vector (7 downto 0);
signal w_add: std_logic_vector(8 downto 0); --one more incase of overflow
signal w_cOut: std_logic_vector(7 downto 0);
signal w_posneg: std_logic_vector( 7 downto 0);
signal w_Lshift: std_logic_vector (7 downto 0);
signal w_Rshift: std_logic_vector (7 downto 0);
signal w_shift: std_logic_vector (7 downto 0);
begin
	-- PORT MAPS ----------------------------------------
	--Output MUX
	w_result <= w_add when i_Op = ("000" or "001") else
	            w_and when i_Op = ("010" or "011") else
	            w_or when i_Op = ("100" or "101") else
	            w_shift when i_Op = ("110" or "111");
	w_posneg <= std_logic_vector(not(unsigned(i_B)+ unsigned(i_Op))) when i_Op = "001" else
	            std_logic_vector(unsigned(i_B)) when i_Op = "000";
	w_add <= std_logic_vector(unsigned(i_A) + unsigned(w_posneg));
	w_carry <= w_add(8);
	w_or <= i_A or i_B;
	w_and <= i_A and i_B;
	w_shift <= w_Lshift when i_Op = "111" else
	           w_Rshift when i_OP = "110";
	w_Lshift <= std_logic_vector(shift_left(unsigned(i_A), to_integer(unsigned (i_B(2 downto 0)))));
	w_Rshift <=std_logic_vector(shift_right(unsigned(i_A), to_integer(unsigned (i_B(2 downto 0)))));
	w_zero <= '1' when w_result = "0000000" else 
	           '0';
	w_sign <= '1' when w_result(7) = '1' else 
	          '0';
	
	-- CONCURRENT STATEMENTS ----------------------------
	o_flag(0)<= w_carry;
	o_flag(1)<= w_zero;
	o_flag(2)<= w_sign;
	o_result <= w_result;
	
end behavioral;
