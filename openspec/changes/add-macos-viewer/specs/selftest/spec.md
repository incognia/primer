## ADDED Requirements

### Requirement: Autoprueba sin cuenta ni red

La aplicación SHALL ofrecer el modo `--selftest`, que carga páginas locales de prueba incluidas en el repositorio y comprueba por sí misma la pantalla completa y los paneles, sin conectarse a Prime Video, sin usar ninguna cuenta y sin acceso a la red.

#### Scenario: Ejecutar la autoprueba

- **WHEN** se inicia la aplicación con `--selftest`
- **THEN** ejecuta las comprobaciones, imprime una línea por comprobación con el resultado, y termina

#### Scenario: Código de salida

- **WHEN** termina la autoprueba
- **THEN** el código de salida es 0 si todas las comprobaciones pasaron y distinto de 0 si alguna falló

### Requirement: Comprobaciones de pantalla completa

La autoprueba SHALL comprobar, con una página local que simula un reproductor, que la pantalla completa llena el área, que no activa la pantalla completa del sistema, que Esc restaura el estilo original y que el modo se mantiene cuando la página reescribe las clases de sus contenedores.

#### Scenario: Llenar el área

- **WHEN** la página de prueba pide la pantalla completa de su contenedor
- **THEN** el contenedor mide lo mismo que el área visible y la ventana no está en pantalla completa del sistema

#### Scenario: Salir restaura el estilo

- **WHEN** la autoprueba simula Esc
- **THEN** el contenedor recupera su tamaño y su atributo de estilo originales

#### Scenario: Redibujado de la página

- **WHEN** la página de prueba reescribe las clases del contenedor durante el modo
- **THEN** el contenedor sigue llenando el área

### Requirement: Comprobaciones de paneles

La autoprueba SHALL comprobar las medidas de uno y de dos paneles y la proporción de la ventana en cada modo.

#### Scenario: Medidas con dos paneles

- **WHEN** la autoprueba abre dos paneles en una ventana de ancho W
- **THEN** cada panel mide (W − 8) / 2 de ancho y la ventana mide 32:9

### Requirement: Alcance de la autoprueba

La autoprueba SHALL NOT sustituir la validación humana de la reproducción ni de la apariencia, y SHALL declarar en su salida que no probó Prime Video.

#### Scenario: Aviso en la salida

- **WHEN** termina la autoprueba
- **THEN** su salida indica que la reproducción y la apariencia en Prime Video requieren validación humana
