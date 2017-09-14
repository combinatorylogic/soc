/*
 * Utilities for the 20.12 fixed point
 */

##function dbl_to_fix(m, f) {
   // f * 2^(32-m) -> int32
   notnet(System.Double f, int m) {
      System.Double tmp = Math.Pow(2.0, (System.Double)(32-m));
      leave (object)((int)(Math.Floor(f * tmp)));
   }}



##syntax of pfclike in clconst, inner: ' ".fx" [cldouble]:d '
{
   dv = %flt:parse(%S<<(d));
   iv = dbl_to_fix(fixed_point_width - (32 - fixed_point_width), dv);
   // println('DX:'(%S<<(d), iv));
   return 'integer'('i32', iv)
}

##syntax of pfclike in clconst, inner: ' ".f" [cldouble]:d '
{
   dv = %flt:parse(%S<<(d));
   iv = dbl_to_fix(fixed_point_width, dv);
   // println('D:'(%S<<(d), iv));
   return 'integer'('i32', iv)
}


##syntax of pfclike in clconst, inner: ' ".wf" '
{
  return 'integer'('i32', 32-fixed_point_width)
}
