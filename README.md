# Plantilla de Sitio para ActiveVFP en IIS

¡Bienvenido al repositorio de la Plantilla de Sitio para ActiveVFP en IIS! En este repositorio, encontrarás los archivos y carpetas necesarios para configurar y ejecutar proyectos de ActiveVFP en Internet Information Services (IIS).

## Acerca de ActiveVFP
ActiveVFP (AVFP) es un proyecto completamente gratuito y de código abierto para crear aplicaciones web con el lenguaje de programación y la base de datos Visual Foxpro _(y otras bases de datos como MSSQL o MySQL)._ Proporciona un marco fácil de usar en código Fox puro para utilizar una **dll vfp multiproceso** _(vfp mtdll)_ llamada desde **ASP.NET**. Si está considerando programar web con FoxPro, usar FoxPro en la nube o convertir VFP de escritorio a web o móvil, usando Android, iPhone o iPad, esta herramienta es para ti.

## Acerca de la Plantilla

ActiveVFP es un marco de trabajo que permite el desarrollo de aplicaciones web utilizando Visual FoxPro. Esta plantilla proporciona la estructura base para configurar y ejecutar proyectos de ActiveVFP en el entorno de IIS. A continuación, se detalla el contenido de cada carpeta y archivo en esta plantilla.

## Estructura de Carpetas y Archivos

- **activevfp.dll** y **activevfp.dll.manifest**: Estos archivos son módulos de ActiveVFP necesarios para su funcionamiento.

- **/bin**
  - **activevfp_dotnetproxy.dll**: Biblioteca que brinda capacidades .NET para ActiveVFP.
  - **App_Code.dll**: Biblioteca que contiene código de aplicación compartido.
  - **AspManifestHelpers.dll**: Biblioteca para ayudar con manifiestos ASP.

- **/css**
  - **jquery-ui-1.8.7.css**, **jquery-ui.css**, **jquery.mobile-1.0rc1.min.css**, **Site.css** y **styles.css**: Archivos CSS para el diseño y estilo del sitio.
  - **Web.Config**: Archivo de configuración para estilos y CSS.

- **/html**
  - **default.avfp**: Plantilla HTML para la página principal del sitio.

- **/prg**
  - **/handlers**
    - **/lib**
      - **resthelper.prg**: Manejador de REST para funciones auxiliares.
    - **resthandler.prg**: Manejador principal de REST.

  - **/rest/controllers**
    - **/jsondb**
      - **configuration.json**: Configuración de base de datos JSON para REST.
      - **examples.avfp**, **jsondb.avfp**, **reference.avfp**, **test.avfp**: Controladores JSON para REST.
      - **jsondb.prg**: Controlador principal para manejar solicitudes JSON.

  - **main.prg**: Archivo principal de inicio de la aplicación.
  - **pages.prg**: Archivo que maneja las páginas y su contenido.
  - **/plugins**
    - **layouts.prg**: Plugin para administrar diseños de página.

- **/reports**
  - **clsheap.prg**, **print2pdf.prg**: Archivos relacionados con generación y manejo de informes.
  - **runfrx.exe**: Ejecutable para generar informes.

- **/javascript**: Archivos JavaScript para la funcionalidad del sitio.
  - **jquery.js**, **jquery-ui.min.js**, **jquery.validate.min.js**, **ui.jqgrid.js**, entre otros.

- **/data**
  - **/newfeats**: Archivos de datos relacionados con nuevas características.

- **/docs**: Documentación relacionada con el sitio y ActiveVFP.
  - **docs.htm**, **IIS_Setup_in_10_steps!.htm**: Documentación HTML.

- **/images**: Imágenes utilizadas en el diseño del sitio.
  - Varias imágenes utilizadas en los archivos CSS y HTML.

- Archivos en la raíz:
  - `activevfp.dll`: La biblioteca principal de ActiveVFP para ejecutar código Visual FoxPro en IIS.
  - `activevfp.dll.manifest`: Archivo de manifiesto que proporciona información sobre la biblioteca `activevfp.dll`.
  - `gxps.exe` y `runfrx.exe`: Utilidades para generar y ejecutar informes de Visual FoxPro.
  - `Web.Config`: Archivo de configuración de IIS para el sitio, define cómo se manejan las solicitudes y otras configuraciones.
  - `webapp.manifest`: Otro archivo de manifiesto relacionado con la aplicación web.

## Licencia

Este proyecto se distribuye bajo la Licencia MIT. Consulta el archivo LICENSE para más detalles.

## Uso con MagicMenu

Puedes utilizar la herramienta MagicMenu para simplificar el proceso de creación y configuración de sitios utilizando esta plantilla. MagicMenu automatiza la descarga y uso de estas mismas plantillas, permitiéndote concentrarte en el desarrollo de tu aplicación.

- Puedes descargar y crear sitios manualmente utilizando los archivos y carpetas proporcionados en este repositorio.
- También puedes utilizar la herramienta MagicMenu para una experiencia más automatizada y amigable.
  
Para obtener más información sobre MagicMenu, visita el repositorio: [MagicMenu en GitHub](https://github.com/Irwin1985/MagicMenu).

## Activación de Características de Windows y Configuración de IIS

Para asegurarte de que IIS funcione correctamente con ActiveVFP, sigue estos pasos:
 - Abre "Panel de control" -> "Programas" -> "Programas y características" -> "Activar o desactivar las características de Windows".
 - Marca la casilla "Internet Information Services" y sus subcaracterísticas.
 - Asegúrate de seleccionar "CGI" y "Filtros ISAPI" en la sección "Servicios World Wide Web" -> "Características de desarrollo de aplicaciones".
 - Completa el proceso y reinicia tu sistema si se te solicita.

## Soporte y Comunidad

- Si tienes preguntas o necesitas ayuda con ActiveVFP, visita el [Foro de ActiveVFP](https://groups.google.com/g/activevfp).
- Ante la ausencia de documentación oficial, el foro es un excelente recurso para obtener ayuda y compartir conocimientos.

## Contribuciones

¡Siéntete libre de contribuir y mejorar esta plantilla! Si tienes sugerencias, mejoras o correcciones, ¡no dudes en hacer un pull request!

## Notas Importantes

- Asegúrate de cumplir con los requisitos de ActiveVFP y las configuraciones recomendadas para IIS.
- Consulta la documentación de ActiveVFP y los recursos de IIS para obtener más información.
- Recuerda que la seguridad y el mantenimiento son fundamentales para un despliegue exitoso.

---

Esperamos que esta plantilla te ayude a configurar y ejecutar tus proyectos de ActiveVFP en IIS. Si tienes preguntas o necesitas ayuda, no dudes en contactarnos.
