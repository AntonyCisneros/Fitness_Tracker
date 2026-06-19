package com.tuinstituto.fitness_tracker

import android.os.Bundle
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executor
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import kotlin.math.sqrt
import io.flutter.plugin.common.EventChannel
import android.Manifest
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import androidx.core.app.ActivityCompat


/**
 * MainActivity: punto de entrada de la aplicación Android
 * - Extiende FlutterFragmentActivity (necesario para BiometricPrompt)
 * - Configura los Platform Channels aquí
 */
class MainActivity: FlutterFragmentActivity() {

    // PASO 1: Definir nombre del canal (DEBE coincidir con Dart)
    private val BIOMETRIC_CHANNEL = "com.tuinstituto.fitness/biometric"
    private val ACCELEROMETER_CHANNEL = "com.tuinstituto.fitness/accelerometer"
    private val GPS_CHANNEL = "com.tuinstituto.fitness/gps"
    private val LOCATION_PERMISSION_REQUEST_CODE = 1001

    // PASO 2: Variables para biometría
    private lateinit var executor: Executor
    private lateinit var biometricPrompt: BiometricPrompt
    private var pendingResult: MethodChannel.Result? = null

    /**
     * configureFlutterEngine: se llama al iniciar la app
     * AQUÍ configuramos TODOS los Platform Channels
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Inicializar executor para biometría
        executor = ContextCompat.getMainExecutor(this)

        // CONFIGURAR PLATFORM CHANNEL - BIOMETRÍA

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BIOMETRIC_CHANNEL
        ).setMethodCallHandler { call, result ->
            /**
             * setMethodCallHandler: escucha llamadas desde Flutter
             *
             * Parámetros:
             * - call: contiene el nombre del método y argumentos
             * - result: objeto para enviar respuesta a Flutter
             */

