# Guía para agentes

*Última modificación: 20 de octubre de 2026, 22:02 (CST)*

Este archivo es para un agente de IA que trabaja en este repositorio. El autor mantiene un repositorio de reglas personales (`rules`) con las *skills* de trabajo (`/commit`, `/changelogger`, `/git-init`, `/licensing`) y sus procedimientos. Está presente en `~/rules`, así que **si existe, manda sobre el resumen de este archivo**; este archivo recoge lo esencial por si no está.

## Qué es Primer

Visor mínimo de los canales deportivos de Prime Video (hoy NBA League Pass; MLB.TV más adelante): abre el sitio oficial en una ventana sin bordes, con uno o dos paneles, para ver dos partidos a la vez en una ventana 32:9 con el audio del panel sin foco silenciado. La pantalla completa no se sobrescribe: al reproducir, el reproductor de Prime Video llena la ventana por sí mismo. Licencia GPLv3; aviso de marcas en `NOTICE.md`.

La página de Prime Video **no trae *multiview* nativo**: los paneles de Primer son la forma de ver varios partidos a la vez. Un panel mide 16:9 y dos paneles forman una ventana 32:9.

Primer nació de DAZNer, otro proyecto del mismo autor. De allí se hereda la forma de trabajar y la estructura de las especificaciones. **Lo que se descubrió de DAZN es una hipótesis aquí, no un hecho**: nada se da por cierto en Prime Video hasta comprobarlo.

## Estructura

```text
macos/     Swift sobre WKWebView; Primer.swift, build.sh y el paquete Primer.app
shared/    (por llenar) páginas locales de prueba de la autoprueba
openspec/  especificaciones y cambios (el plan de trabajo, ver abajo)
```

## Cómo se trabaja: OpenSpec

El plan está en `openspec/`. Las especificaciones de `openspec/specs/` son el contrato del proyecto y describen el comportamiento de la versión de macOS. El cambio que las construyó, `add-macos-viewer`, está archivado en `openspec/changes/archive/2026-10-20-add-macos-viewer/`: su propuesta, su diseño con las decisiones y el registro de lo que se validó, y sus tareas. Hoy no hay cambios activos; uno nuevo se propone con `/opsx:propose`.

Para trabajar un cambio:

1. Tener OpenSpec (Node 20.19 o superior): `npm install -g @fission-ai/openspec@latest`, o usar `npx @fission-ai/openspec@latest <comando>`.
2. Con Claude Code, usar `/opsx:apply <cambio>`. Sin esos comandos, leer `openspec/changes/<cambio>/` (propuesta, especificaciones, diseño y tareas) y seguir las tareas en orden.
3. Ver el estado con `openspec list` y `openspec status --change <cambio>`, y validar con `openspec validate --all --strict`.
4. Marcar una tarea (`- [x]`) solo después de ejecutar su verificación.

## Humano en el ciclo

Este proyecto se trabaja con una persona que valida lo que solo una persona puede juzgar. Cada tarea de `tasks.md` lleva una marca:

- **[AUTO]:** el agente la ejecuta y la verifica (compilar, correr la autoprueba, validar OpenSpec).
- **[HITL]:** la verifica el mantenedor (si Prime Video reproduce, cómo se ve, si el panel sin foco queda sin sonido, qué responde la cuenta).

Reglas para las tareas [HITL]:

1. **El agente prepara, el humano juzga.** Antes de pedir la validación, el agente deja listo lo que haga falta (compilar, abrir la aplicación) y entrega los pasos exactos, qué resultado se espera y qué debe reportar el mantenedor.
2. **El agente no marca una tarea [HITL] como hecha** hasta que el mantenedor confirme el resultado en la conversación.
3. **Lo que se valida queda por escrito.** El agente anota en el apartado «Registro de validación» de `design.md` la fecha, qué se probó y qué dijo el mantenedor, con sus palabras para los fallos.
4. **Si una validación falla**, no se sigue con las tareas que dependen de ella: se documenta y se pregunta cómo seguir.

## Reglas que no se negocian

- **La prueba de reproducción va primero.** El primer grupo de tareas comprueba que Prime Video reproduce un partido del canal deportivo contratado (hoy NBA League Pass) dentro del motor web de la plataforma. **Si falla, detenerse**, documentar el resultado y no construir el resto.
- **No eludir protecciones.** Prohibido eludir DRM, controles de acceso o límites de reproducción —incluido el límite de transmisiones simultáneas de la cuenta— y redistribuir módulos de DRM. Si Prime Video rechaza una reproducción, la aplicación muestra lo que responda y no intenta evitarlo.
- **No afirmar lo que no se ejecutó.** No se marca una tarea como hecha ni se dice que algo funciona si no se pudo compilar y probar. Si algo solo puede verificarse en otra máquina o por el humano, se deja pendiente y se dice quién lo prueba y dónde.
- **Credenciales:** Primer nunca lee, guarda ni registra contraseñas. No escribas credenciales en archivos, registros ni *commits*. Las pruebas de la autoprueba no usan ninguna cuenta.
- **Marcas:** no uses logotipos de Amazon, Prime Video, la NBA ni la MLB. El ícono del proyecto será propio.
- **Cualquier cambio al silenciado del audio** exige repetir su verificación: la autoprueba y la validación del humano con dos partidos.

