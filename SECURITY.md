# Seguridad

El plugin contiene recursos declarativos, menú QML y un componente de ciclo de vida dentro del Quickshell existente. El controlador usa la biblioteca estándar de Python y comandos ya presentes de Omarchy/GNOME. No añade un servicio de sistema ni un proceso residente.

Los cambios de integración deben conservar el modelo de permisos del usuario y limitar sus escrituras a los archivos propios necesarios. Ningún componente debe descargar y ejecutar código, abrir servicios de red, modificar permisos de discos ni solicitar privilegios elevados.

Las revisiones deben comprobar la retirada de efectos al desactivar y desinstalar, las operaciones interrumpidas y la conservación de cambios ajenos. Validar recursos no equivale a demostrar ausencia de vulnerabilidades.

Las acciones de GitHub tienen referencias fijadas, credenciales de checkout desactivadas y permisos de lectura por defecto. Solo CodeQL solicita escritura de resultados de seguridad. Su ejecución remota quedará por comprobar cuando exista un repositorio publicado con esas funciones habilitadas.

Si se descubre un problema, evitar publicar datos personales, configuraciones privadas o detalles explotables en una incidencia pública. Usar el formulario de aviso privado de GitHub Security Advisories cuando esté disponible: https://github.com/gsus67/omarchy-theme-eleven/security/advisories/new. Si no lo está, publicar únicamente una solicitud de contacto sin detalles explotables.
