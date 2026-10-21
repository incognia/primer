# session Specification

## Purpose

Define cómo Primer conserva la sesión del usuario en Prime Video y qué datos nunca guarda.

## Requirements

### Requirement: Sesión persistente

La aplicación SHALL conservar la sesión de Prime Video entre aperturas, y la sesión SHALL compartirse entre los paneles y entre varias instancias abiertas a la vez.

#### Scenario: Reabrir la aplicación

- **WHEN** el usuario inicia sesión, cierra la aplicación y la vuelve a abrir
- **THEN** la sesión de Prime Video sigue iniciada, mientras Prime Video no la haya caducado

#### Scenario: Varias instancias

- **WHEN** el usuario abre una segunda instancia de la aplicación
- **THEN** esa instancia usa la misma sesión sin pedir iniciar sesión otra vez

### Requirement: Sin contraseñas

La aplicación SHALL NOT leer, almacenar ni registrar la contraseña del usuario, los códigos de verificación ni lo que escribe en los campos de Prime Video.

#### Scenario: Inicio de sesión

- **WHEN** el usuario escribe su contraseña o un código de verificación en Prime Video
- **THEN** la aplicación no los guarda ni los escribe en ningún registro

### Requirement: Varias instancias independientes

La aplicación SHALL permitir abrir varias instancias a la vez, cada una con su propia ventana y sus propios paneles.

#### Scenario: Dos instancias

- **WHEN** el usuario abre dos instancias
- **THEN** cada una tiene su ventana y reproduce un partido distinto sin afectar a la otra, siempre que la cuenta lo permita
