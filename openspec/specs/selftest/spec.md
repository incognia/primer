# selftest Specification

## Purpose

Define la autoprueba de Primer, que comprueba por sí misma el audio por foco y los paneles, sin cuenta ni red y sin probar Prime Video.

## Requirements

### Requirement: Autoprueba sin cuenta ni red

La aplicación SHALL ofrecer el modo `--selftest`, que carga páginas locales de prueba incluidas en el repositorio y comprueba por sí misma el audio por foco y los paneles, sin conectarse a Prime Video, sin usar ninguna cuenta y sin acceso a la red.

#### Scenario: Ejecutar la autoprueba

- **WHEN** se inicia la aplicación con `--selftest`
- **THEN** ejecuta las comprobaciones, imprime una línea por comprobación con el resultado, y termina

#### Scenario: Código de salida

- **WHEN** termina la autoprueba
- **THEN** el código de salida es 0 si todas las comprobaciones pasaron y distinto de 0 si alguna falló

### Requirement: Comprobaciones de audio

La autoprueba SHALL comprobar, con páginas locales que tienen elementos de medios, que con dos paneles solo el panel con foco queda sin silenciar, que el silencio se mantiene cuando la página intenta reactivar el audio y que el silencio manual no se revierte al cambiar el foco.

#### Scenario: Panel sin foco silenciado

- **WHEN** la autoprueba abre dos paneles con la página de medios y uno tiene el foco
- **THEN** los elementos de medios del panel sin foco están silenciados y los del panel con foco no

#### Scenario: La página reactiva el audio

- **WHEN** la página de prueba reactiva el audio del panel sin foco
- **THEN** el panel vuelve a quedar silenciado dentro del tiempo que fija el diseño

#### Scenario: Cambiar el foco

- **WHEN** la autoprueba pasa el foco al otro panel
- **THEN** el panel que perdió el foco queda silenciado y el que lo ganó deja de estarlo

#### Scenario: Silencio manual

- **WHEN** la autoprueba silencia a mano el panel con foco y luego cambia el foco y lo recupera
- **THEN** ese panel sigue silenciado

### Requirement: Comprobaciones de paneles

La autoprueba SHALL comprobar las medidas de uno y de dos paneles y la proporción de la ventana en cada modo.

#### Scenario: Medidas con dos paneles

- **WHEN** la autoprueba abre dos paneles en una ventana de ancho W
- **THEN** cada panel mide W / 2 de ancho y la altura completa de la ventana, y la ventana mide 32:9

### Requirement: Alcance de la autoprueba

La autoprueba SHALL NOT sustituir la validación humana de la reproducción ni de la apariencia, y SHALL declarar en su salida que no probó Prime Video.

#### Scenario: Aviso en la salida

- **WHEN** termina la autoprueba
- **THEN** su salida indica que la reproducción y la apariencia en Prime Video requieren validación humana
