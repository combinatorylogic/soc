/*
  Pixel order in memory:
    0  1   2  3  4   5  6  7   -- pixel X pos
  RGBRGBRG BRGBRGBR GBRGBRGB ...
  AAAAAAAA BBBBBBBB AAAAAAAA ...
         0        1        2   -- lword offset


  E.g., byte address of a pixel is:

     D  = x%8 = x&7       --  pixel         address (8 locations in a triplet)
     T  = x/8 = x>>3      --  lword-triplet address (240 triplets)
     L3 = T*3 + 2         --  triplet base lword address in a row
   off3 = (7-D)*3         --  byte offset in a triplet
   off  = off3%8 
          = off3&7        -- byte offset in base lword
      L = L3 - off3/8 
        = L3 - off3>>3    -- base lword address in a row

  a*3 = a*2+a = a<<1+a


  E.g., the first word address 'L' and offset 'off' are following:

inline verilog define {
   reg [31:0]  w3_x;
   wire [31:0] w3_D       = w3_x[2:0];
   wire [31:0] w3_T       = w3_x[28:3];
   wire [31:0] w3_Tx2     = {w3_T[31:1], 1'b0};
   wire [31:0] w3_L3      = w3_Tx2 + w3_T + 2;
   wire [31:0] w3_revD    = 32'd7 - w3_D;
   wire [31:0] w3_revDx2  = {w3_revD[31:1], 1'b0};
   wire [31:0] w3_off3    = w3_revDx2 + w3_revD;
   wire [31:0] w3_off     = off3[2:0];
   wire [31:0] w3_L       = w3_L3 - {29'd0, off3[28:3]};
   reg [31:0] w3_off_r;
   reg [31:0] w3_L_r;
};

inline verilog exec(x) {
   w3_x <= x;
} wait(1) {
   w3_off_r <= w3_off;
   w3_L_r <= w3_L;
};



*/
 

/*
  Possible cases:
    XXXXXXXX YYYYYYYY
    AAA         5
     AAA        4
      AAA       3
       AAA      2
        AAA     1
         AAA    0
          AA A      7
           A AA     6
             AAA    5
              AAA   ...
               AAA
                AAA
                 AAA
                  AAA
    XXXXXXXX YYYYYYYY

  I.e., 6 possible shifts in one 64-bit word,
        and 3 possible cross-word shifts.

  Address & 0b111:  0 - 5  - full shift within one word
  Address & 0b111:  6, 7   - cross word cases

 */


