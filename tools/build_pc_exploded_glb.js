const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const inputPath = path.join(root, 'assets', 'models', 'gaming_desktop_pc.glb');
const outputPath = path.join(root, 'assets', 'models', 'gaming_desktop_pc_exploded.glb');

const rules = [
  {
    part: 'tower casing',
    keywords: ['metal-mesh', 'gallerymodel', 'bg2', 'gigabyte-logo'],
    offset: [-0.85, 0.05, 0.62],
  },
  {
    part: 'motherboard',
    keywords: ['moboaorus', 'ioshield'],
    offset: [-0.75, 0.38, 0.75],
  },
  {
    part: 'gpu',
    keywords: ['nvidia logo', 'geforcertx', 'aorus logotranspa', 'cube.057', 'cube.058', 'cube.059', 'cube.060'],
    offset: [0.95, -0.45, 0.72],
  },
  {
    part: 'psu',
    keywords: ['psuback'],
    offset: [0.75, -0.58, 0.48],
  },
  {
    part: 'storage',
    keywords: ['rgb-hdd', 'maxresdefault'],
    offset: [0.72, -0.28, 0.55],
  },
  {
    part: 'fan rgb',
    keywords: ['aorus case fans'],
    offset: [-0.82, 0.0, 0.68],
  },
  {
    part: 'monitor',
    keywords: ['my screen', 'cube.001', 'cube.002', 'cube.003'],
    offset: [0.0, 0.95, 0.62],
  },
  {
    part: 'keyboard',
    keywords: ['tastatur', 'object_8', 'object_10', 'object_12', 'object_14', 'object_16', 'object_18', 'object_20', 'object_22', 'object_24', 'object_26', 'object_28', 'object_30', 'object_32', 'object_34'],
    offset: [0.0, -0.82, 0.38],
  },
  {
    part: 'mouse and pad',
    keywords: ['souris', 'pewdiepie', 'cube.069'],
    offset: [0.8, -0.48, 0.35],
  },
  {
    part: 'cables',
    keywords: ['beziercurve'],
    offset: [-0.52, -0.34, 0.3],
  },
  {
    part: 'ports',
    keywords: ['usb'],
    offset: [0.58, -0.2, 0.42],
  },
  {
    part: 'desk',
    keywords: ['cube.068', 'cube.070', 'cube.071', 'cube.082', 'cube.088'],
    offset: [0.0, 0.0, -0.42],
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

  const outChunks = chunks.map((chunk) => {
    if (chunk.type === 0x4e4f534a) return { type: chunk.type, data: jsonData };
    return chunk;
  });

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

function parentMap(nodes) {
  const parents = new Map();
  nodes.forEach((node, index) => {
    for (const child of node.children || []) {
      parents.set(child, index);
    }
  });
  return parents;
}

function nodeName(node) {
  return (node.name || '').toLowerCase();
}

function findRule(name) {
  return rules.find((rule) => rule.keywords.some((keyword) => matchesKeyword(name, keyword)));
}

function matchesKeyword(name, keyword) {
  if (keyword.startsWith('object_')) {
    return name === keyword || name.startsWith(`${keyword}_`);
  }

  if (keyword.startsWith('cube.')) {
    return name === keyword || name.startsWith(`${keyword}_`);
  }

  return name.includes(keyword);
}

function hasMatchingParent(index, nodes, parents, rule) {
  let current = parents.get(index);
  while (current !== undefined) {
    const parentName = nodeName(nodes[current]);
    if (rule.keywords.some((keyword) => matchesKeyword(parentName, keyword))) return true;
    current = parents.get(current);
  }
  return false;
}

function addOffset(node, offset) {
  const base = node.translation || [0, 0, 0];
  node.translation = [
    Number((base[0] + offset[0]).toFixed(5)),
    Number((base[1] + offset[1]).toFixed(5)),
    Number((base[2] + offset[2]).toFixed(5)),
  ];

  const baseScale = node.scale || [1, 1, 1];
  node.scale = [
    Number((baseScale[0] * 1.03).toFixed(5)),
    Number((baseScale[1] * 1.03).toFixed(5)),
    Number((baseScale[2] * 1.03).toFixed(5)),
  ];
}

const glb = readGlb(inputPath);
const nodes = glb.json.nodes || [];
const parents = parentMap(nodes);
const changed = [];

nodes.forEach((node, index) => {
  const rule = findRule(nodeName(node));
  if (!rule) return;
  if (hasMatchingParent(index, nodes, parents, rule)) return;
  addOffset(node, rule.offset);
  changed.push(`${index}: ${node.name || '(unnamed)'} -> ${rule.part}`);
});

if (!changed.length) {
  throw new Error('No PC part nodes matched. Exploded GLB was not generated.');
}

glb.json.asset = {
  ...glb.json.asset,
  generator: `${glb.json.asset?.generator || 'unknown'} + Codex exploded PC layout`,
};

writeGlb(outputPath, glb.version, glb.chunks, glb.json);
console.log(`Generated ${path.relative(root, outputPath)}`);
console.log(`Moved ${changed.length} top-level part nodes.`);
console.log(changed.join('\n'));
