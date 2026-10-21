# diagnostics Specification

## Purpose

Define el modo de diagnóstico opcional de Primer, que ayuda a investigar fallos sin afectar el uso normal ni registrar datos personales.

## Requirements

### Requirement: Modo de diagnóstico opcional

La aplicación SHALL activar el modo de diagnóstico solo cuando se inicia con el argumento `--debug`, y SHALL dejarlo desactivado de forma predeterminada.

#### Scenario: Inicio normal

- **WHEN** el usuario abre la aplicación sin argumentos
- **THEN** no se escribe ningún registro y el inspector web queda deshabilitado

#### Scenario: Inicio con diagnóstico

- **WHEN** el usuario abre la aplicación con `--debug`
- **THEN** se escribe `debug.log` junto a la aplicación y el inspector web queda habilitado

### Requirement: Eventos registrados

En modo de diagnóstico, la aplicación SHALL registrar los eventos de audio (panel con foco, panel silenciado e intentos del reproductor de reactivar el audio) y los eventos de cada panel (cambio de tamaño, carga y descarga de la página).

#### Scenario: Audio en diagnóstico

- **WHEN** el reproductor del panel sin foco intenta reactivar su audio con el modo de diagnóstico activo
- **THEN** el registro anota qué panel era, que la aplicación lo volvió a silenciar y la hora

### Requirement: Sin datos personales en el registro

El registro de diagnóstico SHALL NOT contener contraseñas, códigos de verificación, correos ni el contenido de los campos de la página.

#### Scenario: Revisar el registro

- **WHEN** el usuario inicia sesión con el diagnóstico activo y revisa `debug.log`
- **THEN** el registro no contiene su contraseña ni su correo
