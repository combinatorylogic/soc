

// Send a value to vmem
void _vmemset(uint32 addr, uint32 val)
{
	uint32 *channel = _intptr(0x10010);
	uint32 pack = (addr*256) | (val&0xff);
	*channel = pack; // send a word
}

// May be useful?
void _vmemcpy(uint32 *buf, uint32 len)
{
	uint32 *channel = _intptr(0x10010);
	uint32 addr;
	for(addr = 0; addr < len; addr++) {
		uint32 val = buf[addr];
		uint32 pack = (addr*256) | (val&0xff);
		*channel = pack; // send a word
	}
}

// Initialise 8x8 font from a packed 32-bit array.
void _vmempackcpy(uint32 *buf, uint32 len)
{
	uint32 *channel = _intptr(0x10010);
	uint32 addr,i, iaddr;
	addr = 0;
	for(iaddr=0;;iaddr++) {
		uint32 val = buf[iaddr];
		for (i = 0; i < 4; i++) {
			uint32 pack = (addr*256) | (val&0xff);
			*channel = pack; // send a word
			val = val >> 8;
			addr++;
			if (addr >= len) return;
		}
	}
}

##syntax of pfclike in cltop, start: ' [cltypebase]:t [clvarname]:name "=" [fontexpr]:c ";" '
+ {
     fontexpr := ".font:" slist<[fontentry]>:es => es;
     fontentry := [clchar]:c ":" "|"? cslist<[frow],"|">:rows => x(c,rows);
     frow := slist<[chrx]>:cs => cs;
     chrx := { ("_"/".") => {state=pattern} {ctoken=ident} z() }
          /  { ("X" / "x" / "#" / "*") => {ctoken=lexic} o() }
	  ;
  }
{
   n_lshift(a, b) =
     notnet(int a, int b)
       {leave a<<b;};

   ar = %not-init-array(Int32, 128*2, 0);
   mkbyte(r) = foldl(fun(k,i) n_lshift(k,1) + i, 0,
                  map r do match r with z() -> 0 | else -> 1);
		  
   iter x(c,rows) in c do
     {
        bytes = map r in rows do mkbyte(r);
	quads = do loop(b = bytes, i = 0, l = [], m = [])
	           match b with
		      hd:tl -> if(i<4) loop(tl, i+1, l::[hd], m)
			       else loop(tl,0,[hd], m::[l])
                    | else -> if(l) m::[l] else m;
        words = map bs in quads do foldl(fun(k,i) n_lshift(k, 8) + i, 0, reverse(bs));
        aset(ar, c*2, car(words));
	aset(ar, c*2+1, cadr(words))
     };
   lar = %a->l(ar);
   ca = 'constarray'(@map l in lar do 'integer'('i32', l));
   return 'global'([], t, name, ca)
}


#include "fnt.h"

void initvga()
{
   _vmempackcpy(font, 128*8);

   /*
   int32 i,l;
   int32 offset = 1024;
   l = 80*60;
   int32 chr = 'A'; int32 d = 0;
   for (int32 y = 0; y < 60; y++) {
	   for (int32 x = 0; x < 80; x++) {
		   int32 pos = x + y * 80;
		   _vmemset(pos+offset, (d%95)+32);
		   d++;
	   }
   }
   */
}
