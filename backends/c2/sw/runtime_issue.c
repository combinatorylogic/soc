
##syntax of pfclike in classexpr, inner: ' "%" kernel_width "(" [clqident]:k ")" '
{
   depth = aif(chk = ohashget(ll_hls_feedback, %Sm<<(k, " -- PIPELINE DEPTH")))
              chk else 0;
   println('KERNEL_WIDTH'(k, depth));
   return 'const'('integer'('i32', depth))
}

##syntax of verilog in primary, inner: ' "%" kernel_width "(" [ident]:k ")" '
{
   depth = aif(chk = ohashget(ll_hls_feedback, %Sm<<(k, " -- PIPELINE DEPTH")))
              chk else 0;
   println('KERNEL_WIDTH'(k, depth));
   return 'number'(%S<<(depth))
}

##define blit_wire_defs = mkhash()

##{
        vmem_blit = [8;19;1;1;'vmem_in_data';
                     'vmem_in_addr';
                     'vmem_we';
                     'vmem_one';
                     'vmem_dummy';
                     'vmem_dummy';
                     'vmem_dummy'];
        ohashput(blit_wire_defs, 'vmem_blit', vmem_blit);
        vmemddr_blit = [64;28;64;1;
                        'ram1_blit_data';
                        'ram1_blit_addr';
                        'ram1_blit_write';
                        'ram1_blit_waitrequest_n';
                        'ram1_blit_burstcount';
                        'ram1_blit_read_conduit_in';
                        'ram1_blit_read_conduit_out'
                        ];
        ohashput(blit_wire_defs, 'vmemddr_blit', vmemddr_blit);
}

##function gen_issue_wrapper(knm, fixargs, blitter) {
   // Get args:
   rams = aif(chk = ohashget(ll_hls_feedback, %Sm<<(knm, " -- RAM SIGNALS")))
              chk else [];
   ramargs1 = map append [ramnm; signals] in rams do signals;
   args = aif(chk = ohashget(ll_hls_feedback, %Sm<<(knm, " -- MODARGS")))
              chk else ccerror('NO-METADATA-ON-KERNEL'(knm));
   depth = aif(chk = ohashget(ll_hls_feedback, %Sm<<(knm, " -- PIPELINE DEPTH")))
              chk else 0;
   varargs1 = map append a in args do
                match a with
                   ain('REQ',@_) -> []
                 | ain(nm, tp) ->
                   {if(not(memq(nm, fixargs)))
                      [[nm;tp]] else []};
   fixargs1 = map append a in args do
                match a with ain(nm, tp) ->
                   if(memq(nm, fixargs)) [[nm;tp]] else [];
   outreg =  match (map append a in args do
                        match a with aoutreg(nm, tp) -> if (not(nm=='ACK')) [[nm;tp]] else [] | else -> [])
              with
                [[nm;v(width)]] -> [nm;width]
              | else -> ccerror('NO-OUTPUT-SIGNAL'(knm, args));

  <[outnm;outlen]> = outreg;
   
   println('ARGS'(args));
   println('VARARGS'(varargs1));
   println('FIXARGS'(fixargs1));
   println('RAMARGS'(ramargs1));
   println('OUTREGS'(outlen));

   lenfun = fun(a,b) {
                         l = match b with [nm;'v'(w)] -> w
                                   | else -> ccerror('WRONG-WIDTH'(b));
                         return a + l;
                      };

   varargslen = foldl(lenfun, 0, varargs1);
   fixargslen = foldl(lenfun, 0, fixargs1);
   ramargslen = foldl(lenfun, 0, ramargs1);

   /* The result should be:
       module knm_wrapper(input clk, input rst,
                          input [vlen-1:0] vararg,
                          input [flen-1:0] fixarg,
                          input [...] ramfillarg,
                          input req,
                          output ack,
                          output [outlen-1:0] out);
          knm inst (.clk(clk), .reset(rst),
                    .... args and shit
                    );
                    
    */

   wrappername = %Sm<<(knm , "_wrapper");
   mknum(n) = #`(constexpr (number ,n));
   ports = #`((input () (clk))
              (input () (rst))
              (input ((r ,(mknum varargslen) ,(mknum 0))) (vararg))
              (input ((r ,(mknum fixargslen) ,(mknum 0))) (fixarg))
              (input ((r ,(mknum ramargslen) ,(mknum 0))) (ramfillarg))
              (input () (req))
              (output () (ack))
              (output ((r ,(mknum (- outlen 1)) ,(mknum 0))) (out))
              );
   
   mkargvec(snm, ars) =
               { ctr = mkref(0);
                 map [nm;v(w)] in ars do {
                    frm = ^ctr + w - 1;
                    to = ^ctr;
                    ctr := ^ctr + w;
                    #`(n ,nm (idx2 ,snm ,(mknum frm) ,(mknum to)))
                   }};

   fixargvec = mkargvec('fixarg',fixargs1);
   varargvec = mkargvec('vararg',varargs1);
   ramargvec = mkargvec('ramfillarg',ramargs1);

   connections =
      #`((n clk (var clk))
         (n reset (var rst))
         ,@fixargvec
         ,@varargvec
         ,@ramargvec
         (n REQ (var req))
         (n ACK (var ack))
         (n ,outnm (var out)));
   
   mdl = #`(module ,wrappername (,ports)
                  ((moduleinst ,knm () ; no parameters
                              (mod (i inst ()) npcs ,@connections)))
           );

   code = [verilog_pprint_string(verilog_pprint_inner('description'(mdl)))];
   src_code = %generic-filepath(%S<<("./", knm, ".v"));
   f_code = %generic-filepath(%S<<("./", knm, "_wrapper.v"));

   code = code :: [
%S<<(" `define ISSUENAME ",wrappername,"_issue");
%S<<(" `define COMPUTE_CORE ",wrappername);
%S<<(" `define BLITTER ", blitter);
// %S<<("   `include \"", src_code, "\"");
%S<<("   `include \"issue.v\"");
" `undef COMPUTE_CORE";
" `undef ISSUENAME";
" `undef BLITTER"
   ];

   println('WRAPPER_MODULE'(code));
   #(call-with-output-file f_code
       (fun (fp_code)
         (foreach (c code) (fprintln fp_code c))
         ));
   return [f_code; fixargs1; varargs1; fixargslen; varargslen; ramargslen; outlen; depth; ramargs1]
}


