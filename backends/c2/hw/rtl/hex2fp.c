#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv)
{
        char *v=argv[1];
        unsigned int ui;
        sscanf(v, "%x", &ui);
        float fp = *((float *)(&ui));
        printf("%f\n", fp);
        return 0;
}
