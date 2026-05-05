import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

void generateBeep(String path, double frequency, double durationMs, double volume) {
  final sampleRate = 44100;
  final numSamples = (sampleRate * (durationMs / 1000.0)).toInt();
  
  final byteData = ByteData(44 + numSamples * 2);
  
  // RIFF header
  byteData.setUint32(0, 0x52494646, Endian.big); // "RIFF"
  byteData.setUint32(4, 36 + numSamples * 2, Endian.little); // chunk size
  byteData.setUint32(8, 0x57415645, Endian.big); // "WAVE"
  
  // fmt subchunk
  byteData.setUint32(12, 0x666d7420, Endian.big); // "fmt "
  byteData.setUint32(16, 16, Endian.little); // subchunk1size
  byteData.setUint16(20, 1, Endian.little); // audio format (PCM)
  byteData.setUint16(22, 1, Endian.little); // num channels
  byteData.setUint32(24, sampleRate, Endian.little); // sample rate
  byteData.setUint32(28, sampleRate * 2, Endian.little); // byte rate
  byteData.setUint16(32, 2, Endian.little); // block align
  byteData.setUint16(34, 16, Endian.little); // bits per sample
  
  // data subchunk
  byteData.setUint32(36, 0x64617461, Endian.big); // "data"
  byteData.setUint32(40, numSamples * 2, Endian.little); // subchunk2size
  
  // samples
  for (int i = 0; i < numSamples; i++) {
    double envelope = 1.0;
    if (i < 400) {
      envelope = i / 400.0;
    } else if (i > numSamples - 400) {
      envelope = (numSamples - i) / 400.0;
    }
    
    double sample = sin(2 * pi * frequency * (i / sampleRate)) * volume * envelope * 32767;
    byteData.setInt16(44 + i * 2, sample.toInt(), Endian.little);
  }
  
  File(path).writeAsBytesSync(byteData.buffer.asUint8List());
}

void main() {
  generateBeep('assets/sounds/ticket_success.wav', 2500, 150, 0.6);
  generateBeep('assets/sounds/ticket_notify.wav', 1800, 100, 0.4);
  print('Beeps generated.');
}
