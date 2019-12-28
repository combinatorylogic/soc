
inline float _FMUL(float a0, float b0)
{
        inline verilog usemodule "../hw/rtl/fphls_mul.v";
        inline verilog instance hls_FMulFSM(ack = f_mul_ack,
                                            p0  = reg f_mul_p0,
                                            p1  = reg f_mul_p1,
                                            req = reg f_mul_req,
                                            out = f_mul_out);
        inline verilog reset {
                f_mul_req <= 0;
                f_mul_p0 <= 0;
                f_mul_p1 <= 0;
        };
        inline verilog exec(a0, b0) {
                f_mul_p0 <= a0;
                f_mul_p1 <= b0;
                f_mul_req <= 1;
        } wait (f_mul_ack) {
                f_mul_req <= 0;
                } else { f_mul_req <= 0; };
        return (bitcast:float)(inline verilog exec {} return ( f_mul_out ));
}

inline float _FADD(float a0, float b0)
{
        inline verilog usemodule "../hw/rtl/fpaddsub.v";
        inline verilog instance FAddSubFSM(ack = f_add_ack,
                                           subp = reg f_subp,
                                           p0  = reg f_add_p0,
                                           p1  = reg f_add_p1,
                                           req = reg f_add_req,
                                           out = f_add_out);
        inline verilog reset {
                f_add_req <= 0;
                f_add_p0 <= 0;
                f_add_p1 <= 0;
                f_subp <= 0;
        };
        inline verilog exec(a0, b0) {
                f_add_p0 <= a0;
                f_add_p1 <= b0;
                f_subp <= 0;
                f_add_req <= 1;
        } wait (f_add_ack) {
                f_add_req <= 0;
                } else { f_add_req <= 0; };
        return (bitcast:float)(inline verilog exec {} return ( f_add_out ));
}

inline float _FSUB(float a0, float b0)
{
        inline verilog exec(a0, b0) {
                f_add_p0 <= a0;
                f_add_p1 <= b0;
                f_subp <= 1;
                f_add_req <= 1;
        } wait (f_add_ack) {
                f_add_req <= 0;
                } else { f_add_req <= 0; };
        return (bitcast:float)(inline verilog exec {} return ( f_add_out ));
}


inline float _FDIV(float a0, float b0)
{
        inline verilog usemodule "../hw/rtl/fphls_div.v";
        inline verilog instance hls_FDivFSM(ack = f_div_ack,
                                            p0  = reg f_div_p0,
                                            p1  = reg f_div_p1,
                                            req = reg f_div_req,
                                            out = f_div_out);
        inline verilog reset {
                f_div_req <= 0;
                f_div_p0 <= 0;
                f_div_p1 <= 0;
        };
        inline verilog exec(a0, b0) {
                f_div_p0 <= a0;
                f_div_p1 <= b0;
                f_div_req <= 1;
        } wait (f_div_ack) {
                f_div_req <= 0;
                } else { f_div_req <= 0; };
        return (bitcast:float)(inline verilog exec {} return ( f_div_out ));        
}

inline int32 _OGT(float a0, float b0)
{
        
        inline verilog define {
                wire [31:0] ogt_out;
                hls_OGT ogt_111 (.clk(clk),
                                 .reset(rst),
                                 .p0(exec_arg1),
                                 .p1(exec_arg2),
                                 .out(ogt_out));
        };

        return (inline verilog exec(a0, b0) {}
                               return (ogt_out));
}


inline float _SITOFP(int32 v)
{
        inline verilog usemodule "../hw/rtl/fphls_sitofp.v";
        inline verilog instance hls_SIToFPFSM(ack = f_conv_ack,
                                              p0  = reg f_conv_p0,
                                              req = reg f_conv_req,
                                              out = f_conv_out);
        inline verilog reset {
                f_conv_req <= 0;
                f_conv_p0 <= 0;
        };
        inline verilog exec(v) {
                f_conv_p0 <= v;
                f_conv_req <= 1;
        } wait (f_conv_ack) {
                f_conv_req <= 0;
                } else { f_conv_req <= 0; };
        return (bitcast:float)(inline verilog exec {} return ( f_conv_out ));
}
