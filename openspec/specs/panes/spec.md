# panes Specification

## Purpose

Define el modo de uno a tres paneles de Primer y su disposición horizontal o vertical: cómo se crean, se miden, se liberan y cómo se reparten entre ellos el foco y el audio.

## Requirements

### Requirement: De uno a tres paneles

La aplicación SHALL ofrecer un modo de un panel, otro de dos y otro de tres, y cada panel SHALL ser un contexto web independiente que abre el inicio de Prime Video. Los paneles son la forma de ver varios partidos a la vez, porque la página de Prime Video no trae vista múltiple. La aplicación SHALL NOT ofrecer más de tres paneles.

#### Scenario: Pasar a dos paneles

- **WHEN** el usuario elige dos paneles
- **THEN** aparece un segundo panel con el inicio de Prime Video después del primero (a su derecha en horizontal, debajo en vertical)

#### Scenario: Pasar a tres paneles

- **WHEN** el usuario elige tres paneles
- **THEN** aparece un tercer panel con el inicio de Prime Video después del segundo

#### Scenario: Pasar de un panel a tres

- **WHEN** el usuario elige tres paneles con un solo panel abierto
- **THEN** aparecen el segundo y el tercer panel, y el primero conserva su tamaño y sigue reproduciendo sin recargarse

### Requirement: Paneles de proporción 16:9 anidados en la ventana

Cada panel SHALL conservar la proporción 16:9, de modo que un panel llene una ventana 16:9 y n paneles, uno junto al otro o uno sobre otro, llenen una ventana de 16n:9 en horizontal o de 16:9n en vertical.

#### Scenario: Un panel

- **WHEN** hay un panel abierto en una ventana de ancho W
- **THEN** el panel mide W de ancho y W × 9 / 16 de alto

#### Scenario: Dos paneles

- **WHEN** hay dos paneles abiertos en una ventana de ancho W
- **THEN** cada panel mide W / 2 de ancho y W × 9 / 32 de alto, y la ventana conserva la proporción 32:9

#### Scenario: Tres paneles en horizontal

- **WHEN** hay tres paneles abiertos en horizontal en una ventana de ancho W
- **THEN** cada panel mide W / 3 de ancho y W × 3 / 16 de alto, y la ventana conserva la proporción 48:9

#### Scenario: Dos paneles en vertical

- **WHEN** hay dos paneles abiertos en vertical en una ventana de ancho W
- **THEN** cada panel mide W de ancho y W × 9 / 16 de alto, y la ventana conserva la proporción 16:18

#### Scenario: Tres paneles en vertical

- **WHEN** hay tres paneles abiertos en vertical en una ventana de ancho W
- **THEN** cada panel mide W de ancho y W × 9 / 16 de alto, y la ventana conserva la proporción 16:27

### Requirement: Paneles sin hueco

Con dos o tres paneles, la aplicación SHALL dejarlos juntos, sin ningún hueco entre ellos: en horizontal cada uno mide 1/n del ancho de la ventana y toda su altura, y en vertical cada uno mide el ancho completo de la ventana y 1/n de su altura, de modo que la proporción de la ventana no cambie.

#### Scenario: Medidas con tres paneles en horizontal

- **WHEN** hay tres paneles abiertos en horizontal en una ventana de ancho W y alto H
- **THEN** cada panel mide W / 3 de ancho y H de alto, y entre ellos no queda hueco

#### Scenario: Medidas con tres paneles en vertical

- **WHEN** hay tres paneles abiertos en vertical en una ventana de ancho W y alto H
- **THEN** cada panel mide W de ancho y H / 3 de alto, y entre ellos no queda hueco

#### Scenario: Medidas con dos paneles

- **WHEN** hay dos paneles abiertos en una ventana de ancho W y alto H
- **THEN** en horizontal cada panel mide W / 2 de ancho y H de alto, y en vertical W de ancho y H / 2 de alto, sin hueco entre ambos

### Requirement: Paneles adicionales a demanda

La aplicación SHALL crear el segundo y el tercer panel solo cuando se piden y SHALL liberar por completo cada panel que sobre al volver a menos paneles, empezando por el último, y los paneles que ya estaban abiertos SHALL conservar su tamaño y no refrescarse al hacerlo, siempre que la pantalla permita ese tamaño.

#### Scenario: Abrir el segundo panel

- **WHEN** el usuario elige dos paneles con un partido reproduciéndose en el primero
- **THEN** el primer panel conserva su tamaño y sigue reproduciendo sin recargarse

#### Scenario: Abrir el tercer panel

- **WHEN** el usuario elige tres paneles con dos partidos reproduciéndose
- **THEN** los dos primeros paneles conservan su tamaño y siguen reproduciendo sin recargarse

#### Scenario: Volver a dos paneles

- **WHEN** el usuario elige dos paneles con tres paneles abiertos
- **THEN** el tercer panel se detiene, desaparece y libera sus recursos, y los otros dos siguen igual

#### Scenario: Volver a un panel

