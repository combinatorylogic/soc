
int parse_num(int *buf, int *res)
{
        int ibuf[16];
        int pos = 0;
        int idx = 0;
        // Skip whitespace and whatever else
        for(;;) {
                int c = buf[idx];
                if((c>='0' && c<='9') || (c == '-')) {
                        break;
                } else if (!c) return 0;
                else idx++;
        }
        for(;;) {
                int c = buf[idx];
                if (c==0) break;
                if (!((c>='0' && c<='9') || c == '-')) break;
                ibuf[pos++] = c;
                idx++;
        }
        if (pos>0) {
                pos--;
                int reslt = 0;
                int mult = 1;
                for (;pos>=0;pos--) {
                        int c = ibuf[pos];
                        if (c=='-') {reslt = -reslt; break;}
                        reslt += (c-'0') * mult;
                        mult *= 10;
                }
                *res = reslt;
        }
        return idx;
}
