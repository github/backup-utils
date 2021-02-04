Utilidades de copia de seguridad del servidor de GitHub Enterprise
Este repositorio incluye utilidades de respaldo y recuperación para GitHub Enterprise Server .

ACTUALIZACIÓN : La nueva función beta de copia de seguridad y restauración en paralelo requerirá la instalación de GNU awk y moreutils .

Nota : los requisitos de la versión del servidor de GitHub Enterprise han cambiado a partir de Backup Utilities v2.13.0, lanzada el 27 de marzo de 2018.

Características
Las utilidades de copia de seguridad implementan una serie de capacidades avanzadas para los hosts de copia de seguridad, creadas sobre las funciones de copia de seguridad y restauración que ya se incluyen en el servidor de GitHub Enterprise.

Sistema completo de copia de seguridad y recuperación del servidor GitHub Enterprise a través de dos utilidades simples:
ghe-backupy ghe-restore.
Copias de seguridad en línea. No es necesario poner el dispositivo GitHub en modo de mantenimiento durante la ejecución de la copia de seguridad.
Copia de seguridad incremental de los datos del repositorio de Git. Solo se transfieren los cambios desde la última instantánea, lo que conduce a ejecuciones de respaldo más rápidas y menor ancho de banda de red y menor utilización de la máquina.
Almacenamiento de instantáneas eficiente. Solo los datos agregados desde la instantánea anterior consumen espacio nuevo en el host de respaldo.
Múltiples instantáneas de respaldo con períodos de retención configurables.
Los comandos de copia de seguridad se ejecutan con la prioridad más baja de CPU / IO en el dispositivo GitHub, lo que reduce el impacto en el rendimiento mientras se realizan las copias de seguridad.
Se ejecuta en la mayoría de entornos Linux / Unix.
Software de código abierto con licencia del MIT mantenido por GitHub, Inc.
Documentación
Requisitos
Requisitos del host de respaldo
Requisitos de almacenamiento
Requisitos de la versión del servidor de GitHub Enterprise
Empezando
Uso de los comandos de copia de seguridad y restauración
Programación de copias de seguridad
Estructura de archivo de instantánea de copia de seguridad
¿En qué se diferencian las utilidades de copia de seguridad de una réplica de alta disponibilidad?
Estibador
Apoyo
Si encuentra un error o desea solicitar una función en las utilidades de copia de seguridad, abra un problema o extraiga una solicitud en este repositorio. Si tiene una pregunta relacionada con la configuración específica de su servidor de GitHub Enterprise o si desea ayuda con la configuración o recuperación del sitio de respaldo, comuníquese con nuestro equipo de soporte empresarial .
