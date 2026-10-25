# Estado de pruebas (sin ejecutar en Godot)
Este proyecto se escribió en un entorno SIN Godot instalado. Lo que sí se comprobó:
- Referencias entre scripts: todas las llamadas a funciones propias existen (comprobación automática con un script).
- Sangrado homogéneo con tabuladores en todos los .gd.
- Los 16 archivos de audio existen y son WAV válidos (generados por código).
- Copia de seguridad de la versión anterior: miliki-godot-v1-copia-seguridad.zip.
Lo que NO se comprobó (hay que probarlo al abrir en Godot 4.3+):
- Que el proyecto abre sin errores del analizador de GDScript.
- Cinemáticas (inicio, victoria, pepino, derrota) y su salto con Espacio/Intro/Esc/clic.
- Onda de Pepino (R), calidad (G), cambio de armas, animaciones y rendimiento.
Si aparece un error, copia el mensaje de la consola de Godot y se corrige.
