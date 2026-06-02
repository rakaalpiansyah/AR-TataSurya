const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const outputPath = path.join(root, 'assets', 'models', 'pc-professional.glb');

const cubePositions = new Float32Array([
  -0.5, -0.5, 0.5, 0.5, -0.5, 0.5, 0.5, 0.5, 0.5, -0.5, 0.5, 0.5,
  0.5, -0.5, -0.5, -0.5, -0.5, -0.5, -0.5, 0.5, -0.5, 0.5, 0.5, -0.5,
  -0.5, -0.5, -0.5, -0.5, -0.5, 0.5, -0.5, 0.5, 0.5, -0.5, 0.5, -0.5,
  0.5, -0.5, 0.5, 0.5, -0.5, -0.5, 0.5, 0.5, -0.5, 0.5, 0.5, 0.5,
  -0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, -0.5, -0.5, 0.5, -0.5,
  -0.5, -0.5, -0.5, 0.5, -0.5, -0.5, 0.5, -0.5, 0.5, -0.5, -0.5, 0.5,
]);

const cubeNormals = new Float32Array([
  0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1,
  0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1,
  -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0,
  1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0,
  0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0,
  0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0,
]);

const cubeIndices = new Uint16Array([
  0, 1, 2, 0, 2, 3,
  4, 5, 6, 4, 6, 7,
  8, 9, 10, 8, 10, 11,
  12, 13, 14, 12, 14, 15,
  16, 17, 18, 16, 18, 19,
  20, 21, 22, 20, 22, 23,
]);

const json = {
  asset: { version: '2.0', generator: 'Codex procedural gaming PC model' },
  scene: 0,
  scenes: [{ name: 'Gaming PC Exploded View', nodes: [] }],
  nodes: [],
  meshes: [],
  materials: [],
  buffers: [{ byteLength: 0 }],
  bufferViews: [],
  accessors: [],
};

const chunks = [];
const cubePositionAccessor = addAccessor(typed(cubePositions), 34962, 5126, cubePositions.length / 3, 'VEC3', [-0.5, -0.5, -0.5], [0.5, 0.5, 0.5]);
const cubeNormalAccessor = addAccessor(typed(cubeNormals), 34962, 5126, cubeNormals.length / 3, 'VEC3');
const cubeIndexAccessor = addAccessor(typed(cubeIndices), 34963, 5123, cubeIndices.length, 'SCALAR', [0], [23]);

const material = {
  glass: mat('Tempered glass cyan', [0.34, 0.58, 0.78, 0.28], true, [0.02, 0.08, 0.12]),
  frame: mat('Matte black case metal', [0.015, 0.017, 0.022, 1], false, [0.01, 0.012, 0.018]),
  board: mat('Dark teal motherboard PCB', [0.02, 0.14, 0.13, 1], false, [0.0, 0.08, 0.07]),
  metal: mat('Brushed silver metal', [0.62, 0.66, 0.72, 1], false, [0.04, 0.04, 0.05]),
  cooler: mat('Cooler black fins', [0.04, 0.05, 0.06, 1], false, [0.0, 0.12, 0.16]),
  cyan: mat('RGB cyan accent', [0.04, 0.42, 0.62, 1], false, [0.0, 0.55, 0.9]),
  magenta: mat('RGB magenta accent', [0.24, 0.06, 0.36, 1], false, [0.45, 0.0, 0.75]),
  gpu: mat('GPU graphite shroud', [0.035, 0.038, 0.048, 1], false, [0.12, 0.02, 0.2]),
  psu: mat('PSU dark block', [0.035, 0.038, 0.044, 1], false, [0.01, 0.01, 0.012]),
  storage: mat('Storage satin gray', [0.14, 0.15, 0.17, 1], false, [0.03, 0.03, 0.035]),
  cable: mat('Cable sleeving', [0.008, 0.008, 0.01, 1], false, [0, 0, 0]),
};

