

inline void _smemset(uint32 num, uint32 val)
{
        uint32 *channel = (uint32*)(65553);
        uint32 pack = (num<<8) | val;
        *channel = pack;
}

/*
    AAAAAA
   F      B
   F      B
   F      B
    GGGGGG
   E      C
   E      C
   E      C
    DDDDDD    PP

   0  A    1  B    2  C    3  D    4  E
   5  F    6  G    7  P 

0: ABCDEF
1: BC
2: ABGED
3: ABGCD
4: FBGC
5: AFGCD
6: AFGECD
7: ABC
8: AFBGECD
9: AFBGCD
 */

##syntax of pfclike in clconst, inner: ' "::7seg" [number]:n? slist<[UCAlpha]>:ls '
        + { @UCAlphaTk := [A-Z];
            UCAlpha := [UCAlphaTk]:i => $sval(i); }
{       num = foldl (fun (a, b) a+b, 0,
                     map l in ls do
                     case l {
                             'A' -> 1
                           | 'B' -> 2
                           | 'C' -> 4
                           | 'D' -> 8
                           | 'E' -> 16
                           | 'F' -> 32
                           | 'G' -> 64
                           | 'P' -> 128
                           | else -> 0});
        return 'integer'('i32', num); }

        
uint32 digits_7seg[10] =
        {
         ::7seg 0 ABCDEF,
         ::7seg 1 BC,
         ::7seg 2 ABGED,
         ::7seg 3 ABGCD,
         ::7seg 4 FBGC,
         ::7seg 5 AFGCD,
         ::7seg 6 AFGECD,
         ::7seg 7 ABC,
         ::7seg 8 AFBGECD,
         ::7seg 9 AFBGCD
        };

void _sseg_digit(uint32 pos, uint32 d)
{
        if (d>9) return;
        uint32 v = digits_7seg[d];
        _smemset(pos, v);
}


void _sseg_num(uint32 n)
{
        int32 tmp[8];
        int i;
        itoa(n, tmp);
        for (i = 0; i < 8; i++)
                _smemset(i, 0);
        for (i = 0; tmp[i]; i++)
                _sseg_digit(7-i, tmp[i] - '0');
}
