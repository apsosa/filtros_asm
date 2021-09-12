#!/usr/bin/env python3

from termcolor import colored
import subprocess
from libtest import *

if not os.path.exists(TESTINDIR):
    print(colored('ERROR: Debe correr primero el script %s'%(PRIMER_SCRIPT), 'red'))
    exit()

print(colored('Compilando el ejecutable...', 'blue'))
ret = subprocess.run(["make", "-C", "../"])
if ret.returncode!=0:
   print(colored('La compilación falló, intentá correr make desde la raíz del proyecto', 'red'))
   exit()

print(colored('Iniciando test de diferencias ASM vs. la catedra...', 'blue'))

todos_ok = True

imgs = archivos_tests()
imgs.sort()
img0 = imgs[0:int(len(imgs)/2)]
img1 = imgs[int(len(imgs)/2):]

# Ocultar
for i in range(len(img0)):
    ok = verificar('Ocultar', TESTINDIR + "/" + img1[i], 0, 'asm', TESTINDIR + "/" + img0[i])
    todos_ok = todos_ok and ok

# Ocultar
for i in range(len(img1)):
    ok = verificar('Ocultar', TESTINDIR + "/" + img0[i], 0, 'asm', TESTINDIR + "/" + img1[i])
    todos_ok = todos_ok and ok

# Descubrir
for i in range(len(img0+img1)):
    ok = verificar('Descubrir', '', 0, 'asm', CATEDRADIR + "/" + imgs[i] + ".Ocultar.ASM.bmp")
    todos_ok = todos_ok and ok
    
# Zigzag
for i in range(len(imgs)):
    ok = verificar('Zigzag', '', 2, 'asm', TESTINDIR + "/" + imgs[i])
    todos_ok = todos_ok and ok

if todos_ok:
    print(colored("Test de filtros finalizados correctamente", 'green'))
else:
    print(colored("se encontraron diferencias en algunas de las imagenes", 'red'))
