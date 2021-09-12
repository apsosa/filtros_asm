#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>
#include "../tp2.h"

void Descubrir_asm (uint8_t *src, uint8_t *dst, int width, int height,
                      int src_row_size, int dst_row_size);

void Descubrir_c   (uint8_t *src, uint8_t *dst, int width, int height,
                      int src_row_size, int dst_row_size);

typedef void (Descubrir_fn_t) (uint8_t*, uint8_t*, int, int, int, int);


void leer_params_Descubrir(configuracion_t *config, int argc, char *argv[]) {
}

void aplicar_Descubrir(configuracion_t *config)
{
    Descubrir_fn_t *Descubrir = SWITCH_C_ASM( config, Descubrir_c, Descubrir_asm );
    buffer_info_t info = config->src;
    Descubrir(info.bytes, config->dst.bytes, info.width, info.height, 
              info.row_size, config->dst.row_size);
}

void liberar_Descubrir(configuracion_t *config) {

}

void ayuda_Descubrir()
{
    printf ( "       * Descubrir\n" );
    printf ( "           Ejemplo de uso : \n"
             "                         Descubrir -i c facil.bmp\n" );
}

DEFINIR_FILTRO(Descubrir,1)


