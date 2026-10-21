## ADDED Requirements

### Requirement: Sitio oficial de Prime Video

La aplicación SHALL abrir el sitio web oficial de Prime Video al iniciar y en cada panel nuevo, desde donde el usuario accede a sus canales deportivos contratados, como NBA League Pass.

#### Scenario: Inicio

- **WHEN** el usuario abre la aplicación
- **THEN** el panel muestra el inicio del sitio de Prime Video

### Requirement: Reproducción con el DRM del sistema

La aplicación SHALL reproducir el contenido de los canales deportivos de Prime Video, como NBA League Pass, con una suscripción válida usando el DRM del motor web nativo de la plataforma.

#### Scenario: Partido en directo

- **WHEN** el usuario con suscripción válida abre un partido en directo
- **THEN** el video se reproduce con audio

### Requirement: Sin eludir protecciones

La aplicación SHALL NOT eludir el DRM, los controles de acceso ni los límites de reproducción de Prime Video, incluido el número de transmisiones simultáneas que permita la cuenta, y SHALL NOT redistribuir módulos de DRM.

#### Scenario: Límite de transmisiones

- **WHEN** Prime Video rechaza o limita una reproducción, por ejemplo por exceder las transmisiones simultáneas de la cuenta
- **THEN** la aplicación muestra lo que Prime Video responda y no intenta evitarlo

### Requirement: Enlaces que piden una ventana nueva

La aplicación SHALL abrir en el mismo panel los enlaces que piden una ventana nueva.

#### Scenario: Enlace de ventana nueva

- **WHEN** Prime Video abre un enlace con destino de ventana nueva
- **THEN** la dirección se carga en el panel desde el que se abrió y no aparece otra ventana
