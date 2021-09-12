#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>
#include "../tp2.h"

void Zigzag_asm (uint8_t *src, uint8_t *dst, int width, int height,
                      int src_row_size, int dst_row_size);

void Zigzag_c   (uint8_t *src, uint8_t *dst, int width, int height,
                      int src_row_size, int dst_row_size);

typedef void (Zigzag_fn_t) (uint8_t*, uint8_t*, int, int, int, int);

void leer_params_Zigzag(configuracion_t *config, int argc, char *argv[]) {
}

void aplicar_Zigzag(configuracion_t *config)
{
    Zigzag_fn_t *Zigzag = SWITCH_C_ASM( config, Zigzag_c, Zigzag_asm );
    buffer_info_t info = config->src;
    Zigzag(info.bytes, config->dst.bytes, info.width, info.height, 
            info.row_size, config->dst.row_size);
}

void liberar_Zigzag(configuracion_t *config) {

}

void ayuda_Zigzag()
{
    printf ( "       * Zigzag\n" );
    printf ( "           Ejemplo de uso : \n"
             "                         Zigzag -i c facil.bmp\n" );
}

DEFINIR_FILTRO(Zigzag,1)