inline void _ram1_calc_pixeloffsets(int32 pos, int32 x) {

inline verilog define {
   reg [31:0]  w3_x;
   wire [31:0] w3_D;
   assign w3_D = w3_x[2:0];
   wire [31:0] w3_T;
   assign w3_T = w3_x[28:3];
   wire [31:0] w3_Tx2;
   assign w3_Tx2 = {w3_T[30:0], 1'b0};
   wire [31:0] w3_L3;
   assign w3_L3 = w3_Tx2 + w3_T + 2;
   wire [31:0] w3_revD;
   assign w3_revD = 32'd7 - w3_D;
   wire [31:0] w3_revDx2;
   assign w3_revDx2 = {w3_revD[30:0], 1'b0};
   wire [31:0] w3_off3;
   assign w3_off3 = w3_revDx2 + w3_revD;
   wire [31:0] w3_off;
   assign w3_off = w3_off3[2:0];
   wire [31:0] w3_L;
   assign w3_L = w3_L3 - {29'd0, w3_off3[28:3]};
   reg [31:0] w3_off_r;
   reg [31:0] w3_L_r;
   reg [31:0] w3_addr_r;
   reg [31:0] w3_pos;
};

inline verilog reset {
  w3_off_r <= 0;
  w3_L_r <= 0;
  w3_addr_r <= 0;
  w3_pos <= 0;
};

inline verilog exec(pos, x) {
   w3_x <= x;
   w3_pos <= pos;
} wait(1) {
  $display("x=%d, D=%d, T=%d, L3=%d, off=%d, off3=%d", w3_x, w3_D, w3_T, w3_L3, w3_off, w3_off3);
   w3_off_r <= w3_off;
   w3_L_r <= w3_L;
   w3_addr_r <= w3_pos + (w3_L<<3);
};
    
}

inline void _ram1_slow_write(uint32 dst)
// assume data register ram1_writedata_r is already set
// TODO: delay writing the data until destination address changes
//  (sort of a dumb write cache for pixels, will result in 3 times less write
//   transactions).
{
        inline verilog define {

                reg [28:0] ram1_address_r;
                reg [63:0] ram1_writedata_r;
                reg [7:0] ram1_byteenable_r;

		reg [63:0] ram1_value;
		reg [28:0] ram1_prev_address;
		reg [63:0] ram1_bytes_mask;
		wire [1:0] vga_bufid;
		
                reg ram1_write_r;
                reg ram1_read_r;
		reg ram1_cache_hit;
		/*                
                assign ram1_address = ram1_address_r;
                assign ram1_burstcount = 1;
                assign ram1_writedata = ram1_writedata_r;
                assign ram1_byteenable = ram1_byteenable_r;
                assign ram1_write = ram1_write_r;
                assign ram1_read = ram1_read_r;
		*/
        };
        inline verilog reset {
                ram1_address_r <= 0;
                ram1_writedata_r <= 0;
                ram1_byteenable_r <= 0;
                ram1_write_r <= 0;
                ram1_read_r <= 0;
		ram1_value <= 0;
		ram1_prev_address <= 0;
		ram1_cache_hit <= 0;
		ram1_bytes_mask <= 0;
        };
        inline verilog exec(dst) {
	  ram1_writedata_r <= (ram1_value & (~ram1_bytes_mask)) | ram1_writedata_r;
	        ram1_value <=       (ram1_value & ~ram1_bytes_mask) | ram1_writedata_r; // cache the value
                ram1_address_r <= dst >> 3;
                ram1_byteenable_r <= 8'b11111111;
                ram1_write_r <= 1;
		$display("Writing %x at %x (off=%d, L=%d x=%d)", ((ram1_value & (~ram1_bytes_mask)) | ram1_writedata_r), dst>>3,
			 w3_off_r, w3_L_r, w3_x);
	};
		    
}


inline void _ram1_calc_mask(int32 off, int32 v3b)
{
        inline verilog define {
                reg [23:0] ram1_w3b_rgb;
                reg [3:0] ram1_w3b_offset;
                wire [63:0] ram1_w3b_data;
                wire [63:0] ram1_w3b_mask;
                offsetit64 off001 
                          (.clk(clk),
                           .rst(rst),

                           .rgb(exec_arg2[23:0]),   // v3b
                           .offset(exec_arg1[3:0]), // off
                           .data(ram1_w3b_data),
                           .mask(ram1_w3b_mask));
        };
        
                inline verilog exec (off, v3b) {
                        ram1_w3b_rgb <= v3b[23:0];
                        ram1_w3b_offset <= off[3:0];
                } wait(1) {
                        ram1_bytes_mask <= ram1_w3b_mask;
                        ram1_writedata_r <= ram1_w3b_data;
			$display("calc_mask: %x %x", ram1_w3b_mask, ram1_w3b_data);
                };
}

inline void _ram1_w3b(int32 dst, int32 v3b)
{
        int32 off = inline verilog  exec(dst) {} return (w3_off_r);
        if (off > 5) { // 2-word write
                int32 addr = dst;
                int32 off1 = off==7?8:9;
                _ram1_calc_mask(off1, v3b); 
                _ram1_slow_write(addr-8);
		
                _ram1_calc_mask(off, v3b);
                _ram1_slow_write(addr);
        } else {
                int32 addr = dst;
                _ram1_calc_mask(off, v3b);
                _ram1_slow_write(addr);
        }
}

inline void _vga_swapbuffer()
{
        inline verilog define {
                reg [1:0] vga_bufid_r;
                assign vga_bufid = vga_bufid_r;
        };
        inline verilog reset {
                vga_bufid_r <= 0;
        };
        inline verilog exec {
                vga_bufid_r[0] <= 0;// ~vga_bufid_r[0];
        };
};

inline void _vga_putpixel(int32 x, int32 y, int32 color)
{
        int32 rowpos = y * 5760; //byte-aligned address, can we optimise it somehow?
	_ram1_calc_pixeloffsets(rowpos, x);
        int32 addr = inline verilog exec (x) {}
                      return ( 
			      {6'b10, vga_bufid[1:0], w3_addr_r[22:0]}
                             );
        _ram1_w3b(addr, color);
 }
