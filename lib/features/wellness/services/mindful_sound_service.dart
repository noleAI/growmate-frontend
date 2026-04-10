import 'dart:convert';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum MindfulSoundPreset { rain, ocean, chimes }

class MindfulSoundService {
  MindfulSoundService() : _player = AudioPlayer();

  final AudioPlayer _player;
  final Map<MindfulSoundPreset, Uint8List> _bufferCache =
      <MindfulSoundPreset, Uint8List>{};
  final Map<MindfulSoundPreset, String> _dataUriCache =
      <MindfulSoundPreset, String>{};

  Future<void> play({
    required MindfulSoundPreset preset,
    required double volume,
  }) async {
    final safeVolume = volume.clamp(0.0, 1.0);
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(safeVolume);

    final bytes = _bufferCache.putIfAbsent(
      preset,
      () => _generateAmbientWav(preset),
    );

    await _player.stop();
    if (kIsWeb) {
      final dataUri = _dataUriCache.putIfAbsent(
        preset,
        () => _toDataUri(bytes),
      );
      await _player.play(UrlSource(dataUri));
      return;
    }

    await _player.play(BytesSource(bytes));
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }

  Uint8List _generateAmbientWav(MindfulSoundPreset preset) {
    const sampleRate = 22050;
    const durationSeconds = 10;
    final totalSamples = sampleRate * durationSeconds;
    final dataSize = totalSamples * 2;
    final byteData = ByteData(44 + dataSize);

    _writeWavHeader(byteData, sampleRate: sampleRate, dataSize: dataSize);

    final random = Random(17 + preset.index * 19);
    var smoothNoise = 0.0;

    for (var i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final noise = random.nextDouble() * 2 - 1;

      smoothNoise = smoothNoise * 0.986 + noise * 0.09;

      double sample;
      switch (preset) {
        case MindfulSoundPreset.rain:
          final mist = sin(2 * pi * 118 * t) * 0.02;
          sample = smoothNoise * 0.24 + mist;
          break;
        case MindfulSoundPreset.ocean:
          final tide = sin(2 * pi * 0.12 * t) * 0.5 + 0.5;
          final swell = sin(2 * pi * 62 * t) * (0.08 + tide * 0.12);
          sample = swell + smoothNoise * 0.08;
          break;
        case MindfulSoundPreset.chimes:
          final phase = t % 4.0;
          final ping =
              exp(-1.7 * phase) *
              sin(2 * pi * (510 + 24 * sin(2 * pi * 0.35 * phase)) * phase);
          final pad =
              sin(2 * pi * 216 * t) * 0.06 + sin(2 * pi * 270 * t) * 0.045;
          sample = pad + ping * 0.14 + smoothNoise * 0.03;
          break;
      }

      final clamped = sample.clamp(-1.0, 1.0);
      final intValue = (clamped * 32767).round();
      byteData.setInt16(44 + i * 2, intValue, Endian.little);
    }

    return byteData.buffer.asUint8List();
  }

  void _writeWavHeader(
    ByteData data, {
    required int sampleRate,
    required int dataSize,
  }) {
    const channels = 1;
    const bitsPerSample = 16;
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    const blockAlign = channels * bitsPerSample ~/ 8;
    final chunkSize = 36 + dataSize;

    _setAscii(data, 0, 'RIFF');
    data.setUint32(4, chunkSize, Endian.little);
    _setAscii(data, 8, 'WAVE');
    _setAscii(data, 12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, channels, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, byteRate, Endian.little);
    data.setUint16(32, blockAlign, Endian.little);
    data.setUint16(34, bitsPerSample, Endian.little);
    _setAscii(data, 36, 'data');
    data.setUint32(40, dataSize, Endian.little);
  }

  void _setAscii(ByteData data, int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      data.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  String _toDataUri(Uint8List bytes) {
    final base64 = base64Encode(bytes);
    return 'data:audio/wav;base64,$base64';
  }
}
