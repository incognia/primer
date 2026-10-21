# Tasks

Marcas: **[AUTO]** la ejecuta y la verifica el agente. **[HITL]** la valida el mantenedor; el agente no la marca como hecha sin su confirmación en la conversación y anota el resultado en el «Registro de validación» de `design.md`.

## 1. Prueba de reproducción (puerta: detenerse si falla)

- [x] 1.1 [AUTO] Crear `macos/Primer.swift`, una ventana con barra de título normal y un `WKWebView` que abra la dirección de inicio de Prime Video (una constante), con menú de edición y ⌘Q, y `macos/build.sh` que compile con `swiftc` y firme de forma local; verificar que `./build.sh` termina sin errores y que la aplicación sigue viva 3 segundos después de abrirla.
- [x] 1.2 [HITL] Con la aplicación abierta, iniciar sesión con la cuenta propia, abrir el canal deportivo contratado (hoy NBA League Pass) y reproducir un partido; reportar si carga el inicio de sesión (incluidos códigos de verificación), si hay audio y video, la calidad máxima y cualquier mensaje de error; verificar que el resultado queda escrito en el registro de `design.md`. **Si no reproduce, detenerse aquí**, documentar la causa y no construir el resto.
- [x] 1.3 [HITL] Con un partido reproduciéndose, abrir una segunda instancia de la aplicación y reproducir otro partido a la vez; reportar qué responde Prime Video; verificar que queda registrado cuántas transmisiones permite la cuenta. No intentar evitar el límite.
- [x] 1.4 [HITL] Con un partido reproduciéndose en un panel, comprobar que el reproductor llena la ventana por sí mismo y pulsar su botón de pantalla completa; reportar si la ventana pasa a la pantalla completa del sistema; verificar que queda registrado para decidir si se desactiva la pantalla completa del sistema.

## 2. Autoprueba

- [ ] 2.1 [AUTO] Retirar `shared/fill-fullscreen.js` y las tres páginas de prueba de pantalla completa de `shared/fixtures/` (`player.html`, `rewrites-classes.html` y `nested.html`), que ya no hacen falta, y quitar de `.gitignore` las líneas de la copia del script en el paquete; verificar con `grep -r fill-fullscreen .` que no queda ninguna referencia fuera del historial de git, del registro de `design.md` y del historial de cambios.
- [ ] 2.2 [AUTO] Crear páginas locales de prueba de medios en `shared/fixtures/`: una con un elemento `video` con una pista de audio breve y otra que intenta reactivar el audio de sus medios de forma periódica; verificar que abren en un navegador sin errores de consola.
- [ ] 2.3 [AUTO] Implementar `--selftest` con las comprobaciones de los requisitos de `selftest` y correrlo; verificar que termina con código 0, que cada comprobación imprime su resultado y que la salida declara que no probó Prime Video.

## 3. Ventana

- [ ] 3.1 [AUTO] Ventana sin bordes con franja de arrastre de 14 px, ⌥ + arrastrar, doble clic y proporción fija 16:9; verificar con la autoprueba las medidas de los escenarios de «Proporción fija».
- [ ] 3.2 [HITL] Mover la ventana, redimensionarla desde los bordes y hacer doble clic en la franja; reportar si se siente bien y si la proporción se conserva en el monitor del mantenedor; verificar que los escenarios de `window-chrome` quedan confirmados.
- [ ] 3.3 [AUTO] Rellenar y centrar sobre el área útil de la pantalla, y siempre encima; verificar con la autoprueba las medidas de los escenarios de ambos requisitos.
- [ ] 3.4 [HITL] Ejecutar rellenar y centrar en el monitor 32:9 y en el secundario; reportar el resultado; verificar que queda registrado.

## 4. Paneles

- [ ] 4.1 [AUTO] Modo de uno y dos paneles de 16:9 con hueco de 8 px dentro del ancho de la ventana, y segundo panel creado a demanda y liberado al volver a uno; verificar con la autoprueba las medidas de «Paneles de proporción 16:9 anidados en la ventana» y «Hueco entre paneles».
- [ ] 4.2 [HITL] Con un partido reproduciéndose, elegir dos paneles y volver a uno; reportar si el primer panel conserva su tamaño y no se refresca, y si el hueco de 8 px se ve bien; verificar que los escenarios de «Segundo panel a demanda» quedan confirmados.
- [ ] 4.3 [AUTO] Audio por foco con el panel sin foco silenciado aunque su página intente reactivar el audio, cambio de panel con foco y abrir una dirección en el panel con foco; verificar con la autoprueba que solo suena el panel con foco, que el silencio vuelve tras un intento de reactivación y que la dirección se carga solo en el panel con foco.
- [ ] 4.4 [HITL] Con dos partidos de Prime Video en dos paneles en modo 32:9, cambiar el foco con el clic y con el atajo, pausar y reanudar cada partido, y silenciar un panel desde el reproductor; reportar si el panel sin foco no se escucha en ningún momento, si el silencio manual se respeta y si el reproductor llena cada panel; verificar los escenarios de «Audio por foco».

## 5. Sesión, atajos y diagnóstico

- [ ] 5.1 [AUTO] Almacén de datos persistente compartido entre paneles e instancias, atajos y edición de texto, y modo `--debug` que registra los eventos de audio y de cada panel sin datos personales; verificar que sin `--debug` no se crea `debug.log` y que con `--debug` el registro trae esos eventos y no contiene el contenido de los campos.
- [ ] 5.2 [HITL] Cerrar y reabrir la aplicación, abrir una segunda instancia y pegar una contraseña en el inicio de sesión; reportar si la sesión se conserva, si la segunda instancia no pide iniciar sesión y si pegar funciona; verificar los escenarios de `session` y `shortcuts`.

## 6. Documentación y cierre

- [ ] 6.1 [AUTO] Actualizar `README.md` con los requisitos y la compilación, y quitar el aviso de «en especificación»; verificar que un clon nuevo compila siguiendo solo el README.
- [ ] 6.2 [AUTO] Correr `openspec validate --all --strict`; verificar que pasa sin fallos.
- [ ] 6.3 [HITL] El mantenedor usa la aplicación en un partido completo con dos paneles y confirma que cumple el resultado esperado: sin bordes, dos partidos de Prime Video a la vez en 32:9 y el panel sin foco silenciado; verificar que queda registrado en `design.md` y archivar el cambio.