            when (call.method) {
                "checkBiometricSupport" -> {
                    // Flutter llamó a checkBiometricSupport()
                    val canAuth = checkBiometricSupport()
                    result.success(canAuth)  // Enviamos respuesta
                }

                "authenticate" -> {
                    // Guardamos result para responder después (async)
                    pendingResult = result
                    showBiometricPrompt()
                }

                else -> {
                    // Método no reconocido
                    result.notImplemented()
                }
            }
        }

        setupAccelerometerChannel(flutterEngine)
        setupGpsChannel(flutterEngine)
    }

    /**
     * Verificar si el dispositivo soporta biometría
     */
    private fun checkBiometricSupport(): Boolean {
        val biometricManager = BiometricManager.from(this)

        return when (biometricManager.canAuthenticate(
            BiometricManager.Authenticators.BIOMETRIC_STRONG
        )) {
            BiometricManager.BIOMETRIC_SUCCESS -> true
            else -> false
        }
    }

    /**
     * Mostrar diálogo de autenticación biométrica
     */
    private fun showBiometricPrompt() {
        // Configurar información del diálogo
        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Autenticación Biométrica")
            .setSubtitle("Usa tu huella dactilar")
            .setDescription("Coloca tu dedo en el sensor")
            .setNegativeButtonText("Cancelar")
            .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
            .build()

        // Crear BiometricPrompt con callbacks
        biometricPrompt = BiometricPrompt(this, executor,
            object : BiometricPrompt.AuthenticationCallback() {

                override fun onAuthenticationSucceeded(
                    result: BiometricPrompt.AuthenticationResult
                ) {
                    super.onAuthenticationSucceeded(result)
                    //  Autenticación exitosa
                    pendingResult?.success(true)
                    pendingResult = null
                }

                override fun onAuthenticationError(
                    errorCode: Int,
                    errString: CharSequence
                ) {
                    super.onAuthenticationError(errorCode, errString)
                    // ❌ Error en autenticación
                    pendingResult?.success(false)
                    pendingResult = null
                }

                override fun onAuthenticationFailed() {
                    super.onAuthenticationFailed()
                    // Usuario puede reintentar
                }
            }
        )

        // Mostrar el diálogo
        biometricPrompt.authenticate(promptInfo)
    }

    /**
     * Configurar EventChannel para acelerómetro
     *
     * EXPLICACIÓN DIDÁCTICA:
     * - EventChannel.StreamHandler tiene 2 métodos:
     *   1. onListen: cuando Flutter comienza a escuchar
     *   2. onCancel: cuando Flutter deja de escuchar
     */
    private fun setupGpsChannel(flutterEngine: FlutterEngine) {
        val locationManager = getSystemService(LOCATION_SERVICE) as LocationManager
        var locationListener: LocationListener? = null

        // ═══════════════════════════════════════════════════════════
        // METHOD CHANNEL - Operaciones puntuales
        // ═══════════════════════════════════════════════════════════
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            GPS_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isGpsEnabled" -> {
                    val isEnabled = locationManager.isProviderEnabled(
                        LocationManager.GPS_PROVIDER
                    )
                    result.success(isEnabled)
                }

                "requestPermissions" -> {
                    if (hasLocationPermission()) {
                        result.success(true)
                    } else {
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(
                                Manifest.permission.ACCESS_FINE_LOCATION,
                                Manifest.permission.ACCESS_COARSE_LOCATION
                            ),
                            LOCATION_PERMISSION_REQUEST_CODE
                        )
                        result.success(hasLocationPermission())
                    }
                }

                "getCurrentLocation" -> {
                    if (!hasLocationPermission()) {
                        result.error("PERMISSION_DENIED", "Sin permisos", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val location = locationManager.getLastKnownLocation(
                            LocationManager.GPS_PROVIDER
                        ) ?: locationManager.getLastKnownLocation(
                            LocationManager.NETWORK_PROVIDER
                        )

                        if (location != null) {
                            result.success(locationToMap(location))
                        } else {
                            result.error("NO_LOCATION", "No disponible", null)
                        }
                    } catch (e: SecurityException) {
                        result.error("SECURITY_ERROR", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }

        // ═══════════════════════════════════════════════════════════
        // EVENT CHANNEL - Stream de ubicaciones
        // ═══════════════════════════════════════════════════════════
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "$GPS_CHANNEL/stream"
        ).setStreamHandler(object : EventChannel.StreamHandler {

            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                if (!hasLocationPermission()) {
                    events?.error("PERMISSION_DENIED", "Sin permisos", null)
                    return
                }

                locationListener = object : LocationListener {
                    override fun onLocationChanged(location: Location) {
                        events?.success(locationToMap(location))
                    }

                    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
                    override fun onProviderEnabled(provider: String) {}
                    override fun onProviderDisabled(provider: String) {}
                }

                try {
                    locationManager.requestLocationUpdates(
                        LocationManager.GPS_PROVIDER,
                        500L,
                        0f,
                        locationListener!!
                    )
                } catch (e: SecurityException) {
                    events?.error("SECURITY_ERROR", e.message, null)
                }
            }

            override fun onCancel(arguments: Any?) {
                locationListener?.let {
                    locationManager.removeUpdates(it)
                }
                locationListener = null
            }
        })
    }

    private fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun locationToMap(location: Location): Map<String, Any> {
        return mapOf(
            "latitude" to location.latitude,
            "longitude" to location.longitude,
            "altitude" to location.altitude,
            "speed" to location.speed.toDouble(),
            "accuracy" to location.accuracy.toDouble(),
            "timestamp" to location.time
        )
    }

    private fun setupAccelerometerChannel(flutterEngine: FlutterEngine) {
        val sensorManager = getSystemService(SENSOR_SERVICE) as SensorManager
        val accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

        var stepCount = 0
        var lastMagnitude = 0.0
        var sensorEventListener: SensorEventListener? = null

        // Variables para suavizado de magnitud
        val magnitudeHistory = mutableListOf<Double>()
        val historySize = 20

        // Variables para control de envío
        var sampleCount = 0

        // ═══════════════════════════════════════════════════════════
        // CLASIFICACIÓN DE ACTIVIDAD CON ESTABILIDAD
        // ═══════════════════════════════════════════════════════════
        // historySize=15: promedio móvil sobre ~300ms (a 50Hz), suaviza el ruido
        //   del sensor sin perder sensibilidad a cambios reales de actividad.
        // confidence=5: requiere 5 muestras consecutivas (~100ms) de la misma
        //   actividad antes de confirmarla. Con historySize=15, esto equivale a
        //   ~400ms de evidencia consistente, suficiente para filtrar fluctuaciones
        //   pero lo bastante rápido para respuesta casi en tiempo real.
        var lastRawActivityType = "stationary"
        var stableActivityType = "stationary"
        var activityConfidence = 0

        // ═══════════════════════════════════════════════════════════
        // DETECCIÓN DE CAÍDAS
        // ═══════════════════════════════════════════════════════════
        // FALL_PEAK_THRESHOLD = 32.0 m/s² (~3.3g)
        //   Punto medio: 30 detectaba brazos, 35 no detectaba caídas.
        //   32 captura impactos reales filtrando la mayoría de movimientos.
        // MIN_SAMPLES_BETWEEN_PEAKS = 30 (~600ms a 50Hz)
        //   Brazos al correr: picos cada 300-500ms → ignorados.
        //   Caída real: pico aislado con >600ms de separación → detectado.
        val FALL_PEAK_THRESHOLD = 32.0
        val FALL_QUIET_MIN = 6.8
        val FALL_QUIET_MAX = 12.8
        val FALL_COOLDOWN_SAMPLES = 100
        val FALL_QUIET_REQUIRED = 12
        val MIN_SAMPLES_BETWEEN_PEAKS = 30

        var fallPotential = false
        var fallSamplesSincePeak = 0
        var fallQuietCount = 0
        var fallConfirmed = false
        var fallCooldown = 0
        var samplesSinceLastPeak = 999  // empezar alto para permitir primera detección

        // ═══════════════════════════════════════════════════════════
        // CONFIGURAR EVENT CHANNEL
        // ═══════════════════════════════════════════════════════════
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ACCELEROMETER_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {

            /**
             * onListen: Flutter comenzó a escuchar el stream
             * AQUÍ iniciamos el sensor
             */
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                sensorEventListener = object : SensorEventListener {

                    override fun onSensorChanged(event: SensorEvent?) {
                        event?.let {
                            // Calcular magnitud del vector
                            val x = it.values[0]
                            val y = it.values[1]
                            val z = it.values[2]
                            val magnitude = sqrt((x * x + y * y + z * z).toDouble())

                            // Promedio móvil para suavizar
                            magnitudeHistory.add(magnitude)
                            if (magnitudeHistory.size > historySize) {
                                magnitudeHistory.removeAt(0)
                            }
                            val avgMagnitude = magnitudeHistory.average()

                            // Detectar paso
                            if (magnitude > 12 && lastMagnitude <= 12) {
                                stepCount++
                            }
                            lastMagnitude = magnitude

                            // ═══════════════════════════════════════════════
                            // CLASIFICACIÓN DE ACTIVIDAD CON HISTÉRESIS
                            // ═══════════════════════════════════════════════
                            // Umbrales diferentes para entrar y salir de cada estado:
                            //
                            //  entrar running:  > 13.0
                            //  salir running:   < 11.0 (cae a walking)
                            //  entrar walking:  > 10.0
                            //  salir walking:   < 9.7  (cae a stationary)
                            //
                            // Ejemplo corriendo: magnitud oscila 10-15. Con histéresis
                            // se mantiene "running" aunque baje a 11 (solo sale si <10.5).
                            // Ejemplo caminando: magnitud oscila 9.8-11. Se mantiene
                            // "walking" aunque baje a 10.0 (solo sale si <9.9).
                            val newActivityType = when {
                                avgMagnitude > 13.0 -> "running"
                                lastRawActivityType == "running" && avgMagnitude > 11.0 -> "running"
                                avgMagnitude > 10.0 -> "walking"
                                lastRawActivityType == "walking" && avgMagnitude > 9.7 -> "walking"
                                else -> "stationary"
                            }

                            // Incrementar confianza si la actividad cruda se mantiene
                            if (newActivityType == lastRawActivityType) {
                                activityConfidence++
                            } else {
                                activityConfidence = 0
                            }

                            // Solo actualizar actividad estable con 8 muestras de confianza
                            if (activityConfidence >= 8) {
                                stableActivityType = newActivityType
                            }
                            lastRawActivityType = newActivityType

                            // =========================================
                            // DETECCIÓN DE CAÍDAS
                            // =========================================
                            samplesSinceLastPeak++

                            if (fallCooldown > 0) {
                                fallCooldown--
                            }

                            // Solo activar si el pico es aislado (no parte de movimiento rítmico)
                            if (magnitude > FALL_PEAK_THRESHOLD
                                && fallCooldown == 0
                                && samplesSinceLastPeak >= MIN_SAMPLES_BETWEEN_PEAKS) {
                                fallPotential = true
                                fallSamplesSincePeak = 0
                                fallQuietCount = 0
                                samplesSinceLastPeak = 0
                            }

                            if (fallPotential) {
                                fallSamplesSincePeak++

                                if (magnitude > FALL_QUIET_MIN && magnitude < FALL_QUIET_MAX) {
                                    fallQuietCount++
                                    if (fallQuietCount >= FALL_QUIET_REQUIRED) {
                                        fallConfirmed = true
                                        fallPotential = false
                                        fallCooldown = FALL_COOLDOWN_SAMPLES
                                    }
                                } else {
                                    fallQuietCount = 0
                                }

                                if (fallSamplesSincePeak > 25) {
                                    fallPotential = false
                                }
                            }

                            // Enviar cada 3 muestras
                            sampleCount++
                            if (sampleCount >= 3) {
                                sampleCount = 0

                                // ENVIAR DATOS A FLUTTER
                                val data = mapOf(
                                    "stepCount" to stepCount,
                                    "activityType" to stableActivityType,
                                    "magnitude" to avgMagnitude,
                                    "fallDetected" to fallConfirmed
                                )

                                events?.success(data)

                                fallConfirmed = false
                            }
                        }
                    }

                    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
                }

                // Registrar listener del sensor
                sensorManager.registerListener(
                    sensorEventListener,
                    accelerometer,
                    SensorManager.SENSOR_DELAY_GAME
                )
            }

            /**
             * onCancel: Flutter dejó de escuchar
             * AQUÍ detenemos el sensor
             */
            override fun onCancel(arguments: Any?) {
                sensorEventListener?.let {
                    sensorManager.unregisterListener(it)
                }
                sensorEventListener = null
            }
        })

        // MethodChannel auxiliar para control
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "$ACCELEROMETER_CHANNEL/control"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    stepCount = 0
                    stableActivityType = "stationary"
                    lastRawActivityType = "stationary"
                    activityConfidence = 0
                    fallPotential = false
                    fallConfirmed = false
                    fallCooldown = 0
                    samplesSinceLastPeak = 999
                    result.success(null)
                }
                "stop" -> {
                    result.success(null)
                }
                "reset" -> {
                    stepCount = 0
                    stableActivityType = "stationary"
                    lastRawActivityType = "stationary"
                    activityConfidence = 0
                    fallPotential = false
                    fallConfirmed = false
                    fallCooldown = 0
                    samplesSinceLastPeak = 999
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