const parts = [
  {
    name: 'Frame Casing',
    id: 'case_frame',
    assembled: [0, 0, 0],
    exploded: [0, 0, 0],
    shapes: [
      rail('top_front', [-2.2, 1.55, 1.25], [4.4, 0.10, 0.10]),
      rail('top_back', [-2.2, 1.55, -1.25], [4.4, 0.10, 0.10]),
      rail('bottom_front', [-2.2, -1.55, 1.25], [4.4, 0.10, 0.10]),
      rail('bottom_back', [-2.2, -1.55, -1.25], [4.4, 0.10, 0.10]),
      rail('left_front', [-2.2, 0, 1.25], [0.10, 3.1, 0.10]),
      rail('right_front', [2.2, 0, 1.25], [0.10, 3.1, 0.10]),
      rail('left_back', [-2.2, 0, -1.25], [0.10, 3.1, 0.10]),
      rail('right_back', [2.2, 0, -1.25], [0.10, 3.1, 0.10]),
      shape('psu_shroud', [0.85, -1.18, -0.25], [2.5, 0.42, 1.85], material.frame),
    ],
  },
  {
    name: 'Panel Samping Transparan',
    id: 'side_panel',
    assembled: [0, 0, 0],
    exploded: [-1.1, 0, 1.1],
    shapes: [shape('glass_panel', [0, 0, 1.34], [4.42, 3.08, 0.035], material.glass)],
  },
  {
    name: 'Motherboard',
    id: 'motherboard',
    assembled: [-0.75, 0.12, 0.26],
    exploded: [-1.45, 0.35, 1.15],
    shapes: [
      shape('pcb', [0, 0, 0], [2.35, 2.25, 0.08], material.board),
      shape('io_cover', [-0.96, 0.72, 0.08], [0.35, 0.75, 0.10], material.metal),
      shape('chipset', [0.62, -0.48, 0.08], [0.42, 0.42, 0.08], material.metal),
      shape('pcie_slot', [0.25, -0.82, 0.10], [1.35, 0.08, 0.08], material.cyan),
      shape('ram_slot_1', [0.72, 0.32, 0.10], [0.08, 1.25, 0.08], material.cyan),
      shape('ram_slot_2', [0.88, 0.32, 0.10], [0.08, 1.25, 0.08], material.cyan),
    ],
  },
  {
    name: 'CPU',
    id: 'cpu',
    assembled: [-0.96, 0.56, 0.44],
    exploded: [-1.8, 1.0, 1.55],
    shapes: [
      shape('cpu_heat_spreader', [0, 0, 0], [0.58, 0.58, 0.08], material.metal),
      shape('cpu_socket', [0, 0, -0.05], [0.72, 0.72, 0.04], material.frame),
    ],
  },
  {
    name: 'CPU Cooler',
    id: 'cpu_cooler',
    assembled: [-0.96, 0.56, 0.72],
    exploded: [-1.9, 1.28, 1.95],
    shapes: [
      shape('cooler_fins', [0, 0, 0], [0.92, 0.92, 0.28], material.cooler),
      shape('cooler_fan', [0, 0, 0.18], [0.72, 0.72, 0.06], material.cyan),
      shape('cooler_center', [0, 0, 0.22], [0.28, 0.28, 0.07], material.frame),
    ],
  },
  {
    name: 'RAM',
    id: 'ram',
    assembled: [-0.05, 0.76, 0.45],
    exploded: [0.45, 1.3, 1.55],
    shapes: [
      shape('ram_stick_a', [-0.09, 0, 0], [0.10, 1.2, 0.22], material.frame),
      shape('ram_rgb_a', [-0.09, 0, 0.14], [0.08, 1.12, 0.06], material.cyan),
      shape('ram_stick_b', [0.12, 0, 0], [0.10, 1.2, 0.22], material.frame),
      shape('ram_rgb_b', [0.12, 0, 0.14], [0.08, 1.12, 0.06], material.magenta),
    ],
  },
  {
    name: 'GPU',
    id: 'gpu',
    assembled: [-0.30, -0.60, 0.58],
    exploded: [0.35, -1.25, 1.85],
    shapes: [
      shape('gpu_board', [0, 0, -0.08], [1.95, 0.34, 0.08], material.board),
      shape('gpu_shroud', [0, 0, 0.08], [1.9, 0.46, 0.24], material.gpu),
      shape('gpu_fan_left', [-0.45, 0, 0.23], [0.42, 0.34, 0.06], material.cyan),
      shape('gpu_fan_right', [0.45, 0, 0.23], [0.42, 0.34, 0.06], material.magenta),
    ],
  },
  {
    name: 'Power Supply Unit',
    id: 'psu',
    assembled: [1.12, -1.0, 0.18],
    exploded: [1.95, -1.45, 0.95],
    shapes: [
      shape('psu_body', [0, 0, 0], [1.05, 0.62, 0.68], material.psu),
      shape('psu_label', [0, 0.33, 0.01], [0.72, 0.04, 0.42], material.metal),
      shape('psu_fan_grill', [0, 0, 0.36], [0.52, 0.52, 0.04], material.frame),
    ],
  },
  {
    name: 'NVMe SSD',
    id: 'nvme',
    assembled: [-0.05, 0.0, 0.47],
    exploded: [0.75, 0.15, 1.45],
    shapes: [
      shape('nvme_board', [0, 0, 0], [0.95, 0.16, 0.06], material.frame),
      shape('nvme_label', [0.12, 0, 0.05], [0.38, 0.13, 0.035], material.cyan),
    ],
  },
  {
    name: 'Storage Drive',
    id: 'storage',
    assembled: [1.15, -0.24, 0.18],
    exploded: [1.95, -0.35, 0.95],
    shapes: [
      shape('drive_body', [0, 0, 0], [0.86, 0.58, 0.16], material.storage),
      shape('drive_label', [0, 0, 0.10], [0.62, 0.38, 0.035], material.metal),
    ],
  },
  {
    name: 'Front Intake Fans',
    id: 'front_fans',
    assembled: [-2.14, 0.22, 0.38],
    exploded: [-2.85, 0.18, 1.12],
    shapes: [
      shape('front_fan_top', [0, 0.52, 0], [0.12, 0.64, 0.64], material.cyan),
      shape('front_fan_mid', [0, -0.22, 0], [0.12, 0.64, 0.64], material.magenta),
      shape('front_filter', [0.05, 0.15, -0.04], [0.08, 1.7, 1.1], material.frame),
    ],
  },
  {
    name: 'Rear Exhaust Fan',
    id: 'rear_fan',
    assembled: [2.12, 0.78, 0.38],
    exploded: [2.75, 1.05, 1.05],
    shapes: [
      shape('rear_fan', [0, 0, 0], [0.12, 0.66, 0.66], material.cyan),
      shape('rear_grill', [-0.05, 0, 0], [0.08, 0.8, 0.8], material.frame),
    ],
  },
  {
    name: 'Cable Bundle',
    id: 'cables',
    assembled: [0.75, -0.38, 0.74],
    exploded: [1.55, -0.85, 1.55],
    shapes: [
      shape('atx_cable', [0, 0, 0], [1.2, 0.08, 0.08], material.cable),
      shape('gpu_power', [0.25, -0.18, 0.06], [0.95, 0.08, 0.08], material.cable),
      shape('rgb_cable', [-0.2, 0.18, 0.08], [0.75, 0.06, 0.06], material.cyan),
    ],
  },
];

