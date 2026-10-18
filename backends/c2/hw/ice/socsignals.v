
                 input RX,
                 output TX,

                 output LED1,
                 output LED2,
                 output LED3,
                 output LED4,
                 output LED5,
                 output LED6,
                 output LED7,
                 output LED8,

`ifdef ICE_DEBUG                       
                 output PCdebug1,
                 output PCdebug2,
                 output PCdebug3,
                 output PCdebug4,
                 output PCdebug5,
                 output PCdebug6,
                 output PCdebug7,
                 output PCdebug8,
`endif                      

`ifdef ICE_STEPPERS
                 output [3:0] STEPPERX1,
                 output [3:0] STEPPERX2,
                 output [3:0] STEPPERX3,
                 output [3:0] STEPPERX4,
`endif                       
