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

La autoprueba SHALL comprobar las medidas de uno, de dos y de tres paneles en las dos disposiciones y la proporción de la ventana en cada caso, que el audio por foco deja sonar un solo panel con tres paneles, que los atajos nuevos están en el menú y la proporción de cine con un solo panel: el ciclo, las medidas, el deshabilitado con más de un panel y el regreso a 16:9.

#### Scenario: Medidas con dos paneles

- **WHEN** la autoprueba abre dos paneles en horizontal en una ventana de ancho W
- **THEN** cada panel mide W / 2 de ancho y la altura completa de la ventana, y la ventana mide 32:9

#### Scenario: Medidas con tres paneles en las dos disposiciones

- **WHEN** la autoprueba abre tres paneles, primero en horizontal y luego en vertical
- **THEN** en horizontal cada panel mide W / 3 de ancho y la altura completa, con ventana 48:9; y en vertical cada panel mide el ancho completo y 1/3 de la altura, con ventana 16:27, sin hueco en ninguna

#### Scenario: Audio con tres paneles

- **WHEN** la autoprueba abre tres paneles con la página de medios y pasa el foco por cada uno
- **THEN** solo los medios del panel con foco están sin silenciar, y los de los otros dos, silenciados

#### Scenario: Atajos nuevos

- **WHEN** la autoprueba revisa el menú
- **THEN** ⌘3 es «3 paneles», ⌥⌘H es la disposición horizontal, ⌥⌘V es la vertical y ⌥⌘P es la proporción, y ⌘V sigue siendo «Pegar» y ⌘H «Inicio de Prime Video»

#### Scenario: Ciclo de proporción con un panel

- **WHEN** la autoprueba ejecuta la acción de proporción cinco veces con un panel
- **THEN** la ventana pasa por 1.85:1, 2.35:1, 2.39:1, 2.40:1 y 16:9 con el mismo ancho, y el panel llena la ventana en cada paso

#### Scenario: Proporción con más de un panel

- **WHEN** la autoprueba tiene dos paneles abiertos y revisa el elemento de proporción del menú
- **THEN** el elemento está deshabilitado, y con un panel está habilitado

#### Scenario: Regreso a 16:9

- **WHEN** la autoprueba abre un segundo panel con la ventana en una proporción distinta de 16:9 y después vuelve a un panel
- **THEN** la ventana midió 32:9 con dos paneles y vuelve a 16:9 con uno

### Requirement: Alcance de la autoprueba

La autoprueba SHALL NOT sustituir la validación humana de la reproducción ni de la apariencia, y SHALL declarar en su salida que no probó Prime Video.

#### Scenario: Aviso en la salida

- **WHEN** termina la autoprueba
- **THEN** su salida indica que la reproducción y la apariencia en Prime Video requieren validación humana
