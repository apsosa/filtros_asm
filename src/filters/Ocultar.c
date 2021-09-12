#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>
#include "../tp2.h"

void Ocultar_asm (uint8_t *src, uint8_t *src2, uint8_t *dst, int width, int height,
                      int src_row_size, int dst_row_size);

void Ocultar_c   (uint8_t *src, uint8_t *src2, uint8_t *dst, int width, int height,
                      int src_row_size, int dst_row_size);

typedef void (Ocultar_fn_t) (uint8_t*, uint8_t*, uint8_t*, int, int, int, int);

void ayuda_Ocultar();
void leer_params_Ocultar(configuracion_t *config, int argc, char *argv[]) {
    if (config->archivo_entrada_2 == NULL) {
        printf("El filtro diff requiere de dos archivos de entrada\n\n");
        ayuda_Ocultar();
        exit(EXIT_FAILURE);
    } else {
        printf ( "  Archivo de entrada : %s\n", config->archivo_entrada_2);
    }
}

void aplicar_Ocultar(configuracion_t *config)
{
    Ocultar_fn_t *Ocultar = SWITCH_C_ASM( config, Ocultar_c, Ocultar_asm );
    buffer_info_t info = config->src;
	buffer_info_t info2 = config->src_2;
    if (info.width != info2.width || info.height != info2.height) {
        perror("Las imagenes deben tener el mismo tamaño en pixeles");
    }
    Ocultar(info.bytes, info2.bytes, config->dst.bytes, info.width, info.height, 
            info.row_size, config->dst.row_size);
}

void liberar_Ocultar(configuracion_t *config) {

}

void ayuda_Ocultar()
{
    printf ( "       * Ocultar\n" );
    printf ( "           Ejemplo de uso : \n"
             "                         Ocultar -i c facil.bmp oculto.bmp\n" );
}

DEFINIR_FILTRO(Ocultar,2)