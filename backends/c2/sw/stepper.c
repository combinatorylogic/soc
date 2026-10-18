
inline void _stepper_nsteps(int idx, int n, int dir)
{
        // Verilog part: instantiate stepper controllers and
        // expose their interfaces.
        inline verilog include "../rtl/stepperctl.v";
        inline verilog define {
                reg [3:0] stepper_req;
                reg [3:0] stepper_dir;
                reg [31:0] stepper_nsteps;
                wire [3:0] stepper_ready;
                reg [1:0] stepper_idx;
                wire current_stepper_ready;
                assign current_stepper_ready =
                        stepper_idx == 0?stepper_ready[0]:
                        stepper_idx == 1?stepper_ready[1]:
                        stepper_idx == 2?stepper_ready[2]:
                        stepper_idx == 3?stepper_ready[3]:0;
                
                stepperctl c1 (.clk(clk),
                               .rst(rst),
                               .ctl(STEPPER1),
                               .ready(stepper_ready[0]),
                               .req(stepper_req[0]),
                               .nsteps(stepper_nsteps),
                               .dir(stepper_dir[0]));
                stepperctl c2 (.clk(clk),
                               .rst(rst),
                               .ctl(STEPPER2),
                               .ready(stepper_ready[1]),
                               .req(stepper_req[1]),
                               .nsteps(stepper_nsteps),
                               .dir(stepper_dir[1]));
                stepperctl c3 (.clk(clk),
                               .rst(rst),
                               .ctl(STEPPER3),
                               .ready(stepper_ready[2]),
                               .req(stepper_req[2]),
                               .nsteps(stepper_nsteps),
                               .dir(stepper_dir[2]));
                stepperctl c4 (.clk(clk),
                               .rst(rst),
                               .ctl(STEPPER4),
                               .ready(stepper_ready[3]),
                               .req(stepper_req[3]),
                               .nsteps(stepper_nsteps),
                               .dir(stepper_dir[3]));
        };
        // Extended instructions: accessing steppers interface

        inline verilog reset {
                stepper_req <= 0;
                stepper_dir <= 0;
                stepper_nsteps <= 0;
        };

        int dir4 = (dir&1) << idx;
        int nsteps4 = n;
        int req4 = 1 << idx;
        // Set direction and nsteps
        inline verilog exec (dir4,nsteps4) {
                stepper_dir <= dir4;
                stepper_nsteps <= nsteps4;
        };
        // Make sure a selected stepper is ready
        inline verilog exec (idx) {
                stepper_idx <= idx;
        } wait (current_stepper_ready) {
        };
        // Issue a req for this stepper
        inline verilog exec (req4) {
                stepper_req <= req4;
        } wait (1) {
                stepper_req <= 0;
        };
}


inline int _stepper_ready()
{
        return inline verilog exec {} return ( stepper_ready );
}

inline void _stepper_wait_all()
{
        inline verilog exec {
        } wait ( stepper_ready == 4'b1111 ) {};
}
