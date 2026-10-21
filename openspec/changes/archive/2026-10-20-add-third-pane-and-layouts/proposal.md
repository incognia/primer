## Why

Dos paneles dejan fuera la noche en que el calendario trae tres partidos que importan al mismo tiempo, y el único arreglo hoy es abrir otra instancia de la aplicación, con su propia ventana que acomodar. Además, una ventana 32:9 solo se aprovecha en una pantalla ultra ancha: en una pantalla normal o en una vertical, dos partidos uno junto al otro quedan pequeños, y apilarlos tendría más sentido.

## What Changes

- Un **tercer panel**, a demanda, con ⌘3, igual que el segundo: se crea solo cuando se pide y se libera por completo al volver a menos paneles.
- Dos **disposiciones** de los paneles, con ⌥⌘H (horizontal, uno junto al otro) y ⌥⌘V (vertical, uno sobre otro). La horizontal es la de hoy y la que se usa al abrir.
- La proporción fija de la ventana depende del número de paneles y de la disposición: horizontal 16n:9 (16:9, 32:9, 48:9) y vertical 16:9n (16:9, 16:18, 16:27).
- Al cambiar de disposición o de número de paneles, el primer panel conserva su tamaño siempre que la pantalla lo permita, para que su reproductor no se refresque.
- El audio por foco se generaliza a N paneles: suena solo el panel con foco, y el clic que da el foco no llega a la página en todos los demás.
- La autoprueba cubre tres paneles, las dos disposiciones y los atajos nuevos.
- **Atajos:** ⌘V (pegar) y ⌘H (inicio de Prime Video) se conservan tal como están; las disposiciones usan ⌥⌘H y ⌥⌘V (decisión del mantenedor, 2026-10-20).

Fuera del alcance:

- Más de tres paneles.
- Disposiciones mixtas (por ejemplo, uno grande y dos pequeños, o una cuadrícula 2×2).
- Recordar la disposición entre aperturas de la aplicación: siempre abre con un panel y disposición horizontal.
- Arrastrar para reordenar o redimensionar paneles; todos miden lo mismo.
- Eludir el límite de transmisiones simultáneas de la cuenta: si Prime Video rechaza el tercer partido, la aplicación muestra lo que responda y no lo evita.
- MLB.TV, otras plataformas e íconos.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `panes`: de «uno o dos» a uno, dos o tres paneles; la disposición horizontal o vertical; medidas y proporción por número de paneles y disposición; el panel nuevo a demanda y la liberación; audio por foco y clic de foco con N paneles; el cambio de panel recorre todos.
- `window-chrome`: la proporción fija de la ventana según número de paneles y disposición.
- `shortcuts`: ⌘3 y ⌥⌘H / ⌥⌘V; se conservan ⌘V y ⌘H.
- `selftest`: comprobaciones de tres paneles, de las dos disposiciones y de los atajos nuevos.

## Impact

- `macos/Primer.swift`: `PaneGrid` (disposición, `layoutPanes`, un tercer panel), `windowAspect` y `windowFrame` (reciben la disposición), `App.setPanes` y una acción nueva para la disposición, el menú «Paneles» y la autoprueba.
- `README.md` (tabla de atajos, «Qué hace») y `AGENTS.md` («Dos paneles alcanzan» deja de ser el hecho vigente; el cambio de audio exige repetir su validación).
- Sin dependencias nuevas, sin cambios en la sesión, el diagnóstico ni la reproducción.
- Riesgo con la cuenta: tres reproducciones a la vez pueden superar el límite de transmisiones simultáneas de la cuenta; es la pregunta abierta que el cambio debe medir, no sortear.
