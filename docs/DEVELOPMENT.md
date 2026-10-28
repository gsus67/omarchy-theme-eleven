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
- El manifiesto declara `menu`: Omarchy solo entrega la capacidad AppLibrary
  a los plugins que declaran ese tipo. MenuBridge conserva el summon nativo.
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
