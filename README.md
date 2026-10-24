# Miliki y el Pepino (Godot 4.3+)
Soulslike de un solo jefe: Miliki contra Fuvu, guardián del pepino de Jimmy, para devolver la felicidad a Ceuta.

## Ejecutar
1. Instala Godot 4.3 o superior (versión estándar, no .NET).
2. Importa `project.godot` y pulsa F5. La primera vez Godot importa los sonidos.

## Controles
WASD mover · ratón o ← → cámara · clic izq. ataque rápido · clic der. ataque pesado · Espacio esquivar · Mayús correr · Q fijar objetivo · F curarse · **1 / 2 / 3 cambiar de arma** · Esc pausa.

## Armas (cfg.gd)
| Tecla | Arma | Carácter |
|---|---|---|
| 1 | Espada de Miliki | equilibrada |
| 2 | Hacha del hortelano | lenta, golpe ancho y mucho daño |
| 3 | Podadera curva | rápida, alcance corto, daño bajo |

## Física
Movimiento con inercia, impulso al atacar, retroceso al recibir daño, capa y bufanda con muelle, retroceso y deslizamiento del jefe, vibración de cámara al caminar el jefe.

## Estructura
`cfg.gd` equilibrio · `models.gd` modelos procedurales y armas · `player.gd` · `boss.gd` · `game.gd` mundo, cámara, HUD, audio y estados · `audio/` sonidos.

## Modelos 3D externos (opcional)
Si existen `models/miliki.glb` o `models/fuvu.glb`, el juego los usa en lugar de los procedurales (ajusta la escala en `Cfg.EXT`). Fuentes con licencia CC0: Kenney, Quaternius, KayKit y Poly Haven. Poly Pizza es mayoritariamente CC-BY (hay que dar crédito). Comprueba siempre la licencia de cada archivo y apúntala en CREDITS.md.

## Exportar a Windows
Proyecto → Exportar → Windows Desktop. Sin firma digital, SmartScreen puede avisar.

## Estado
Sin probar dentro de Godot: pueden hacer falta correcciones menores.
