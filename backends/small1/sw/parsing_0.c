
typedef struct _pcontext {
  int *str;
  int pos;
  int len;
  int eof;
  void *extra;    // binding context, etc.
  void *poolptr;  // pool allocator handler or NULL if using plain malloc
} pcontext;

typedef ::fun void(pcontext *, void *, int *) parsefunptr;
typedef struct _parsefun {
  parsefunptr *fn;
  void *env;
} parsefun;

int peek(pcontext *ctx) {
  if(ctx->eof) return -1;
  return ctx->str[ctx->pos];
}

void advance(pcontext *ctx) {
  if (ctx->eof) return;
  ctx->pos++;
  if (ctx->pos >= ctx->len) ctx->eof = 1;
}

int savepos(pcontext *ctx) {
  return ctx->pos;
}

void restorepos(pcontext *ctx, int npos) {
  ctx->pos = npos; ctx->eof = 0;
}

int runparser(pcontext *ctx, parsefun *fn)
{
  int res;
  (*(fn->fn))(ctx, fn->env, &res);
  return res;
}

typedef struct _psequenceenv {
  parsefun *a;
  parsefun *b;
} psequenceenv;


void parsesequence(pcontext *ctx, void *env, int *res)
{
  *res = 0;
  psequenceenv *penv = (psequenceenv*)env;
  int opos = savepos(ctx);
  int r1 = runparser(ctx,penv->a);
  if (r1) {
    int r2 = runparser(ctx, penv->b);
    if (r2) {*res = r2; return;}
    else {
      restorepos(ctx, opos);
      return;
    }
  } else return;
}
parsefun *mksequence(parsefun *a, parsefun *b)
{
  psequenceenv *e = (psequenceenv *)malloc(sizeof(psequenceenv));
  e->a = a; e->b = b;
  parsefun *seq = (parsefun *)malloc(sizeof(parsefun));
  seq -> fn = &parsesequence;
  seq -> env = e;
  return seq;
}


void parsechoice(pcontext *ctx, void *env, int *res)
{
  *res = 0;
  psequenceenv *penv = (psequenceenv*)env;
  int r1 = runparser(ctx,penv->a);
  if (r1) {
    *res = r1;
    return;
  }
  int r2 = runparser(ctx, penv->b);
  if (r2) {*res = r2; return;}
}
parsefun *mkchoice(parsefun *a, parsefun *b)
{
  psequenceenv *e = (psequenceenv *)malloc(sizeof(psequenceenv));
  e->a = a; e->b = b;
  parsefun *seq = (parsefun *)malloc(sizeof(parsefun));
  seq -> fn = &parsechoice;
  seq -> env = e;
  return seq;
}


void parseplus(pcontext *ctx, void *env, int *res)
{
  parsefun* fn = (parsefun*)env;
  *res = 0;
  int r1 = runparser(ctx, fn);
  if (!r1) return;
  *res = r1;
  while(runparser(ctx, fn));
}
parsefun *mkplus(parsefun *fn)
{
  parsefun *pls = (parsefun *)malloc(sizeof(parsefun));
  pls -> fn = &parseplus;
  pls -> env = fn;
  return pls;
}

//// Char recogniser
int parsechar(pcontext *ctx, int chr)
{
  int next = peek(ctx);
  if (next == chr) {
    advance(ctx);
    return 1;
  }
  return 0;
}
void parsechar_w(pcontext *ctx, void *env, int *res)
{
  int chr = _ptrint(env);
  *res = parsechar(ctx, chr);
}
parsefun *mkparsechar(int chr)
{
  parsefun *fn = (parsefun *)malloc(sizeof(parsefun));
  fn -> fn = &parsechar_w;
  fn -> env = _intptr(chr);
  return fn;
}


////  Range recogniser
int parserange(pcontext *ctx, int from, int to)
{
  int next = peek(ctx);
  if (next >= from && next <= to) {
    advance(ctx);
    return 1;
  }
  return 0;
}
typedef struct _rangeenv {int from; int to;} rangeenv;
void parserange_w(pcontext *ctx, void *env, int *res) {
  rangeenv *penv = (rangeenv*)env;
  *res = parserange(ctx, penv->from, penv->to);
};
parsefun *mkparserange(int from, int to)
{
  parsefun *fn = (parsefun *)malloc(sizeof(parsefun));
  fn -> fn = &parserange_w;
  fn -> env = malloc(sizeof(rangeenv));
  rangeenv* renv = (rangeenv*)(fn->env);
  renv->from = from;
  renv->to = to;
  return fn;
}


//// Recognisers yielding value
typedef struct _pbindcontext {
  voidptr slots[32]; // variable slots
  int slpos; // next binding position
  struct _pbindcontext *par; // parent context
} pbindcontext;

pbindcontext *newpbindcontext(pbindcontext *par) 
{
  pbindcontext *c = (pbindcontext *)malloc(sizeof(pbindcontext));
  c->par = par;
  c->slpos = 0;
  return c;
}

typedef ::fun void(int, pcontext *, pbindcontext *, void **)  ctorfun;
void bindtoparent(pcontext *ctx, void *val)
{
  pbindcontext *pc = (pbindcontext*)(ctx->extra);
  pc->slots[pc->slpos++] = val;
}

// AST tags:
// 0 - string node
// 1 - numeric node
// 2 - tagged n-tuple node
// 3 - list node
typedef struct _asttuplehdr {
  int tag; // =2
  int len; // number of elements
  int itag; // tuple tag
  void* first; //first elt
} asttuplehdr;
typedef struct _astlistnode {
  int tag; // =3
  void *hd;
  struct _astlistnode *tl;
} astlistnode;

void cleanupast(void *ptr)
{
  int* iptr = (int*) ptr;
  int tag = *iptr;
  if(tag == 2) { //ntuple
    asttuplehdr *hdr = (asttuplehdr *)ptr;
    void **elts = &(hdr->first);
    int i,l; l = hdr->len;
    for(i=0;i<l;i++) {
      cleanupast(elts[i]);
    }
    free(ptr);
    return;
  } else if(tag==3) { //list
    astlistnode *nd = (astlistnode*)ptr;
    cleanupast(nd->hd);
    cleanupast(nd->tl);
    free(ptr);
    return;
  } else {
    free(ptr);
    return;
  }
}

void cleanupbindcontext(pbindcontext *bctx) 
{
  int i, n;
  void** slots;
  n = bctx->slpos; slots = bctx->slots;
  for(i = 0; i < n; i++) {
    cleanupast(slots[i]);
  }
}

int parsebind(pcontext *ctx, parsefun *fn, ctorfun *cfn)
{
  int oldpos = savepos(ctx);
  pbindcontext *nbctx = newpbindcontext(ctx->extra); // parent  context in  extra
  ctx->extra = nbctx;
  int ret = runparser(ctx, fn);
  if (ret) {
    void *ctret;
    (*cfn)(oldpos, ctx, nbctx, &ctret);
    ctx->extra = nbctx->par;
    free(nbctx);
    bindtoparent(ctx, ctret);
    return 1;
  } else {
    if (ctx->poolptr == _intptr(0))
      cleanupbindcontext(nbctx); // no need to clean pool-allocated stuff
    ctx->extra = nbctx->par;
    free(nbctx);
    return 0;
  }
}
