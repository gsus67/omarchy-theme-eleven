# Instrucciones para colaboradores

Leer primero README.md y PLAN.md. Estas instrucciones también sirven como traspaso local para Claude.

- Prioridad actual: menú Inicio, iconos y explorador. La referencia visual es el Windows del propietario: búsqueda redondeada, anclados, recomendaciones, categorías, avatar y menú de energía. Atajos Windows solo si no chocan; nunca sustituir los existentes. No ampliar el alcance sin indicación del propietario.
- Un único plugin gestiona tema e Inicio. Tool solo cambia su activación; no borra el plugin. Al apagar se restauran efectos y se conservan las preferencias dentro del plugin. Al desinstalar se retira también esa carpeta. No afirmar que está instalado o terminado sin comprobarlo.
- Reutilizar componentes existentes de Omarchy. No añadir dependencias, paquetes, procesos residentes ni permisos elevados.
- Conservar el botón Inicio visible en su sitio, con el icono nativo de Omarchy en azul (#0078d4) y el clic derecho nativo. Su contenedor debe declarar implicitWidth e implicitHeight; no validar solo la apertura por IPC. Priorizar ahora la apariencia del menú.
- No modificar la Taskbar del propietario. Solo hereda los colores y dimensiones de la barra nativa; mantener las posiciones de ambas barras.
- No editar `/usr/share/omarchy`. Leer su código para verificar las API disponibles, sin asumir que las de otra versión coinciden.
- No instalar o aplicar un prototipo al escritorio mientras sus efectos y retirada no estén comprobados. No cerrar Nautilus ni reiniciar aplicaciones con trabajo del usuario.
- Cada cambio persistente debe tener propietario, alcance y retirada precisos. No borrar cachés compartidas ni restaurar configuraciones completas sobre cambios del usuario.
- No copiar recursos propietarios de Windows. Para recursos externos, incluir licencia y procedencia verificable antes de incorporarlos.
- Mantener las instrucciones de instalación ajustadas al estado real: no documentar comandos de un complemento inexistente.
- Ejecutar `python3 scripts/check_theme.py` después de cambiar la base visual. Añadir pruebas de comportamiento cuando se implemente la integración de Inicio y su limpieza.
- No publicar, desplegar, crear mensajes a terceros o modificar otra máquina a partir de este trabajo sin autorización correspondiente.
