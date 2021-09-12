
global Ocultar_asm


section .rodata

align 16
mask_blue:  times 4 dd 0x000000FF 
mask_green: times 4 dd 0x0000FF00
mask_red:   times 4 dd 0x00FF0000
mask_alpha: times 4 dd 0xFF000000

mask_bitsMirror: db 12,12,12,0,12,12,12,0,12,12,12,0,12,12,12,0
mask_color: db 0,0,0,0,4,4,4,4,8,8,8,8,12,12,12,12


mask_primerBitRojo:   times 4 dd 0x00040000
mask_segundoBitRojo:  times 4 dd 0x00200000

mask_primerBitVerde:  times 4 dd 0x00000800
mask_segundoBitVerde: times 4 dd 0x00004000

mask_primerBitAzul:   times 4 dd 0x00000010
mask_segundoBitAzul:  times 4 dd 0x00000080

mask_resultado:       times 4 dd 0x00FCFCFC
mask_tranparenciaYcolor: times 4 dd 0xFF030303


section .text
  ; |	 rbp     | <-rsp
  ; |dst_row_size| <-rsp + 8
  ; |     return | <- rsp + 16
  ; | XXXXXXXXXX |

; void Ocultar_asm (uint8_t *src, uint8_t *src2, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size);


%define src r8
%define src2 rax
%define dst r9
%define srcMirror r10
%define tot_pixeles rcx
%define contador r11
%define anchoPixel 4
%define desplazamiento -16
%define indice_scrMirror r12
Ocultar_asm: ; rdi= *src, rsi = *src2, rdx = *dst, ecx=with,r8d=height,r9d=src_row_size,[rsp+8]=dst_row_size  
	push rbp ; 
	mov rbp,rsp
	push r12
	mov r11, rdx ;preservo rdx 
	xor rax,rax
	; filas*columnas
	mov eax, ecx
	imul r8d
	mov tot_pixeles, rax
	mov rdx,r11 ;  restauro rdx
	mov contador,0
	mov indice_scrMirror, tot_pixeles ; r12=desplazamiento a ultimo pixel
	.ciclo:
		cmp tot_pixeles,0
		jz .fin
		
		; Pasamos a escala de grises	
		; Para ello obtengo cada componente ultizando de Mascaras

		lea src2,[rsi + contador]
		movdqu xmm1, [src2] ; levanto 4 pixeles  
		
		; Obtengo la componente BLUE
		movdqa xmm2, [mask_blue] 
		pand xmm2,xmm1 ; xmm2 =|0|0|0|b|.....|0|0|0|b|
		
		; Obtengo la componente RED
		movdqa xmm3,[mask_red]
		pand xmm3, xmm1 ; xmm3 =|0|r|0|0|.....|0|r|0|0|
		psrld xmm3,16 ; xmm3 =|0|0|0|r|.....|0|0|0|r| 
		
		; Obtengo la componente GREEN
		movdqa xmm4,[mask_green]
		pand xmm4, xmm1 ; xmm4 =|0|0|g|0|.....|0|0|g|0|
		psrld xmm4, 8 ; xmm4 =|0|0|0|g|.....|0|0|0|g|
		
		;mulplico por 2 la componente GREEN
		paddw xmm4,xmm4 ;xmm4 =|0|0|0|2g|.....|0|0|0|2g|
		
		paddw xmm4,xmm2 ;xmm4 =|0|0|0|b+2g|.....|0|0|0|b+2g|
		paddw xmm4,xmm3 ;xmm4 =|0|0|0|b+2g+r|.....|0|0|0|b+2g+r|
		psrlw xmm4, 2 ; xmm4 =|0|0|0|(b+2g+r)/4|.....|0|0|0|(b+2g+r)/4|

		
		;Comenzamos el procedimiento para ocultar la imagen 
		
		; levanto el scr(mirror)
		;movdqu xmm12,[mask_mirror]
		lea srcMirror, [rdi + indice_scrMirror * anchoPixel + desplazamiento]
		movdqa xmm5 , [srcMirror]
		pshufd xmm5, xmm5, 0x1b ; 0001 1011 ; reubico para matchear el primer prixel con el ultimo

		; Obtengo los bits de src2Mirror a xortear
		movdqa xmm6, [mask_bitsMirror]; xmm6=|0|12|12|12|.....|0|12|12|12|
		pand xmm6, xmm5 ; xmm6=|0|bit[3,2]|bit[3,2]|bit[3,2]|.....|0|bit[3,2]|bit[3,2]|bit[3,2]|
		psrlw xmm6,2 ; pongo los bits 3,2 en los lugares menos significativos de cada componente

		;reubico el resultado
		movdqa xmm7, [mask_color]
		pshufb xmm4, xmm7 ; xmm4=|color1|color1|color1|color1|.....|color4|color4|color4|color4| donde color= (b+2g+r)/4

		;Tomo el primer bit a xortear de color con el bit del componente red de scr2(mirror)
		movdqu xmm8,xmm4
		movdqa xmm9, [mask_primerBitRojo]
		pand xmm8, xmm9 ; xmm8 =|..|..|..|bit[2].color1|.....|..|..|..|bit[2].color4|
		psrlw xmm8,1 

		;Tomo el 2do bit a xortear de color con el bit del componente red de scr2(mirror)
		movdqu xmm10, xmm4
		movdqa xmm9, [mask_segundoBitRojo]
		pand xmm10,xmm9 ;xmm10 =|..|..|..|bit[5].color1|.....|..|..|..|bit[5].color4|
		psrlw xmm10,5 

		por xmm10,xmm8 ; xmm10= |..|..|..|bit[2]ybit[5]de color|....|..|..|..|bit[2]ybit[5]de color|

		;Tomo el primer bit a xortear de color con el bit de componente green de scr2(mirror)
		movdqu xmm1,xmm4 
		movdqa xmm9,[mask_primerBitVerde]
		pand xmm1,xmm9 ;xmm1 =|..|..|bit[3].color1|..|.....|..|..|bit[3].color4|..	|
		psrlw xmm1, 2 
		;Tomo el 2do bit a xortear de color con el bit del componente green de scr2(mirror)
		movdqu xmm2, xmm4
		movdqa xmm9, [mask_segundoBitVerde]
		pand xmm2,xmm9 ;xmm2 =|..|..|bit[6].color1|..|.....|..|..|bit[6].color4|..|
		psrlw xmm2,6 

		por xmm1,xmm2 ; xmm1= |..|..|bit[3]ybit[6]de color|..|....|..|..|bit[3]ybit[6]de color|..|

		;Tomo el primer bit a xortear de color con el bit de componente blue de scr2(mirror)
		movdqu xmm3,xmm4 ;  
		movdqa xmm9,[mask_primerBitAzul]
		pand xmm3,xmm9 ;xmm3 =|..|bit[4].color1|..|..|.....|..|..|bit[4].color4|..|
		psrlw xmm3,3 
 		
 		;Tomo el 2do bit a xortear de color con el bit de componente blue de scr2(mirror)
		movdqu xmm5,xmm4 ;  
		movdqa xmm9,[mask_segundoBitAzul]
		pand xmm5,xmm9 ;xmm5 =|..|bit[7].color1|..|..|.....|..|bit[7].color4|..|..|
		psrlw xmm5,7 

		por xmm3,xmm5 ; xmm3= |..|bit[4]ybit[7]de color|..|..|....|..|bit[4]ybit[7]de color|..|..|

		;Ahora junto todos los bit de color que tengo en xmm10,xmm1y xmm3 que estan en la parte menos significativa de cada componente
		por xmm10,xmm1
		por xmm10,xmm3 ;xmm10=|..|bit[4][7]|bit[3]bit[6]|bit[2]bit[5]|....|..|bit[4][7]|bit[3]bit[6]|bit[2]bit[5]|

		pxor xmm10,xmm6 ; aplico el xor entre los bits

		;levanto los pixeles de src
		lea src,[rdi + contador]
		movdqu xmm0, [src]
		movdqa xmm1,[mask_resultado]
		pand xmm0,xmm1 ; pongo ceros en los 2 bits menos significativos de cada componente y la trampararencia en ceros

		movdqa xmm2, [mask_tranparenciaYcolor]
		pand xmm10, xmm2 ; tengo la transparencia y los valores a guardar  
		movdqa xmm4, [mask_alpha]
		por xmm10, xmm4
		por xmm0, xmm10 ; tengo el valor para ponerlo en dst
		
		lea dst, [rdx + contador]
		movdqu [dst],xmm0

		add contador,16
		sub tot_pixeles,4
		sub indice_scrMirror,4

	jmp .ciclo
	.fin:
	pop r12
	pop rbp
	ret
