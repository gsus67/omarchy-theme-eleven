# Traspaso local de Eleven

## Alcance aceptado

Primero Inicio, iconos y explorador. Un único plugin gestiona tema e Inicio;
Tool lo puede activar y apagar. Apagar no desinstala ni borra sus preferencias.
No añadir paquetes, servicios de sistema, otro explorador ni cambios a Taskbar.

## Implementado

- Tema declarativo, fondo original y selección de iconos existentes.
- Inicio QML con búsqueda, anclados, lista completa, carpetas y acceso a los
  controles de sesión de Omarchy. Usa la API compartida `shell.appLibrary`.
- El catálogo nativo devuelve filas `{entry, score, ...}`: StartContent extrae
  `row.entry`. No tratar esas filas como si fueran DesktopEntry directamente.
- El catálogo usa la AppLibrary nativa cuando está disponible y mantiene un
  respaldo con `DesktopEntries`. El plugin evita declarar el tipo `menu` para
  que Omarchy enrute Inicio a la copia del widget del monitor enfocado.
- Un componente de ciclo de vida de Quickshell aplica/restaura mediante un
  recibo, hashes y cambios individuales. Sin código de fondo fuera de la shell.
- Preferencias ignoradas por Git dentro de `.eleven/`, para que eliminar un
  plugin ya apagado no dependa de ejecutar código después de su eliminación.
- Limpiador temporal fuera de la carpeta únicamente mientras está activo,
  para soportar la eliminación de un plugin activo por el gestor nativo.
- No se restauran valores GNOME si cambiaron después. Los valores antes no
  definidos se restablecen con `reset`. No se restaura una copia completa de
  shell.json ni se borran directorios compartidos.

## Verificación realizada antes de instalar

- 20 pruebas Python/JavaScript: ciclo completo, reactivación, retirada activa
  y apagada, interrupción, preferencias y cambios ajenos, enlaces y colisiones.
- 8 resultados correctos de Qt Quick Test, incluidos inicio/fin de suite:
  búsqueda real con teclado, Enter, Escape, selección, vacío y tamaño estrecho.
- Render real con el catálogo AppLibrary instalado: 62 aplicaciones cargadas
  y captura `build/start-preview.png`. Las primeras pruebas detectaron y
  corrigieron la diferencia entre filas del catálogo y DesktopEntry.
- Renderizado/restauración nativos con bubblewrap y HOME real oculto mediante
  un montaje, sin modificar la variable HOME, sin red ni sesión D-Bus.
- Compilación de los componentes con las API reales de Omarchy/Wayland, sin
  instanciar el servicio ni aplicar el tema. Manifiesto validado por Omarchy.
- CI preparada con referencias fijadas, pruebas de comportamiento, CodeQL y
  zizmor. No se ha publicado el repositorio ni ejecutado esas acciones remotas.

## Verificación en la sesión real

- Instalación con `omarchy plugin add` desde el clon local, inicialmente apagado.
- Activación y desactivación mediante `omarchy-tool plugins on/off`, la misma
  ruta del interruptor de Tool. Estado IPC confirma 62 aplicaciones y contenido
  cargado. Captura real acotada al menú en `build/start-native.png`.
- Al apagar: igualdad semántica exacta de shell.json con el estado anterior,
  tema Tokyo Night y enlace del fondo restaurados, valores GNOME efectivos y
  explícitos idénticos. SHA-256 de anclados de Taskbar sin cambios. Plugin retenido.
- Se guardaron dos anclados de prueba, se volvió a activar y apagar y se
  confirmó su conservación. Después se desinstaló apagado: sin carpeta de plugin,
  tema temporal, recibo ni limpiador. Los anclados de prueba se retiraron con él.
- Se reinstaló, activó y desinstaló activo con el gestor nativo. El limpiador
  sobrevivió a la eliminación de la carpeta, restauró exactamente el estado
  previo y se retiró a sí mismo y a sus archivos temporales.
- No se cerró Nautilus ni se reiniciaron aplicaciones. No se instalaron paquetes,
  se solicitaron privilegios del sistema ni se modificó la máquina del primo.
- Tras estas pruebas se deja un clon nuevo instalado **apagado**, con las
  preferencias iniciales, para revisión desde Tool → Plugins → Eleven.

