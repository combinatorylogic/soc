   .align 8
   irq:

       r1 = #0x8002
       r1 = [r1] // read and ignore
        
       r1 = 0
       goto <r1> // quit the IRQ handler

   .align 8
   main:
       call primes // Init the primes table

       r9 = 0
       r6 = #@RAM
       r11 = #32
    main_loop_0:
       r4 = 33; r3 = 0x21; r5 = 1
       r10 = r9
       r10 << r5
       r10 = r10 + r6
       r13 = [r10]
       if r13 goto skip_blink
         r1 = #0x8008
         [r1] = r9 // blink leds
      skip_blink:
       r9 ++
       r12 = r11 - r9
       if !r12 goto reset_counter
       goto main_loop
      reset_counter:
       r9 = 0

    main_loop:
       r1 = r3
       call putc
       r4--
       r3 = r3 + r5
       
      if r4 goto main_loop
       call nl; call nl

       r1 = #@HELLO
       call puts
       call nl; call nl
       r1 = #@BYE
       call puts
       call nl


       goto main_loop_0

   HELLO: .asciiz "Hello, world!"
   BYE:   .asciiz "Bye!"


   .align 8
   nl:
       push r1
       r1 = 0x0d
       call putc
       r1 = 0x0a
       call putc
       r1 = pop
       ret

   .align 8
   putc:
       ret
       push r2
       push r3

       r2 = #0x8004 // uart ready addr
     putc_uart_wait:
       r3 = [r2]    // uart ready?
      if !r3 goto putc_uart_wait
       

       r2 = #0x8006 // uart dout addr
       [r2] = r1    // r1 - argument

       r3 = pop
       r2 = pop
       ret

   // r1 - pointer to a string
   .align 8
   puts:
       push r1
       push r2
       push r3
       
       r3 = #0xff
      puts_loop:
         r2 = [r1] // unaligned reads will only have one valid byte output
         r2 = r2&r3
        if !r2 goto puts_end
         push r1
         r1 = r2
         call putc
         r1 = pop
         r1++ // read byte by byte
        goto puts_loop
      puts_end:
       r3 = pop
       r2 = pop
       r1 = pop
       ret


   .align 8
   primes:
     push r1
     push r2
     push r3
     push r4
     push r8
     push r9
     push r10
     
     r1 = #@RAM // Array start
     r4 = 1
     r1 >> r4
     r2 = 2     // Step
     r3 = #32  // Array size
     r9 = r1 + r3 // Array end
     r8 = #0x8000 // negative
     r10 = #16 // Max step

     steploop:
       r1 = #@RAM // Array start
       r4 = 1
       r1 >> r4
       r3 = r1 + r2
       r3 = r3 + r2
       
       iterloop:
          r4 = 1
          r1 = r3
          r1 << r4
         [r1] = r4
          r3 = r3 + r2
          
          r4 = r9 - r3
          r4 = r4 & r8
         if !r4 goto iterloop
          r2 ++
          r4 = r10 - r2
          r4 = r4 & r8
         if !r4 goto steploop


     r10 = pop
     r9  = pop
     r8  = pop
     r4  = pop
     r3  = pop
     r2  = pop
     r1  = pop
     ret


   // End of code section
   .align 8
     RAM: .asciiz ""


