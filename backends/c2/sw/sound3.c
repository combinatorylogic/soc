#include "./runtime_ice_small.c"
#include "./sound_ctl.c"

// python -c "import math; print [int((1<<16) * 0.5*(math.sin(x/256.0*2.0*math.pi)+1.0)) for x in range(256)]"
int sine[256] = {
        32768, 33572, 34375, 35178, 35979, 36779, 37576, 38370, 39160, 39947, 40729, 41507, 42280, 43046, 43807, 44561, 45307, 46046, 46778, 47500, 48214, 48919, 49614, 50298, 50972, 51636, 52287, 52927, 53555, 54171, 54773, 55362, 55938, 56500, 57047, 57580, 58098, 58600, 59087, 59558, 60013, 60452, 60874, 61279, 61666, 62037, 62389, 62724, 63041, 63340, 63620, 63882, 64125, 64349, 64553, 64739, 64906, 65053, 65181, 65289, 65378, 65447, 65496, 65526, 65536, 65526, 65496, 65447, 65378, 65289, 65181, 65053, 64906, 64739, 64553, 64349, 64125, 63882, 63620, 63340, 63041, 62724, 62389, 62037, 61666, 61279, 60874, 60452, 60013, 59558, 59087, 58600, 58098, 57580, 57047, 56500, 55938, 55362, 54773, 54171, 53555, 52927, 52287, 51636, 50972, 50298, 49614, 48919, 48214, 47500, 46778, 46046, 45307, 44561, 43807, 43046, 42280, 41507, 40729, 39947, 39160, 38370, 37576, 36779, 35979, 35178, 34375, 33572, 32768, 31963, 31160, 30357, 29556, 28756, 27959, 27165, 26375, 25588, 24806, 24028, 23255, 22489, 21728, 20974, 20228, 19489, 18757, 18035, 17321, 16616, 15921, 15237, 14563, 13899, 13248, 12608, 11980, 11364, 10762, 10173, 9597, 9035, 8488, 7955, 7437, 6935, 6448, 5977, 5522, 5083, 4661, 4256, 3869, 3498, 3146, 2811, 2494, 2195, 1915, 1653, 1410, 1186, 982, 796, 629, 482, 354, 246, 157, 88, 39, 9, 0, 9, 39, 88, 157, 246, 354, 482, 629, 796, 982, 1186, 1410, 1653, 1915, 2195, 2494, 2811, 3146, 3498, 3869, 4256, 4661, 5083, 5522, 5977, 6448, 6935, 7437, 7955, 8488, 9035, 9597, 10173, 10762, 11364, 11980, 12608, 13248, 13899, 14563, 15237, 15921, 16616, 17321, 18035, 18757, 19489, 20228, 20974, 21728, 22489, 23255, 24028, 24806, 25588, 26375, 27165, 27959, 28756, 29556, 30357, 31160, 31963
};

// 4 channels,
//    each have a phase timer, phase step, command timer, command buffer

int phasetime[4];
int phasestep[4];

inline int mixedsample() {
        int out = 0;
        /*for(int i = 0; i < 4; i++) {
                int scaled = (phasetime[i] >> 13) & 0xff;
                out += sine[ scaled ];
                phasetime[i] += phasestep[i];
        }
        */
        int i = 0;
        int scaled = (phasetime[i] >> 13) & 0xff;
        out += sine[ scaled ];
        phasetime[i] += phasestep[i];
        return out; //out >> 3;
}

// Commands: phasesteps for each channel.

##define samplerate = 44169

/*
C4 - 261.6256
D4- 293.6648
E4 - 329.6276
F4 - 349.2282	
G4 - 391.9954
A4 - 440
B4 - 493.8833
*/

 ##function hz_to_step(hz0) {
        hz = %S<<(hz0);
        notnet(string hz, int samplerate) {
                leave (object)((int)(2097152.0 *  System.Double.Parse(hz) / ((float)samplerate)));
        }}

        
