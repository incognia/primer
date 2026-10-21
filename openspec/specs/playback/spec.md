# playback Specification

## Purpose

Define qué carga Primer, cómo deja que el reproductor llene su ventana o su panel, y bajo qué condiciones reproduce contenido, incluidas las prohibiciones sobre el DRM, los controles de acceso y los límites de la cuenta.

## Requirements

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

### Requirement: El reproductor llena la ventana o el panel

La aplicación SHALL dejar que el reproductor de Prime Video llene por sí mismo la ventana con un panel, o su panel con dos paneles, al reproducir, y SHALL NOT sobrescribir la API de pantalla completa de la página.

#### Scenario: Un panel

- **WHEN** el usuario reproduce un partido con un panel abierto
- **THEN** el reproductor llena la ventana sin que la aplicación intervenga

#### Scenario: Dos paneles

- **WHEN** el usuario reproduce un partido en cada uno de dos paneles
- **THEN** cada reproductor llena su panel y el otro panel no cambia

#### Scenario: Botón de pantalla completa del reproductor

- **WHEN** el usuario pulsa el botón de pantalla completa del reproductor
- **THEN** la aplicación no lo intercepta ni lo emula, y responde como lo haga el motor web del sistema
