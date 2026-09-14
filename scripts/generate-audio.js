/**
 * Generates minimal valid WAV files for MVP listening exercises.
 * Run: node scripts/generate-audio.js
 */
const fs = require('fs');
const path = require('path');

function writeWav(filePath, durationSec = 0.35, frequency = 440, volume = 0.25) {
  const sampleRate = 8000;
  const numSamples = Math.floor(sampleRate * durationSec);
  const dataSize = numSamples * 2;
  const buffer = Buffer.alloc(44 + dataSize);

  buffer.write('RIFF', 0);
  buffer.writeUInt32LE(36 + dataSize, 4);
  buffer.write('WAVE', 8);
  buffer.write('fmt ', 12);
  buffer.writeUInt32LE(16, 16);
  buffer.writeUInt16LE(1, 20);
  buffer.writeUInt16LE(1, 22);
  buffer.writeUInt32LE(sampleRate, 24);
  buffer.writeUInt32LE(sampleRate * 2, 28);
  buffer.writeUInt16LE(2, 32);
  buffer.writeUInt16LE(16, 34);
  buffer.write('data', 36);
  buffer.writeUInt32LE(dataSize, 40);

  for (let i = 0; i < numSamples; i++) {
    const t = i / sampleRate;
    const envelope = Math.min(1, i / (sampleRate * 0.02), (numSamples - i) / (sampleRate * 0.05));
    const sample = Math.sin(2 * Math.PI * frequency * t) * volume * envelope;
    buffer.writeInt16LE(Math.max(-32767, Math.min(32767, Math.floor(sample * 32767))), 44 + i * 2);
  }

  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, buffer);
}

const root = path.join(__dirname, '..', 'public', 'audio');
writeWav(path.join(root, 'abandon.wav'), 0.4, 440);
writeWav(path.join(root, 'abandon-slow.wav'), 0.7, 220);
console.log('Wrote public/audio/abandon.wav and abandon-slow.wav');