- **WHEN** el usuario elige un panel con tres paneles abiertos
- **THEN** el segundo y el tercer panel se detienen, desaparecen y liberan sus recursos

#### Scenario: La pantalla no da para el tamaño

- **WHEN** la ventana con el panel nuevo o con la disposición nueva no cabe en el área útil de la pantalla
- **THEN** la ventana se reduce, conservando su proporción, hasta caber, y es aceptable que los reproductores se ajusten a su nuevo tamaño

### Requirement: Audio por foco

Con dos o tres paneles, la aplicación SHALL dejar sonar solo el panel con foco y SHALL mantener silenciados los demás, aunque la página o el reproductor de esos paneles intente reactivar su audio, y SHALL NOT reactivar el audio de un panel que el usuario silenció desde el reproductor.

#### Scenario: Cambiar el foco

- **WHEN** el usuario hace clic en un panel que estaba silenciado
- **THEN** ese panel suena y los demás quedan silenciados

#### Scenario: Silencio manual

- **WHEN** el usuario silencia el panel con foco desde el reproductor de Prime Video
- **THEN** el panel permanece silenciado hasta que el usuario lo active

#### Scenario: El reproductor reactiva el audio

- **WHEN** el reproductor de un panel sin foco reactiva su propio audio
- **THEN** el panel vuelve a quedar silenciado y no se escucha

#### Scenario: Dos partidos en 32:9

- **WHEN** hay dos paneles reproduciendo partidos distintos en una ventana 32:9
- **THEN** se escucha solo el partido del panel con foco

#### Scenario: Tres partidos

- **WHEN** hay tres paneles reproduciendo partidos distintos
- **THEN** se escucha solo el partido del panel con foco

#### Scenario: Cambiar de disposición

- **WHEN** el usuario cambia entre horizontal y vertical
- **THEN** el panel con foco sigue siendo el mismo y sigue siendo el único que suena

### Requirement: El clic que da el foco no llega al reproductor

Con dos o tres paneles, un clic en un panel sin foco SHALL limitarse a pasarle el foco y el audio, y SHALL NOT entregarse a la página, de modo que no pause ni reanude el video. Desde el siguiente clic, el panel SHALL comportarse como el reproductor lo haga.

#### Scenario: Clic en el panel sin foco

- **WHEN** el usuario hace clic en el video de un panel sin foco
- **THEN** el panel recibe el foco y el audio, y el video no se pausa ni se reanuda

#### Scenario: Clic en el panel con foco

- **WHEN** el usuario hace clic en el video del panel que ya tiene el foco
- **THEN** el clic llega al reproductor y este responde como lo haga normalmente

#### Scenario: Un solo panel

- **WHEN** hay un solo panel abierto
- **THEN** todos los clics llegan al reproductor

### Requirement: Cambio de panel con foco

La aplicación SHALL permitir pasar el foco y el audio al siguiente panel con un atajo de teclado, y después del último SHALL volver al primero.

#### Scenario: Cambiar de panel

- **WHEN** el usuario ejecuta la acción de siguiente panel con dos paneles abiertos
- **THEN** el foco y el audio pasan al otro panel

#### Scenario: Recorrer tres paneles

- **WHEN** el usuario ejecuta la acción de siguiente panel tres veces con tres paneles abiertos
- **THEN** el foco pasa por el segundo, por el tercero y vuelve al primero

### Requirement: Abrir una dirección en el panel con foco

La aplicación SHALL permitir escribir una dirección web y abrirla en el panel con foco.

#### Scenario: Abrir una dirección

- **WHEN** el usuario ejecuta la acción de abrir dirección y confirma una dirección
- **THEN** el panel con foco carga esa dirección y los demás paneles no cambian

### Requirement: Disposición horizontal o vertical

La aplicación SHALL ofrecer dos disposiciones de los paneles: horizontal, con los paneles uno junto al otro, y vertical, con los paneles uno sobre otro, y SHALL abrir siempre en la horizontal. Cambiar de disposición SHALL conservar los mismos paneles, su orden, el foco y lo que cada uno reproduce, sin recargarlos. Con un solo panel, la disposición no cambia nada visible, pero SHALL recordarse para cuando se abran más paneles durante esa ejecución.

#### Scenario: Pasar a vertical

- **WHEN** el usuario elige la disposición vertical con dos paneles abiertos
- **THEN** el primer panel queda arriba y el segundo debajo, y ambos siguen reproduciendo sin recargarse

#### Scenario: Volver a horizontal

- **WHEN** el usuario elige la disposición horizontal con dos paneles en vertical
- **THEN** el primer panel queda a la izquierda y el segundo a la derecha, en el mismo orden

#### Scenario: Elegir la disposición con un solo panel

- **WHEN** el usuario elige la disposición vertical con un solo panel y después abre un segundo
- **THEN** el segundo panel aparece debajo del primero

#### Scenario: Apertura de la aplicación

- **WHEN** el usuario abre la aplicación
- **THEN** hay un panel y la disposición es la horizontal, sin importar cuál se usó la vez anterior
