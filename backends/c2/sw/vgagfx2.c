
// Read a byte, modify its hi or lo part, write it back
inline void _vmemblend(int32 pos, int32 mask, int32 v)
{
        inline verilog reset {
                vmem_re <= 0;
        };
        int32 tmp = inline verilog exec(pos) {
                vmem_in_addr <= pos;
                vmem_re <= 1;
        } wait (vmem_re) {
                vmem_re <= 0;
        } return ( vmem_p1_out_data );
        tmp = (tmp&mask)|v;
        inline verilog exec(pos, tmp) {
                vmem_in_addr <= pos;
                vmem_we <= 1;
                vmem_in_data <= tmp;
        } wait (vmem_we) {
                vmem_we <= 0;
        };
}


inline void _vmemsetpixel(int32 x, int32 y, int32 v)
{
        int32 pos = (x>>1) + y * 320;
        int32 odd = x&1;
        int32 nv = odd?v:v<<4;
        _vmemblend(pos, odd?0xf0:0x0f, nv);
}


