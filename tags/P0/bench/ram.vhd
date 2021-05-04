-------------------------------------------------------------------------------
--                                                                           --
--                                                                           --
-- miniMIPS Superscalar Processor : testbench                                --
-- based on miniMIPS Processor                                               --
--                                                                           --
--                                                                           --
-- Author : Miguel Cafruni                                                   --
-- miguel_cafruni@hotmail.com                                                --
--                                                           December 2018   --
-------------------------------------------------------------------------------

-- If you encountered any problem, please contact :
--
--   lmouton@enserg.fr  (2003 version)
--   oschneid@enserg.fr (2003 version)
--   shangoue@enserg.fr (2003 version)
--   miguel_cafruni@hotmail.com (Superscalar version 2018)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pack_mips.all;

entity ram is
   generic (mem_size : natural := 256;  -- Size of the memory in words
            latency : time := 0 ns);
   port(
       req         : in std_logic;
       adr         : in bus32;
       data_inout  : inout bus32;
       r_w         : in std_logic;
       ready       : out std_logic;

       req2         : in std_logic;
       adr2         : in bus32;
       data_inout2  : inout bus32;
       r_w2         : in std_logic;
       ready2       : out std_logic
   );
end;


architecture bench of ram is
    type storage_array is array(natural range 1024 to 1024+4*mem_size - 1) of bus8;
    signal storage : storage_array; -- The memory
begin

    process(adr, data_inout, r_w, adr2, data_inout2, r_w2)
        variable inadr : integer;
        variable i : natural;
        variable inadr2 : integer;
        variable j : natural;
    begin
        inadr := to_integer(unsigned(adr));

        if (inadr>=storage'low) and (inadr<=storage'high) then
            
            ready <= '0', '1' after latency;
            if req = '1' then    
                if r_w /= '1' then  -- Reading in memory
                    for i in 0 to 3 loop
                        data_inout(8*(i+1)-1 downto 8*i) <= storage(inadr+(3-i)) after latency;
                    end loop;
                else
                    for i in 0 to 3 loop
                        storage(inadr+(3-i)) <= data_inout(8*(i+1)-1 downto 8*i) after latency;
                    end loop;
                    data_inout <= (others => 'Z');
                end if;
            else
                data_inout <= (others => 'Z');
            end if;
        else
            data_inout <= (others => 'Z');
            ready <= 'L';
        end if;

        inadr2 := to_integer(unsigned(adr2));

        if (inadr2>=storage'low) and (inadr2<=storage'high) then
            
            ready2 <= '0', '1' after latency;
            if req2 = '1' then    
                if r_w2 /= '1' then  -- Reading in memory
                    for j in 0 to 3 loop
                        data_inout2(8*(j+1)-1 downto 8*j) <= storage(inadr2+(3-j)) after latency;
                    end loop;
                else
                    for j in 0 to 3 loop
                        storage(inadr2+(3-j)) <= data_inout2(8*(j+1)-1 downto 8*j) after latency; --report "Valor j = " & integer'image(j);-- 04/09/18
                    end loop;
                    data_inout2 <= (others => 'Z');    
                end if;
            else
                data_inout2 <= (others => 'Z');
            end if;
        else
            data_inout2 <= (others => 'Z');
            ready2 <= 'L';
        end if;
    end process;

end bench;
