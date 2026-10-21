## MODIFIED Requirements

### Requirement: Paneles de proporción 16:9 anidados en la ventana

Con dos o tres paneles, cada panel SHALL conservar la proporción 16:9, de modo que n paneles, uno junto al otro o uno sobre otro, llenen una ventana de 16n:9 en horizontal o de 16:9n en vertical. Con un solo panel, el panel SHALL llenar la ventana con la proporción vigente de esta (16:9 al abrir, o la que haya elegido el usuario).

#### Scenario: Un panel

- **WHEN** hay un panel abierto en una ventana de ancho W con la proporción 16:9
- **THEN** el panel mide W de ancho y W × 9 / 16 de alto

#### Scenario: Un panel con proporción de cine

- **WHEN** hay un panel abierto en una ventana de ancho W con la proporción 1.85:1, 2.35:1, 2.39:1 o 2.40:1
- **THEN** el panel llena la ventana y mide W de ancho y W / 1.85, W / 2.35, W / 2.39 o W / 2.40 de alto

#### Scenario: Dos paneles

- **WHEN** hay dos paneles abiertos en una ventana de ancho W
- **THEN** cada panel mide W / 2 de ancho y W × 9 / 32 de alto, y la ventana conserva la proporción 32:9

#### Scenario: Tres paneles en horizontal

- **WHEN** hay tres paneles abiertos en horizontal en una ventana de ancho W
- **THEN** cada panel mide W / 3 de ancho y W × 3 / 16 de alto, y la ventana conserva la proporción 48:9

#### Scenario: Dos paneles en vertical

- **WHEN** hay dos paneles abiertos en vertical en una ventana de ancho W
- **THEN** cada panel mide W de ancho y W × 9 / 16 de alto, y la ventana conserva la proporción 16:18

#### Scenario: Tres paneles en vertical

- **WHEN** hay tres paneles abiertos en vertical en una ventana de ancho W
- **THEN** cada panel mide W de ancho y W × 9 / 16 de alto, y la ventana conserva la proporción 16:27