##syntax of pfclike in clcode, inner (verilog): ' "%" issue_threads_sync "("
       [clqident]:kernel "," [constantExpression]:cores "," [fixargs]:fx ","
       [clqident]:blitcore ")" [clcode]:body '
    + {
        fixargs := "{" ecslist<[fixarg],",">:args "}" => args;
        fixarg := [clqident]:id "=" [clexpr]:v => p(id, v);
    }
{
    wrap = gen_issue_wrapper(kernel, map(cadr, fx), blitcore);
    nbody = #`(begin
        (macroapp issue_instance (verb ,kernel) (verb ,fx) (verb ,blitcore)
                                 (verb ,wrap) (verb ,cores))
        (macroapp issue_setup_fixargs (verb ,kernel) (verb ,fx))
        ,body
        (macroapp issue_sync_wait)
        (macroapp issue_pop)
      );
    return nbody;
}

##define issue_context_stack = mkref([])

##function fn_issue_instance (kernel, fixargs, blitcore, wrapper, cores) {
  println('INSTANCE'(kernel, fixargs, blitcore, wrapper, cores));
 
  corename = %Sm<<(kernel, "_wrapper_issue");
  symbols(varargname, fixargname, blitdestname, ramargname, 
          queue_we_name, issue_available_name, issue_idle_name) {
   //TODO:
  <[f_code; fixargs1; varargs1; fixarglen; vararglen; ramargslen; outlen; depth; ramargs1]> = wrapper;
   knm = kernel;
   ramargslen = if (ramargslen>0) ramargslen else 1;
   fixarglen = if (fixarglen>0) fixarglen else 1;
   vararglen1 = vararglen-1;
   fixarglen1 = fixarglen-1;
   ncores = cadr(cores);
   println('NCORES='(cores));
   

  <[blitdatawidth;
    blitwidth;
    extrainwidth;
    extraoutwidth;
    blit_data_out;
    blit_addr;
    blit_we;
    blit_available;
    blit_burst_count;
    blit_extrain;
    blit_extraout]> = ohashget(blit_wire_defs, blitcore);

   blitwidth1 = blitwidth-1;
   ramfillwidth1 =  ramargslen - 1;
   computeoutwidth = 4; // TODO: where is it coming from?!?
   computewidth = depth;

   corenameid = %Sm<<(knm, "_wrapper_issue");
   wrapperpath = f_code;
   queuedatalen = vararglen + blitwidth;
   code = .clike-code `{
     inline verilog include \wrapperpath\;
     inline verilog define {
        reg [.num: \vararglen1\:0]
            .id:  \varargname\;
        reg [.num: \fixarglen1\:0] .id: \fixargname\;
        reg [.num: \blitwidth1\:0] .id: \blitdestname\;
        reg [.num: \ramfillwidth1\:0] .id: \ramargname\;
        reg .id: \queue_we_name\;
        wire .id: \issue_available_name\;
        wire .id: \issue_idle_name\;
        .id: \corename\ #(.NUMBER_OF_CORES( .expr: \ncores\ ),
                     .QUEUE_PACKET_LEN( .num: \queuedatalen\ ),
                     .COMMON_ARGS_LEN( .num: \fixarglen\ ),
                     .RAMFILL_ARGS_LEN( .num: \ramargslen\ ),
                     .BLIT_WIDTH( .num: \blitdatawidth\ ),
                     .BLIT_ADDR_WIDTH( .num: \blitwidth\ ),

                     .BLIT_EXTRA_IN_WIDTH( .num: \extrainwidth\ ),
                     .BLIT_EXTRA_OUT_WIDTH( .num: \extraoutwidth\ ),

                     .COMPUTE_OUT_WIDTH( .num: \computeoutwidth\ ),
                     .COMPUTE_OUT_STAGES( .num: \computewidth\ )) 
          .id: \corenameid\
        (.clk (clk),
         .rst (rst),
         .common_args( .var: \fixargname\ ),
         .ramfill_args( .var: \ramargname\ ),
         .queue_data_in({ .var: \blitdestname\, .var: \varargname\ }),
         .queue_we( .var: \queue_we_name\ ),
         .queue_available( .var: \issue_available_name\ ),
         // STUBS for now
         .blit_data_out(.var: \blit_data_out\),
         .blit_addr_out(.var: \blit_addr\),
         .blit_burst_count(.var: \blit_burst_count\),
         .blit_we(.var: \blit_we\),
         .blit_available(.var: \blit_available\),
         .blit_extrain(.var: \blit_extrain\),
         .blit_extraout(.var: \blit_extraout\),
         //
         .idle( .var: \issue_idle_name\ ));
     };
     inline verilog reset {
       .id: \varargname\ <= 0;
       .id: \fixargname\ <= 0;
       .id: \blitdestname\ <= 0;
       .id: \ramargname\ <= 0;
       .id: \queue_we_name\ <= 0;
     };
     }
  `;
  println(code);
  // Push the wire names and stuff
  context = [knm;
              varargname;
               fixargname;
                blitdestname;
                 queue_we_name;
                  issue_idle_name;
                   issue_available_name;
                    ramargname;
                      wrapper
                    ];
  issue_context_stack := context:^issue_context_stack;
  #`(begin ,code)
}}


