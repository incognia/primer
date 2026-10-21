## ADDED Requirements

### Requirement: Llenar la ventana o el panel

Cuando la página pida la pantalla completa de un elemento, la aplicación SHALL estirarlo hasta llenar la ventana con un panel, o su panel con dos paneles, sin entrar a la pantalla completa del sistema.

#### Scenario: Un panel

- **WHEN** la página pide la pantalla completa con un panel abierto
- **THEN** el elemento llena toda la ventana y el sistema no cambia a pantalla completa

#### Scenario: Dos paneles

- **WHEN** la página pide la pantalla completa en uno de dos paneles
- **THEN** el elemento llena solo ese panel y el otro panel no cambia

### Requirement: Salir de la pantalla completa

La aplicación SHALL salir del modo con la tecla Esc o con el mismo botón del reproductor, y SHALL restaurar el estado y el estilo originales del elemento.

#### Scenario: Salir con Esc

- **WHEN** el usuario pulsa Esc durante la pantalla completa
- **THEN** el elemento regresa a su lugar con su tamaño y estilo anteriores

### Requirement: Compatibilidad con el reproductor de Prime Video

La aplicación SHALL resolver la pantalla completa de cada botón que el reproductor de Prime Video ofrezca para ella, de modo que el elemento llene la ventana o el panel, quede visible y siga reproduciendo, sin quedar vacío ni negro.

#### Scenario: Botón de pantalla completa del reproductor

- **WHEN** el usuario pulsa el botón de pantalla completa del reproductor durante un partido
- **THEN** el reproductor llena la ventana o el panel, el video sigue visible y con audio, y el sistema no cambia a pantalla completa

#### Scenario: Controles del reproductor

- **WHEN** el reproductor está en pantalla completa
- **THEN** sus controles siguen mostrándose y funcionando dentro del área

### Requirement: Resistencia a los redibujados de la página

La aplicación SHALL mantener la pantalla completa aunque la página reescriba las clases o los estilos de sus contenedores, SHALL mostrar los contenedores que la página oculte y SHALL ocultar el resto de la página mientras dure.

#### Scenario: La página reescribe sus contenedores

- **WHEN** la página reescribe las clases del contenedor del reproductor tras detectar la pantalla completa
- **THEN** el elemento sigue llenando el área y sigue visible

### Requirement: Estado visible para la página

La aplicación SHALL hacer que la página vea el elemento como elemento en pantalla completa y que reciba los eventos de cambio de pantalla completa al entrar y al salir.

#### Scenario: La página consulta el estado

- **WHEN** la página consulta qué elemento está en pantalla completa durante el modo
- **THEN** obtiene el elemento estirado, y al salir obtiene que no hay ninguno

### Requirement: Script compartido

La emulación de pantalla completa SHALL implementarse con un único script JavaScript, `shared/fill-fullscreen.js`, que la aplicación carga en cada panel antes de que se ejecute la página. El script SHALL partir del de DAZNer y SHALL adaptarse solo después de observar cómo pide la pantalla completa el reproductor de Prime Video.

#### Scenario: Mismo archivo en el paquete

- **WHEN** se compila la aplicación
- **THEN** la emulación de pantalla completa usa el contenido de `shared/fill-fullscreen.js` sin copias modificadas

### Requirement: Registro mediante un gancho neutro

El script SHALL reportar su diagnóstico solo mediante la función global `window.__primerLog`, que la plataforma enlaza a su propio mecanismo, y SHALL NOT fallar ni registrar nada si esa función no existe.

#### Scenario: Con gancho y diagnóstico activo

- **WHEN** la plataforma define `window.__primerLog` y activa el diagnóstico
- **THEN** el script envía sus eventos a esa función

#### Scenario: Sin gancho

- **WHEN** la plataforma no define `window.__primerLog`
- **THEN** el script funciona igual y no produce errores

### Requirement: Diagnóstico controlado desde fuera

El script SHALL leer si el diagnóstico está activo de la variable global `window.__primerDebug`, definida por la plataforma antes de cargarlo, y SHALL NOT medir ni registrar nada cuando vale falso o no existe.

#### Scenario: Diagnóstico apagado

- **WHEN** `window.__primerDebug` no está definida o vale falso
- **THEN** el script no mide ni registra eventos y el comportamiento de pantalla completa no cambia
