-- vim: sw=4 ts=4 et
-- 2 hot 2 handle
--
-- An NCL bit is basically two rail one-hot specified as such:
--
--   d : std_logic_vector(1 downto 0);
--
--   d = "00" -- NULL
--   d = "10" -- 0, note d(1) = '1', d(0) = '0'
--   d = "01" -- 1
--
-- Our NCL implementation operates as follows:
--
--   entity foo is
--     port( d : (in) ncl_logic(7 downto 0) );
--   end foo;
--
-- d(0)(L) will give the low bit, d(0)(H) will give the high bit,
-- on data bit 0.
library IEEE;
use IEEE.std_logic_1164.all;

package ncl is
    type ncl_logic is record
        L : std_logic;
        H : std_logic;
    end record;

    type ncl_logic_vector is array (natural range <>) of ncl_logic;

    -- NULL check
    function ncl_is_null(d : ncl_logic)        return std_logic;
    function ncl_is_null(d : ncl_logic_vector) return std_logic_vector;
    -- Encoder and decoder
    function ncl_encode (d : std_logic)        return ncl_logic;
    function ncl_encode (d : std_logic_vector) return ncl_logic_vector;
    function ncl_decode (d : ncl_logic)        return std_logic;
    function ncl_decode (d : ncl_logic_vector) return std_logic_vector;
    -- Logic operators
    function "and"  (l, r: ncl_logic) return ncl_logic;
    function "nand" (l, r: ncl_logic) return ncl_logic;
    function "or"   (l, r: ncl_logic) return ncl_logic;
    function "nor"  (l, r: ncl_logic) return ncl_logic;
    function "xor"  (l, r: ncl_logic) return ncl_logic;
    function "xnor" (l, r: ncl_logic) return ncl_logic;
    function "not"  (l   : ncl_logic) return ncl_logic;
    -- Logical operators on multiple bits
    function "and"  (l, r: ncl_logic_vector) return ncl_logic_vector;
    function "nand" (l, r: ncl_logic_vector) return ncl_logic_vector;
    function "or"   (l, r: ncl_logic_vector) return ncl_logic_vector;
    function "nor"  (l, r: ncl_logic_vector) return ncl_logic_vector;
    function "xor"  (l, r: ncl_logic_vector) return ncl_logic_vector;
    function "xnor" (l, r: ncl_logic_vector) return ncl_logic_vector;
    function "not"  (l   : ncl_logic_vector) return ncl_logic_vector;
end;

