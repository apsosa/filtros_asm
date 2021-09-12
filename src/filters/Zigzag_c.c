#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>
#include "../tp2.h"
#include "../helper/utils.h"

void Zigzag_c(
    uint8_t *src,
    uint8_t *dst,
    int width,
    int height,
    int src_row_size,
    int dst_row_size)
{
    bgra_t (*src_matrix)[(src_row_size+3)/4] = (bgra_t (*)[(src_row_size+3)/4]) src;
    bgra_t (*dst_matrix)[(dst_row_size+3)/4] = (bgra_t (*)[(dst_row_size+3)/4]) dst;

    for (int i = 2; i < height-2; i++) {
        for (int j = 2; j < width-2; j++) {
            if( i%4 == 0 || i%4 == 2) {
                dst_matrix[i][j].b = (src_matrix[i][j-2].b + src_matrix[i][j-1].b + src_matrix[i][j].b + src_matrix[i][j+1].b + src_matrix[i][j+2].b) / 5;
                dst_matrix[i][j].g = (src_matrix[i][j-2].g + src_matrix[i][j-1].g + src_matrix[i][j].g + src_matrix[i][j+1].g + src_matrix[i][j+2].g) / 5;
                dst_matrix[i][j].r = (src_matrix[i][j-2].r + src_matrix[i][j-1].r + src_matrix[i][j].r + src_matrix[i][j+1].r + src_matrix[i][j+2].r) / 5;
            }
            else {
                if( i%4 == 1 ) {
                    dst_matrix[i][j].b = src_matrix[i][j-2].b;
                    dst_matrix[i][j].g = src_matrix[i][j-2].g;
                    dst_matrix[i][j].r = src_matrix[i][j-2].r;
                } else {
                    dst_matrix[i][j].b = src_matrix[i][j+2].b;
                    dst_matrix[i][j].g = src_matrix[i][j+2].g;
                    dst_matrix[i][j].r = src_matrix[i][j+2].r;
                }
            }
            dst_matrix[i][j].a = 255;
        }
    }

    utils_paintBorders32(dst, width, height, src_row_size, 2, 0xFFFFFFFF);
}
