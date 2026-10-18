#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv)
{
        char *v=argv[1];
        float fp = atof(v);
        unsigned int ui = *((unsigned int *)(&fp));
        printf("%x\n", ui);
        return 0;
}