package body ncl is
    -- returns the glitch "11" as NULL as well
    function ncl_is_null(d: ncl_logic) return std_logic is
    begin
        return d.H XNOR d.L;
    end function;

    function ncl_is_null(d : ncl_logic_vector) return std_logic_vector is
        variable dout : std_logic_vector(d'RANGE);
    begin
        for i in d'RANGE loop
            dout(i) := ncl_is_null(d(i));
        end loop;
        return dout;
    end function;

    function ncl_encode (d : std_logic) return ncl_logic is
    begin
        return (L <= d, H <= NOT d);
    end function;

    function ncl_encode (d : std_logic_vector) return ncl_logic_vector is
        variable dout : ncl_logic_vector(d'RANGE);
    begin
        for i in d'RANGE loop
            dout(i) := ncl_encode(d(i));
        end loop;
        return dout;
    end function;

    -- In NCL, the low bit represents the value and the high
    -- bit is the inverse of the value.
    function ncl_decode (d : ncl_logic) return std_logic is
    begin
        -- Invalid, can't decode.
        -- Can't read this reliably, so check BEFORE decoding!
        if (ncl_is_null(d)) then
            return 'U';
        end if;
        return (d.L);
    end function;

    function ncl_decode (d : ncl_logic_vector) return std_logic_vector is
        variable dout : std_logic_vector(d'RANGE);
    begin
        for i in d'RANGE loop
            dout(i) := ncl_decode(d(i));
        end loop;
        return dout;
    end function;

    -- For all logical functions, the low bit is the logical
    -- operator applied to the low bits, and the high bit is
    -- the inverse applied to the high bits.
    --
    -- If either is NULL, return NULL.
    function "and" (l, r : ncl_logic) return ncl_logic is
    begin
        if (ncl_is_null(l) OR ncl_is_null(r)) then
            return (H<='0', L<='0');
        end if;
        return (L<= l.L AND r.L, H<= l.H NAND r.H);
    end function;

    function "nand" (l, r : ncl_logic) return ncl_logic is
    begin
        if (ncl_is_null(l) OR ncl_is_null(r)) then
            return (H<='0', L<='0');
        end if;
        return (L<= l.L NAND r.L, H<= l.H AND r.H);
    end function;

    function "or" (l, r : ncl_logic) return ncl_logic is
    begin
        if (ncl_is_null(l) OR ncl_is_null(r)) then
            return (H<='0', L<='0');
        end if;
        return (L<= l.L OR r.L, H<= l.H NOR r.H);
    end function;

    function "nor" (l, r : ncl_logic) return ncl_logic is
    begin
        if (ncl_is_null(l) OR ncl_is_null(r)) then
            return (H<='0', L<='0');
        end if;
        return (L<= l.L NOR r.L, H<= l.H OR r.H);
    end function;

    function "xor" (l, r : ncl_logic) return ncl_logic is
    begin
        if (ncl_is_null(l) OR ncl_is_null(r)) then
            return (H<='0', L<='0');
        end if;
        return (L<= l.L XOR r.L, H<= l.H XNOR r.H);
    end function;

    function "xnor" (l, r : ncl_logic) return ncl_logic is
    begin
        if (ncl_is_null(l) OR ncl_is_null(r)) then
            return (H<='0', L<='0');
        end if;
        return (L<= l.L XNOR r.L, H<= l.H XOR r.H);
    end function;

    function "not" (l    : ncl_logic) return ncl_logic is
    begin
        if (ncl_is_null(l)) then
            return (H<='0', L<='0');
        end if;
        return (L<= NOT l.L, H<= NOT l.H);
    end function;

    -- Above functions on arrays
    function "and" (l, r : ncl_logic_vector) return ncl_logic_vector is
        variable dout : ncl_logic_vector(l'RANGE);
    begin
        for i in l'RANGE loop
            dout(i) := l(i) AND r(i));
        end loop;
        return dout;
    end function;

    function "nand" (l, r : ncl_logic_vector) return ncl_logic_vector is
        variable dout : ncl_logic_vector(l'RANGE);
    begin
        for i in l'RANGE loop
            dout(i) := l(i) NAND r(i));
        end loop;
        return dout;
    end function;

    function "or" (l, r : ncl_logic_vector) return ncl_logic_vector is
        variable dout : ncl_logic_vector(l'RANGE);
    begin
        for i in l'RANGE loop
            dout(i) := l(i) OR r(i));
        end loop;
        return dout;
    end function;

    function "nor" (l, r : ncl_logic_vector) return ncl_logic_vector is
        variable dout : ncl_logic_vector(l'RANGE);
    begin
        for i in l'RANGE loop
            dout(i) := l(i) NOR r(i));
        end loop;
        return dout;
    end function;

    function "XOR" (l, r : ncl_logic_vector) return ncl_logic_vector is
        variable dout : ncl_logic_vector(l'RANGE);
    begin
        for i in l'RANGE loop
            dout(i) := l(i) XOR r(i));
        end loop;
        return dout;
    end function;

    function "XNOR" (l, r : ncl_logic_vector) return ncl_logic_vector is
        variable dout : ncl_logic_vector(l'RANGE);
    begin
        for i in l'RANGE loop
            dout(i) := l(i) XNOR r(i));
        end loop;
        return dout;
    end function;

    function "not" (l    : ncl_logic_vector) return ncl_logic_vector is
        variable dout : ncl_logic_vector(l'RANGE);
    begin
        for i in l'RANGE loop
            dout(i) := NOT l(i));
        end loop;
        return dout;
    end function;
end package body;