##syntax of pfclike in cltop, start: ' "#" song "{" slist<[clnotes]>:ns "}" ";"? '
        + {
 clnotes := [clnote]:n [clnote] [clnote] [clnote] => n;
clnote := { "C1" => `"261.6256" }
           /   { "D1" => `"293.6648" }
          /    { "E1" => `"329.6276" }
         /     {  "F1" => `"349.2282" }
         /     {"G1" => `"391.9954"}
         /  {"A1" =>  `"440.0" }
        /   {"B1" => `"493.8833" }

        / {"C2" => `"523.2511"}
        / {"D2" => `"587.3295"}
        / {"E2" => `"659.2551"}
        / {"F2" => `"698.4565"}
        / {"G2" => `"783.9909"}
        / {"A2" => `"880.0000"}
        / {"B2" => `"987.7666"}
        
        /   {"-" => `"0"}
            }
{
     mknote(n) =  'integer'('i32', hz_to_step(n));
     tp = 'array'('integer'('i32'), ['const'('integer'('i32',length(ns)))]);
     notes = 'constarray'(@map n in ns do mknote(n));
     return 'begin'('global'([], tp, 'v'('commands'), notes),
                           'global'([], 'integer'('i32'), 'v'('command_max'), 'integer'('i32', length(ns))));
}

#song {
   -    -    -     -
   -    -    -     -
   -    -    -     -
   -    -    -     -
   -    -    -     -
   -    -    -     -
   -    -    -     -
   -    -    -     -
   -    -    -     -
   A1 A1 -     -
   
   B1 B1 -     -

   C2 C2 -     -
   C2 C2 -     -
   C2 C2 -     -
   C2 C2 -     -
   -    -    -     -
   C2 C2 -     -
   -    -    -     -
   B1 B1 -     -
   -    -    -     -
   C2 C2 -     -
   -    -    -     -
   D2 D2 -     -
   -    -    -     -
   E2 E2 -     -
   E2 E2 -     -
   E2 E2 -     -
   E2 E2 -     -
   E2 E2 -     -
   E2 E2 -     -
   -    -    -     -
   D2 D2 -     -
   -    -    -     -
   C2 C2  -     -
   -    -    -     -
   B1 B1  -     -
   B1 B1  -     -
   -    -    -     -
   D2 D2  -     -
   D2 D2  -     -
   D2 D2  -     -
   D2 D2  -     -
   -    -    -     -
   C2 C2  -     -
   -    -    -     -
   B1 B1 -     -
   -    -    -     -
   A1 A1 -     -
   A1 A1 -     -
   A1 A1 -     -
   A1 A1 -     -
   A1 A1 -     -
   A1 A1 -     -
   -    -    -     -
   A1 A1 -     -
   -    -    -     -
   B1  -    -     -
   -    -    -     -
   C2 -    -     -
   C2 -    -     -
   C2 -    -     -
   C2 -    -     -
   -    -    -     -
   C2 -    -     -
   -    -    -     -
   B1  -    -     -
   -    -    -     -
   C2  -    -     -
   -    -    -     -
   D2 -    -     -
   -    -    -     -
   E2  -    -     -
   -    -    -     -
   F2  -    -     -
   -    -    -     -
   E2  -    -     -
   -    -    -     -
   D2 -    -     -
   -    -    -     -
   E2  -    -     -
   E2  -    -     -
   E2  -    -     -
   E2  -    -     -
   -    -    -     -
   E2  -    -     -
   -    -    -     -
   F2  -    -     -
   -    -    -     -
   -    -    -     -
   };


int command_counter = 0;

inline void next_command() {
        int ctr = command_counter;
        /*        ctr = ctr << 2;
        for (int i = 0; i<4; i++) {
                phasestep[i] = commands[ctr + i];
                }*/
        phasestep[0] = commands[ctr];
        command_counter++;
        if (command_counter > command_max) command_counter = 0;
}

void bootentry()
{
        int t = 0;
        int cmd_t = 0;
        int sec = 0;
        int alter = 1;
        int cmd_threshold = 2760;
        _snd_set_rate(44169); // sample rate for the PWM output

        for(;;) {
                int sample = mixedsample();
                _snd_buffer_push(sample);
                t++; cmd_t++;
                if (cmd_t > cmd_threshold) {
                        next_command();
                        cmd_t = 0;
                }
                if (t > 44169) {alter = 1 - alter; t = 0; sec++; _leds(sec);}
        }
}
