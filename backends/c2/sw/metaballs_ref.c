#include <stdio.h>

int metaball(int x, int y, int x1, int x2, int y1, int y2, int mass)
{
        int dx1 = x - x1;
        int dx2 = x - x2;
        int dy1 = y - y1;
        int dy2 = y - y2;
        int d1sq = dx1 * dx1 + dy1 * dy1;
        int d2sq = dx2 * dx2 + dy2 * dy2;
        int g1 = 0, g2 = 0;
        if (d1sq>0) g1 =  mass / d1sq;
        if (d2sq>0) g2 =  mass / d2sq; 
        return g1 + g2;
}

int main()
{
        int x2 = 10, step = 1;
        for (int delta = 1;;delta++) {
                int idelta = delta % 40;
                if (idelta == 0) step = -step;
                int x1 = 10,
                        y1 = 10, y2 = 20;
                x2 += step;
                int mass = 150;
                printf("%c[2J\n", 27);
                for (int y = 0; y < 50; y++) {
                        for (int x = 0; x < 80; x++)  {
                                int m = metaball(x, y, x1, x2, y1, y2, mass);
                                if (m > 0) printf("%c", '.' + (m%30)); else printf(" ");
                        }
                        printf("\n");
                        
                }
        }
}

