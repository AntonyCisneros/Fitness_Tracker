# Guión de Video — Fitness Tracker: Migración a Plugins + CRUD de Historial

**Duración total:** ~2 minutos  
**Formato:** Voz en off + grabación de pantalla (VS Code + emulador)

---

## Línea de tiempo

| Segmento | Tiempo | Acumulado |
|----------|--------|-----------|
| 1. Introducción | 0:00 – 0:20 | 20s |
| 2. Migración: Platform Channels → Plugins | 0:20 – 0:55 | 35s |
| 3. Arquitectura del CRUD | 0:55 – 1:35 | 40s |
| 4. Demo visual + cierre | 1:35 – 2:00 | 25s |

---

## Segmento 1 — Introducción (0:00 – 0:20)

### Voz en off

> Inicialmente, nuestra app de fitness usaba Platform Channels para comunicarse con las capacidades nativas del dispositivo: autenticación biométrica, GPS y acelerómetro. Sin embargo, este enfoque implicaba escribir código nativo en Kotlin para Android, lo que añadía complejidad, duplicación de lógica y riesgo de errores entre plataformas.
>
> La solución: migrar estas funcionalidades a plugins oficiales de Flutter. Y además, añadimos un sistema CRUD completo para gestionar el historial de actividad física del usuario.

### Qué mostrar en pantalla
- Título del proyecto, logo o portada
- Transición suave al código

---

## Segmento 2 — Migración Platform Channels → Plugins (0:20 – 0:55)

### Voz en off

> Aquí está el antes: `platform_channels.dart`. Tres canales definidos con strings hardcodeados — biometría, acelerómetro y GPS. Este archivo ya no se importa en ninguna parte del proyecto. Es código muerto.
>
> Ahora, en `pubspec.yaml`, tenemos tres plugins oficiales:
> - `local_auth` para autenticación biométrica
> - `geolocator` para GPS y ubicación en tiempo real
> - `sensors_plus` para el acelerómetro
>
> Veamos cómo se traduce esto en el código. En `biometric_datasource.dart`, en vez de invocar un `MethodChannel`, simplemente usamos `LocalAuthentication.authenticate()` con opciones como `stickyAuth` y `biometricOnly`.
>
> Para el GPS, `gps_datasource.dart` expone `Geolocator.getCurrentPosition()` y un `Stream` de posiciones con `getPositionStream()`. Sin canales manuales, sin código nativo.
>
> Y el acelerómetro es donde está la lógica más compleja: conteo de pasos, clasificación de actividad con histéresis y detección de caídas. Todo se procesa en Dart usando `accelerometerEventStream()` de `sensors_plus`.
>
> ¿El resultado en Android? `MainActivity.kt` pasó de más de 500 líneas a solo 5. El `AndroidManifest` ya no declara servicios ni permisos innecesarios. Toda la lógica vive en Dart.

### Qué mostrar en pantalla
1. **0:20** — Abrir `platform_channels.dart` (10 líneas, código muerto)
2. **0:25** — `pubspec.yaml`: resaltar `local_auth`, `geolocator`, `sensors_plus`
3. **0:30** — Scroll rápido por `biometric_datasource.dart` (41 líneas)
4. **0:35** — Scroll rápido por `gps_datasource.dart` (51 líneas)
5. **0:40** — Abrir `accelerometer_datasource.dart`, resaltar `accelerometerEventStream()` y constantes de thresholds
6. **0:48** — Comparar `MainActivity.kt` (5 líneas) con el `platform_channels.dart` muerto
7. **0:52** — `AndroidManifest.xml`: solo 3 permisos declarados

---

## Segmento 3 — Arquitectura del CRUD (0:55 – 1:35)

### Voz en off

> Para el historial de actividad, implementamos un CRUD completo usando Clean Architecture con tres capas.
>
> En la capa de dominio, `ActivityRecord` es la entidad: fecha, pasos, tipo de actividad, calorías estimadas, distancia y notas. Extiende `Equatable` para comparación por valor.
>
> En la capa de datos, `ActivityRecordDataSource` usa `sqflite` para persistir los registros en SQLite. Tenemos los seis métodos del CRUD: insertar, obtener todos, obtener por ID, actualizar, eliminar y eliminar todos. Es un singleton — una sola instancia de base de datos para toda la app.
>
> En la capa de presentación, `HistoryBloc` gestiona el estado con cinco eventos: `LoadHistory`, `AddRecord`, `UpdateRecord`, `DeleteRecord` y `DeleteAllRecords`. Tras cada mutación, el BLoC re-despacha `LoadHistory` internamente para refrescar la lista desde la base de datos. El estado puede ser `HistoryInitial`, `HistoryLoading`, `HistoryLoaded` con la lista, o `HistoryError`.
>
> El flujo completo es: la UI dispara un evento → el BLoC llama al datasource → el datasource ejecuta SQL → el BLoC emite el nuevo estado → la UI se reconstruye reactivamente.

