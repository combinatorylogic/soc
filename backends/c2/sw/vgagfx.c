inline void _vmemcls()
{
        inline verilog reset { vga_clsrq <= 0; vmem_we <= 0; };
        inline verilog exec {
                vga_clsrq <= 1;
        } wait (vga_clsack) { vga_clsrq <= 0; } else { vga_clsrq <= 0; };
}

inline void _vmemdump()
{
        int32 *channel = (int32*)(65599);
        *channel = 1;
}


inline void _vmemwaitscan()
{
        inline verilog exec { vmem_bufswap <= vmem_bufswap; } wait (vga_scan) { vmem_bufswap <= vmem_bufswap; }
        else { vmem_bufswap <= vmem_bufswap; };
}


inline void _vmemswap()
{
        inline verilog reset { vmem_bufswap <= 0; };
        inline verilog exec {
                vmem_bufswap <= ~vmem_bufswap;
        } noreturn;
}