function shape(name, translation, scale, materialIndex) {
  return { name, translation, scale, materialIndex };
}

function rail(name, translation, scale) {
  return shape(name, translation, scale, material.frame);
}

function mat(name, color, blend = false, emissive = [0, 0, 0]) {
  json.materials.push({
    name,
    alphaMode: blend ? 'BLEND' : 'OPAQUE',
    doubleSided: true,
    emissiveFactor: emissive,
    pbrMetallicRoughness: {
      baseColorFactor: color,
      metallicFactor: blend ? 0.05 : 0.25,
      roughnessFactor: 0.35,
    },
  });
  return json.materials.length - 1;
}

parts.forEach((part, partIndex) => {
  const children = part.shapes.map((item) => {
    const meshIndex = json.meshes.push({
      name: `${part.name} - ${item.name}`,
      primitives: [{
        attributes: { POSITION: cubePositionAccessor, NORMAL: cubeNormalAccessor },
        indices: cubeIndexAccessor,
        material: item.materialIndex,
      }],
    }) - 1;
    return json.nodes.push({
      name: `${part.name} ${item.name}`,
      mesh: meshIndex,
      translation: item.translation,
      scale: item.scale,
    }) - 1;
  });

  const rootNode = json.nodes.push({
    name: part.name,
    children,
    translation: part.assembled,
    extras: {
      pcPartId: part.id,
      pcPartIndex: partIndex + 1,
      assembled: part.assembled,
      exploded: part.exploded,
    },
  }) - 1;
  json.scenes[0].nodes.push(rootNode);
});

function align4(value) {
  return (value + 3) & ~3;
}

function typed(array) {
  return Buffer.from(array.buffer, array.byteOffset, array.byteLength);
}

function addAccessor(buffer, target, componentType, count, type, min, max) {
  const bufferView = addBufferView(buffer, target);
  const accessor = { bufferView, componentType, count, type };
  if (min) accessor.min = min;
  if (max) accessor.max = max;
  json.accessors.push(accessor);
  return json.accessors.length - 1;
}

function addBufferView(buffer, target) {
  const current = chunks.reduce((sum, chunk) => sum + chunk.length, 0);
  const aligned = chunks.reduce((sum, chunk) => sum + align4(chunk.length), 0);
  const padding = Buffer.alloc(aligned - current);
  if (padding.length) chunks.push(padding);
  json.bufferViews.push({
    buffer: 0,
    byteOffset: aligned,
    byteLength: buffer.length,
    ...(target ? { target } : {}),
  });
  chunks.push(buffer);
  return json.bufferViews.length - 1;
}

function writeGlb() {
  const bin = Buffer.concat(chunks);
  json.buffers[0].byteLength = bin.length;
  const jsonText = JSON.stringify(json);
  const jsonPadding = align4(Buffer.byteLength(jsonText)) - Buffer.byteLength(jsonText);
  const jsonBuffer = Buffer.concat([Buffer.from(jsonText), Buffer.alloc(jsonPadding, 0x20)]);
  const binPadding = align4(bin.length) - bin.length;
  const binBuffer = Buffer.concat([bin, Buffer.alloc(binPadding)]);
  const header = Buffer.alloc(12);
  header.write('glTF', 0);
  header.writeUInt32LE(2, 4);
  header.writeUInt32LE(12 + 8 + jsonBuffer.length + 8 + binBuffer.length, 8);
  const jsonHeader = Buffer.alloc(8);
  jsonHeader.writeUInt32LE(jsonBuffer.length, 0);
  jsonHeader.write('JSON', 4);
  const binHeader = Buffer.alloc(8);
  binHeader.writeUInt32LE(binBuffer.length, 0);
  binHeader.write('BIN\0', 4);
  fs.writeFileSync(outputPath, Buffer.concat([header, jsonHeader, jsonBuffer, binHeader, binBuffer]));
}

writeGlb();
console.log(`Created ${outputPath}`);
