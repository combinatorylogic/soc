# 1. read 16 bytes into shift register
# 2. shift it N times left by 3 bytes
# 3. once 


def shift3(lst, initp):
    reg = [' ' for a in range(16)] + [' ' for a in range(16)]
    for x in range(2,32):
        reg[x] = lst[x-3]
    if initp:
        print("Output: {%r%r%r}"%(lst[31],lst[30],lst[29]))
    return reg

def shiftreg():
    src = [hex(a)[2] for a in range(16)]
    reg = ['x'] + [hex(a)[2] for a in range(16)] + ['x' for a in range(15)]
    leftpos = 1
    cyc = 1
    initp = False
    # Pixel clock:
    while True:
        reg = shift3(reg, initp)
        leftpos = leftpos + 3
        if ((not initp) and leftpos > 15):
            initp = True
        if (leftpos > 15):
            # FSM
            if (cyc == 0):
                cyc = 2
            elif (cyc == 2):
                cyc = 1
            elif (cyc == 1):
                cyc = 0
            print('Reading at %r-%r'%( cyc+16, cyc))
            for x in range(cyc):
                reg[x] = ' '
            for x in range(16):
                reg[x + cyc] = src[x]
            #for x in range(2-cyc):
            #    reg[16+cyc+x] = 'x'
            leftpos = cyc
        


shiftreg()
    


# 0123456789abcdef
#                   X123456789abcdef
#   0123456789abcdefX123456789abcdef
#                  X123456789abcdefX123456789abcdef
#  0123456789abcdefX123456789abcdefX123456789abcdef
#                 X123456789abcdefX123456789abcdefX123456789abcdef
# 0123456789abcdefX123456789abcdefX123456789abcdefX123456789abcdef

# 0123456789abcdef
#                   0123456789abcdef

# i.e., cycle is:
# 1-16, shift-shift-shift...
# 0-15, shift-shift-shift...
# 2-17, shift-shift-shift...
# 1-16, shift-shift-shift...
# 0-15, ...



#  0 | 0123456789abcdef0123456789abcde|
#  1 |    0123456789abcdef0123456789ab|
#  2 |       0123456789abcdef012345678|
#  3 |          0123456789abcdef012345|
#  4 |             0123456789abcdef012|
#  5 |                0123456789abcdef|
