# Plantilla de Sitio para ActiveVFP en IIS

¡Bienvenido al repositorio de la Plantilla de Sitio para ActiveVFP en IIS! En este repositorio, encontrarás los archivos y carpetas necesarios para configurar y ejecutar proyectos de ActiveVFP en Internet Information Services (IIS).

## Acerca de ActiveVFP
ActiveVFP (AVFP) es un proyecto completamente gratuito y de código abierto para crear aplicaciones web con el lenguaje de programación y la base de datos Visual Foxpro _(y otras bases de datos como MSSQL o MySQL)._ Proporciona un marco fácil de usar en código Fox puro para utilizar una **dll vfp multiproceso** _(vfp mtdll)_ llamada desde **ASP.NET**. Si está considerando programar web con FoxPro, usar FoxPro en la nube o convertir VFP de escritorio a web o móvil, usando Android, iPhone o iPad, esta herramienta es para ti.

## Acerca de la Plantilla

ActiveVFP es un marco de trabajo que permite el desarrollo de aplicaciones web utilizando Visual FoxPro. Esta plantilla proporciona la estructura base para configurar y ejecutar proyectos de ActiveVFP en el entorno de IIS. A continuación, se detalla el contenido de cada carpeta y archivo en esta plantilla.

## Estructura de Carpetas y Archivos

- `bin/`: Esta carpeta contiene las bibliotecas y ejecutables necesarios para el funcionamiento de ActiveVFP.
  - `activevfp_dotnetproxy.dll`: Un proxy que conecta ActiveVFP con componentes .NET.
  - `App_Code.dll`: Biblioteca que contiene código de aplicación compilado, con clases y funciones compartidas.
  - `AspManifestHelpers.dll`: Biblioteca que facilita la carga de bibliotecas .NET en IIS.

- `html/`: Aquí se encuentra el archivo principal de tu aplicación ActiveVFP.
  - `default.avfp`: Página principal de tu aplicación, donde puedes incluir lógica y marcado.

- `prg/handlers/lib/`: Contiene scripts que proveen funciones auxiliares para manejar solicitudes REST.
  - `resthelper.prg`: Script que ofrece funciones útiles para el manejo de solicitudes REST.

- `prg/handlers/`: En esta carpeta se encuentra el controlador que maneja solicitudes REST.
  - `resthandler.prg`: Controlador que gestiona las solicitudes REST, haciendo uso de `resthelper.prg` y otras funciones.

- `prg/rest/controllers/`: Aquí se colocan los controladores de la aplicación, encargados de manejar solicitudes REST específicas.

- `prg/`: Esta carpeta contiene scripts y componentes generales de la aplicación.
  - `main.prg`: Punto de entrada potencial para configurar el entorno y llamar a otros componentes.

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

[Enlace a la documentación de ActiveVFP](enlace-a-documentacion)
[Enlace a recursos de IIS](enlace-a-recursos-iis)
