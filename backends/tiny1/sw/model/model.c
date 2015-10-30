/* Memory map:

   0 -  31: slots for vregs
   32 - 63: IRQ mode vregs
   64 - 127: microcode handlers table

   128 - 139: IRQ handler entry, one for all, must fit 12 bytes

   140 - 151: Entry point

   152 - MUEND: mucode

   MUEND+1 - 16383: code + data

   16384 - 65535: memory-mapped area
   
*/

#include <stdlib.h>
#include <stdio.h>


typedef unsigned short ushort;
typedef unsigned int uint;

typedef struct _CPU {
        ushort PC;
        ushort A;
        ushort B;
        ushort C;

        char CR;

        char   IRQ; // Interrupt requested

        char   O; // in an IRQ?
        ushort savedPC; // while in IRQ handler

        ushort MPC;
        ushort ISRC;
        ushort muOP;

        unsigned char MEM[16384];

        int fsm_state;
} CPU;

#define FSM_FETCH_ISRC 0
#define FSM_FETCH_MPC  1
#define FSM_FETCH_MUOP 2
#define FSM_EXEC_MUOP  3

#define IRQ_HANDLER_ENTRY 96

inline static
int fromsig6(uint v) {
        uint tmp;
        int *ret = (int*)(&tmp);
        if (v&0x20) {  // signed
                tmp = 0xffffffc0 | (v&0x3f); // sign-extend
        } else {
                tmp = v&0x3f;
        }
        return *ret;
}

inline static ushort readword(CPU *state, ushort addr) {
        if (addr < 0x4000)
                return *((ushort *)(state->MEM + addr));
        else {
                printf("ILLEGAL READ AT %x [PC=%d]\n", addr, state->PC);
                exit(-1);
        }
}

inline static void writeword(CPU *state, ushort addr, ushort v) {
        if (addr < 0x4000)
                *((ushort *)(state->MEM + addr)) = v;
        else {
                printf("ILLEGAL WRITE AT %x [PC=%d]\n", addr, state->PC);
                exit(-1);
        }
}

inline static
void step(CPU *state)
{
        int i;
        switch(state->fsm_state) {
        case FSM_FETCH_ISRC:
                if (state->IRQ && !state->O) {
                        state->savedPC = state->PC;
                        state->PC = IRQ_HANDLER_ENTRY;
                        state->O  = 1;
                } else if (state->O && state->PC == 0) { // IRQ handler done working
                        state->PC = state->savedPC;
                        state->O = 0;
                }
                state->ISRC = readword(state, state->PC);
                state->fsm_state = FSM_FETCH_MPC;
                break;
        case FSM_FETCH_MPC:
                state->MPC = readword(state, 64 +
                                      (((state->ISRC>>11)&0x1f)<<1));
                state->fsm_state = FSM_FETCH_MUOP;
                break;
        case FSM_FETCH_MUOP:
                state->muOP = readword(state, state->MPC);
                state->fsm_state = FSM_EXEC_MUOP;
                break;
        case FSM_EXEC_MUOP:
                {
                        ushort muOP = state->muOP;
                        int AL = (muOP>>14)&3;
                        int SH = (muOP>>12)&3;
                        int DS = (muOP>>10)&3;
                        int MM = (muOP>>8)&3;
                        int CN = (muOP>>6)&3;
                        int IS = (muOP>>4)&3;
                        int IMMD = muOP&15;
                        int SIMMED = muOP&0x3f;

                        int IS1 = (CN==0)?IS:0;

                        // Special handling for vreg memory
                        ushort offset = (state->O)?0x20:0;
                        ushort effC =
                                (IS==0 && IMMD == 1)?(offset|(state->C<<1)):
                                (IS==0 && IMMD == 2)?(state->MPC|2):
                                /* else */ state->C;

                        ushort MEMRD = 0;

                        if ( MM==1 ) {
                           if (effC & 0x8000) { // mmap i/o
                                   ushort mmaddr = effC & 0x7fff;
                                   switch(mmaddr) {
                                   case 0: // UART valid. TODO!
                                           MEMRD = 1;
                                           break;
                                   case 1: // UART din
                                           MEMRD = getchar();
                                           break;
                                   case 2: // UART ready.
                                           MEMRD = 1;  // always ready
                                           break;
                                   default: break;
                                   }
                           } else MEMRD = readword(state, effC);
                        }
                        
                        uint SRC =
                                (MM==1)?MEMRD:
                                (MM==3)?((IMMD&1)?state->CR:state->ISRC):
                                (IS1==1)?(short)IMMD:
                                (IS1==2)?state->PC:
                                (IS1==3)?state->C:state->A;

                        
                        uint ALU1 =
                                (AL==0)?(SRC + state->B):
                                (AL==1)?(SRC & (state->B)):
                                (AL==2)?SRC: /* (AL==3)? */ ~SRC;
                        uint ALU2x =
                                (SH==0)?ALU1:
                                (SH==1)?ALU1<<1:
                                (SH==2)?ALU1>>1:
                                /* (SH==3)? */ ALU1>>4;

                        ushort ALU2 = (ushort)ALU2x;
                        state->CR = (ALU2x&0x10000)!=0;
                        
                        if (MM==2) {
                                if (effC & 0x8000) { // mmap i/o
                                        ushort mmaddr = effC & 0x7fff;
                                        switch(mmaddr) {
                                        case 3: putchar(ALU2); fflush(stdout);
                                                break; // UART out
                                        case 512: // halt
                                                exit(0);
                                                break;
                                        default: break; // no do no nothing
                                        }
                                } else writeword(state, effC, ALU2);
                        } else if (!CN) {
                                switch(DS) {
                                case 0: state->A  = ALU2; break;
                                case 1: state->B  = ALU2; break;
                                case 2: state->C  = ALU2; break;
                                case 3: state->PC = ALU2; break;
                                }
                        }
                        short delta = 2;
                        if (MM == 1 && (IS==0 && IMMD == 2)) delta = 4;
                        switch (CN) {
                        case 0: break;
                        case 1: if (ALU2==0) delta = fromsig6(SIMMED)<<1; break;
                        case 2: if (ALU2!=0) delta = fromsig6(SIMMED)<<1; break;
                        case 3: delta = fromsig6(SIMMED)<<1; break;
                        }
                        state->MPC = state->MPC + delta;
                        if (delta == 0) {
                                state->fsm_state = FSM_FETCH_ISRC;
                        } else {
                                state->fsm_state = FSM_FETCH_MUOP;
                        }
                }
                break;
        }
}





int main(int argc, char **argv)
{
        FILE *fsrc = NULL;
        uint size = 0;
        ushort *buf = NULL;
        uint n = 0;

        // Read hex file
        if (argc!=2) return -1;
        fsrc = fopen(argv[1], "r");
        
        fscanf(fsrc, "%x\n", &size);
        buf = (ushort *)malloc(2 * size + 2);
        for (n = 0; n < size; n++) {
                uint tmp;
                fscanf(fsrc, "%x\n", &tmp);
                buf[n] = tmp;
        }
        // Setup
        CPU c0;
        c0.PC = 140;
        c0.IRQ = 0;
        c0.fsm_state = FSM_FETCH_ISRC;
        for (n = 0; n < size; n++) {
                *((ushort *)(&c0.MEM[n*2])) = buf[n];
        }
        // Run
        for(;;) {
                step(&c0);
        }
        return 0;
}
