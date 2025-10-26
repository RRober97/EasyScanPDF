# Revisión funcional de PDF Scanner

## Cobertura del flujo principal
- La app define rutas para `Splash`, `MainScanning`, `CameraScanning`, `PdfGeneration` y `ShareDocument`, pero no existen implementaciones para biblioteca, paywall o ajustes; la navegación principal solo cubre un subconjunto del flujo solicitado. 【F:lib/routes/app_routes.dart†L3-L25】
- `CameraScanningInterface` mantiene una lista local `_capturedImages`, pero al terminar el escaneo hace `Navigator.pushReplacementNamed` de vuelta a la pantalla principal sin entregar datos al módulo de generación de PDF, rompiendo el flujo "Escanear → Lienzo → Generar PDF". 【F:lib/presentation/camera_scanning_interface/camera_scanning_interface.dart†L216-L266】
- `PdfGeneration` usa imágenes mock (`_capturedPages`) y genera un PDF vacío mediante texto plano en lugar de procesar las capturas reales, por lo que el flujo "Lienzo → PDF" no es funcional. 【F:lib/presentation/pdf_generation/pdf_generation.dart†L42-L118】【F:lib/presentation/pdf_generation/pdf_generation.dart†L144-L209】
- `ShareDocument` crea un PDF simulado en `_generateMockPDF` y no consume el PDF generado en el paso previo; además no hay retorno a Home ni biblioteca tras compartir. 【F:lib/presentation/share_document/share_document.dart†L47-L148】

## Lógica de negocio y límites
- No existe `SubscriptionService` ni banderas de `isPro`; ninguna pantalla aplica límites de páginas o PDFs, ni muestra paywall. 【F:lib/presentation/camera_scanning_interface/camera_scanning_interface.dart†L20-L182】
- Tampoco hay `StorageService` que rote los archivos; los guardados son simulados en memoria o con PDFs de texto plano. 【F:lib/presentation/pdf_generation/pdf_generation.dart†L144-L209】
- El nombre de archivos sigue el patrón `ScanPDF_...` pero sin el formato requerido `Scan_YYYYMMDD_HHMMSS.pdf`. 【F:lib/presentation/pdf_generation/pdf_generation.dart†L158-L205】

## Problemas técnicos y de UX
- `CameraScanningInterface` utiliza detección simulada y no maneja edición de páginas (rotar, reordenar, eliminar); tampoco transfiere el estado de `_capturedImages` a otras pantallas. 【F:lib/presentation/camera_scanning_interface/camera_scanning_interface.dart†L39-L214】
- No hay pantallas ni servicios para biblioteca, ajustes, restauración de compras, ni mensajes de estado vacíos. 【F:lib/routes/app_routes.dart†L3-L25】
- `flutter analyze` fallaría por imports duplicados y faltantes (por ejemplo, `share_document.dart` usaba `utf8` sin importar `dart:convert`). 【F:lib/presentation/pdf_generation/pdf_generation.dart†L9-L20】【F:lib/presentation/share_document/share_document.dart†L1-L149】

## Mejoras aplicadas en esta revisión
- Se reemplazó la plantilla de contador por una configuración real de `MaterialApp` con temas claro/oscuro, rutas centralizadas y soporte de `Sizer`. 【F:lib/main.dart†L1-L33】
- Se eliminaron imports duplicados y dependencias de animación no utilizadas en `PdfGeneration`, dejando un temporizador autocontenido. 【F:lib/presentation/pdf_generation/pdf_generation.dart†L1-L121】
- Se añadió el import de `dart:convert` para permitir la generación del PDF simulado durante el flujo de compartir. 【F:lib/presentation/share_document/share_document.dart†L1-L148】

## Próximos pasos sugeridos
1. Implementar un gestor de estado (p.ej. Riverpod/Provider) que comparta capturas, PDFs y estado de suscripción entre pantallas.
2. Sustituir los mocks por integraciones reales: cámara → lienzo con edición, generación de PDF con `pdf` package, almacenamiento en `getApplicationDocumentsDirectory` con rotación acorde al plan.
3. Construir pantallas de Biblioteca, Paywall y Ajustes, conectando límites de planes y flujos de compra/restauración.
4. Añadir manejo completo de límites (Normal vs Pro), toasts y bloqueos con redirección al paywall.
5. Consolidar pruebas (`flutter analyze`, tests widget) y eliminar dependencias web sobrantes.
