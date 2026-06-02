const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const input = path.join(root, 'assets', 'models', 'chess.glb');
const output = path.join(root, 'assets', 'models', 'chess-interactive.glb');
const source = fs.readFileSync(input);
const jsonLength = source.readUInt32LE(12);
const json = JSON.parse(source.toString('utf8', 20, 20 + jsonLength));
const binOffset = 20 + jsonLength + 8;
const bin = Buffer.from(source.subarray(binOffset));

const pieceRoots = json.nodes
  .map((node, index) => ({ node, index }))
  .filter(({ node }) => /^Circle(\.\d+)?$/.test(node.name || ''));

for (const { node } of pieceRoots) {
  const child = json.nodes[node.children[0]];
  const mesh = json.meshes[child.mesh];
  const accessor = json.accessors[mesh.primitives[0].attributes.POSITION];
  const center = [
    (accessor.min[0] + accessor.max[0]) / 2,
    (accessor.min[1] + accessor.max[1]) / 2,
    0,
  ];
  for (const childIndex of node.children) {
    centerAccessor(json, bin, json.nodes[childIndex].mesh, center);
  }
  // Convert the original matrix node into standard TRS. glTF runtime animation
  // and Three.js position updates are reliable only when matrix is not fixed.
  const matrix = node.matrix;
  node.translation = [
    center[0] * matrix[0] + center[1] * matrix[4] + center[2] * matrix[8],
    center[0] * matrix[1] + center[1] * matrix[5] + center[2] * matrix[9],
    center[0] * matrix[2] + center[1] * matrix[6] + center[2] * matrix[10],
  ];
  node.rotation = [-Math.SQRT1_2, 0, 0, Math.SQRT1_2];
  node.scale = [1000, 1000, 1000];
  delete node.matrix;
}

json.animations = [];
const chunks = [bin];
for (const { node, index } of pieceRoots) {
  for (let rowDelta = -7; rowDelta <= 7; rowDelta++) {
    for (let colDelta = -7; colDelta <= 7; colDelta++) {
      if (rowDelta === 0 && colDelta === 0) continue;
      addMoveAnimation(node, index, rowDelta, colDelta);
    }
  }
  addScaleAnimation(`hide|${node.name}`, index, node.scale, [0, 0, 0]);
  addScaleAnimation(`show|${node.name}`, index, [0, 0, 0], node.scale);
}
json.buffers[0].byteLength = chunks.reduce((sum, chunk) => sum + chunk.length, 0);
const combinedBin = Buffer.concat(chunks);
writeGlb(json, combinedBin, output);
console.log(`Wrote ${path.relative(root, output)} with ${pieceRoots.length} movable pieces and ${json.animations.length} move clips.`);

function addMoveAnimation(node, nodeIndex, rowDelta, colDelta) {
  const timeAccessor = addFloatAccessor(new Float32Array([0, 0.38]), 'SCALAR');
  const start = node.translation;
  const translationAccessor = addFloatAccessor(new Float32Array([
    start[0], start[1], start[2],
    start[0] + colDelta * 3600, start[1], start[2] - rowDelta * 3600,
  ]), 'VEC3');
  json.animations.push({
    name: `move|${node.name}|${rowDelta}|${colDelta}`,
    samplers: [{ input: timeAccessor, output: translationAccessor, interpolation: 'LINEAR' }],
    channels: [{ sampler: 0, target: { node: nodeIndex, path: 'translation' } }],
  });
}

function addScaleAnimation(name, nodeIndex, from, to) {
  const timeAccessor = addFloatAccessor(new Float32Array([0, 0.18]), 'SCALAR');
  const scaleAccessor = addFloatAccessor(new Float32Array([...from, ...to]), 'VEC3');
  json.animations.push({
    name,
    samplers: [{ input: timeAccessor, output: scaleAccessor, interpolation: 'LINEAR' }],
    channels: [{ sampler: 0, target: { node: nodeIndex, path: 'scale' } }],
  });
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

function centerAccessor(document, buffer, meshIndex, center) {
  const mesh = document.meshes[meshIndex];
  for (const primitive of mesh.primitives) {
    const accessor = document.accessors[primitive.attributes.POSITION];
    const view = document.bufferViews[accessor.bufferView];
    const offset = (view.byteOffset || 0) + (accessor.byteOffset || 0);
    const stride = view.byteStride || 12;
    for (let index = 0; index < accessor.count; index++) {
      const cursor = offset + index * stride;
      buffer.writeFloatLE(buffer.readFloatLE(cursor) - center[0], cursor);
      buffer.writeFloatLE(buffer.readFloatLE(cursor + 4) - center[1], cursor + 4);
    }
    accessor.min[0] -= center[0];
    accessor.max[0] -= center[0];
    accessor.min[1] -= center[1];
    accessor.max[1] -= center[1];
  }
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
