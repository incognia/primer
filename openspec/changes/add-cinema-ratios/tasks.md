# Tasks

Marcas: **[AUTO]** la ejecuta y la verifica el agente. **[HITL]** la valida el mantenedor; el agente no la marca como hecha sin su confirmación en la conversación y anota el resultado en el «Registro de validación» de `design.md`.

## 1. Proporción del panel único

- [ ] 1.1 [AUTO] En `macos/Primer.swift`, agregar el tipo de proporción del panel único (16:9, 2.35:1 y 2.39:1, con su siguiente en la secuencia) y pasarlo a `windowAspect(forPanes:layout:ratio:)`, que lo usa solo con un panel; verificar que `macos/build.sh` compila sin advertencias y que la autoprueba existente sigue pasando.
- [ ] 1.2 [AUTO] Extender `windowFrame` con la proporción de origen y de destino: con un panel conserva el ancho, calcula el alto como W / razón, conserva la esquina superior izquierda y se reduce con la misma proporción si no cabe; al pasar a dos o tres paneles desde una proporción de cine, parte de un panel 16:9 con el mismo ancho; verificar con comprobaciones nuevas de la autoprueba las medidas de los escenarios de «Proporción de cine con un solo panel» y «Un panel con proporción de cine».

## 2. Acción y menú

- [ ] 2.1 [AUTO] Agregar a `App` la proporción vigente, la acción de proporción (siguiente en la secuencia, solo con un panel), el reinicio a 16:9 en `setPanes` al pasar a más de un panel y al volver a uno, y el elemento «Proporción» (⌥⌘P) del menú «Paneles», con la validación del menú que lo deshabilita con más de un panel; verificar con la autoprueba de atajos que ⌥⌘P existe, que sus 12 acciones propias tienen destino y que el elemento está habilitado con un panel y deshabilitado con dos.

## 3. Autoprueba

- [ ] 3.1 [AUTO] Agregar a la autoprueba el ciclo (16:9 → 2.35:1 → 2.39:1 → 16:9) con el mismo ancho y esquina fija, que el panel llena la ventana en cada paso, que con más de un panel la acción no cambia nada, y el regreso a 16:9 al abrir un segundo panel desde 2.39:1 y al volver a uno; verificar corriendo `macos/Primer.app/Contents/MacOS/Primer --selftest` y que termina con código 0.
- [ ] 3.2 [AUTO] Verificar con comprobaciones nuevas que rellenar y centrar y el arrastre de bordes usan la proporción vigente (2.35:1 y 2.39:1) y que el audio por foco, el clic de foco y el registro de diagnóstico no cambian con un panel de proporción de cine; verificar con la corrida completa, también con `--debug`.

## 4. Documentación

- [ ] 4.1 [AUTO] Actualizar `README.md` (qué hace y tabla de atajos con ⌥⌘P) y `AGENTS.md` (descripción de las proporciones); verificar con `grep` que ambos mencionan 2.35 y 2.39 y que la tabla de atajos incluye ⌥⌘P.
- [ ] 4.2 [AUTO] Validar con `openspec validate --all --strict` y verificar que termina sin errores.

## 5. Validación humana

- [ ] 5.1 [HITL] Con la aplicación compilada y abierta, con una película 2.39:1 (como «Rápidos y Furiosos») en un solo panel, pulsar ⌥⌘P varias veces; reportar cómo se ve cada proporción (si desaparecen las barras negras, si la película sigue sin interrupción al cambiar el alto de la ventana y si el reproductor llena la ventana); verificar que queda anotado en el registro de `design.md`.
- [ ] 5.2 [HITL] Abrir un segundo panel (⌘2) con la ventana en 2.39:1, comprobar que ⌥⌘P no hace nada y el elemento del menú aparece deshabilitado, y volver a un panel (⌘1); reportar si la ventana vuelve a 16:9 y qué hace el primer panel al abrir el segundo; verificar que queda anotado.
- [ ] 5.3 [HITL] En el monitor 32:9 y en el secundario, ejecutar ⌘F en 2.35:1 y en 2.39:1; reportar el resultado; verificar que queda anotado.
