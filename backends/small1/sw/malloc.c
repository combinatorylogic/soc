

// memory pool - always placed at the end of the code segment 
int32 _data[1];

// very stupid and expensive malloc

void _splitblock(int32 blockpos, int32 len, int32 blocklen, int32 blocknext, int32 blockprev)
{
  int32 newblock = blockpos + 2 + len;
  _data[blockpos] = len;
  _data[blockpos+1] = 0;
  _data[blockprev] = newblock;
  _data[newblock] = blocklen - len - 2;
  _data[newblock+1] = blocknext;
}

int32 *malloc(int32 len)
{
  int32 blockpos = _data[0];
  int32 blockprev = 0;

  while(1) {
    int32 blocklen = _data[blockpos];
    int32 blocknext = _data[blockpos + 1];
    if (len <= blocklen) { // use this block
      _splitblock(blockpos, len, blocklen, blocknext, blockprev);
      return &(_data[blockpos+2]); // This is where an allocated chunk is
    } else {
      blockprev = blockpos + 1;
      blockpos = blocknext;
    }
    if (blockpos == 0) return _intptr(0); // out of memory
  }
}

void free(int32 *ptr)
{
  int32 pos = _ptrint(ptr) - _ptrint(_data);
  ptr[-1] = _data[0];
  _data[0] = pos-2;
}


void _mem_init() {
  _data[0] = 1; // next free block
  _data[1] = 33554432 - (_ptrint(_data) - 0x20000);
    // LogiPi got 256Mb SDRAM, Atlys got only 128Mb
    // And we may later need an area for the memory-mapped cached stacks,
    // if we ever do multitasking
  _data[2] = 0; // next free block
}
