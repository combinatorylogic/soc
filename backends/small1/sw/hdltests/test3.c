#include "../runtime.c"

int32 buf[128];
void _printtsth(int32 *str, int32 num)
{
  _print(str);
  itoah(num, buf);
  _print(buf);
  _print("\n");
}

void bootentry()
{
  int x = 0xfa;
  int y = 0xfb;
  inline verilog define {
    wire [31:0] test3_tmp;
  };
  inline verilog define {
    assign test3_tmp = {stack_data_a[7:0], stack_data_b[7:0]};
  };
  _printtsth("result=",inline verilog exec(x,y) {} return (test3_tmp));
  _testhalt();
}
