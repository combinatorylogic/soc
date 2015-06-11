#include "../runtime.c"
#include "../malloc.c"
#include "../parsing_0.c"

int32 tmp[128];
void _printnum(int32 *str, int32 v)
{
  itoa(v,tmp);
  _print(str);
  _print(tmp);
  _print("\n");
}
void _printpos(int32 *str, int32 *ptr)
{
  int32 p = _ptrint(ptr);
  itoah(p,tmp);
  _print(str);
  _print(tmp);
  _print("\n");
}

void bootentry()
{
  _mem_init();

  parsefun *f = mksequence(mkparsechar('A'),
                           mksequence(mkparsechar('B'),
                                      mkparsechar('C')));

  parsefun *g = mksequence(mkparsechar('D'),
                           mksequence(mkparsechar('E'),
                                      mkparsechar('F')));

  parsefun *z = mkplus(mkchoice(mkparsechar('G'),
                                mkparsechar('H')));

  pcontext *ctx = (pcontext *)malloc(sizeof(pcontext));
  ctx -> str = "ABCDEFGHHGGHGHGHGGG000";
  ctx -> eof = 0;
  ctx -> pos = 0;
  ctx -> len = strlen(ctx->str);

  int v = runparser(ctx, f);
  _printnum("V=", v);
  _printnum("POS=", ctx->pos);
  v = runparser(ctx, f);
  _printnum("V1=", v);
  _printnum("POS1=", ctx->pos);
  v = runparser(ctx, g);
  _printnum("V2=", v);
  _printnum("POS2=", ctx->pos);
  v = runparser(ctx, z);
  _printnum("V3=", v);
  _printnum("POS3=", ctx->pos);
  _testhalt();
}
