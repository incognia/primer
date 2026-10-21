# Tasks

Marcas: **[AUTO]** la ejecuta y la verifica el agente. **[HITL]** la valida el mantenedor; el agente no la marca como hecha sin su confirmación en la conversación y anota el resultado en el «Registro de validación» de `design.md`.

## 1. Proporción del panel único

- [x] 1.1 [AUTO] En `macos/Primer.swift`, agregar el tipo de proporción del panel único (16:9, 2.35:1 y 2.39:1, con su siguiente en la secuencia) y pasarlo a `windowAspect(forPanes:layout:ratio:)`, que lo usa solo con un panel; verificar que `macos/build.sh` compila sin advertencias y que la autoprueba existente sigue pasando.
- [x] 1.2 [AUTO] Extender `windowFrame` con la proporción de origen y de destino: con un panel conserva el ancho, calcula el alto como W / razón, conserva la esquina superior izquierda y se reduce con la misma proporción si no cabe; al pasar a dos o tres paneles desde una proporción de cine, parte de un panel 16:9 con el mismo ancho; verificar con comprobaciones nuevas de la autoprueba las medidas de los escenarios de «Proporción de cine con un solo panel» y «Un panel con proporción de cine».

- [x] 1.3 [AUTO] Agregar 2.40:1 a `PanelRatio` y a la secuencia (16:9 → 2.35:1 → 2.39:1 → 2.40:1 → 16:9), tras la primera prueba del mantenedor; verificar con comprobaciones de la autoprueba la secuencia y las medidas de 2.40:1 (alto W / 2.40).

- [x] 1.4 [AUTO] Agregar 1.85:1 a `PanelRatio` y a la secuencia, justo después de 16:9 (16:9 → 1.85:1 → 2.35:1 → 2.39:1 → 2.40:1 → 16:9), a petición del mantenedor; verificar con comprobaciones de la autoprueba la secuencia y las medidas de 1.85:1 (alto W / 1.85).

## 2. Acción y menú

- [x] 2.1 [AUTO] Agregar a `App` la proporción vigente, la acción de proporción (siguiente en la secuencia, solo con un panel), el reinicio a 16:9 en `setPanes` al pasar a más de un panel y al volver a uno, y el elemento «Proporción» (⌥⌘P) del menú «Paneles», con la validación del menú que lo deshabilita con más de un panel; verificar con la autoprueba de atajos que ⌥⌘P existe, que sus 12 acciones propias tienen destino y que el elemento está habilitado con un panel y deshabilitado con dos.

## 3. Autoprueba

- [x] 3.1 [AUTO] Agregar a la autoprueba el ciclo (16:9 → 2.35:1 → 2.39:1 → 16:9) con el mismo ancho y esquina fija, que el panel llena la ventana en cada paso, que con más de un panel la acción no cambia nada, y el regreso a 16:9 al abrir un segundo panel desde 2.39:1 y al volver a uno; verificar corriendo `macos/Primer.app/Contents/MacOS/Primer --selftest` y que termina con código 0.
- [x] 3.2 [AUTO] Verificar con comprobaciones nuevas que rellenar y centrar y el arrastre de bordes usan la proporción vigente (2.35:1 y 2.39:1) y que el audio por foco, el clic de foco y el registro de diagnóstico no cambian con un panel de proporción de cine; verificar con la corrida completa, también con `--debug`.

- [x] 3.3 [AUTO] Actualizar el ciclo de la autoprueba a cuatro pasos (2.35:1, 2.39:1, 2.40:1 y 16:9); verificar corriendo `macos/Primer.app/Contents/MacOS/Primer --selftest` y que termina con código 0.

- [x] 3.4 [AUTO] Actualizar el ciclo de la autoprueba a cinco pasos (1.85:1, 2.35:1, 2.39:1, 2.40:1 y 16:9); verificar corriendo `macos/Primer.app/Contents/MacOS/Primer --selftest` y que termina con código 0.

## 4. Documentación

- [x] 4.1 [AUTO] Actualizar `README.md` (qué hace y tabla de atajos con ⌥⌘P) y `AGENTS.md` (descripción de las proporciones); verificar con `grep` que ambos mencionan 2.35 y 2.39 y que la tabla de atajos incluye ⌥⌘P.
- [x] 4.2 [AUTO] Validar con `openspec validate --all --strict` y verificar que termina sin errores.
- [x] 4.3 [AUTO] Actualizar `README.md` y `AGENTS.md` con 2.40:1 en la secuencia; verificar con `grep` que ambos mencionan 2.40.
- [x] 4.4 [AUTO] Actualizar `README.md` y `AGENTS.md` con 1.85:1 en la secuencia; verificar con `grep` que ambos mencionan 1.85.

## 5. Validación humana

- [x] 5.1 [HITL] Con la aplicación compilada y abierta, con una película 2.39:1 (como «Rápidos y Furiosos») en un solo panel, pulsar ⌥⌘P varias veces; reportar cómo se ve cada proporción (si desaparecen las barras negras, si la película sigue sin interrupción al cambiar el alto de la ventana y si el reproductor llena la ventana); verificar que queda anotado en el registro de `design.md`.
- [x] 5.2 [HITL] Abrir un segundo panel (⌘2) con la ventana en 2.39:1, comprobar que ⌥⌘P no hace nada y el elemento del menú aparece deshabilitado, y volver a un panel (⌘1); reportar si la ventana vuelve a 16:9 y qué hace el primer panel al abrir el segundo; verificar que queda anotado.
- [x] 5.3 [HITL] En el monitor 32:9 y en el secundario, ejecutar ⌘F en cada proporción de cine (1.85:1, 2.35:1, 2.39:1 y 2.40:1); reportar el resultado; verificar que queda anotado.
