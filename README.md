# Eleven para Omarchy

Plugin que aplica un tema claro inspirado en Windows 11 y un menú Inicio, reutilizando Omarchy, Quickshell, Nautilus, fuentes e iconos instalados. Sin paquetes adicionales, privilegios elevados, servicios de sistema ni otro proceso residente.

## Activar y desactivar desde Tool

El plugin aparece como **Eleven** en Tool → Plugins. Su interruptor activa o desactiva la experiencia completa.

- **Activar:** registra temporalmente la paleta, aplica la apariencia clara, el fondo y los iconos disponibles, y sustituye únicamente el botón del menú nativo por Inicio. Conserva el resto de la barra y la posición de ambas barras.
- **Desactivar:** restaura el tema, el fondo, los ajustes individuales y el botón anteriores cuando todavía pertenecen a Eleven. El plugin, su código, sus recursos originales y tus anclados se conservan.
- **Reactivar:** vuelve a aplicar Eleven conservando tus preferencias.
- **Desinstalar:** el gestor nativo borra el plugin y sus preferencias. Si estaba activo, un limpiador temporal restaura sus efectos aunque la carpeta ya haya desaparecido. Si estaba apagado, ya no hay efectos aplicados ni limpiador fuera del plugin.

Las preferencias de Inicio están dentro de `.eleven/preferences.json`, ignorado por Git. No se modifican los anclados de Taskbar. Los archivos de usuario modificados después no se borran ni se sustituyen por una copia antigua.

## Menú Inicio

Distribución ajustada al Windows que mostró el propietario: búsqueda redondeada con lupa, anclados, recomendaciones en dos columnas, categorías de aplicaciones y pie con avatar y encendido. El desplegable de energía contiene todas las acciones nativas de Omarchy; suspensión e hibernación aparecen solo cuando están disponibles. Anclar/desanclar usa el clic derecho y el catálogo sigue siendo el de Omarchy. Escape, flechas, Enter y Tab usan los controles Qt y el panel nativo. No registra documentos recientes ni usa otro indexador.

El botón conserva el icono nativo de Omarchy en azul (`#0078d4`), un área de clic de 44 píxeles y un símbolo más grande, además del clic derecho para abrir la terminal; solo cambia el menú que abre al pulsarlo. Los iconos de aplicaciones son los instalados. Inicio se despliega debajo de la barra superior, con la barra encima; el panel nativo adapta el anclaje si la barra está en otra posición. No sustituye los menús internos de selección de Omarchy.

## Explorador y barras

Nautilus sigue siendo el explorador. Esta etapa aplica el modo claro y los iconos mediante los ajustes GNOME existentes; no parchea GTK ni instala otro explorador. «Este equipo» se reutiliza desde «Discos en mosaicos» de Tool, sin activarlo ni duplicar su extensión desde Eleven.

Taskbar hereda el estilo de la barra nativa. Este proyecto no modifica su código, sus anclados ni sus opciones. Se conservan las posiciones y la preferencia de transparencia; no se reemplaza ninguna barra.

## Instalación

Instala el plugin con el gestor nativo de Omarchy. Queda apagado para poder activarlo desde Tool:

```sh
omarchy plugin add https://github.com/gsus67/omarchy-theme-eleven.git
```

Después se maneja desde Tool o con:

```sh
omarchy plugin enable io.github.gsus67.omarchy-theme-eleven
omarchy plugin disable io.github.gsus67.omarchy-theme-eleven
omarchy plugin remove io.github.gsus67.omarchy-theme-eleven
```

No hace falta instalar el tema por separado. También se puede usar una ruta a un clon local con `omarchy plugin add <ruta>`.

## Cómo aplica el tema sin privilegios

Usa el renderizado nativo de Omarchy con `OMARCHY_THEME_HEADLESS=1` y `OMARCHY_THEME_SKIP_BACKGROUND=1`, y aplica la presentación con su IPC y los ajustes GNOME del usuario. Esto evita los pasos generales de cambio de tema que pueden modificar políticas del navegador, descargar integraciones, ejecutar hooks del usuario o reiniciar aplicaciones. No cambia `/usr/share/omarchy`, reglas de privilegios, montajes ni asociaciones MIME.

