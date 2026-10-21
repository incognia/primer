## ADDED Requirements

### Requirement: Proporción de cine con un solo panel

Con un solo panel, la aplicación SHALL ofrecer una acción que cambie la proporción de la ventana de forma secuencial entre 16:9, 2.35:1 y 2.39:1, y de 2.39:1 vuelva a 16:9. La ventana SHALL abrir en 16:9. Al cambiar la proporción, la ventana SHALL conservar su ancho y su esquina superior izquierda, y SHALL reducirse con la misma proporción hasta caber si no cabe en el área útil de la pantalla. Con dos o más paneles la acción SHALL estar deshabilitada, y al abrir un segundo panel la ventana SHALL volver a 16:9 antes de repartir los paneles. Al volver a un solo panel la proporción SHALL ser 16:9.

#### Scenario: Ciclo con un panel

- **WHEN** el usuario ejecuta la acción tres veces seguidas con un panel abierto en 16:9
- **THEN** la ventana pasa a 2.35:1, luego a 2.39:1 y después vuelve a 16:9, con el mismo ancho en cada paso

#### Scenario: Medidas de la ventana

- **WHEN** la ventana de ancho W pasa a 2.35:1 o a 2.39:1
- **THEN** su alto es W / 2.35 o W / 2.39, y conserva su esquina superior izquierda

#### Scenario: Con más de un panel

- **WHEN** hay dos o tres paneles abiertos
- **THEN** la acción de proporción aparece deshabilitada y no cambia la ventana

#### Scenario: Abrir un segundo panel

- **WHEN** el usuario abre un segundo panel con la ventana en 2.35:1 o en 2.39:1
- **THEN** la ventana vuelve a 16:9, el primer panel conserva su ancho y los dos paneles quedan en 32:9

#### Scenario: Volver a un panel

- **WHEN** el usuario vuelve a un panel después de haber usado una proporción de cine y varios paneles
- **THEN** la ventana queda en 16:9

#### Scenario: Rellenar y centrar

- **WHEN** el usuario ejecuta rellenar y centrar con la ventana en 2.39:1
- **THEN** la ventana conserva 2.39:1 y es la más grande que cabe en el área útil

## MODIFIED Requirements

### Requirement: Proporción fija

La aplicación SHALL permitir redimensionar la ventana desde sus bordes solo conservando la proporción que le corresponde: con n paneles, 16n:9 en la disposición horizontal y 16:9n en la vertical (16:9 con un panel; 32:9 y 16:18 con dos; 48:9 y 16:27 con tres); con un solo panel, además, la que haya elegido el usuario entre 16:9, 2.35:1 y 2.39:1.

#### Scenario: Redimensionar con un panel

- **WHEN** el usuario arrastra un borde con un panel abierto
- **THEN** el ancho y el alto cambian juntos y la proporción sigue siendo la vigente (16:9, 2.35:1 o 2.39:1)

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
