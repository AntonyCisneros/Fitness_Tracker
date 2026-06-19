import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();

  bool _initialized = false;
  String _lastSpoken = '';

  Future<void> init() async {
    if (_initialized) return;

    try {
      final languages = await _flutterTts.getLanguages;
      print('🗣️ TTS idiomas disponibles: $languages');

      if (languages.contains('es-ES')) {
        await _flutterTts.setLanguage('es-ES');
      } else if (languages.contains('es')) {
        await _flutterTts.setLanguage('es');
      } else {
        print('⚠️ TTS: español no disponible, usando idioma por defecto');
      }

      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      _initialized = true;
      print('✅ TTS inicializado correctamente');
    } catch (e) {
      print('❌ TTS error de inicialización: $e');
      _initialized = true;
    }
  }

  Future<void> speak(String text) async {
    print('🗣️ TTS speak: "$text" (last: "$_lastSpoken")');

    if (!_initialized) {
      await init();
    }

    if (text == _lastSpoken) {
      print('⏭️ TTS: texto repetido, ignorando');
      return;
    }
    _lastSpoken = text;

    try {
      await _flutterTts.stop();
      final result = await _flutterTts.speak(text);
      print('✅ TTS hablado (result=$result): "$text"');
    } catch (e) {
      print('❌ TTS error al hablar: $e');
    }
  }

  /// Fuerza el habla ignorando el filtro de repetición.
  /// Usar solo para alertas críticas como detección de caída.
  Future<void> speakAlert(String text) async {
    print('🚨 TTS ALERT: "$text"');

    if (!_initialized) {
      await init();
    }

    try {
      await _flutterTts.stop();
      await Future.delayed(const Duration(milliseconds: 50));
      final result = await _flutterTts.speak(text);
      print('✅ TTS alerta hablada (result=$result): "$text"');
    } catch (e) {
      print('❌ TTS error en alerta: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('❌ TTS error al detener: $e');
    }
  }

  void reset() {
    _lastSpoken = '';
    print('🔄 TTS reset');
  }
}
