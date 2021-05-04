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


library IEEE;
use IEEE.std_logic_1164.all;

library std;
use std.textio.all;

library work;
use work.pack_mips.all;

entity sim_minimips is
end;

architecture bench of sim_minimips is
  constant threshold : integer := 21;
  component minimips is
  port (
      clock    : in std_logic;
      clock2   : in std_logic;
      reset    : in std_logic;

      ram_req  : out std_logic;
      ram_adr  : out bus32;
      ram_r_w  : out std_logic;
      ram_data : inout bus32;
      ram_ack  : in std_logic;

      ram_req2  : out std_logic;
      ram_adr2  : out bus32;
      ram_r_w2  : out std_logic;
      ram_data2 : inout bus32;
      ram_ack2  : in std_logic;

      it_mat   : in std_logic
  );
  end component;


  component ram is
    generic (mem_size : natural := 65536;
             latency : time := 50 ns);
    port(
        req        : in std_logic;
        adr        : in bus32;
        data_inout : inout bus32;
        r_w        : in std_logic;
        ready      : out std_logic;

        req2        : in std_logic;
        adr2        : in bus32;
        data_inout2 : inout bus32;
        r_w2        : in std_logic;
        ready2      : out std_logic
  );
  end component;

  component rom is
  generic (mem_size : natural := 65536;
           start : natural := 0;
           latency : time := 50 ns);
  port(
          adr : in bus32;
          donnee : out bus32;
          ack : out std_logic;

          adr2 : in bus32;
          donnee2 : out bus32;
          ack2 : out std_logic;

          load : in std_logic;
          fname : in string
  );
  end component;

  signal clock : std_logic := '0';
  signal clock2 : std_logic := '0';
  signal reset : std_logic;

  signal it_mat : std_logic := '0';

  -- Connexion with the code memory
  signal load : std_logic;
  signal fichier : string(1 to 7) := "rom.bin";

  -- Connexion with the Ram
  signal ram_req : std_logic;
  signal ram_adr : bus32;
  signal ram_r_w : std_logic;
  signal ram_data : bus32;
  signal ram_rdy : std_logic;

  signal ram_req2 : std_logic;
  signal ram_adr2 : bus32;
  signal ram_r_w2 : std_logic;
  signal ram_data2 : bus32;
  signal ram_rdy2 : std_logic;

  signal end_sim : std_logic := '0';

begin

    U_minimips : minimips port map (
        clock => clock,
	     clock2 => clock2,
        reset => reset,
        ram_req => ram_req,
        ram_adr => ram_adr,
        ram_r_w => ram_r_w,
        ram_data => ram_data,
        ram_ack => ram_rdy,

        ram_req2 => ram_req2,
        ram_adr2 => ram_adr2,
        ram_r_w2 => ram_r_w2,
        ram_data2 => ram_data2,
        ram_ack2 => ram_rdy2,

        it_mat => it_mat
    );

    U_ram : ram port map (
        req => ram_req,
        adr => ram_adr,
        data_inout => ram_data,
        r_w => ram_r_w,
        ready => ram_rdy,

        req2 => ram_req2,
        adr2 => ram_adr2,
        data_inout2 => ram_data2,
        r_w2 => ram_r_w2,
        ready2 => ram_rdy2
    );

    U_rom : rom port map (
        adr => ram_adr,
        donnee => ram_data,
        ack => ram_rdy,

        adr2 => ram_adr2,
        donnee2 => ram_data2,
        ack2 => ram_rdy2,

        load => load,
        fname => fichier
    );

    --clock <= not clock after 10 ns;
    clock <= not clock after 100 ns;
    clock2 <= not clock2 after 100 ns;
    --reset <= '0', '1' after 5 ns, '0' after 25 ns;
    reset <= '0', '1' after 25 ns, '0' after 350 ns;
    --ram_data <= (others => 'L');
    --ram_data2 <= (others => 'L');

    load <= '1', '0' after 25 ns;

    -- Memory Mapping --
    -- 0000 - 00FF      ROM

    process (ram_adr, ram_r_w, ram_data)
    begin -- Emulation of an I/O controller
        ram_data <= (others => 'Z');

        case ram_adr is
            when X"00002000" => -- declenche une lecture avec interruption
                                it_mat <= '1' after 1000 ns;
                                ram_rdy <= '1' after 5 ns;
            when X"00002001" => -- fournit la donnee et lache l'it
                                it_mat <= '0';
                                ram_data <= X"FFFFFFFF";
                                ram_rdy <= '1' after 5 ns;
            when others      => ram_rdy <= 'L';
        end case;
    end process;

    -- STOP SIMULATION PROCESS
  process (clock, reset)
     variable ram_adr_bak : bus32;
     variable count : integer;
  begin
     if reset = '1' then
        ram_adr_bak := (others => '0');
        count := 0;
     elsif clock'event and clock='1' then
        if ram_adr_bak = ram_adr then
           count := count + 1;
        else
           count := 0;
           ram_adr_bak := ram_adr;
        end if;
        if count > threshold then
           end_sim <= '1';
        end if;
     end if;
  end process;

end bench;
