const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const inputPath = path.join(root, 'assets', 'models', 'solar-professional.glb');
const outputPath = path.join(root, 'assets', 'models', 'solar-ar.glb');

function align4(length) {
  return (length + 3) & ~3;
}

function parseGlb(buffer) {
  if (buffer.toString('utf8', 0, 4) !== 'glTF') {
    throw new Error('Input is not a GLB file.');
  }

  const chunks = [];
  let offset = 12;
  while (offset < buffer.length) {
    const chunkLength = buffer.readUInt32LE(offset);
    const chunkType = buffer.toString('utf8', offset + 4, offset + 8);
    chunks.push({
      chunkLength,
      chunkType,
      start: offset + 8,
      end: offset + 8 + chunkLength,
    });
    offset += 8 + chunkLength;
  }

  const jsonChunk = chunks.find((chunk) => chunk.chunkType === 'JSON');
  const binChunk = chunks.find((chunk) => chunk.chunkType === 'BIN\0');
  if (!jsonChunk || !binChunk) {
    throw new Error('GLB must contain JSON and BIN chunks.');
  }

  return {
    json: JSON.parse(buffer.toString('utf8', jsonChunk.start, jsonChunk.end).trim()),
    bin: buffer.subarray(binChunk.start, binChunk.end),
  };
}

function writeGlb(json, bin) {
  const jsonText = JSON.stringify(json);
  const jsonPadding = align4(Buffer.byteLength(jsonText)) - Buffer.byteLength(jsonText);
  const jsonBuffer = Buffer.concat([Buffer.from(jsonText), Buffer.alloc(jsonPadding, 0x20)]);
  const binPadding = align4(bin.length) - bin.length;
  const binBuffer = Buffer.concat([bin, Buffer.alloc(binPadding)]);
  const totalLength = 12 + 8 + jsonBuffer.length + 8 + binBuffer.length;

  const header = Buffer.alloc(12);
  header.write('glTF', 0);
  header.writeUInt32LE(2, 4);
  header.writeUInt32LE(totalLength, 8);

  const jsonHeader = Buffer.alloc(8);
  jsonHeader.writeUInt32LE(jsonBuffer.length, 0);
  jsonHeader.write('JSON', 4);

  const binHeader = Buffer.alloc(8);
  binHeader.writeUInt32LE(binBuffer.length, 0);
  binHeader.write('BIN\0', 4);

  fs.writeFileSync(outputPath, Buffer.concat([header, jsonHeader, jsonBuffer, binHeader, binBuffer]));
}

const { json, bin } = parseGlb(fs.readFileSync(inputPath));
const removedNodes = new Set();

json.nodes = (json.nodes || []).map((node, index) => {
  if (node.extras?.generatedOrbitGuide) {
    removedNodes.add(index);
    const { mesh, children, ...rest } = node;
    return {
      ...rest,
      scale: [0, 0, 0],
    };
  }
  return node;
});

json.scenes = (json.scenes || []).map((scene) => ({
  ...scene,
  nodes: (scene.nodes || []).filter((nodeIndex) => !removedNodes.has(nodeIndex)),
}));

json.nodes = json.nodes.map((node) => {
  if (!node.children) return node;
  return {
    ...node,
    children: node.children.filter((nodeIndex) => !removedNodes.has(nodeIndex)),
  };
});

json.animations = (json.animations || [])
  .map((animation) => {
    const usedSamplers = new Set();
    const channels = (animation.channels || []).filter((channel) => {
      const keep = !removedNodes.has(channel.target?.node);
      if (keep) usedSamplers.add(channel.sampler);
      return keep;
    });

    const samplerMap = new Map();
    const samplers = [];
    (animation.samplers || []).forEach((sampler, index) => {
      if (!usedSamplers.has(index)) return;
      samplerMap.set(index, samplers.length);
      samplers.push(sampler);
    });

    return {
      ...animation,
      samplers,
      channels: channels.map((channel) => ({
        ...channel,
        sampler: samplerMap.get(channel.sampler),
      })),
    };
  })
  .filter((animation) => animation.channels.length > 0);

json.extensionsUsed = (json.extensionsUsed || []).filter(
  (extension) => extension !== 'KHR_materials_emissive_strength',
);
if (json.extensionsUsed.length === 0) delete json.extensionsUsed;
delete json.extensionsRequired;

(json.materials || []).forEach((material) => {
  delete material.extensions;
});

json.asset = {
  ...json.asset,
  generator: 'Codex AR-compatible solar-system pass',
};

writeGlb(json, bin);
console.log(`Created ${outputPath}`);
