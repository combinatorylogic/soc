

inline void _snd_set_rate(int rate)
{
        int cpuclk = 25000000; // BlackIce board, 25MHz clock
        int rateclk = 566; //cpuclk / rate; // e.g., rate = 44100, then rateclk = 566; Use 44169 for a precise rate

        // PWM will now fetch a new sample from a queue every `rateclk` clock cycles;
        // 100% duty cycle is also `rateclk` cycles now, so we must scale 65536 max sample down to `rateclk` nearest power of 2,
        // which is, in our case, 512.

        // Looks like we have to hardcode it...
        
        inline verilog reset {
                sound_clr_rate <= 512;
        };
        inline verilog exec(rateclk) { sound_clr_rate <= rateclk; };
}

// Wait for a PWM queue to be ready, push a sample into the PWM queue.
inline void _snd_buffer_push(int sample)
{

        inline verilog exec { begin end }
        wait(~sound_clr_full) { begin end };
        
        inline verilog reset {
                sound_clr_sample <= 0;
                sound_clr_req <= 0;
        };
        inline verilog exec (sample) {
                sound_clr_sample <= (sample>>7); // see? hardcoded duty cycle scaling
                sound_clr_req <= 1; }
        wait  ( sound_clr_req ) { sound_clr_req <= 0; };
}



