
 __hls void edgecache(int.1 we, int.32 addr, int.64 val, int.64 *out)
 {
     int.32 addrs[64];
     int.64 values[64];
     for (int.16 i = 0; i < 64; i++) {
       if (we) {
          if (addrs[i] == 0) {
              addrs[i] = addr; values[i] = val;
              return;
          }
       } else {
         if (addrs[i] == addr) {
              *out = values[i];
              return;
         }
       }
     }
 }


