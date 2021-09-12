#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>
#include "../tp2.h"
#include "../helper/utils.h"

void Descubrir_c(
    uint8_t *src,
    uint8_t *dst,
    int width,
    int height,
    int src_row_size,
    int dst_row_size)
{
    bgra_t (*src_matrix)[(src_row_size+3)/4] = (bgra_t (*)[(src_row_size+3)/4]) src;
    bgra_t (*dst_matrix)[(dst_row_size+3)/4] = (bgra_t (*)[(dst_row_size+3)/4]) dst;


    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
           //  _7_ _6_ _5_ _4_ _3_ _2_ _1_ _0_
           // | B | G | R | B | G | R | x | x |
           // |_0_|_0_|_0_|_1_|_1_|_1_|_x_|_x_|
           //  
            uint8_t b = ((src_matrix[(height-1)-i][(width-1)-j].b >> 2) ^ src_matrix[i][j].b) & 0x3;
            uint8_t g = ((src_matrix[(height-1)-i][(width-1)-j].g >> 2) ^ src_matrix[i][j].g) & 0x3;
            uint8_t r = ((src_matrix[(height-1)-i][(width-1)-j].r >> 2) ^ src_matrix[i][j].r) & 0x3;

            uint8_t bit2 = (r >> 1) & 0x1;
            uint8_t bit3 = (g >> 1) & 0x1;
            uint8_t bit4 = (b >> 1) & 0x1;
            uint8_t bit5 = r & 0x1;
            uint8_t bit6 = g & 0x1;
            uint8_t bit7 = b & 0x1;

            uint8_t color = (bit7 << 7) | (bit6 << 6) | (bit5 << 5) | (bit4 << 4) | (bit3 << 3) | (bit2 << 2);

            dst_matrix[i][j].b = color;
            dst_matrix[i][j].g = color;
            dst_matrix[i][j].r = color;
            dst_matrix[i][j].a = 255;

        }
    }
}
