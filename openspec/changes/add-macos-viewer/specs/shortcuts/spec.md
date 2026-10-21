## ADDED Requirements

### Requirement: Atajos de la aplicación

La aplicación SHALL ofrecer atajos con la tecla ⌘: 1 y 2 para el número de paneles, L para abrir una dirección, R para recargar, H para el inicio de Prime Video, ` para cambiar de panel, T para siempre encima, F para rellenar y centrar, W para cerrar y Q para salir.

#### Scenario: Recargar

- **WHEN** el usuario pulsa el atajo de recargar
- **THEN** el panel con foco se recarga y los demás no

#### Scenario: Salir

- **WHEN** el usuario pulsa el atajo de salir
- **THEN** la aplicación se cierra por completo

### Requirement: Edición de texto

La aplicación SHALL permitir deshacer, cortar, copiar, pegar y seleccionar todo en los campos de texto de Prime Video, con los atajos y el menú de edición habituales de macOS.

#### Scenario: Pegar una contraseña

- **WHEN** el usuario pega texto en un campo de Prime Video
- **THEN** el texto aparece en el campo
