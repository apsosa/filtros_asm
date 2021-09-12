global Descubrir_asm

section .rodata

mask_bitsMirror: db 12,12,12,0,12,12,12,0,12,12,12,0,12,12,12,0
mask_bitsParaArmar: times 4 dd 0x00030303
mask_setearbits:    times 4 dd 0x00FCFCFC
mask_transparencia: times 4 dd 0xFF000000
mask_reubicar: db 0,0,0,0,4,4,4,4,8,8,8,8,12,12,12,12

mask_blueBit7: times 4 dd 0x00000001
mask_blueBit4: times 4 dd 0x00000002

mask_reubicarGreen: db 1,0,0,0,5,0,0,0,9,0,0,0,13,0,0,0
mask_greenBit6: times 4 dd 0x00000100
mask_greenBit3: times 4 dd 0x00000200

mask_reubicarRed:  db 2,0,0,0,6,0,0,0,10,0,0,0,14,0,0,0
mask_redBit5:   times 4 dd 0x00010000
mask_redBit2:   times 4 dd 0x00020000


section .text

; void Descubrir_asm(uint8_t *src, uint8_t *dst, int width, int height,int src_row_size, int dst_row_size);


%define src r11
%define srcMirror r10
%define dst r8
%define ancho_pixel 4
%define desplazamiento -16
%define tot_pixeles rax
%define indice_scrMirror rcx
%define indice_inicio r9
Descubrir_asm:; rdi= *src, rsi = *dst, edx = with,ecx=height,r8d=src_row_size,  r9d=dst_row_size
	push rbp
	mov rbp, rsp 
	xor rax,rax
	; filas*columnas
	mov eax, edx
	imul ecx ; rax = filas*columnas 
	;inicializo indice para recorrer source
	mov indice_inicio,0
	mov indice_scrMirror, tot_pixeles ; r12=desplazamiento a ultimo pixel

	.ciclo:
		cmp tot_pixeles,0
		jz .fin

		; Procedimiento para descubir la imagen

		;levanto los pixeles para recorrelos de inicio-fin
		lea src,[rdi + indice_inicio]
		movdqu xmm1, [src] ; levanto 4 pixeles  

		; Levanto los pixeles espejo de scr para recorrer de fin-inicio
		lea srcMirror,[rdi + indice_scrMirror * ancho_pixel + desplazamiento]
		movdqu xmm2, [srcMirror] ; levanto 4 pixeles 
		pshufd xmm2, xmm2, 0x1b ; 0001 1011 ; reubico para matchear el primer prixel con el ultimo
		
		psrlw xmm2,2 ; pongo los bits 3,2 en los lugares menos significativos de cada componente
		pxor xmm1, xmm2 ; xorteo los pixeles de scr con los de scrMirror 

		; Me quedo con los 2 bits menos significativos de cada componente
		movdqu xmm3, [mask_bitsParaArmar]
		pand xmm1, xmm3

		;Procedimiento para rearmar la imagen en escala de grises
		;Voy a armar color en cada pixel de un xmm para luego reubicarlo en cada byte
		
		; Ubico los bits de blue 
		movdqu xmm4,[mask_blueBit7]
		pand xmm4, xmm1
		psllw xmm4,7 ; ubico el bit	7 para color

		movdqu xmm5, [mask_blueBit4]
		pand xmm5, xmm1
		psllw xmm5,3 ;ubico el bit 4 para color

		por xmm4, xmm5 ; tengo el bit 4 y 7 para color

		; Ubico los bits de green
		movdqu xmm6, [mask_greenBit6] 
		pand xmm6, xmm1
		movdqu xmm5,[mask_reubicarGreen]
		pshufb xmm6, xmm5 ;ubico el componente green en el byte menos significativo del pixel
		psllw xmm6,6 ; ubico el bit	6 para color

		movdqu xmm7,[mask_greenBit3]
		pand xmm7,xmm1
		movdqu xmm5,[mask_reubicarGreen]
		pshufb xmm7, xmm5 ;ubico el componente green en el byte menos significativo del pixel
		psllw xmm7,2 ;ubico el bit 3 para color

		por xmm6, xmm7 ; tengo el bit 3 y 6 para color
		
		; Ubico los bits de red
		movdqu xmm8, [mask_redBit5]
		pand xmm8, xmm1
		movdqu xmm5,[mask_reubicarRed]
		pshufb xmm8, xmm5 ;ubico el componente red en el byte menos significativo del pixel
		psllw xmm8, 5 ; ubico el bit 5 para color

		movdqu xmm9, [mask_redBit2]
		pand xmm9,xmm1
		movdqu xmm5,[mask_reubicarRed]
		pshufb xmm9, xmm5 ;ubico el componente red en el byte menos significativo del pixel
		psllw xmm9, 1 ;ubico el bit 2 para color

		por xmm8, xmm9 ; tengo el bit 3 y 6 para color
		
		; Ahora junto todos los bits de xmm4,xmm6,xmm8
		por xmm4,xmm6
		por xmm4,xmm8 ; en cada pixel en el byte menos significativo tengo el valor de color

		; Seteo el bit 0 y el bit 1 que no fueron almacenados en la imagen oculta
		movdqu xmm10, [mask_setearbits]
		pand xmm4, xmm10

		; Reubico los grises en cada componente
		movdqu xmm12, [mask_reubicar]
		pshufb xmm4,xmm12

		;seteo la tranparencia
		movdqu xmm11,[mask_transparencia]
		por xmm4, xmm11


		lea dst, [rsi + indice_inicio]
		movdqu [dst], xmm4


		;Actualizo mis contadores
		add indice_inicio, 16
		sub tot_pixeles, 4
		sub indice_scrMirror, 4

	jmp .ciclo
	.fin:
	pop rbp
	ret
