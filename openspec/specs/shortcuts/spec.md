# shortcuts Specification

## Purpose

Define los atajos de teclado de Primer y las acciones de edición de texto, con la tecla ⌘.

## Requirements

### Requirement: Atajos de la aplicación

La aplicación SHALL ofrecer atajos con la tecla ⌘: 1, 2 y 3 para el número de paneles, L para abrir una dirección, R para recargar, H para el inicio de Prime Video, ` para cambiar de panel, T para siempre encima, F para rellenar y centrar, W para cerrar y Q para salir; y con ⌥⌘ los de la disposición de los paneles: H para la horizontal y V para la vertical. ⌘V SHALL seguir siendo «Pegar» y ⌘H SHALL seguir abriendo el inicio de Prime Video.

#### Scenario: Recargar

- **WHEN** el usuario pulsa el atajo de recargar
- **THEN** el panel con foco se recarga y los demás no

#### Scenario: Salir

- **WHEN** el usuario pulsa el atajo de salir
- **THEN** la aplicación se cierra por completo

#### Scenario: Tres paneles

- **WHEN** el usuario pulsa ⌘3
- **THEN** la aplicación muestra tres paneles

#### Scenario: Disposición

- **WHEN** el usuario pulsa ⌥⌘V con dos o tres paneles abiertos
- **THEN** los paneles quedan uno sobre otro, y con ⌥⌘H quedan uno junto al otro

#### Scenario: Los atajos de siempre no cambian

- **WHEN** el usuario pulsa ⌘V en un campo de texto y ⌘H en un panel
- **THEN** ⌘V pega el texto y ⌘H abre el inicio de Prime Video en el panel con foco, sin cambiar la disposición

### Requirement: Edición de texto

La aplicación SHALL permitir deshacer, cortar, copiar, pegar y seleccionar todo en los campos de texto de Prime Video, con los atajos y el menú de edición habituales de macOS.

#### Scenario: Pegar una contraseña

- **WHEN** el usuario pega texto en un campo de Prime Video
- **THEN** el texto aparece en el campo
