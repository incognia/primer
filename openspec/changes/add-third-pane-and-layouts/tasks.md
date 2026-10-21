# Tasks

Marcas: **[AUTO]** la ejecuta y la verifica el agente. **[HITL]** la valida el mantenedor; el agente no la marca como hecha sin su confirmación en la conversación y anota el resultado en el «Registro de validación» de `design.md`.

## 1. Modelo de disposición y de tres paneles

- [ ] 1.1 [AUTO] En `macos/Primer.swift`, dar a `PaneGrid` una disposición (horizontal o vertical, horizontal al abrir), un máximo de tres paneles y un `layoutPanes()` que reparta la ventana en n franjas iguales sin hueco (en vertical el primer panel arriba); verificar que `macos/build.sh` compila sin advertencias y que la autoprueba existente sigue pasando.
- [ ] 1.2 [AUTO] Cambiar `windowAspect` a `windowAspect(forPanes:layout:)` (16n:9 en horizontal, 16:9n en vertical) y `windowFrame` a `windowFrame(forPanes:layout:from:maxSize:)`, que conserva el tamaño del panel, escala y desplaza para caber en el área útil y mantiene la esquina superior izquierda; verificar con comprobaciones nuevas de la autoprueba las medidas de los escenarios de «Paneles de proporción 16:9 anidados en la ventana» y «La pantalla no da para el tamaño».

## 2. Acciones y atajos

- [ ] 2.1 [AUTO] Generalizar `App.setPanes` para 1, 2 y 3 paneles (cambia primero los paneles y después la ventana, una sola vez), agregar `setLayout` y sus acciones, y las entradas de menú «3 paneles» (⌘3), «Disposición horizontal» (⌥⌘H) y «Disposición vertical» (⌥⌘V), con un ayudante de menú que admita el modificador ⌥; verificar con la autoprueba de atajos que ⌘3, ⌥⌘H y ⌥⌘V existen, que ⌘V sigue siendo «Pegar» y ⌘H «Inicio de Prime Video», y que las acciones tienen destino.
- [ ] 2.2 [AUTO] Verificar que el foco, el siguiente panel (recorre los tres y vuelve al primero) y los clics de foco funcionan con tres paneles y no cambian al cambiar de disposición; verificar con comprobaciones nuevas de la autoprueba.

## 3. Autoprueba

- [ ] 3.1 [AUTO] Agregar a la autoprueba las medidas de tres paneles en horizontal y en vertical, de dos paneles en vertical, la proporción de la ventana en cada caso, que no hay hueco, y el cambio entre disposiciones con los mismos paneles (mismo orden, mismo foco, mismo tamaño); verificar corriendo `macos/Primer.app/Contents/MacOS/Primer --selftest` y que termina con código 0.
- [ ] 3.2 [AUTO] Agregar a la autoprueba el audio por foco con tres paneles (solo suena el que tiene el foco, la página que reactiva el audio de un panel sin foco queda silenciada, y el silencio manual no se revierte al pasar el foco por los tres); verificar con la misma corrida y que no hay sonido al ejecutarla.
- [ ] 3.3 [AUTO] Verificar que `rellenar y centrar` y el modo `--debug` funcionan con tres paneles y en vertical (la proporción vigente y el registro de cada panel) con comprobaciones nuevas de la autoprueba; verificar con la corrida completa.

## 4. Documentación

- [ ] 4.1 [AUTO] Actualizar `README.md` (qué hace, tabla de atajos con ⌘3, ⌥⌘H y ⌥⌘V, y que la disposición no se recuerda) y `AGENTS.md` (descripción de uno a tres paneles, la decisión de dos paneles que ya no es la vigente y las proporciones); verificar con `grep` que no quedan «dos paneles» como límite ni «⌘1 · ⌘2» como únicos atajos de paneles.
- [ ] 4.2 [AUTO] Validar con `openspec validate --all --strict` y verificar que termina sin errores.

## 5. Validación humana

- [ ] 5.1 [HITL] Con la aplicación compilada y abierta, reproducir algo en el primer panel, abrir el segundo y el tercero (⌘2, ⌘3) y alternar entre ⌥⌘V y ⌥⌘H; reportar si el primer panel sigue reproduciendo sin interrupción, si los paneles quedan pegados y sin hueco, y la proporción de la ventana en cada caso; verificar que queda anotado en el registro de `design.md`.
- [ ] 5.2 [HITL] Con tres paneles reproduciendo (tres películas, o un partido, una película y un partido de otro deporte, como futbol, según lo que haya y lo que permita el cupo), reportar qué responde Prime Video con tres reproducciones, si solo suena el panel con foco al pasar por los tres con clic y con ⌘\`, y que el clic que da el foco no pausa; verificar que queda anotado, y que el límite de la cuenta queda registrado sin intentar evitarlo.
- [ ] 5.3 [HITL] En el monitor 32:9 y en el secundario, ejecutar ⌘F con tres paneles en cada disposición, y volver a uno y a dos paneles con ⌘1 y ⌘2; reportar el resultado; verificar que queda anotado y que, al volver, los paneles que sobran se detienen.
