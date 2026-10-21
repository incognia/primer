## ADDED Requirements

### Requirement: Uno o dos paneles

La aplicación SHALL ofrecer un modo de un panel y otro de dos paneles, y cada panel SHALL ser un contexto web independiente que abre el inicio de Prime Video. Los paneles son la forma de ver varios partidos a la vez, porque la página de Prime Video no trae vista múltiple.

#### Scenario: Pasar a dos paneles

- **WHEN** el usuario elige dos paneles
- **THEN** aparece un segundo panel con el inicio de Prime Video a la derecha del primero

### Requirement: Paneles de proporción 16:9 anidados en la ventana

Cada panel SHALL conservar la proporción 16:9, de modo que un panel llene una ventana 16:9 y dos paneles, uno junto al otro, llenen una ventana 32:9.

#### Scenario: Un panel

- **WHEN** hay un panel abierto en una ventana de ancho W
- **THEN** el panel mide W de ancho y W × 9 / 16 de alto

#### Scenario: Dos paneles

- **WHEN** hay dos paneles abiertos en una ventana de ancho W
- **THEN** cada panel mide (W − hueco) / 2 de ancho y esa cantidad × 9 / 16 de alto, y la ventana conserva la proporción 32:9

### Requirement: Hueco entre paneles

Con dos paneles, la aplicación SHALL dejar un hueco de 8 px entre ellos, incluido dentro del ancho de la ventana, de modo que la proporción 32:9 de la ventana no cambie. El valor de 8 px se hereda de DAZNer y SHALL ajustarse si una persona lo valida y resulta inadecuado para Prime Video.

#### Scenario: Medidas con dos paneles

- **WHEN** hay dos paneles abiertos en una ventana de ancho W
- **THEN** cada panel mide (W − 8) / 2 de ancho y entre ambos queda un hueco de 8 px

### Requirement: Segundo panel a demanda

La aplicación SHALL crear el segundo panel solo cuando se pide y SHALL liberarlo por completo al volver a un panel, y el panel que ya estaba abierto SHALL conservar su tamaño y no refrescarse al hacerlo.

#### Scenario: Abrir el segundo panel

- **WHEN** el usuario elige dos paneles con un partido reproduciéndose en el primero
- **THEN** el primer panel conserva su tamaño y sigue reproduciendo sin recargarse

#### Scenario: Volver a un panel

- **WHEN** el usuario elige un panel con dos paneles abiertos
- **THEN** el segundo panel se detiene, desaparece y libera sus recursos

### Requirement: Audio por foco

Con dos paneles, la aplicación SHALL dejar sonar solo el panel con foco y SHALL mantener silenciado el otro, aunque la página o el reproductor de ese panel intente reactivar su audio, y SHALL NOT reactivar el audio de un panel que el usuario silenció desde el reproductor.

#### Scenario: Cambiar el foco

- **WHEN** el usuario hace clic en el panel que estaba silenciado
- **THEN** ese panel suena y el otro queda silenciado

#### Scenario: Silencio manual

- **WHEN** el usuario silencia el panel con foco desde el reproductor de Prime Video
- **THEN** el panel permanece silenciado hasta que el usuario lo active

#### Scenario: El reproductor reactiva el audio

- **WHEN** el reproductor del panel sin foco reactiva su propio audio
- **THEN** el panel vuelve a quedar silenciado y no se escucha

#### Scenario: Dos partidos en 32:9

- **WHEN** hay dos paneles reproduciendo partidos distintos en una ventana 32:9
- **THEN** se escucha solo el partido del panel con foco

### Requirement: El clic que da el foco no llega al reproductor

Con dos paneles, un clic en el panel sin foco SHALL limitarse a pasarle el foco y el audio, y SHALL NOT entregarse a la página, de modo que no pause ni reanude el video. Desde el siguiente clic, el panel SHALL comportarse como el reproductor lo haga.

#### Scenario: Clic en el panel sin foco

- **WHEN** el usuario hace clic en el video del panel sin foco
- **THEN** el panel recibe el foco y el audio, y el video no se pausa ni se reanuda

#### Scenario: Clic en el panel con foco

- **WHEN** el usuario hace clic en el video del panel que ya tiene el foco
- **THEN** el clic llega al reproductor y este responde como lo haga normalmente

#### Scenario: Un solo panel

- **WHEN** hay un solo panel abierto
- **THEN** todos los clics llegan al reproductor

### Requirement: Cambio de panel con foco

La aplicación SHALL permitir pasar el foco y el audio al siguiente panel con un atajo de teclado.

#### Scenario: Cambiar de panel

- **WHEN** el usuario ejecuta la acción de siguiente panel con dos paneles abiertos
- **THEN** el foco y el audio pasan al otro panel

### Requirement: Abrir una dirección en el panel con foco

La aplicación SHALL permitir escribir una dirección web y abrirla en el panel con foco.

#### Scenario: Abrir una dirección

- **WHEN** el usuario ejecuta la acción de abrir dirección y confirma una dirección
- **THEN** el panel con foco carga esa dirección y los demás paneles no cambian
