//none
`ifdef ICE_DEBUG
output [31:0] PCdebug,
`endif
`ifdef ICE_STEPPERS
                 output [3:0] STEPPER1,
                 output [3:0] STEPPER2,
                 output [3:0] STEPPER3,
                 output [3:0] STEPPER4,
`endif  
