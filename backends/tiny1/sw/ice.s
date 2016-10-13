   .align 8
   irq:

       r1 = #0x8002
       r1 = [r1] // read and ignore
        
       r1 = 0
       goto <r1> // quit the IRQ handler

   .align 8
   main:
       r9 = #0xf
    main_loop_0:
       r4 = 33; r3 = 0x21; r5 = 1
       r9++
       r1 = #0x8008
       r8 = r9
       [r1] = r8 // blink leds
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

