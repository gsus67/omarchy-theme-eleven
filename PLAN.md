# Primera entrega: Inicio, iconos y explorador

Orden de prioridad confirmado por el propietario: **Inicio → iconos → explorador de archivos**.

Arquitectura aceptada después: **un único plugin** aplica el tema y el menú. Tool lo activa/desactiva sin borrarlo. Apagado conserva código, recursos originales y preferencias internas; se restauran los efectos aplicados. La desinstalación nativa elimina el plugin y completa la retirada incluso si ya estaba apagado.

## Inicio

- Distribución inspirada en Windows 11: búsqueda superior, cuadrícula de aplicaciones ancladas, acceso a todas las aplicaciones y pie con usuario y controles de sesión.
- Usar `shell.appLibrary` para filtrar y lanzar las aplicaciones existentes. Respetar las aplicaciones ocultas y no ejecutar texto de búsqueda como comandos.
- Usar el panel nativo para foco, Escape, cierre al pulsar fuera, ajuste a la pantalla y varios monitores.
- Mantener la barra superior encima del menú; no mover las barras. Usar el anclaje de la barra existente sin moverla.
- No sustituir los menús de selección internos de Omarchy ni romper sus atajos y utilidades.
- Crear los elementos visuales al abrir cuando sea posible. Sin sondeos periódicos, indexador nuevo, red ni registro de documentos recientes.
- Si hace falta un complemento, su activación y retirada deben probarse antes de tocar la configuración real. No dejar dos botones de Inicio ni perder el acceso al menú nativo.

## Iconos

- Reutilizar iconos de aplicaciones y un tema ya instalado; comprobar la disponibilidad antes de aplicar una selección.
- Incorporar solo recursos adicionales necesarios para Inicio y la navegación. No descargar un paquete completo para unos pocos símbolos.
- Guardar autoría, licencia completa, URL, revisión fija y SHA-256 de cada recurso incorporado. No extraer iconos ni fuentes de una instalación de Windows.
- Incluir alternativas cuando un icono no exista.

## Explorador

- Mantener Nautilus: no instalar otro explorador, extensiones paralelas ni parches a sus binarios.
- Comprobar colores claros, selección, contraste, iconos y navegación con las capacidades disponibles de GTK/libadwaita. No prometer una distribución de Windows que un tema nativo no puede reproducir.
- «Este equipo» pertenece a la función reversible «Discos en mosaicos» de Tool. El tema no monta discos, cambia permisos ni instala esa extensión por su cuenta.
- No cerrar Nautilus automáticamente: puede tener operaciones de archivos en curso. Si necesita reabrirse, indicarlo al usuario.

## Antes de considerar esta entrega terminada

- Verificación visual real de Inicio y Nautilus, incluyendo teclado y tamaños de pantalla.
- Activar, desactivar, volver a activar y desinstalar sin dejar cambios propios. Conservar configuraciones y cambios ajenos; comprobar también una operación interrumpida.
- Instrucciones de instalación nativa y retirada verificadas contra la versión de Omarchy soportada. Sin instalación de dependencias ni privilegios añadidos.
- Acciones de CI con permisos mínimos y referencias fijadas, sin secretos en trabajos que procesen contribuciones externas.
- Documentación local actualizada para que Claude u otro colaborador pueda continuar sin inferir qué está terminado.

## Fuera del alcance inicial

Widgets nuevos, reemplazo de Taskbar, nuevos servicios, sustitución de aplicaciones, modificación de asociaciones de archivos y nuevas funciones de Tool. El fondo y la paleta ya preparados son la base visual, no la prioridad de desarrollo.
