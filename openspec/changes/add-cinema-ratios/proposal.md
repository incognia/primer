## Why

Muchas películas no son 16:9: las de acción llegan en 2.39:1 y otras en 2.35:1. En un panel 16:9, Prime Video las muestra con barras negras arriba y abajo (se vio con una película en la prueba de tres paneles), y esas barras ocupan pantalla sin aportar nada. Con un solo panel, la ventana podría tener la proporción de la película y llenarla.

## What Changes

- Con **un solo panel**, una acción nueva, ⌥⌘P («proporción»), cambia la proporción de la ventana de forma secuencial: 16:9 → 2.35:1 → 2.39:1 → 16:9 → …
- La acción **solo está habilitada con un panel**: con dos o tres paneles el elemento del menú aparece deshabilitado y el atajo no hace nada.
- Al abrir un segundo panel (⌘2, ⌘3), la ventana vuelve a 16:9 antes de repartir los paneles, porque los paneles múltiples son siempre 16:9. Al volver a un panel, la proporción sigue siendo 16:9: no se recuerda la que había.
- Al cambiar la proporción se conserva el ancho y la esquina superior izquierda de la ventana; cambia el alto. El panel llena la ventana, así que el reproductor se ajusta al nuevo tamaño.
- Rellenar y centrar (⌘F) y el arrastre de bordes usan la proporción vigente.
- La autoprueba cubre el ciclo, las medidas, el deshabilitado con más de un panel y el regreso a 16:9.

Fuera del alcance:

- Otras proporciones (21:9, 1.85:1, 4:3, 2.20:1) o una proporción escrita a mano.
- Detectar la proporción de la película y ajustar la ventana por sí sola: el usuario elige.
- Proporciones distintas de 16:9 con dos o tres paneles.
- Recordar la proporción entre aperturas de la aplicación, o al volver de varios paneles a uno.
- Recortar o estirar el video: la ventana cambia de forma y el reproductor de Prime Video decide cómo llenar su espacio.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `window-chrome`: la proporción fija con un panel puede ser 16:9, 2.35:1 o 2.39:1, el ciclo secuencial, su deshabilitado con más de un panel y el regreso a 16:9 al abrir otro panel.
- `panes`: un panel llena la ventana con la proporción vigente; con dos o tres paneles cada panel sigue siendo 16:9.
- `shortcuts`: ⌥⌘P para la proporción.
- `selftest`: comprobaciones del ciclo, las medidas, el deshabilitado y el regreso a 16:9.

## Impact

- `macos/Primer.swift`: un tipo para la proporción del panel único, `windowAspect` y `windowFrame` (reciben la proporción), `App.setPanes`, una acción y su validación en el menú «Paneles» y la autoprueba.
- `README.md` (tabla de atajos y «Qué hace») y `AGENTS.md` (descripción de proporciones).
- Sin cambios en el audio por foco, la sesión ni el diagnóstico. Sin dependencias nuevas.
- Riesgo: cambiar el alto de la ventana hace que el reproductor se ajuste. Es una hipótesis de DAZN, no verificada en Prime Video, y la valida el mantenedor.
