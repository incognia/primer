## Context

Hoy la proporción de la ventana sale de dos cifras: el número de paneles y la disposición (`windowAspect(forPanes:layout:)`), y `windowFrame` calcula el marco deduciendo el tamaño de un panel del marco actual, de modo que los paneles que ya estaban abiertos conserven su tamaño (`macos/Primer.swift`). Con un solo panel, el panel llena la ventana y esta es 16:9. Ver `proposal.md` para el motivo.

Dos cosas no se han observado: cómo reacciona el reproductor de Prime Video a que cambie el alto de la ventana con el mismo ancho (hipótesis heredada de DAZN, no verificada), y si el reproductor, al recibir una ventana 2.39:1, muestra la película sin barras. Esto último lo decide Prime Video, no Primer.

## Goals / Non-Goals

**Goals:**

- Que la proporción del panel único sea un tercer eje, independiente del número de paneles y la disposición, pero que solo exista con un panel.
- Que las funciones puras de medidas (`windowAspect`, `windowFrame`) sigan siendo lo que prueba la autoprueba.

**Non-Goals:**

- Los límites de alcance de `proposal.md`; en particular, detectar la proporción de la película o ajustar el contenido.

## Decisions

- **Un tipo para la proporción del panel único.** Un tipo de tres casos (16:9, 2.35:1 y 2.39:1) con su tamaño relativo (16×9, 235×100 y 239×100) y un método para pasar al siguiente. `windowAspect(forPanes:layout:ratio:)` recibe la proporción y solo la usa con `n == 1`; con más paneles la ignora. Alternativa descartada: una lista libre de proporciones, que invitaría a tantas combinaciones como se quiera y rompería la regla de que los paneles múltiples son 16:9.
- **Al cambiar de proporción: mismo ancho, esquina superior izquierda fija.** El alto sale de `W / razón`. Pasar de 16:9 a 2.35:1 reduce el alto, y de 2.39:1 a 16:9 lo aumenta, así que ese último paso puede no caber en la pantalla: se reduce con la misma proporción, igual que hoy con los paneles. Alternativa descartada: conservar el alto, que cambiaría el ancho y movería el borde derecho de la ventana.
- **El estado vive en la aplicación, no en `PaneGrid`.** La proporción es una propiedad de la ventana con un panel. `App` guarda la proporción vigente (16:9 al abrir) y `setPanes` la usa o la reinicia. `PaneGrid` no cambia.
- **Abrir un segundo panel reinicia a 16:9.** `setPanes(n)` con `n > 1` construye el marco como si el panel único estuviera en 16:9: se conserva el ancho del panel y el alto pasa a `W × 9 / 16`; así los paneles siguen midiendo 16:9 y el primero conserva su ancho. Con eso, el alto del primer panel cambia al abrir el segundo desde una proporción de cine, y se acepta: es el precio de volver a 16:9. Al volver a un panel, la proporción es 16:9 (no se recuerda).
- **Deshabilitado con más de un panel, por validación del menú.** `App` implementa la validación de elementos de menú: el de proporción está habilitado solo si `grid.count == 1`. Así el atajo no hace nada y el elemento se ve atenuado, sin código especial en la acción. Un efecto: la autoprueba puede comprobarlo llamando a esa validación sobre el elemento del menú.
- **Rellenar y centrar y el arrastre no cambian.** Usan `window.aspectRatio`, que ya refleja la proporción vigente.
- **Atajo ⌥⌘P** con el mismo ayudante de menú de ⌥⌘H y ⌥⌘V. No choca con ningún atajo de Primer ni, que se sepa, con uno del sistema; se confirma al probarlo.

## Risks / Trade-offs

- **Cambiar el alto de la ventana puede refrescar o desajustar el reproductor.** → Hipótesis de DAZN, sin verificar en Prime Video. La validación humana observa si la película sigue sin interrupción al cambiar de proporción; si falla, se documenta y se decide cómo seguir.
- **El reproductor de Prime puede seguir mostrando barras.** Si la película es 2.39:1 y la ventana también, no debería haberlas; si el reproductor las agrega de todos modos, no es algo que Primer controle. → Se anota lo que se vea.
- **Contenido 16:9 en una ventana 2.39:1.** Un partido o una serie quedarían con barras a los lados o recortados según decida el reproductor. → Es una elección del usuario y 16:9 está a un atajo.
- **Abrir un segundo panel desde 2.39:1 cambia el alto del primero.** → Se acepta y queda en el diseño; la validación lo observa.
- **Dos proporciones casi iguales (2.35 y 2.39)** cambian muy poco el alto (menos de 2 %). → El usuario las pidió; la secuencia no se simplifica.

## Migration Plan

Sin migración: la proporción no se guarda, y la sesión es la misma. Para volver atrás basta revertir los *commits* del cambio.

## Open Questions

- ¿Prime Video muestra una película 2.39:1 sin barras en una ventana 2.39:1, o las agrega de todos modos? Lo responde la validación; no cambia lo que se construye.

## Registro de validación

| Fecha | Tarea | Qué se probó | Resultado |
|---|---|---|---|
