const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const inputPath = path.join(root, 'assets', 'models', 'computer-_pc_futuristic.glb');
const normalPath = path.join(root, 'assets', 'models', 'computer_pc_futuristic_named.glb');
const explodedPath = path.join(root, 'assets', 'models', 'computer_pc_futuristic_exploded.glb');

const partGroups = [
  {
    part: 'Futuristic Case',
    nodes: [2, 3, 4, 9, 16, 18, 22, 23, 24, 33, 34, 35, 36, 37, 38],
    offset: [-0.6, 0.0, 0.45],
  },
  {
    part: 'Side Panel',
    nodes: [11, 12, 13],
    offset: [-1.05, 0.0, 0.25],
  },
  {
    part: 'Motherboard',
    nodes: [10, 17, 27, 28],
    offset: [-0.25, 0.55, 0.55],
  },
  {
    part: 'Cooling System',
    nodes: [8, 25, 43],
    offset: [0.0, 0.85, 0.7],
  },
  {
    part: 'Memory Module',
    nodes: [20, 26, 29, 30, 31, 32],
    offset: [-0.65, 0.35, 0.85],
  },
  {
    part: 'Graphics Unit',
    nodes: [14, 15, 21, 39, 40],
    offset: [0.85, -0.25, 0.55],
  },
  {
    part: 'Power Bay',
    nodes: [5, 6, 7, 19],
    offset: [0.55, -0.75, 0.35],
  },
  {
    part: 'Rear I/O',
    nodes: [41, 42],
    offset: [0.35, -0.35, 0.8],
  },
];

function align4(value) {
  return (value + 3) & ~3;
}

function readGlb(filePath) {
  const buffer = fs.readFileSync(filePath);
  if (buffer.slice(0, 4).toString('ascii') !== 'glTF') {
    throw new Error(`${filePath} is not a binary glTF file.`);
  }

  const chunks = [];
  let offset = 12;
  while (offset < buffer.length) {
    const chunkLength = buffer.readUInt32LE(offset);
    const chunkType = buffer.readUInt32LE(offset + 4);
    chunks.push({
      type: chunkType,
      data: buffer.slice(offset + 8, offset + 8 + chunkLength),
    });
    offset += 8 + chunkLength;
  }

  const jsonChunk = chunks.find((chunk) => chunk.type === 0x4e4f534a);
  if (!jsonChunk) throw new Error('GLB JSON chunk not found.');

  return {
    version: buffer.readUInt32LE(4),
    chunks,
    json: JSON.parse(jsonChunk.data.toString('utf8').trim()),
  };
}

function writeGlb(filePath, version, chunks, json) {
  const jsonText = JSON.stringify(json);
  const jsonLength = align4(Buffer.byteLength(jsonText));
  const jsonData = Buffer.alloc(jsonLength, 0x20);
  jsonData.write(jsonText);

  const outChunks = chunks.map((chunk) => (
    chunk.type === 0x4e4f534a ? { type: chunk.type, data: jsonData } : chunk
  ));

  const totalLength = 12 + outChunks.reduce((sum, chunk) => sum + 8 + chunk.data.length, 0);
  const output = Buffer.alloc(totalLength);
  output.write('glTF', 0, 'ascii');
  output.writeUInt32LE(version, 4);
  output.writeUInt32LE(totalLength, 8);

  let offset = 12;
  for (const chunk of outChunks) {
    output.writeUInt32LE(chunk.data.length, offset);
    output.writeUInt32LE(chunk.type, offset + 4);
    chunk.data.copy(output, offset + 8);
    offset += 8 + chunk.data.length;
  }

  fs.writeFileSync(filePath, output);
}

function cloneGlb(glb) {
  return {
    version: glb.version,
    chunks: glb.chunks,
    json: JSON.parse(JSON.stringify(glb.json)),
  };
}

function applyNames(glb) {
  const nodes = glb.json.nodes || [];
  if (nodes[1]) nodes[1].name = 'Futuristic Gaming PC Tower';

  for (const group of partGroups) {
    for (const nodeIndex of group.nodes) {
      const node = nodes[nodeIndex];
      if (!node) continue;
      node.name = `${group.part} ${node.name || `Node_${nodeIndex}`}`;
    }
  }

  glb.json.asset = {
    ...glb.json.asset,
    generator: `${glb.json.asset?.generator || 'unknown'} + Codex semantic PC labels`,
  };
}

function applyExplode(glb) {
  const nodes = glb.json.nodes || [];
  for (const group of partGroups) {
    for (const nodeIndex of group.nodes) {
      const node = nodes[nodeIndex];
      if (!node) continue;
      const base = node.translation || [0, 0, 0];
      node.translation = [
        Number((base[0] + group.offset[0]).toFixed(5)),
        Number((base[1] + group.offset[1]).toFixed(5)),
        Number((base[2] + group.offset[2]).toFixed(5)),
      ];

      const baseScale = node.scale || [1, 1, 1];
      node.scale = [
        Number((baseScale[0] * 1.02).toFixed(5)),
        Number((baseScale[1] * 1.02).toFixed(5)),
        Number((baseScale[2] * 1.02).toFixed(5)),
      ];
    }
  }

  glb.json.asset = {
    ...glb.json.asset,
    generator: `${glb.json.asset?.generator || 'unknown'} + Codex semantic PC exploded layout`,
  };
}

const source = readGlb(inputPath);

const normal = cloneGlb(source);
applyNames(normal);
writeGlb(normalPath, normal.version, normal.chunks, normal.json);

const exploded = cloneGlb(source);
applyNames(exploded);
applyExplode(exploded);
writeGlb(explodedPath, exploded.version, exploded.chunks, exploded.json);

console.log(`Generated ${path.relative(root, normalPath)}`);
console.log(`Generated ${path.relative(root, explodedPath)}`);
console.log(`Renamed ${partGroups.reduce((sum, group) => sum + group.nodes.length, 0)} nodes across ${partGroups.length} part groups.`);