La barra no cambia de posición ni de preferencia de transparencia. Se mantiene
la distribución de Nautilus; el cambio actual del explorador es modo claro e
iconos. Queda pendiente que el propietario revise la apariencia y señale los
ajustes visuales que desea para acercarla más a Windows 11.

El propietario autorizó después publicar el repositorio y un release. No
modificar otra máquina sin una instrucción correspondiente. Al publicar: rama, PR y todos
los controles verdes antes de main, tal como pidió para Taskbar.

## Ventana de Configuración Eleven

Inicio abre una ventana propia de Quickshell (`start/SettingsWindow.qml`) con
barra de título, minimizar/maximizar/cerrar, navegación lateral, búsqueda global
y tarjetas inspiradas en Configuración de Windows 11. El servicio persistente
del plugin mantiene una sola ventana y un único destino IPC; las copias por
monitor del widget ya no registran handlers repetidos. La ventana usa tamaño
declarativo y se centra con dispatchers efímeros de Hyprland; no se escribe una
regla permanente en la configuración del usuario.
`SettingsContent.qml`
define las secciones Sistema, Bluetooth y dispositivos, Red, Personalización,
Aplicaciones y Seguridad. Las filas usan paneles nativos o herramientas ya
instaladas: editores de la configuración personal, audio, Bluetooth y Wi-Fi,
selectores de tema/fondo y opciones de pantalla, atajos, barra, salvapantallas,
terminal predeterminada, SSH e información de Omarchy. Se omitieron enlaces a
`omarchy.menu` porque ese complemento está desactivado en la máquina de desarrollo;
también se omitieron ajustes que instalan paquetes o requieren permisos elevados.
La navegación lateral y las tarjetas son botones accesibles con teclado. No se
añaden dependencias ni se invoca sudo. La paleta respeta el modo claro/oscuro
existente. Los SVG de ajustes/persona son activos Fluent ya incluidos con MIT.
Esta implementación está en la rama `feat/light-dark-backgrounds`; requiere las
comprobaciones remotas antes de integrarse en `main`. No crear un release hasta
completar esa revisión.
Resultado local: 42 pruebas Python, 20 Qt Quick Test, compilación de entradas
contra la sesión de Omarchy, render nativo aislado, validación del plugin y
`git diff --check` pasan. `qmllint` acaba con avisos heredados de `Start.qml`
por imports de Omarchy que no puede resolver fuera del entorno completo; los
dos archivos nuevos de Configuración no generan avisos.

Las capturas de referencia aportadas para Configuración de Windows están
inventariadas y resumidas en [`capturas win/REFERENCIA_SETTINGS.md`](../capturas%20win/REFERENCIA_SETTINGS.md).

## Corrección posterior: conservar Inicio en la barra

El propietario observó que Inicio desaparecía. Causa confirmada: Start.qml
no exponía implicitWidth/implicitHeight; el host le asignaba ancho cero. La
apertura por IPC había ocultado ese fallo en la validación inicial.

Se enlazan ambas dimensiones al botón y se conserva el WidgetButton nativo:
glifo instalado de Omarchy, fuente existente, márgenes y clic derecho de
terminal. El clic izquierdo abre Eleven. La prueba con los tipos reales ahora
instancia el widget (sin activar el servicio) y exige dimensiones positivas.
No modificar la distribución de la barra para nuevos ajustes del menú.

