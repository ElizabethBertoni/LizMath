import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Controla os efeitos sonoros do Emplake em todas as telas.
class GameSound {
  GameSound._();

  static final AudioPlayer _player = AudioPlayer();
  static bool enabled = true;

  static Future<void> toggle() async {
    enabled = !enabled;

    if (enabled) {
      // Tocar imediatamente após o clique também libera o áudio no navegador.
      await play('click');
    } else {
      try {
        await _player.stop();
      } catch (error) {
        debugPrint('Erro ao parar o áudio: $error');
      }
    }
  }

  static Future<void> play(String soundName) async {
    if (!enabled) return;

    try {
      // Não chamar stop() antes de play(): no navegador, isso pode fazer
      // perder a autorização de áudio concedida pelo clique do usuário.
      await _player.play(
        AssetSource('sounds/$soundName.wav'),
        volume: 0.85,
      );
    } catch (error) {
      debugPrint('Erro ao reproduzir "$soundName": $error');
    }
  }

  static Future<void> dispose() async {
    await _player.dispose();
  }
}