### Qué mostrar en pantalla
1. **0:55** — Diagrama de carpetas: `domain/ → data/ → presentation/`
2. **1:00** — `activity_record.dart`: mostrar `copyWith()`, `toMap()`, `fromMap()`
3. **1:08** — `activity_record_datasource.dart`: scroll por métodos `insertRecord`, `getAllRecords`, `deleteRecord`, `deleteAllRecords`
4. **1:18** — `history_bloc.dart`: mostrar eventos (`LoadHistory`, `AddRecord`, etc.) y el patrón `add(LoadHistory())` en los handlers
5. **1:30** — Mostrar `main.dart` donde al detener el tracking se crea un `ActivityRecord` y se despacha al `HistoryBloc`

---

## Segmento 4 — Demo visual + cierre (1:35 – 2:00)

### Voz en off

> El resultado es una interfaz con tema oscuro y glassmorphism. Las tarjetas translúcidas con blur flotan sobre un fondo degradado.
>
> En el login, la autenticación biométrica se activa con un solo tap. En el dashboard, vemos el contador de pasos con su anillo circular, el tipo de actividad detectada en tiempo real y la ruta GPS renderizada con un `CustomPainter` que dibuja el trayecto con efecto de brillo.
>
> Y aquí está el historial: animaciones de entrada escalonadas, chips de métricas para cada registro, y menú contextual para editar notas o eliminar. También tenemos un botón para eliminar todos los registros con confirmación.
>
> La migración a plugins nos permitió eliminar más de 500 líneas de código nativo, centralizar toda la lógica en Dart, y hacer la app más mantenible y portable entre plataformas. El CRUD de historial cierra el ciclo: el usuario no solo registra su actividad en tiempo real, sino que puede revisar, editar y gestionar su historial completo.

### Qué mostrar en pantalla
1. **1:35** — Abrir `app_theme.dart`, mostrar `GlassCard`, `AppColors`, constantes del tema
2. **1:40** — Emulador: login con biométrico (mostrar el diálogo nativo)
3. **1:45** — Emulador: dashboard con pasos, actividad detectada, mini-mapa
4. **1:50** — Emulador: pestaña Historial con lista de registros
5. **1:54** — Demostrar editar nota, eliminar registro, diálogo "eliminar todos"
6. **1:58** — Cierre destacando las 3 mejoras clave

---

## Notas para la grabación

### Preparación previa
- [ ] Abrir proyecto en VS Code con tema oscuro y fuente grande
- [ ] Tener el emulador corriendo con algunos registros previos cargados
- [ ] Preparar los archivos en tabs ordenados según el orden del guión
- [ ] Desactivar notificaciones y popups del sistema

### Archivos a tener abiertos (en orden)
1. `platform_channels.dart` (el "fósil")
2. `pubspec.yaml` (plugins resaltados)
3. `biometric_datasource.dart`
4. `gps_datasource.dart`
5. `accelerometer_datasource.dart`
6. `MainActivity.kt`
7. `activity_record.dart`
8. `activity_record_datasource.dart`
9. `history_bloc.dart`
10. `history_page.dart`
11. `app_theme.dart`

### Transiciones sugeridas
- Entre archivos de código: `Ctrl+Tab` rápido
- Entre VS Code y emulador: fade o corte directo
- Resaltar líneas: cursor o selección con mouse

### Frases clave a enfatizar
- "De más de 500 líneas de Kotlin a solo 5"
- "Toda la lógica ahora vive en Dart"
- "CRUD completo: crear, leer, actualizar, eliminar"
- "Glassmorphism + tema oscuro"
- "Clean Architecture en tres capas"

---

## Resumen visual para diapositiva final (opcional)

```
┌──────────────────────────────────────────────┐
│           MIGRACIÓN COMPLETADA               │
│                                              │
│  Platform Channels ──────► Plugins Oficiales │
│                                              │
│  🔐 local_auth     → Biometría               │
│  📍 geolocator      → GPS                    │
│  📳 sensors_plus    → Acelerómetro           │
│                                              │
│  + CRUD de Historial (sqflite + BLoC)        │
│  + UI Glassmorphism + Tema Oscuro            │
│                                              │
│  📉 -500 líneas Kotlin │ 📈 +695 líneas Dart │
│  ✅ 0 errores          │ ✅ 0 warnings       │
└──────────────────────────────────────────────┘
```
