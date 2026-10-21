## Context

DAZNer ya resolvió el mismo problema para DAZN: una ventana sin bordes, uno o dos paneles y una pantalla completa que llena la ventana. En Prime Video esto último no hace falta: según el mantenedor, el reproductor llena la ventana por sí mismo al reproducir, así que el centro del trabajo es el audio de los dos paneles. Primer quiere lo mismo para los canales deportivos de Prime Video: hoy NBA League Pass y, más adelante, MLB.TV, que se contratan como canales dentro de Prime Video. Por eso el proyecto se construye sobre Prime Video y no se ata a un deporte. Hay dos diferencias de fondo:

- **Prime Video no trae vista múltiple.** En DAZN, la página resolvía varios partidos en una cuadrícula. Aquí, los paneles de Primer son la forma de ver dos partidos a la vez. Un panel mide 16:9 y dos paneles forman una ventana 32:9.
- **El reproductor y su DRM son otros.** Lo que se descubrió de DAZN (cómo se comporta su reproductor, qué reescribe, qué márgenes calcula) es una hipótesis hasta observarlo en Prime Video.

Este cambio se ejecuta con una persona en el ciclo: lo que solo una persona puede juzgar lo valida el mantenedor, y lo que el agente puede comprobar por sí mismo se comprueba con una autoprueba.

## Goals / Non-Goals

**Goals:**

- Dos partidos de Prime Video a la vez en una ventana 32:9, con el audio del panel sin foco silenciado, expresado como las especificaciones de este cambio.
- Que el agente pueda verificar por su cuenta todo lo que no dependa de Prime Video (`--selftest`), y que el humano valide lo demás con pasos exactos.
- Empezar por la prueba de reproducción y detenerse si falla.

**Non-Goals:**

- Windows y Linux, instalador, firma de código, tiendas.
- Más de dos paneles.
- Emular o sobrescribir la pantalla completa: el reproductor de Prime Video llena la ventana por sí mismo.
- Eludir el DRM, los controles de acceso o el límite de transmisiones simultáneas de la cuenta.
- Cualquier otro servicio distinto de Prime Video.

## Decisions

- **Repositorio aparte.** Primer vive en su propio repositorio, no en una rama de DAZNer: las marcas, las especificaciones y el reto abierto de DAZNer son de DAZN, y una rama larga divergiría de `main`. Si más adelante comparten mucho código, se extrae un núcleo común con datos en la mano.
- **Lenguaje y motor:** Swift sobre `WKWebView`, compilado con `swiftc`, como DAZNer. Es la única plataforma que se puede compilar y probar en la máquina del autor, y el motor web nativo de macOS usa el DRM del sistema.
- **Pantalla completa:** no se sobrescribe. El mantenedor observó que, al reproducir, el reproductor de Prime Video llena la ventana por sí mismo; Primer no intercepta `requestFullscreen` ni carga ningún script en la página para ello. Falta confirmarlo con dos paneles y saber qué hace el botón de pantalla completa del reproductor (tarea 1.4). Esta decisión sustituye a la de reutilizar el script de DAZNer, que se había copiado a `shared/fill-fullscreen.js` y se retira (tarea 2.1).
- **Audio por foco:** el panel sin foco se mantiene silenciado, también cuando su reproductor intenta reactivar el audio. El mecanismo es una pregunta abierta; el punto de partida es el de DAZNer (JavaScript sobre los elementos `video` y un temporizador), que hay que validar con Prime Video.
- **Proporción y hueco:** 16:9 con un panel, 32:9 con dos, y un hueco de 8 px dentro del ancho de la ventana. El hueco se hereda de DAZN, donde nacía de la cuadrícula de su *multiview*; aquí no hay cuadrícula, y se valida visualmente.
- **Autoprueba:** `--selftest` abre páginas locales (`shared/fixtures/`) con elementos de medios, mide el estado de silencio de cada panel y las medidas de los paneles, y revisa la proporción de la ventana. No usa red ni cuenta. Sirve para que el agente verifique el audio por foco y los paneles sin una persona, y no sustituye la validación humana.
- **Sesión:** almacén de datos persistente del motor web, compartido entre paneles e instancias.
- **User agent:** la identificación real de `WKWebView` (el WebKit del sistema) con el sufijo de Safari, `Version/27.0 Safari/605.1.15`, añadido con `applicationNameForUserAgent`; la versión es la de Safari de la Mac del mantenedor. Con la identificación predeterminada Prime Video respondió «Video no disponible» y Safari sí reproducía (tarea 1.2, 2026-10-20); con el sufijo reproduce. El motor no cambia: sigue siendo WebKit, y no se oculta ni se evita ninguna protección.
- **Dirección de inicio:** una sola constante en el código, para cambiarla sin tocar el resto (ver preguntas abiertas).
- **Humano en el ciclo:** cada tarea lleva la marca [AUTO] (la ejecuta y verifica el agente) o [HITL] (la valida el mantenedor). El agente prepara los pasos y el resultado esperado; el humano responde; el agente lo anota en el registro de abajo y solo entonces marca la tarea.

## Risks / Trade-offs

