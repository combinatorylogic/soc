


int uart_buffer[128];
int uart_pos;


// UART_send is blocking, unless the length of the message is less than the size
// of the outgoing FIFO
void uart_send(int* str)
{
        for(int idx = 0; str[idx]; idx++) {
                int c = str[idx];
                while ( !(*((uint32*)65538))) {}
                *((uint32*)65539) = c;
        }
}

void uart_sendc(uint32 c)
{
  uint32 str[2];
  str[0] = c;
  str[1] = 0;
  uart_send(str);
}

// C2 is a real-time CPU without any interrupts support.
// You're supposed to do in hardware whatever you want to use your interrupts for.
// Therefore, we need to poll UART frequently in order not to allow its FIFO to
// overflow. The longest it may take to process this poll routine is the depth
// of the FIFO, and it's unlikely to ever be over 1-2 characters.
int polluart()
{
        int ret = 0;
        while(*((uint32*)65537)) {
            int c = *((uint32*)65539);
            uart_buffer[uart_pos++] = c;
            while ( !(*((uint32*)65538))) {}
            *((uint32*)65539) = c; // echo it back
            ret = 1;
        }
        if (ret) {
                uart_buffer[uart_pos] = 0;
                if (uart_buffer[uart_pos-1]== 13) {
                    //uart_send(uart_buffer); // ECHO
                    return 1;
                }
        }
        return 0;
}
