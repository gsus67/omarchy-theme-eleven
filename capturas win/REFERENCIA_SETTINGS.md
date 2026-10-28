# Guía de las capturas de Configuración de Windows

Esta guía resume lo que se ve en las imágenes de esta carpeta para poder
consultarlas sin volver a abrir cada captura. En las imágenes compuestas, la
referencia es únicamente la ventana de Configuración de Windows; los paneles de
Omarchy, el editor, la terminal y el texto del proyecto que aparecen alrededor
son contexto de la captura, no parte del diseño que se quiere reproducir.

## Capturas

| Archivo | Página | Elementos visibles que sirven de referencia |
|---|---|---|
| `Pasted image.png` | Bluetooth y dispositivos | Lista de impresoras, teléfono/dispositivos móviles, cámaras, mouse, teclado, lápiz y Windows Ink, reproducción automática y USB. Cada fila combina nombre, descripción breve y acceso a detalles. |
| `Pasted image (2).png` | Red e Internet | Resumen de Ethernet, VPN, proxy y acceso telefónico; accesos a Ethernet, VPN, zona móvil, proxy, acceso telefónico y opciones avanzadas de red. |
| `Pasted image (3).png` | Personalización *(compuesta)* | Vista previa de personalización y accesos de apariencia, incluidos fondo, colores, temas y pantalla de bloqueo. Ignorar el editor y el texto de desarrollo visibles fuera de Windows. |
| `Pasted image (4).png` | Aplicaciones | Aplicaciones instaladas, configuración avanzada, aplicaciones predeterminadas, mapas sin conexión, aplicaciones para sitios web y reproducción de vídeo. |
| `Pasted image (5).png` | Cuentas | Encabezado de cuenta Microsoft y accesos a información personal, opciones de inicio de sesión, otros usuarios, acceso laboral o educativo, correo y cuentas, familia y respaldo. Es contenido específico de Windows/Microsoft. |
| `Pasted image (6).png` | Hora e idioma | Resumen de fecha, hora y zona horaria; filas para Fecha y hora, Idioma y región, Escritura y Voz. |
| `Pasted image (7).png` | Juegos | Página sencilla con Xbox Game Bar, Capturas y Modo de juego. |
| `Pasted image (8).png` | Accesibilidad | Grupos de visión, audición e interacción. Se alcanzan a ver tamaño de texto, efectos visuales, puntero y tacto, cursor de texto y lupa; la página continúa con más opciones. |
| `Pasted image (9).png` | Privacidad y seguridad | Secciones de Seguridad y Permisos de Windows; accesos a Seguridad de Windows, encontrar el dispositivo, cifrado y controles de recomendaciones, voz, escritura y diagnósticos. |
| `Pasted image (10).png` | Windows Update *(compuesta)* | Estado de actualizaciones pausadas, acción para reanudarlas, opción de recibir antes las novedades, pausar actualizaciones e historial. El texto de terminal/editor que rodea la ventana no forma parte de la referencia. |
| `Pasted image (11).png` | Sistema → Pantalla *(compuesta)* | Brillo/color, luz nocturna, HDR y escala/disposición. La captura indica que algunos ajustes de pantalla no se pueden cambiar desde una sesión remota. |
| `Pasted image (12).png` | Sistema → Sonido *(compuesta)* | Dispositivo de salida, volumen, dispositivo predeterminado, entrada y opciones avanzadas de sonido. La captura contiene ventanas superpuestas; usar solo el panel de Configuración como guía. |
| `Pasted image (13).png` | Bluetooth y dispositivos → Mouse | Botón principal, velocidad del puntero, precisión mejorada, desplazamiento, dirección y desplazamiento sobre ventanas inactivas; enlace relacionado con puntero y tacto. |
| `Pasted image (14).png` | Bluetooth y dispositivos → Teclado | Retardo y velocidad de repetición con controles deslizantes y área de prueba; tecla Copilot, comportamiento de Imprimir pantalla y enlaces relacionados con escritura/accesibilidad. |
| `Pasted image (15).png` | Red e Internet → Ethernet *(compuesta)* | Perfil de red público/privado, enlace a seguridad/firewall, autenticación y propiedades de Ethernet como IP, DNS y conexión de uso medido. |
| `Pasted image (16).png` | Red e Internet → VPN | Agregar VPN, configuración avanzada, dos opciones para permitir VPN en redes medidas o durante roaming y enlaces de ayuda. |
| `Pasted image (17).png` | Red e Internet → Configuración de red avanzada | Adaptadores y su estado, acciones para habilitarlos/deshabilitarlos, opciones de uso compartido, consumo de datos, propiedades de hardware/conexión y restablecimiento de red. |

## Patrones visuales compartidos

- Ventana de aplicación propia: navegación persistente a la izquierda y página
  de contenido a la derecha, con controles de ventana en la parte superior.
- La navegación agrupa páginas por categorías. La página activa se distingue
  claramente del resto.
- Cada página tiene un título grande, a veces una explicación breve, y agrupa
  controles relacionados bajo subtítulos.
- Las filas de acceso suelen mostrar título y descripción; el chevrón indica
  que abre otra página. Los ajustes directos usan el control apropiado, como
  selector, deslizador o interruptor.
- El contenido puede exceder la altura disponible y desplazarse; no se debe
  intentar comprimir una página larga en una sola pantalla.

## Cómo aplicar la referencia en Eleven

Las imágenes orientan la estructura y jerarquía visual. Los controles que se
ofrezcan deben corresponder a funciones que realmente existen en Omarchy/Linux
y a herramientas disponibles en el equipo. No representar ajustes de Windows
como si funcionaran en Linux: Cuenta Microsoft, Windows Update y Seguridad de
Windows, por ejemplo, no son páginas transferibles. Las categorías sin una
acción Linux real deben omitirse o presentarse solo cuando exista una
integración nativa concreta.

Para las páginas existentes de Eleven, tomar como referencia Sistema
(pantalla y sonido), Bluetooth y dispositivos (mouse/teclado solo si hay una
acción local real), Red e Internet, y Personalización. Conservar la navegación
lateral y el formato de ventana; usar las filas para abrir herramientas
nativas, y mostrar controles directos únicamente cuando puedan leer y cambiar
el estado real del sistema.

## Nota sobre el origen

Las capturas son referencias locales aportadas para esta implementación. La
guía describe su contenido y patrones de interfaz; no incluye recursos de
Windows ni propone redistribuir iconos, logotipos o activos de Microsoft.