- **Prime Video puede no reproducir dentro de `WKWebView`.** Puede rechazar la sesión o el DRM en un motor embebido. Se mitiga con la prueba de reproducción como primera tarea y con la decisión explícita de detener el trabajo si falla.
- **Límite de transmisiones simultáneas.** Dos paneles o dos instancias son dos transmisiones, y la cuenta puede no permitirlas. No se elude: se mide en la tarea 1.3 y, si no se puede, el modo de dos paneles queda como mostrar lo que Prime Video responda.
- **Prime Video puede reactivar el audio del panel silenciado.** Si el reproductor restaura su propio audio, silenciar desde fuera puede no bastar o dejar escapar sonido unos instantes. Se mitiga con una revisión periódica y se mide en la tarea 4.4.
- **El reproductor puede no llenar la ventana en todos los casos.** Lo observó el mantenedor con un panel; con dos paneles de 16:9 o con ventanas pequeñas puede comportarse distinto. Se confirma en las tareas 1.4 y 4.4.
- **La autoprueba puede dar falsa confianza.** Una página de prueba no es Prime Video. Por eso declara en su salida que no probó Prime Video y por eso la validación final es humana.
- **Inicio de sesión con pasos extra.** Los códigos de verificación o las llaves de acceso pueden abrir ventanas o flujos que un motor embebido no maneja. Se observa en la tarea 1.2.
- **Contenido con restricciones por región.** Las restricciones de transmisión de cada liga dependen de la región y la cuenta. Están fuera del alcance de Primer, que solo muestra lo que el sitio ofrezca.

## Open Questions

- ¿Cuál es la dirección de inicio correcta para la cuenta del mantenedor? Depende de la región y del canal. Se resuelve en la tarea 1.2.
- ¿Qué hace el botón de pantalla completa del reproductor de Prime Video dentro de Primer? ¿Saca la ventana a la pantalla completa del sistema? ¿Conviene desactivarla con `isElementFullscreenEnabled = false`? Lo responde la tarea 1.4.
- ¿Cuántas transmisiones simultáneas permite la cuenta del mantenedor? Lo responde la tarea 1.3.
- ¿El hueco de 8 px entre paneles se ve bien en Prime Video, o conviene otro valor? Lo responde la tarea 4.2.
- ¿Cómo se mantiene silenciado el panel sin foco? En DAZNer se hizo con JavaScript sobre los elementos `video` y un temporizador. ¿Basta con Prime Video, que puede reactivar su audio? ¿Con qué cadencia se revisa? Se decide en la tarea 4.3 y se mide en la 4.4.
- ¿Cómo se mantiene al día la versión de Safari del sufijo del *user agent*? Hoy está fija en el código y se desactualizará; se decide si se lee en ejecución o se revisa a mano.
- ¿Hace falta un ícono desde el principio? Hoy no hay ícono; se diseña uno propio antes de publicar.

## Registro de validación

Aquí el agente anota lo que validó el mantenedor: fecha, tarea, qué se probó y qué respondió, con sus palabras cuando algo falla. Una fila nueva por validación.

| Fecha | Tarea | Qué se probó | Resultado del mantenedor |
|---|---|---|---|
| 2026-10-20 | 1.2 | Primer 1.1 con el *user agent* predeterminado de `WKWebView`; reproducir un video de Prime Video | **Resultado parcial, sin aprobar.** El mantenedor envió una captura: «Video no disponible. Tenemos problemas para reproducir este video. Para obtener ayuda, dirígete a www.primevideo.com/help.» con un botón «Aceptar». Falta aclarar qué video era, si había sesión iniciada, si había otra instancia abierta y si el mismo video reproduce en Safari con la misma cuenta. |
| 2026-10-20 | 1.2 (control) | El mismo tipo de video, en Safari de la misma Mac y con la misma cuenta | **Reproduce en Safari.** Antes del video, Prime Video muestra «Información de contenido en directo» con botones «Cerrar reproductor» y «Continuar» (casilla «No volver a mostrar este mensaje»). Con el video en marcha, la pestaña muestra el ícono de audio activo y la captura sale en negro, como es normal con DRM. Conclusión: la cuenta, la región y el contenido no son la causa; el fallo está en el motor embebido de Primer (hipótesis a probar: el *user agent*). |
| 2026-10-20 | 1.2 (resultado) | Primer con el sufijo de Safari en el *user agent*, mismo partido que en Safari | **Reproduce.** El mantenedor confirmó «ya reproduce» y envió una foto del celular con un partido de la NBA en curso dentro de la ventana de Primer. La calidad máxima, la confirmación explícita del audio y la dirección (URL) del partido o del canal **no se reportaron**. Observación: la ventana muestra botones y barra de título, y no mantiene proporción; es lo previsto para la tarea 1.1 y se resuelve en el grupo 3. |
| 2026-10-20 | Plan (precisión) | Decisión del mantenedor sobre la pantalla completa y el audio | **Dicho por el mantenedor, sin verificar por el agente:** «cuando reproduces automáticamente llena la ventana», así que no hay que sobrescribir la pantalla completa; el trabajo se centra en el audio, con dos partidos de Prime Video en 32:9 y el otro panel silenciado. Se confirma en las tareas 1.4 y 4.4. Consecuencias en el plan: se elimina la capacidad `fullscreen-emulation`, se retiran las antiguas tareas 2.1 y 2.2, ya hechas (`shared/fill-fullscreen.js` y las tres páginas de `shared/fixtures/`, *commit* `7ec1e4e`) y el antiguo grupo 5 de tareas, y las demás se renumeran (el plan pasa de 24 a 20 tareas). |
| 2026-10-20 | 1.2 (aclaración) | Qué había activo cuando falló Primer por primera vez | **Aclarado por el mantenedor:** ya estaba viendo el partido cuando Primer falló, y describe el fallo como algo que no terminaba de cargar en Primer, mientras que «directamente en Safari» no tuvo problema. Lectura del agente: había otra transmisión activa y Safari reprodujo en esas mismas condiciones, así que el límite de transmisiones simultáneas no explica el fallo y la causa más probable es la identificación del motor de Primer, que se corrigió con el sufijo de Safari. Se debilitaría solo si el partido que ya veía era el propio Safari y Primer fue la segunda transmisión; no se preguntó. |