## #(clike_defmacro issue_instance (k f b w c)
            (fn_issue_instance (cadr k) (cadr f) (cadr b) (cadr w) (cadr c)))

## #(clike_defmacro issue_sync_wait ()
  =pf: {
     <[knm;
              varargname;
               fixargname;
                blitdestname;
                 queue_we_name;
                  issue_idle_name;
                   issue_available_name;
                    ramargname;
                      wrapper
                    ]> = car(^issue_context_stack);
      code = .clike-code `{
         inline verilog exec {}
         wait ( .id: \issue_idle_name\ ) {} else {};
      }`;
      return code;
     })
     
## #(clike_defmacro issue_pop ()
       =pf: issue_context_stack := cdr(^issue_context_stack);
        `(begin ))

##syntax of pfclike in clcode, inner: ' "%" emit_task "(" cslist<[argpair],",">:args ")" '
   + { argpair := [clqident]:nm "=" [clexpr]:e => p(nm, e); }
{
   // Defer all the actual work to macro expansion phase, to ensure
   #`(begin
        (macroapp emit_task_macro (verb ,args)))
}

##syntax of pfclike in clcode, inner: ' "%" prefill_array "(" [clqident]:vn "," [clexpr]:addr "," [clexpr]:val ")" '
{
   // Defer all the actual work to macro expansion phase, to ensure
   #`(begin
        (macroapp prefill_array (verb (,vn ,addr ,val))))
}


## #(clike_defmacro issue_setup_fixargs (krn fx)
=pf: {
   // Get the current context:
   <[knm;
              varargname;
               fixargname;
                blitdestname;
                 queue_we_name;
                  issue_idle_name;
                   issue_available_name;
                    ramargname;
                      wrapper
                    ]> = car(^issue_context_stack);

  <[f_code; fixargs1; varargs1; fixargslen; varargslen; ramargslen; outlen; depth; ramargs1]> = wrapper;
   //TODO: pass / compute arg names and their positions in the bit vector.
   mkargvec(ars) =
               { ctr = mkref(0);
                 map [nm;v(w)] in ars do {
                    frm = ^ctr + w - 1;
                    to = ^ctr;
                    ctr := ^ctr + w;
                    [nm; frm; to]
                   }};
   xargs = mkargvec(fixargs1);
   <verb(nargs)> = fx;
   println('NARGS='(nargs));
   icode =  map p(nm, e) in nargs do symbols(tmp) {
       [nm; tmp; .clike-code `var \tmp\ = ::expr \e\; `]
   };
   nmh = mkhash();
   iicode = map [nm;tmp;code] in icode do {ohashput(nmh, nm, tmp); code};
   argscode = map [nm;frm;to] in xargs do { // TODO: set args in pairs if possible
     tnm = ohashget(nmh, nm);
     .clike-code `{
       inline verilog exec ( \tnm\ ) {
         .id: \fixargname\ [ .num: \frm\ : .num: \to\ ] <= .var: \tnm\;
       };
     }`;
   };
   return #`(begin ,@iicode ,@argscode);
  })