La copia temporal del tema es `~/.config/omarchy/themes/eleven-managed`; el recibo y limpiador existen en `~/.local/state/omarchy-theme-eleven` mientras está activo. Al apagar se retiran esas copias aplicadas y se mantienen los originales dentro del plugin. La limpieza usa un inventario de archivos y sus hashes y no sigue enlaces a recursos ajenos. Los ajustes GNOME previamente no definidos se restauran con `reset`, sin dejar nuevos valores explícitos.

La integración está desarrollada contra Omarchy 4.0.6. Si no puede registrar la apariencia anterior o la versión carece del renderizado seguro, cancela la activación. Los componentes QML se ejecutan en el mismo proceso de la shell, como cualquier plugin de Omarchy.

## Estado y comprobaciones

El menú está implementado y renderizado con el catálogo real de aplicaciones; existen pruebas de comportamiento y de limpieza. La comprobación nativa del tema se ejecuta con la carpeta personal real oculta en bubblewrap, sin acceso a la sesión ni a la red. Véase [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) para el estado de la instalación y el traspaso a Claude.

```sh
python3 scripts/check_theme.py
python3 -m unittest discover -s tests -v
QT_QPA_PLATFORM=offscreen QT_QPA_PLATFORMTHEME= QT_QUICK_CONTROLS_STYLE=Basic QT_QUICK_BACKEND=software /usr/lib/qt6/bin/qmltestrunner -input tests/qml
python3 scripts/check_native_theme.py
python3 scripts/check_host_qml.py
```

Una vista previa independiente permite revisar Inicio sin activar el plugin ni cambiar el tema:

```sh
python3 scripts/preview_start.py
python3 scripts/preview_start.py --capture build/start-preview.png
```

En esa vista previa, los cambios de anclados solo duran hasta cerrarla. Los accesos a carpetas y sesión no ejecutan acciones; las aplicaciones sí pueden abrirse mediante el catálogo nativo al pulsarlas.

## Licencia

Código, paleta y fondo originales bajo [MIT](LICENSE). Los iconos de aplicaciones y las fuentes se reutilizan del sistema. Para los controles del menú se incluyen 14 SVG de Fluent System Icons de Microsoft, unos 12 KB en total, bajo MIT; su [licencia](assets/fluent/LICENSE), [avisos](assets/fluent/NOTICE) y [procedencia con revisión fija y hashes](assets/fluent/sources.json) se conservan en el repositorio. No contiene recursos extraídos de Windows, fuentes propietarias ni logotipos de Microsoft y no está afiliado a Microsoft. Los SVG solo se han recoloreado; no se han extraído iconos ni fuentes de Windows.

## Atajos compatibles

Mientras Eleven está activo, registra en tiempo de ejecución únicamente las
combinaciones libres: Windows/Super izquierda o derecha para Inicio, Ctrl+Esc,
Win+E (explorador), Win+R (aplicaciones), Win+I (configuración), Win+S (búsqueda)
y Win+L (bloquear). Las ocupadas se omiten: en la máquina de desarrollo Win+E
ya abre archivos y Win+L cambia la distribución, y ambos se conservan.

No modifica los archivos de Hyprland ni registra pulsaciones. Usa bindings
nativos; tras una recarga de configuración vuelve a comprobar los conflictos.
Al apagar o desinstalar retira sus referencias. Si el usuario añade después
otra acción con la misma combinación, se desactiva únicamente el handle propio
para conservar la nueva; ese registro inerte desaparece en la siguiente
recarga del compositor. No se ejecutan comandos de apagado durante las pruebas.

## Versión y compatibilidad

La primera versión es v0.1.0. Probada en Omarchy 4.0.6, Hyprland 0.56.2 y
Quickshell/Qt 6.12. La apariencia se inspira en la VM Windows del propietario;
las aplicaciones y las funciones de Linux siguen siendo las instaladas.

Los archivos temporales de la apariencia solo existen mientras está activo.
Al desinstalar se pierden las preferencias internas de Inicio, como ocurre
con los datos propios del plugin. Los archivos que el usuario haya modificado
después se conservan. No se incluye ningún recurso propietario de Windows.
