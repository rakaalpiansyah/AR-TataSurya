const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const input = path.join(root, 'assets', 'models', 'chess-interactive.glb');
const output = path.join(root, 'assets', 'models', 'chess-learning.glb');
const source = fs.readFileSync(input);
const jsonLength = source.readUInt32LE(12);
const jsonStart = 20;
const json = JSON.parse(source.toString('utf8', jsonStart, jsonStart + jsonLength));
const binHeaderStart = jsonStart + jsonLength;
const binLength = source.readUInt32LE(binHeaderStart);
const binType = source.toString('ascii', binHeaderStart + 4, binHeaderStart + 8);
const bin = Buffer.from(source.subarray(binHeaderStart + 8, binHeaderStart + 8 + binLength));
const chunks = [bin];

if (binType !== 'BIN\0') {
  throw new Error(`Unexpected GLB binary chunk type: ${binType}`);
}

json.animations = [];
json.asset = {
  ...json.asset,
  generator: 'Codex AR chess learning animation asset',
};
json.materials = json.materials || [];
addLearningAnimation();

function addLearningAnimation() {
  const animation = {
    name: 'Skakmat putih',
    samplers: [],
    channels: [],
  };
  const lessons = [
    // Scholar's mate: 1. e4 e5 2. Qh5 Nc6 3. Bc4 Nf6 4. Qxf7#
    { node: 'Circle.021', start: 0.4, moves: [[0, 0, 0], [-1, 0, 1100], [-2, 0, 0]] }, // white pawn e2 -> e4
    { node: 'Circle.015', start: 2.0, moves: [[0, 0, 0], [1, 0, 1100], [2, 0, 0]] }, // black pawn e7 -> e5
    { node: 'Circle.007', start: 3.6, moves: [[0, 0, 0], [-2, 2, 1450], [-4, 4, 0], [-5, 3, 1450], [-6, 2, 0]] }, // queen d1 -> h5 -> f7#
    { node: 'Circle.034', start: 5.4, moves: [[0, 0, 0], [1, 0.5, 1250], [2, 1, 0]] }, // black knight b8 -> c6
    { node: 'Circle.003', start: 7.0, moves: [[0, 0, 0], [-1.5, -1.5, 1350], [-3, -3, 0]] }, // white bishop f1 -> c4
    { node: 'Circle.030', start: 8.6, moves: [[0, 0, 0], [1, -0.5, 1250], [2, -1, 0]] }, // black knight g8 -> f6
  ];
  for (const lesson of lessons) {
    const nodeIndex = json.nodes.findIndex((node) => node.name === lesson.node);
    if (nodeIndex === -1) throw new Error(`Missing learning node: ${lesson.node}`);
    const node = json.nodes[nodeIndex];
    const base = node.translation;
    const times = [0, lesson.start];
    const translations = [
      translationFor(base, lesson.moves[0]),
      translationFor(base, lesson.moves[0]),
    ];
    for (let index = 1; index < lesson.moves.length; index++) {
      times.push(lesson.start + index * 0.45);
      translations.push(translationFor(base, lesson.moves[index]));
    }
    times.push(15.5, 18);
    translations.push(
      translationFor(base, lesson.moves[lesson.moves.length - 1]),
      translationFor(base, lesson.moves[0]),
    );
    const samplerIndex = animation.samplers.length;
    animation.samplers.push({
      input: addFloatAccessor(new Float32Array(times), 'SCALAR'),
      output: addFloatAccessor(new Float32Array(translations.flat()), 'VEC3'),
      interpolation: 'LINEAR',
    });
    animation.channels.push({
      sampler: samplerIndex,
      target: { node: nodeIndex, path: 'translation' },
    });
  }
  addCaptureScaleAnimation(animation, 'Circle.016', 5.25); // black f7 pawn captured by Qxf7#
  json.animations.push(animation);
}

function addCaptureScaleAnimation(animation, nodeName, captureTime) {
  const nodeIndex = json.nodes.findIndex((node) => node.name === nodeName);
  if (nodeIndex === -1) throw new Error(`Missing capture node: ${nodeName}`);
  const scale = json.nodes[nodeIndex].scale || [1, 1, 1];
  const samplerIndex = animation.samplers.length;
  animation.samplers.push({
    input: addFloatAccessor(new Float32Array([0, captureTime, captureTime + 0.2, 15.5, 18]), 'SCALAR'),
    output: addFloatAccessor(new Float32Array([
      ...scale,
      ...scale,
      0, 0, 0,
      0, 0, 0,
      ...scale,
    ]), 'VEC3'),
    interpolation: 'LINEAR',
  });
  animation.channels.push({
    sampler: samplerIndex,
    target: { node: nodeIndex, path: 'scale' },
  });
}

const combinedBin = Buffer.concat(chunks);
writeGlb(json, combinedBin, output);
console.log(`Wrote ${path.relative(root, output)} with one educational animation.`);

function translationFor(base, move) {
  const [rowDelta, colDelta, lift] = move;
  return [
    base[0] + colDelta * 3600,
    base[1] + lift,
    base[2] - rowDelta * 3600,
  ];
}

function addFloatAccessor(values, type) {
  const buffer = Buffer.from(values.buffer, values.byteOffset, values.byteLength);
  const offset = chunks.reduce((sum, chunk) => sum + chunk.length, 0);
  const padding = Buffer.alloc((4 - offset % 4) % 4);
  if (padding.length) chunks.push(padding);
  const byteOffset = chunks.reduce((sum, chunk) => sum + chunk.length, 0);
  chunks.push(buffer);
  const bufferView = json.bufferViews.length;
  json.bufferViews.push({ buffer: 0, byteOffset, byteLength: buffer.length });
  const accessor = json.accessors.length;
  json.accessors.push({ bufferView, componentType: 5126, count: values.length / (type === 'VEC3' ? 3 : 1), type });
  return accessor;
}

function writeGlb(document, binary, outputPath) {
  document.buffers[0].byteLength = binary.length;
  const jsonBuffer = Buffer.from(JSON.stringify(document));
  const paddedJson = Buffer.concat([jsonBuffer, Buffer.alloc((4 - jsonBuffer.length % 4) % 4, 0x20)]);
  const paddedBin = Buffer.concat([binary, Buffer.alloc((4 - binary.length % 4) % 4)]);
  const header = Buffer.alloc(12);
  header.write('glTF', 0);
  header.writeUInt32LE(2, 4);
  header.writeUInt32LE(12 + 8 + paddedJson.length + 8 + paddedBin.length, 8);
  const jsonHeader = Buffer.alloc(8);
  jsonHeader.writeUInt32LE(paddedJson.length, 0);
  jsonHeader.write('JSON', 4);
  const binHeader = Buffer.alloc(8);
  binHeader.writeUInt32LE(paddedBin.length, 0);
  binHeader.write('BIN\0', 4);
  fs.writeFileSync(outputPath, Buffer.concat([header, jsonHeader, paddedJson, binHeader, paddedBin]));
}
