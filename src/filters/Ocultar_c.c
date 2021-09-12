#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>
#include "../tp2.h"
#include "../helper/utils.h"

void Ocultar_c(
    uint8_t *src,
    uint8_t *src2,
    uint8_t *dst,
    int width,
    int height,
    int src_row_size,
    int dst_row_size)
{
    bgra_t (*src_matrix)[(src_row_size+3)/4] = (bgra_t (*)[(src_row_size+3)/4]) src;
    bgra_t (*dst_matrix)[(dst_row_size+3)/4] = (bgra_t (*)[(dst_row_size+3)/4]) dst;
    bgra_t (*src2_matrix)[(src_row_size+3)/4] = (bgra_t (*)[(src_row_size+3)/4]) src2;

    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {

            uint8_t color = (uint32_t)(src2_matrix[i][j].b + 2 * src2_matrix[i][j].g + src2_matrix[i][j].r) >> 2;
           //  _7_ _6_ _5_ _4_ _3_ _2_ _1_ _0_
           // | B | G | R | B | G | R | x | x |
           // |_0_|_0_|_0_|_1_|_1_|_1_|_x_|_x_|
           //
            uint8_t bitsB = (((color >> 4) & 0x1) << 1) | ((color >> 7) & 0x1);
            uint8_t bitsG = (((color >> 3) & 0x1) << 1) | ((color >> 6) & 0x1);
            uint8_t bitsR = (((color >> 2) & 0x1) << 1) | ((color >> 5) & 0x1);

            dst_matrix[i][j].b = (src_matrix[i][j].b & 0xFC) + ((bitsB & 0x3) ^ ((src_matrix[(height-1)-i][(width-1)-j].b >> 2) & 0x3));
            dst_matrix[i][j].g = (src_matrix[i][j].g & 0xFC) + ((bitsG & 0x3) ^ ((src_matrix[(height-1)-i][(width-1)-j].g >> 2) & 0x3));
            dst_matrix[i][j].r = (src_matrix[i][j].r & 0xFC) + ((bitsR & 0x3) ^ ((src_matrix[(height-1)-i][(width-1)-j].r >> 2) & 0x3));
            dst_matrix[i][j].a = 255;

        }
    }
}
