inline void _sleep(uint32 ms)
{
        int32 time = ms * 25000;
        inline verilog define { reg [31:0] sleep_counter; };
        inline verilog reset {
                sleep_counter <= 0;
        };
        inline verilog exec(time) {
                sleep_counter <= time;
        } wait (sleep_counter == 0) {
                sleep_counter <= 0;
        } else { sleep_counter <= sleep_counter - 1; };
}


inline void _vmemset(uint32 addr, uint32 v)
{
        inline verilog reset {
                data_we_cpu <= 0;
                data_rq_cpu <= 0;
                sram_adr_cpu <= 0;
                sram_out <= 0;};
        inline verilog exec(addr, v) {
                sram_adr_cpu <= addr[17:0];
                sram_out <= v[15:0];
                data_rq_cpu <= 1;
        } wait (data_we_cpu) {
                data_we_cpu <= 0;
                data_rq_cpu <= 0;
        } else {
                if (grant_cpu) begin
                        data_we_cpu <= 1;
                end
        };
}

void _vmemcls()
{
        for (int32 i = 0; i < 19200; i++) _vmemset(i, 0);
}

inline void _vgaenable()
{
        inline verilog reset {
                vgaenable <= 0;
        };
        int32 i = 0;
        inline verilog exec (i) {
                vgaenable <= 1;
        };
}