Validado en la sesión tras recargar la shell: botón de 24,75×40 píxeles,
62 aplicaciones y apertura correcta del panel. El propietario pidió conservar
ese símbolo de Omarchy en azul (#0067c0); únicamente se fija su foreground.
La prueba volvió a dejar Eleven apagado y restauró la barra anterior.

Ajuste solicitado después: el símbolo usa #0078D4, azul primario de Microsoft
Fluent, en lugar del azul de acento anterior #0067C0. Referencia primaria:
https://microsoft.github.io/fluentui-design-tokens/ (Global-Color-Blue-Primary).
El cambio se limita al símbolo de Inicio; no modifica la paleta del tema.

Ajuste visual siguiente: el propietario pidió un botón Inicio más grande,
con proporciones más próximas a Windows. Ancho horizontal de 48 píxeles;
altura igual a la barra existente. Glifo de hasta 32 píxeles de fuente,
limitado por la altura de la barra; conserva el símbolo y azul #0078D4.
La variante vertical intercambia las dimensiones, sin mover la barra.

Ajuste fino posterior: reducir ligeramente a 44 píxeles de área de clic
y hasta 28 píxeles de fuente, manteniendo el símbolo, azul y posición.

## Menú detallado y atajos compatibles

Se tomó como referencia visual la VM Windows del propietario, dejada abierta
por él. Las capturas de Windows solo se guardan en /tmp, no se redistribuyen.
La versión revisada añade búsqueda redondeada, recomendaciones en dos columnas,
categorías con vistas previas de aplicaciones, avatar y desplegable de energía
con todas las opciones nativas (suspender/hibernar según disponibilidad).

14 iconos Fluent oficiales, MIT, unos 12 KB; licencia, NOTICE y hashes de origen
y recoloreado en assets/fluent. Los logotipos de aplicaciones siguen siendo los
instalados; no se extraen recursos de Windows ni se instalan paquetes.

Atajos: Lua nativo en tiempo de ejecución, sin tocar ~/.config/hypr. Se omiten
combinaciones existentes, físicas ambiguas y catch-all. El protocolo de retiro
comprueba claves compartidas antes de unbind: Hyprland 0.56.2 elimina todas las
entradas con una misma combinación, incluso con un handle. Si otro usuario
añadió esa combinación después, solo se deshabilita nuestra referencia. No hay
oyentes de todas las teclas ni grabación. Tras configreloaded se reconcilian.

Pruebas nuevas incluyen categorías, clic real de encendido, siete opciones
filtradas, Escape del desplegable, licencias/hashes SVG y conflictos de atajos.
La suite de Qt ahora hace visible TestCase y fija su ventana a 640×726 para
que las pruebas de ratón alcancen el pie real. No se apaga, reinicia ni bloquea
la máquina durante las pruebas.

La primera recarga con el plugin ya activo dejó el widget con un proxy antiguo
del catálogo: funcionaba después de apagar/encender, pero no era fiable al
iniciar la shell. Se comparte ahora la capacidad AppLibrary desde el servicio
propio mediante Session.qml, siguiendo las actualizaciones del host, sin otro
catálogo ni sondeo. El hover de energía tiene fondo suave y tooltip claro como
la referencia. Las pruebas incluyen ratón real sobre el botón y el tooltip.

Corrección definitiva de la dependencia del catálogo: Omarchy puede revocar
también la fachada del servicio y dejar su API a null durante una actualización
del registro. AppCatalog.qml mantiene la interfaz estable usando el singleton
DesktopEntries existente, el AppSearch.js instalado y el helper de ocultación
nativo cuando esa fachada no existe. No crea otro AppLibrary ni otro escáner
de iconos; solo reacciona a cambios del registro. Se probó contra el sistema
real con la fachada ausente. El widget usa este adaptador estable del servicio.

Validación final aplicada: el catálogo permanece disponible después de
reiniciar y de recargar el registro de plugins, incluso con bar.shell revocado.
Se conservaron por comparación los 231 bindings previos. Se registraron solo
Super izquierda/derecha, Ctrl+Esc, Win+R y Win+I; Win+E, Win+S y Win+L se
omitieron por sus asignaciones existentes. Retirada real al apagar: vuelven
exactamente los 231 bindings, sin entradas de Eleven.

31 pruebas Python/JS/Lua y 12 resultados Qt Quick Test correctos. La simulación
de pulsaciones por wtype no validó de forma fiable el modificador solo en esta
sesión; no afirmar que equivale a una prueba física del teclado. El propietario
puede probar la tecla Windows con Eleven activo. No se ejecutó ninguna acción
de apagar, reiniciar, suspender ni cerrar sesión.

Preparación de v0.1.0: el registro pasó de 62 a 63 aplicaciones durante la
comprobación, lo cual es un cambio legítimo. No usar un número fijo para probar
estabilidad: comprobar disponibilidad y respeto de filtros, no una cantidad
inmutable. Se autoriza publicación con rama, PR y todo verde antes de main.


### Variante oscura mediante el selector nativo (rama local)

`Ctrl+Super+Espacio` conserva su binding nativo `omarchy-menu toggle background`.
Los dos PNG propios se preparan en backgrounds del tema administrado. Un
FileView del directorio current con preload=false observa solo cambios de
metadatos (incluida sustitución del enlace background). Tras un debounce de
150 ms ejecuta sync-background; no carga el PNG, no sondea ni añade un daemon.
La operación exige plugin habilitado, recibo activo, tema administrado actual
y ruta resuelta idéntica a uno de sus dos fondos. Un fondo ajeno no cambia modo.

El modo modifica la misma paleta administrada usando variants/dark cuando
corresponde; el renderizado nativo sigue en headless, sin hooks, privilegios ni
reinicios de aplicaciones. Session.mode y Appearance adaptan Inicio sin
recrear el catálogo. Variantes Fluent claras para contraste oscuro mantienen
licencia, geometría, procedencia y hashes. Las preferencias se fusionan para
no perder anclados al guardar modo ni modo al guardar anclados.

El recibo conserva la apariencia ORIGINAL anterior a la activación durante
todos los cambios de modo. pendingMode/pendingAssets permiten recuperar una
interrupción; un error de aplicación intenta volver al modo anterior. Al
limpiar se eliminan solo recursos con hashes propios. No cargar controladores
ni instalar paquetes para esta función. No publicada como nuevo release.


La prueba real detectó que guardar appearanceMode dentro del clon en cada
aviso disparaba el observador de código nativo. Se evita toda escritura
innecesaria y el modo activo permanece en el recibo; se guarda en preferencias
al DESACTIVAR, cuando el plugin ya está apagado. Así los cambios entre fondos
no recargan el widget ni el catálogo. Si el proceso se reinicia, el modo se
recupera del recibo. No confundir un rescan con invalidar la caché de QML:
durante desarrollo fue necesario un reinicio nativo de shell para cargar
las nuevas definiciones, conservando aplicaciones y anclajes.


Icono Files solicitado en Inicio Y Taskbar inferior: se incorpora sin alterar
el SVG oficial Document Folder 24 color de la misma revisión Fluent MIT. Inicio
lo usa directamente; para Taskbar se prepara un solo SVG bajo
~/.local/share/icons/eleven-managed/scalable/apps/org.gnome.Nautilus.svg,
que su índice nativo ya prioriza. Propietario: fileIconHash en recibo; rechazar
colisiones/enlaces y conservar ediciones ajenas. Retirar solo archivo propio y
padres vacíos del contenedor. rescanPlugins nativo una vez al añadir/retirar
recrea índices/widgets; no se ejecuta al alternar claro/oscuro. No cambios de
Taskbar, lanzadores, asociaciones, paquetes ni cachés compartidas.


Corrección de preferencia del propietario: prefiere el icono de las carpetas
existentes al Fluent Document Folder a color. Este último se RETIRÓ del árbol.
Inicio resuelve folder con el catálogo nativo; Taskbar reutiliza el PNG local
de Yaru-blue incrustado sin enlaces externos en un SVG autocontenido (necesario
por su índice SVG-first); alternativa SVG Adwaita si Yaru-blue no existe. No
se redistribuyen esos recursos ni se cambian sus licencias. El recibo y la
retirada del único icono aplicado siguen igual. No confundir propuesta de
Document Folder con el resultado final elegido por el propietario.


Corrección de esquinas solicitada: Rectangle.clip es rectangular y no recorta
sus hijos al radio del fondo. El pie ahora usa bottomLeftRadius/bottomRightRadius
8 y topLeftRadius/topRightRadius 0; sus márgenes de 1 px conservan el borde.
El KeyboardPanel nativo toma su radio de Style.cornerRadius/Hyprland: Eleven
aplica decoration.rounding=8 en tiempo de ejecución mediante hl.config,
registrando previousRounding en recibo y restaurándolo al apagar si sigue en 8.
Un valor distinto posterior se conserva. La restauración cubre también un
fallo antes de aplicar el tema. No edita ~/.config/hypr ni usa máscaras/blur.
La rama de iconos superiores sigue en investigación: una paleta no sustituye
los glifos de los widgets. El clon nativo con omarchy.clonedFrom conserva
capacidades de OSD/WiFiQR/Speedtest; una sustitución genérica bajo el mismo id
de Eleven perdería esas capacidades. Pendiente decisión del propietario sobre
variantes auxiliares visibles en Tool frente a conservar una sola entrada.
