## MODIFIED Requirements

### Requirement: Proporción fija

La aplicación SHALL permitir redimensionar la ventana desde sus bordes solo conservando la proporción que le corresponde: con n paneles, 16n:9 en la disposición horizontal y 16:9n en la vertical (16:9 con un panel; 32:9 y 16:18 con dos; 48:9 y 16:27 con tres).

#### Scenario: Redimensionar con un panel

- **WHEN** el usuario arrastra un borde con un panel abierto
- **THEN** el ancho y el alto cambian juntos y la proporción sigue siendo 16:9

#### Scenario: Redimensionar con dos paneles

- **WHEN** el usuario arrastra un borde con dos paneles abiertos en horizontal
- **THEN** la proporción sigue siendo 32:9

#### Scenario: Redimensionar con tres paneles en horizontal

- **WHEN** el usuario arrastra un borde con tres paneles abiertos en horizontal
- **THEN** la proporción sigue siendo 48:9

#### Scenario: Redimensionar en vertical

- **WHEN** el usuario arrastra un borde con dos o tres paneles abiertos en vertical
- **THEN** la proporción sigue siendo 16:18 con dos paneles y 16:27 con tres

#### Scenario: Cambiar de disposición

- **WHEN** el usuario cambia entre horizontal y vertical con más de un panel
- **THEN** la proporción de la ventana pasa a la de la nueva disposición y rellenar y centrar usa esa proporción
