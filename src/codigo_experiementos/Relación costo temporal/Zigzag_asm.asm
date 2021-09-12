
global Zigzag_asm

section .data
desempaquetador: times 16 db 0 

section .rodata
mask_division: times 4 dd 5.0
mask_white: times 16 db 255
mask_dosPixelesL: db 0,0,0,0,0,0,0,0,255,255,255,255,255,255,255,255
mask_dosPixelesH: db 255,255,255,255,255,255,255,255,0,0,0,0,0,0,0,0
section .text


; void Zigzag_asm (uint8_t *src, uint8_t *dst, int width, int height,int src_row_size, int dst_row_size);
%define src rdi
%define dst rsi
;%define desempaquetador xmm15
%define des_1pxl -4 
%define des_2pxl 8
%define modulo_fila r12
%define cant_filas_restantes r13

Zigzag_asm: ; rdi = src, rsi = dst, edx = width, ecx = height,r8d=src_row_size, r9d = dst_row_size
	push rbp
	mov rbp, rsp
	

	;limpiamos parte alta

	mov edx, edx
	mov ecx, ecx
	mov r8d, r8d
	mov r9d, r9d
	
	;inicializo un registro con el modulo de la fila
	push r12
	mov modulo_fila, 2

	;inicializo un registro con la cantidad de filas a recorrer
	push r13
	mov cant_filas_restantes, rcx
	sub cant_filas_restantes, 4


	;conservo punteros para pintar bordes
	mov r10, rsi
	
	;avanzamos el puntero inicial a la posición [2][2]
	lea src, [rdi + r8*2 + 8]
	lea dst, [rsi + r8*2 + 8]

	;puntero al final de la fila
	lea r11, [src + r8 - 16]

	pxor xmm15,xmm15


	; src arranca en el prixel 2
	.modulo0o2:
		
		; xmm0 = ←←, xmm1 = ←, xmm2 = ., xmm3 = →, xmm4 = →→
		
		; i % 4 == 0 || i%4 ==2
		movdqu xmm0, [src - 8]	; src[i][j-2] xmm2 = |pixel0|..|..|..|			  
		movdqu xmm1, [src - 4]  ; src[i][j-1] xmm2 = |pixel1|..|..|..|
		
		movdqu xmm2, [src + 0]  ; src[i][j]  xmm3 = |pixel2|pixel3|prixel4|prixe5|
		
		movdqu xmm3, [src + 4] 	; src[i][j+1]  xmm1 = |pixel6|pixel7|prixel8|prixe9|
		movdqu xmm4, [src + 8]	; src[i][j+2] xmm4 = |pixel10|pixel11|prixel12|prixe13|
		
		movdqu xmm5, xmm0
		movdqu xmm6, xmm1
		movdqu xmm7, xmm2
		movdqu xmm8, xmm3
		movdqu xmm9, xmm4 
		
	;******Procesamos los 2 pixeles de la parte baja******	
		
		;Suma de cada componente
		punpcklbw xmm5, [desempaquetador] ; xmm5 = | src[i][j-2]₀ |
		punpcklbw xmm6, [desempaquetador] ; xmm6 = | src[i][j-1]₀ |
		punpcklbw xmm7, [desempaquetador] ; xmm7 = | src[i][j]₀	|
		punpcklbw xmm8, [desempaquetador] ; xmm8 = | src[i][j+1]₀ |
		punpcklbw xmm9, [desempaquetador] ; xmm9 = | src[i][j+2]₀ |
		paddw xmm7, xmm5
		paddw xmm7, xmm6
		paddw xmm7, xmm8
		paddw xmm7, xmm9 ; xmm7=(src i,j-2 + src i,j-1 + src i,j + src i,j+1 + src i,j+2 )₀
		
		; Ahora realizamos la division

				movdqu xmm5, xmm7 ; preservo xmm7
			
				;Arrnacamos con la parte baja
			
				;Primero desempaquetamos las words a doble
				punpcklwd xmm5,[desempaquetador] ; xmm5 = 0 | suma₀ | 0 | suma₀ ... 0 | suma₀ | 0 | suma₀
			
				;Ahora converimos las dobles desempaquetados
				cvtdq2ps xmm6, xmm5 ; conversion a ps
			
				;Ahora divido por 5 cada (Verificar si  los 5 de la mascara son realmentes floats)
				movdqu xmm8, [mask_division]
				divps xmm6, xmm8 ; xmm6=resultado de la division de la parte baja
		
				;Ahora convertimos los ps a interger
				cvttps2dq xmm9, xmm6 ;xmm9=suma/5 en dwords
		
				;Vamos con la parte alta
				punpckhwd xmm7,[desempaquetador] ; xmm7 = 0 | suma₁ | 0 | suma₁ ... 0 | suma₁ | 0 | suma₁
		
				;Ahora converimos las dobles desempaquetados
				cvtdq2ps xmm5, xmm7 ; conversion a ps
				
				;Ahora divido por 5 cada (Verificar si  los 5 de la mascara son realmentes floats)
				divps xmm5, xmm8; xmm5 = resultado de la division parte alta
		
				;Ahora convertimos los ps a interger
				cvttps2dq xmm5, xmm5 ;xmm5=suma/5 en dwords
	
				;Ahora los vuelvo a empaquetar a words
				packusdw xmm9, xmm5 ; xmm9 = suma/5 baja en cada words
		
	;*******Procesamos los 2 pixeles de la parte alta de la misma manera********
		
		punpckhbw xmm0, [desempaquetador] ; xmm0 = | src[i][j-2]₁ | 
		punpckhbw xmm1, [desempaquetador] ; xmm1 = | src[i][j-1]₁ |
		punpckhbw xmm2, [desempaquetador] ; xmm2 = | src[i][j]₁   | 
		punpckhbw xmm3, [desempaquetador] ; xmm3 = | src[i][j+1]₁ |
		punpckhbw xmm4, [desempaquetador] ; xmm4 = | src[i][j+2]₁ |

		;realizamos las sumas
		paddw xmm0, xmm1
		paddw xmm0, xmm2
		paddw xmm0, xmm3
		paddw xmm0, xmm4 ;xmm0 = (src i,j-2 + src i,j-1 + src i,j + src i,j+1 + src i,j+2 )₁
			
		; Ahora realizamos la division
				movdqu xmm5, xmm0 ; preservo xmm0
		
				;Primero desempaquetamos las words a doble
				punpcklwd xmm5,[desempaquetador] ; xmm5 = 0 | suma₀ | 0 | suma₀ ... 0 | suma₀ | 0 | suma₀
				
				;Ahora converimos las dobles desempaquetados
				cvtdq2ps xmm6, xmm5 ; conversion a ps
				
				;Ahora divido por 5 cada (Verificar si  los 5 de la mascara son realmentes floats)
				movdqu xmm8, [mask_division]
				divps xmm6, xmm8 ; xmm6=resultado de la division de la parte baja
		
				;Ahora convertimos los ps a interger
				cvttps2dq xmm10, xmm6 ;xmm10=suma/5 en dwords
		
				;Vamos con la parte alta
				punpckhwd xmm0,[desempaquetador] ; xmm0 = 0 | suma₁ | 0 | suma₁ ... 0 | suma₁ | 0 | suma₁
		
				;Ahora converimos las dobles desempaquetados
				cvtdq2ps xmm5, xmm0 ; conversion a ps
				
				;Ahora divido por 5 cada (Verificar si  los 5 de la mascara son realmentes floats)
				divps xmm5, xmm8; xmm5 = resultado de la division parte alta
		
				;Ahora convertimos los ps a interger
				cvttps2dq xmm11, xmm5 ;xmm11=suma/5 en dwords
	
				;Ahora los vuelvo a empaquetar a words
				packusdw xmm10, xmm11 ; xmm10 = suma/5 alta en cada word

		
		packuswb xmm9,xmm10
		movdqu [dst],xmm9
		add src, 16
		add dst, 16

		cmp src, r11
		je .finFila

		jmp .modulo0o2

		.finFila:

			;verificamos si ya recorrimos todas las filas
			dec cant_filas_restantes
			cmp cant_filas_restantes, 0
			je .pintar_bordes

			;avanzamos los punteros a la siguiente fila
			add src, 16
			add dst, 16
			
			;incrementamos el puntero al fin de la siguiente fila
			lea r11, [src + r8 - 16]

			;continuamos con la siguiente formula a aplicar
			inc modulo_fila
			cmp modulo_fila, 1
			je .modulo1
			cmp modulo_fila, 2
			je .modulo0o2
			cmp modulo_fila, 3
			je .modulo3
			mov modulo_fila, 0
			jmp .modulo0o2
			

		; i%4 == 1
		.modulo1:
			movdqu xmm1,[src - des_2pxl]
			movdqu [dst], xmm1
			add src, 16
			add dst, 16
			cmp src, r11
			je .finFila
			jmp .modulo1
		

		; i%4 == 3
		.modulo3:
			movdqu xmm1,[src + des_2pxl]
			movdqu [dst], xmm1
			add src, 16
			add dst, 16
			cmp src, r11
			je .finFila
			jmp .modulo3

	.pintar_bordes:
	
	;restauro puntero
	mov dst, r10
	
	;puntero al final de la 2da fila
	lea r11, [dst + r8*2]

	;inicializo un registro con la cantidad de filas a recorrer para los bordes Horizontales
	mov cant_filas_restantes, rcx

	;inicializo un registro con la cantidad de columnas a recorrer para los bordesHorizontales
	sub cant_filas_restantes, 4
				
				.bordeSuperior:
					
					;Pinto los bordes
					movdqu xmm2, [mask_white]
					movdqu [dst], xmm2

					;avanzo punteros
					add dst, 16
					
					;verifico si llegue al final
					cmp r11, dst
					je .bordesHorizontales
					jmp .bordeSuperior
					


				.bordesHorizontales:
					;arranco desde la posición [2][0]

					;proceso los 2 pixeles del borde inicial
					movdqu xmm1, [dst]

					movdqu xmm2, [mask_dosPixelesL]
					pand xmm2, xmm1

					movdqu xmm3, [mask_dosPixelesH]
					por xmm3, xmm2

					movdqu [dst], xmm3

					
					;Salto al final de la fila
					lea dst, [dst + r8 - 16]
					
					;proceso los 2 pixeles del borde final
					movdqu xmm1, [dst]

					movdqu xmm2, [mask_dosPixelesH]
					pand xmm2, xmm1

					movdqu xmm3, [mask_dosPixelesL]
					por xmm3, xmm2

					movdqu [dst], xmm3
					
					;avanzo punteros
					add dst, 16

					sub cant_filas_restantes, 1

					cmp cant_filas_restantes, 0
					
					jz .bordeinferior
					jmp .bordesHorizontales


									
				
				.bordeinferior:
					;puntero al final 
					lea r11, [dst + r8*2]

					.ciclo_final:
					
					;Pinto los bordes
					movdqu xmm2, [mask_white]
					movdqu [dst], xmm2

					;avanzo punteros
					add dst, 16
					
					;verifico si llegue al final
					cmp r11, dst
					je .fin
					jmp .ciclo_final
					


	.fin:				
	pop r13
	pop r12
	pop rbp
	ret
