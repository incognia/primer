## MODIFIED Requirements

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
