## Context

Hoy `PaneGrid` administra uno o dos paneles pegados en horizontal, `windowAspect` da 16:9 o 32:9, y `windowFrame` calcula el marco de la ventana para que, al abrir el segundo panel, el primero conserve su tamaño (`macos/Primer.swift`). El audio por foco, el clic que solo da el foco y el siguiente panel ya trabajan sobre la lista de paneles y su índice de foco, de modo que casi no dependen de que sean dos. Ver `proposal.md` para el motivo.

Lo que no se ha observado: cómo reacciona el reproductor de Prime Video a que un panel cambie de lugar (no de tamaño) dentro de la ventana, y si la cuenta admite tres reproducciones a la vez. Ambas cosas son hipótesis hasta medirlas.

## Goals / Non-Goals

**Goals:**

- Que el número de paneles (1 a 3) y la disposición (horizontal o vertical) sean dos ejes independientes del mismo modelo, sin casos especiales por cada combinación.
- Que cambiar de disposición o de número de paneles no cambie el tamaño de los paneles que ya están abiertos, mientras la pantalla lo permita.
- Que el audio por foco siga siendo una sola regla: suena el panel con foco.

**Non-Goals:**

- Cuadrículas (2×2), tamaños desiguales o paneles que se arrastran; los límites de alcance están en `proposal.md`.
- Persistir la disposición entre ejecuciones.

## Decisions

- **Dos ejes, un solo modelo.** `PaneGrid` guarda una disposición (`horizontal` o `vertical`) junto a la lista de paneles. `layoutPanes()` reparte la ventana en n franjas iguales a lo largo del eje de la disposición; en vertical el primer panel va arriba (en AppKit el origen está abajo, así que el índice 0 se coloca en la franja superior). Alternativa descartada: una vista distinta por disposición, que duplicaría el reparto, el foco y el audio.
- **La proporción sale de las dos cifras.** `windowAspect(forPanes: n, layout:)` da 16n:9 en horizontal y 16:9n en vertical. Cada panel sigue midiendo 16:9 en cualquier combinación.
- **El tamaño del panel manda, no el de la ventana.** `windowFrame(forPanes:layout:from:maxSize:)` deduce el tamaño de un panel del marco actual (ventana ÷ paneles a lo largo del eje de la disposición actual) y construye el marco nuevo con ese mismo panel repetido n veces a lo largo del eje de la nueva disposición. Así, pasar de horizontal a vertical con los mismos paneles deja cada panel exactamente del mismo tamaño y solo cambia su posición; abrir un panel lo suma sin tocar los demás. Conserva la esquina superior izquierda, como hoy. Alternativa descartada: conservar el ancho de la ventana, que reescala todos los paneles y obliga al reproductor a ajustarse.
- **Si no cabe, se reduce toda la ventana.** Si el marco nuevo excede el área útil de la pantalla en ancho o en alto, se escala por el mismo factor (se conserva la proporción) hasta caber, y se desplaza lo mínimo para quedar dentro del área útil. Ahí sí cambia el tamaño de los paneles, y se acepta (escenario «La pantalla no da para el tamaño»). Tres paneles horizontales (48:9) en una pantalla de 32:9 ya caen en este caso.
- **Paneles a demanda, en bloque.** `setPanes(n)` acepta 1, 2 o 3: añade o quita paneles hasta llegar a n, primero cambia los paneles y después fija una sola vez la proporción y el marco de la ventana, para no pasar por tamaños intermedios. Se quitan siempre los últimos, y se liberan igual que hoy.
- **Disposición con un solo panel.** `setLayout(_:)` cambia la disposición siempre; solo cambia la ventana si hay más de un panel. Con uno, queda guardada para el siguiente panel que se abra (escenario «Elegir la disposición con un solo panel»). No se persiste: al abrir la aplicación la disposición es horizontal.
- **Audio y foco, sin cambios de mecanismo.** El guardián de JavaScript, `wantsMuted` y el clic que solo da el foco ya se calculan con «hay más de un panel» y «este no es el que tiene el foco»; con tres paneles funcionan igual. Esto no cambia el silenciado, pero la regla de `AGENTS.md` exige repetir su verificación (autoprueba y validación humana) porque ahora hay un caso nuevo, tres paneles.
- **Atajos.** Siguen las decisiones del mantenedor (2026-10-20): ⌘3 para tres paneles; ⌥⌘H y ⌥⌘V para la disposición, porque ⌘V es «Pegar» y ⌘H abre el inicio. El menú necesita poder declarar el modificador además de ⌘ (hoy el ayudante `add` solo usa ⌘). ⌥⌘H es en macOS el atajo de «Ocultar los demás»; Primer no tiene ese elemento en su menú, así que no hay choque.

## Risks / Trade-offs

- **Tres reproducciones pueden rebasar el límite de la cuenta.** → No se evita: el panel muestra lo que Prime Video responda. Se mide en la validación (tarea 5.2); el contenido de la prueba puede ser tres películas, o un partido, una película y un partido de otro deporte (como futbol), según el cupo, como se hizo con dos paneles.
- **Mover un panel dentro de la ventana puede refrescar o desajustar el reproductor.** Es una hipótesis heredada de DAZN, no verificada en Prime Video. → La validación humana (tarea 5.1) observa si el partido sigue sin interrupción al cambiar de disposición; si falla, se documenta y se decide cómo seguir.
- **Tres paneles horizontales son pequeños en pantallas normales.** En una de 1920 px de ancho, cada panel mide 640 × 360. → Es una elección del usuario; la disposición vertical existe para eso. No se limita.
- **La ventana vertical de tres paneles (16:27) es muy alta.** En una pantalla de 1440 px de alto, cada panel mide unos 853 × 480. → Se reduce hasta caber según la regla de arriba.
- **Cambiar la proporción de la ventana puede chocar con «rellenar y centrar» o con el doble clic en la franja.** → Ambos usan la proporción vigente de la ventana; la autoprueba lo comprueba en las dos disposiciones.

## Migration Plan

Sin migración: la disposición y el número de paneles no se guardan, y la sesión es la misma. Para volver atrás basta revertir los *commits* del cambio; el contrato de `openspec/specs/` no cambia hasta archivarlo.

## Open Questions

- ¿Cuántas transmisiones simultáneas admite la cuenta? Con tres paneles puede dejar de bastar el cupo que alcanzó para dos. Es la pregunta abierta del diseño archivado (`add-macos-viewer`) y este cambio la mide con tres, sin sortear el límite.
- ¿Cuál es la proporción más cómoda para tres partidos en el monitor 32:9 del mantenedor: tres horizontales reducidos o uno grande y dos pequeños? Lo segundo está fuera del alcance; esta pregunta decide si hace falta un cambio posterior.

## Registro de validación

| Fecha | Tarea | Qué se probó | Resultado |
|---|---|---|---|
| 2026-10-20 | Atajos de la disposición | Qué hacer con ⌘V y ⌘H, que ya son «Pegar» y «Inicio de Prime Video» | **Decidido por el mantenedor:** ⌥⌘H (horizontal) y ⌥⌘V (vertical); ⌘V y ⌘H se conservan. |
