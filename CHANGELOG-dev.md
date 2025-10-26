# CHANGELOG (dev)

## Implementación de flujo completo
- Se conectó el flujo real de escaneo: inicio, captura desde cámara/galería, edición en lienzo, generación y almacenamiento del PDF, compartir y acceso a la biblioteca.
- Se reemplazaron los mocks de cámara, generación de PDF y compartición por servicios reales basados en Riverpod.
- Se aplicaron los límites de plan (Normal vs Pro) en captura, generación y almacenamiento, mostrando el paywall cuando corresponde.
- Se añadieron servicios dedicados (suscripción, sesión de escaneo, PDF, almacenamiento y compartir) consumidos desde la UI.
- Se incorporaron pruebas unitarias para validar límites de generación y rotación de almacenamiento.