## Qué se sabe y qué no

Hechos que vienen del autor:

- NBA League Pass se contrata como canal dentro de Prime Video, y el autor planea contratar también MLB.TV por la misma vía. Por eso Primer se construye sobre Prime Video y no se ata a un solo deporte.
- Dos paneles alcanzan: es una decisión del autor, basada en su lectura del calendario de la NBA, que este repositorio no ha verificado.
- El resultado esperado: aplicación sin bordes con dos paneles en 32:9, el panel sin foco silenciado, y sin sobrescribir la pantalla completa.
- Al reproducir, el reproductor de Prime Video llena la ventana por sí mismo, y con dos paneles llena cada panel (confirmado por el autor).
- La pantalla completa del reproductor funciona con dos paneles (confirmado por el autor), así que no se desactiva con `isElementFullscreenEnabled`.

Hipótesis heredadas de DAZN, **sin verificar en Prime Video**:

- Que cambiar el tamaño de la ventana refresca el reproductor, por lo que conviene abrir el segundo panel cambiando primero la ventana.
- Que una captura de pantalla de un video con DRM sale en negro: no sirve para diagnosticar.

Preguntas abiertas: están en la sección «Open Questions» del diseño archivado (`openspec/changes/archive/2026-10-20-add-macos-viewer/design.md`). Siguen abiertas aunque el cambio esté archivado: quien abra un cambio nuevo debe traer a su diseño las que le afecten.

## Depuración

- `--debug` escribe `debug.log` junto a la aplicación y habilita el inspector web. Está apagado por omisión y no debe versionarse.
- En modo de diagnóstico se registran los eventos de audio y de cada panel, nunca contraseñas ni el contenido de los campos.

## Repositorio de reglas del autor (`rules`)

Ubicación: `~/rules`. Qué usar de ahí, si existe:

- **Flujo de trabajo:** `/changelogger` y `/commit` (procedimientos en `cot/changelog.md` y `cot/committing.md`), y `/git-init` y `/licensing` para configurar un repositorio nuevo.
- **Estilo del español:** `rulesets/LINGUISTICS.md`.
- **Si no existe `rules`:** seguir el resumen de la sección siguiente y avisar al usuario de que falta.

## Idioma, *commits* y CHANGELOG

Resumen de lo esencial; si `rules` está disponible, sus procedimientos prevalecen.

- **Documentación y especificaciones:** español de México, sin anglicismos innecesarios, con comillas angulares «». Las palabras clave de OpenSpec (`SHALL`, `MUST`, `WHEN`, `THEN`) se dejan en inglés. El código y sus comentarios pueden seguir el estilo del archivo que se edita.
- **Mensajes de *commit*:** inglés internacional (UK), formato Conventional Commits (`feat`, `fix`, `docs`, `refactor`, `chore`), con un cuerpo de viñetas que describa cambios concretos. *Commits* atómicos: un cambio lógico cada uno, con `git add -- <archivos>` y sin `git add .` cuando se mezclan tipos.
- **No mencionar el CHANGELOG** en el cuerpo de un *commit*.
- **CHANGELOG.md:** un bloque por fecha, `## [AAAA-MM-DD] - Título descriptivo`, con la fecha en hora del centro de México (UTC-6). Viñetas `tipo: descripción en español`, sin subencabezados, con la más reciente arriba, sin líneas en blanco entre viñetas y solo añadiendo (no se editan viñetas existentes). El `CHANGELOG.md` va en el último *commit* de cada serie.
- **Identidad de Git:** la del autor ya está configurada en su máquina. No cambies `user.name`, `user.email` ni el remoto. Si falta, pide la identidad al usuario.
- **Publicar:** el remoto es `origin` (`git@github.com:incognia/primer.git`, por SSH). El autor trabaja solo y directo en `main`. No hagas `git push` sin que el usuario lo haya pedido.
- **Sin *pull requests*, *hooks* ni CI:** no hay ramas de trabajo, PR, protección de ramas, *hooks* de git ni flujos de GitHub Actions, y no se agregan sin que el autor lo pida. La verificación es `openspec validate --all --strict` más las tareas [AUTO] y [HITL].