## #(clike_defmacro prefill_array (arroffval)
=pf: {
   // Get the current context:
   <[knm;
              varargname;
               fixargname;
                blitdestname;
                 queue_we_name;
                  issue_idle_name;
                   issue_available_name;
                    ramargname;
                      wrapper
                    ]> = car(^issue_context_stack);

  <[f_code; fixargs1; varargs1; fixargslen; varargslen; ramargslen; outlen; depth; ramargs1]> = wrapper;
   ht = mkhash();
   mkargvec(ars) =
               { ctr = mkref(0);
                 map [nm;v(w)] in ars do {
                    frm = ^ctr + w - 1;
                    to = ^ctr;
                    ctr := ^ctr + w;
                    println('OOOOO'(nm, frm, to));
                    ohashput(ht, nm, [frm;to]);
                    [nm; frm; to]
                   }};
   xargs = mkargvec(ramargs1);
   rams = aif(chk = ohashget(ll_hls_feedback, %Sm<<(knm, " -- RAM SIGNALS")))
              chk else [];

   tmp = gensym();
  <verb([vn; addr; val])> = arroffval;
  <[valfrm; valto]>   = ohashget(ht, 'array_data');
  <[addrfrm; addrto]> = ohashget(ht, 'array_addr');

  <[wefrm; weto]>   = ohashget(ht, %Sm<<("array_", vn, "_we"));// TODO: do it the right way
  
   // TODO: emit a lifted inline function instead, and re-use it for all the next cases
   //  for the same ram.
   tmp1 = gensym(); tmp2 = gensym();
   .clike-code `{
       var \tmp1\ = ::expr \addr\;
       var \tmp2\ = ::expr \val\;
       inline verilog exec ( \tmp1\, \tmp2\ ) {
          .id: \ramargname\ [ .num: \addrfrm\ : .num: \addrto\ ] <= .var: \tmp1\; 
          .id: \ramargname\ [ .num: \valfrm\ : .num: \valto\ ] <= .var: \tmp2\;
          .id: \ramargname\ [ .num: \wefrm\ : .num: \weto\ ] <= 1;
       } wait (1) {
          .id: \ramargname\ [ .num: \wefrm\ : .num: \weto\ ] <= 0;
       };
   }`;
  })



## #(clike_defmacro emit_task_macro (args)
  =pf: {
   // Get the current context:
   <[knm;
              varargname;
               fixargname;
                blitdestname;
                 queue_we_name;
                  issue_idle_name;
                   issue_available_name;
                    ramargname;
                      wrapper
                    ]> = car(^issue_context_stack);

  <[f_code; fixargs1; varargs1; fixargslen; varargslen; ramargslen; outlen; depth; ramargs1]> = wrapper;
   //TODO: pass / compute arg names and their positions in the bit vector.
   mkargvec(ars) =
               { ctr = mkref(0);
                 map [nm;v(w)] in ars do {
                    frm = ^ctr + w - 1;
                    to = ^ctr;
                    ctr := ^ctr + w;
                    [nm; frm; to]
                   }};
   xargs = mkargvec(varargs1);
   <verb(nargs)> = args;
   icode =  map p(nm, e) in nargs do symbols(tmp) {
       [nm; tmp; .clike-code `var \tmp\ = ::expr \e\; `]
   };
   nmh = mkhash();
   iicode = map [nm;tmp;code] in icode do {ohashput(nmh, nm, tmp); code};
   argscode = map [nm;frm;to] in xargs do { // TODO: set args in pairs if possible
     tnm = ohashget(nmh, nm);
     nmstr = 'const'('string'(%S<<(nm, "= ")));
     vtnm = 'var'(tnm);
     .clike-code `{
       inline verilog exec ( \tnm\ ) {
         .id: \varargname\ [ .num: \frm\ : .num: \to\ ] <= .var: \tnm\;
       };
     }`;
   };

   tempbd = ohashget(nmh, 'blit_destination');
   code = .clike-code `{
      inline verilog exec { } wait ( .id: \issue_available_name\) {} else { } ;
      inline verilog exec ( \tempbd\ ) {
         .id: \blitdestname\ <= .var: \tempbd\;
         .id: \queue_we_name\ <= 1;
      } wait (1) {
         .id: \queue_we_name\ <= 0;
      };
   }`;
   ret =  #`(begin ,@iicode ,@argscode ,code );
   println('EMIT-CODE'(ret));
   return ret
   
  }
)


