# window-chrome Specification

## Purpose

Define la ventana sin bordes de Primer: cómo se muestra, se mueve, se redimensiona, se rellena y se mantiene encima de otras ventanas.

## Requirements

### Requirement: Ventana sin bordes

La aplicación SHALL mostrar su contenido en una ventana sin bordes, sin botones de ventana y sin barra de título visible.

#### Scenario: Apertura

- **WHEN** el usuario abre la aplicación
- **THEN** la ventana no muestra bordes, botones ni barra de título

### Requirement: Mover la ventana

La aplicación SHALL permitir mover la ventana arrastrando desde una franja invisible de 14 px en el borde superior, y desde cualquier punto manteniendo la tecla ⌥ Option.

#### Scenario: Arrastre desde la franja

- **WHEN** el usuario arrastra desde la franja superior
- **THEN** la ventana se mueve con el puntero

#### Scenario: Arrastre con tecla modificadora

- **WHEN** el usuario mantiene ⌥ Option y arrastra desde cualquier punto del contenido
- **THEN** la ventana se mueve con el puntero

#### Scenario: Doble clic en la franja

- **WHEN** el usuario hace doble clic en la franja superior
- **THEN** la ventana alterna entre maximizada y su tamaño anterior

### Requirement: Proporción fija

La aplicación SHALL permitir redimensionar la ventana desde sus bordes solo conservando la proporción 16:9 con un panel y 32:9 con dos paneles.

#### Scenario: Redimensionar con un panel

- **WHEN** el usuario arrastra un borde con un panel abierto
- **THEN** el ancho y el alto cambian juntos y la proporción sigue siendo 16:9

#### Scenario: Redimensionar con dos paneles

- **WHEN** el usuario arrastra un borde con dos paneles abiertos
- **THEN** la proporción sigue siendo 32:9

### Requirement: Rellenar y centrar

La aplicación SHALL ofrecer una acción que agrande la ventana al máximo que cabe en el área útil de la pantalla, conservando su proporción, y la deje centrada.

#### Scenario: Pantalla más ancha que la proporción

- **WHEN** el usuario ejecuta la acción en una pantalla más ancha que la proporción de la ventana
- **THEN** la ventana ocupa todo el alto útil, conserva su proporción y queda centrada horizontalmente

#### Scenario: Pantalla más alta que la proporción

- **WHEN** el usuario ejecuta la acción en una pantalla más alta que la proporción de la ventana
- **THEN** la ventana ocupa todo el ancho útil, conserva su proporción y queda centrada verticalmente

### Requirement: Siempre encima

La aplicación SHALL permitir alternar que la ventana permanezca por encima de las demás.

#### Scenario: Activar y desactivar

- **WHEN** el usuario ejecuta la acción de siempre encima dos veces seguidas
- **THEN** la ventana queda por encima de las demás y después vuelve a su nivel normal
