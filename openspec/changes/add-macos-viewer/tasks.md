# Tasks

Marcas: **[AUTO]** la ejecuta y la verifica el agente. **[HITL]** la valida el mantenedor; el agente no la marca como hecha sin su confirmación en la conversación y anota el resultado en el «Registro de validación» de `design.md`.

## 1. Prueba de reproducción (puerta: detenerse si falla)

- [ ] 1.1 [AUTO] Crear `macos/Primer.swift`, una ventana con barra de título normal y un `WKWebView` que abra la dirección de inicio de Prime Video (una constante), con menú de edición y ⌘Q, y `macos/build.sh` que compile con `swiftc` y firme de forma local; verificar que `./build.sh` termina sin errores y que la aplicación sigue viva 3 segundos después de abrirla.
- [ ] 1.2 [HITL] Con la aplicación abierta, iniciar sesión con la cuenta propia, abrir el canal deportivo contratado (hoy NBA League Pass) y reproducir un partido; reportar si carga el inicio de sesión (incluidos códigos de verificación), si hay audio y video, la calidad máxima y cualquier mensaje de error; verificar que el resultado queda escrito en el registro de `design.md`. **Si no reproduce, detenerse aquí**, documentar la causa y no construir el resto.
- [ ] 1.3 [HITL] Con un partido reproduciéndose, abrir una segunda instancia de la aplicación y reproducir otro partido a la vez; reportar qué responde Prime Video; verificar que queda registrado cuántas transmisiones permite la cuenta. No intentar evitar el límite.
- [ ] 1.4 [HITL] Sin el script de pantalla completa, pulsar el botón de pantalla completa del reproductor; reportar si la ventana pasa a la pantalla completa del sistema y cuántos botones de pantalla completa ofrece el reproductor; verificar que queda registrado para decidir el siguiente paso.

## 2. Script de pantalla completa y autoprueba

- [ ] 2.1 [AUTO] Copiar `../DAZNer/shared/fill-fullscreen.js` a `shared/fill-fullscreen.js` renombrando solo los ganchos a `window.__primerDebug`, `window.__primerLog` y `window.__pane`; verificar con `node --check` que la sintaxis es válida y con `diff` que la lógica no cambió.
- [ ] 2.2 [AUTO] Crear páginas locales de prueba en `shared/fixtures/`: un reproductor simulado con su botón de pantalla completa, uno que reescribe las clases de sus contenedores al entrar en pantalla completa y uno con contenedores anidados; verificar que abren en un navegador sin errores de consola.
- [ ] 2.3 [AUTO] Cargar el script en cada panel antes de la página, con un puente que define los ganchos, y hacer que `build.sh` lo copie al paquete antes de firmar y falle si falta; verificar que `./build.sh` deja `fill-fullscreen.js` idéntico al original en `Primer.app/Contents/Resources/`.
- [ ] 2.4 [AUTO] Implementar `--selftest` con las comprobaciones de los requisitos de `selftest` y correrlo; verificar que termina con código 0, que cada comprobación imprime su resultado y que la salida declara que no probó Prime Video.

## 3. Ventana

- [ ] 3.1 [AUTO] Ventana sin bordes con franja de arrastre de 14 px, ⌥ + arrastrar, doble clic y proporción fija 16:9; verificar con la autoprueba las medidas de los escenarios de «Proporción fija».
- [ ] 3.2 [HITL] Mover la ventana, redimensionarla desde los bordes y hacer doble clic en la franja; reportar si se siente bien y si la proporción se conserva en el monitor del mantenedor; verificar que los escenarios de `window-chrome` quedan confirmados.
- [ ] 3.3 [AUTO] Rellenar y centrar sobre el área útil de la pantalla, y siempre encima; verificar con la autoprueba las medidas de los escenarios de ambos requisitos.
- [ ] 3.4 [HITL] Ejecutar rellenar y centrar en el monitor 32:9 y en el secundario; reportar el resultado; verificar que queda registrado.

## 4. Paneles

- [ ] 4.1 [AUTO] Modo de uno y dos paneles de 16:9 con hueco de 8 px dentro del ancho de la ventana, y segundo panel creado a demanda y liberado al volver a uno; verificar con la autoprueba las medidas de «Paneles de proporción 16:9 anidados en la ventana» y «Hueco entre paneles».
- [ ] 4.2 [HITL] Con un partido reproduciéndose, elegir dos paneles y volver a uno; reportar si el primer panel conserva su tamaño y no se refresca, y si el hueco de 8 px se ve bien; verificar que los escenarios de «Segundo panel a demanda» quedan confirmados.
- [ ] 4.3 [AUTO] Audio por foco, cambio de panel con foco y abrir una dirección en el panel con foco; verificar con la autoprueba que el panel sin foco queda silenciado y que la dirección se carga solo en el panel con foco.
- [ ] 4.4 [HITL] Con dos partidos en dos paneles, cambiar el foco con el clic y con el atajo, y silenciar un panel desde el reproductor; reportar si el audio sigue al foco y si el silencio manual se respeta; verificar los escenarios de «Audio por foco».

## 5. Pantalla completa en Prime Video

- [ ] 5.1 [HITL] Abrir la aplicación con `--debug`, reproducir un partido y pulsar cada botón de pantalla completa del reproductor; entregar `debug.log` revisando antes que no contenga datos personales; verificar que el registro trae los eventos de entrada y salida.
- [ ] 5.2 [AUTO] Analizar `debug.log`, adaptar `shared/fill-fullscreen.js` solo con lo observado y volver a correr la autoprueba; verificar que la autoprueba sigue en verde y que cada cambio al script queda explicado en el registro de `design.md`.
- [ ] 5.3 [HITL] Probar la pantalla completa en un panel, en cada panel de dos y con Esc y con el mismo botón; reportar si el reproductor llena la ventana o el panel, si conserva video, audio y controles, y si el sistema nunca entra en pantalla completa; verificar los escenarios de `fullscreen-emulation`.

## 6. Sesión, atajos y diagnóstico

- [ ] 6.1 [AUTO] Almacén de datos persistente compartido entre paneles e instancias, atajos y edición de texto, y modo `--debug` sin datos personales; verificar que sin `--debug` no se crea `debug.log` y que con `--debug` el registro no contiene el contenido de los campos.
- [ ] 6.2 [HITL] Cerrar y reabrir la aplicación, abrir una segunda instancia y pegar una contraseña en el inicio de sesión; reportar si la sesión se conserva, si la segunda instancia no pide iniciar sesión y si pegar funciona; verificar los escenarios de `session` y `shortcuts`.

## 7. Documentación y cierre

- [ ] 7.1 [AUTO] Actualizar `README.md` con los requisitos y la compilación, y quitar el aviso de «en especificación»; verificar que un clon nuevo compila siguiendo solo el README.
- [ ] 7.2 [AUTO] Correr `openspec validate --all --strict`; verificar que pasa sin fallos.
- [ ] 7.3 [HITL] El mantenedor usa la aplicación en un partido completo con dos paneles y confirma que cumple el resultado esperado: sin bordes y botón de pantalla completa que llena la ventana o el panel; verificar que queda registrado en `design.md` y archivar el cambio.
