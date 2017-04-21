#include "../runtime.c"

__hls void primes(int32 stage, int32 prev, int32 *next) {
        int32 buf[1025];
        if (stage == 0) { // Precharge
                for (int i = 0; i < 1025; i++) buf[i] = 0;
                for (int m = 2; m <= 32; m++) {
                        if (!buf[m]) {
                                for (int k = m + m; k <= 1024; k+= m)
                                        buf[k] = 1;
                        }
                }
        } else if (stage == 1) { // Fetch
                for (int i = prev; i < 1025; i++) {
                        if (!buf[i]) {
                                *next = i;
                                return;
                        }
                }
                *next = 0;
                return;
        }
}

void sw_primes() {
        int32 sbuf[1025]; // using stack because it's faster than DDR
        for (int i = 0; i < 1025; i++) sbuf[i] = 0;
        for (int m = 2; m <= 32; m++) {
                if (!sbuf[m]) {
                                for (int k = m + m; k <= 1024; k+= m)
                                        sbuf[k] = 1;
                }
        }
}

void _printtst(int32 *str, int32 num)
{
  int32 buf[32];
  _print(str);
  itoa(num, buf);
  _print(buf);
  _print("\n");
}

void bootentry()
{
        int32 ret;
        int32 c0 = _perfcounter();
        primes(0, 0, &ret); // initialise
        int32 c1 = _perfcounter();

        int32 c0s = _perfcounter();
        sw_primes();
        int32 c1s = _perfcounter();

        ret = 1;
        _printtst(">>  Cycles: ", c1-c0);
        _printtst(">>  SW cycles: ", c1s-c0s);
        do {    // fetch
                primes(1, ret+1, &ret);
                _printtst("Next prime: ", ret);
        } while (ret!=0);
        _testhalt();
}
