const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const inputPath = path.join(root, 'assets', 'models', 'solar-withname.glb');
const outputPath = path.join(root, 'assets', 'models', 'solar-professional.glb');

const planetLabels = new Map([
  [2, 'Bumi'],
  [7, 'Jupiter'],
  [12, 'Mars'],
  [17, 'Merkurius'],
  [25, 'Neptunus'],
  [30, 'Pluto'],
  [37, 'Saturnus'],
  [40, 'Matahari'],
  [44, 'Uranus'],
  [49, 'Venus'],
  [54, 'Merkurius'],
  [55, 'Venus'],
  [56, 'Bulan'],
]);

const hiddenNodes = new Set([28, 29, 30, 31, 32]);
const LOOP_DURATION = 168;
const LOOP_STEPS = 169;
const EARTH_ORBIT_PERIOD = 42;
const ORBIT_RADII = {
  mercury: 7.2,
  venus: 9.4,
  earth: 11.8,
  mars: 14.4,
  jupiter: 18.6,
  saturn: 22.6,
  uranus: 26.2,
  neptune: 29.6,
};
const EARTH_ORBIT_RADIUS = ORBIT_RADII.earth;
const MOON_ORBIT_RADIUS = 1.35;
const detachedPlanarNodes = new Map([
  [3, EARTH_ORBIT_RADIUS],
  [13, ORBIT_RADII.mars],
  [8, ORBIT_RADII.jupiter],
  [38, ORBIT_RADII.saturn],
  [45, ORBIT_RADII.uranus],
  [26, ORBIT_RADII.neptune],
]);
const visualScales = new Map([
  [40, [0.62, 0.62, 0.62]],
  [54, [0.24, 0.24, 0.24]],
  [55, [0.38, 0.38, 0.38]],
  [3, [0.40, 0.40, 0.40]],
  [56, [0.12, 0.12, 0.12]],
  [13, [0.32, 0.32, 0.32]],
  [8, [0.86, 0.86, 0.86]],
  [38, [0.78, 0.78, 0.78]],
  [45, [0.54, 0.54, 0.54]],
  [26, [0.54, 0.54, 0.54]],
]);

const orbitNodes = [
];

const spinNodes = [
  { node: 40, name: 'Rotasi Matahari', period: 56 },
  { node: 54, name: 'Rotasi Merkurius', period: 84 },
  { node: 55, name: 'Rotasi Venus', period: 168, retrograde: true },
  { node: 3, name: 'Rotasi Bumi', period: 24 },
  { node: 56, name: 'Rotasi Bulan', period: 56 },
  { node: 13, name: 'Rotasi Mars', period: 28 },
  { node: 8, name: 'Rotasi Jupiter', period: 14 },
  { node: 38, name: 'Rotasi Saturnus', period: 14 },
  { node: 45, name: 'Rotasi Uranus', period: 24 },
  { node: 26, name: 'Rotasi Neptunus', period: 24 },
];

const translationOrbitNodes = [
  {
    node: 54,
    name: 'Orbit Merkurius',
    period: 24,
    radius: ORBIT_RADII.mercury,
    center: [0, 0, 0],
    retrograde: true,
  },
  {
    node: 55,
    name: 'Orbit Venus',
    period: 28,
    radius: ORBIT_RADII.venus,
    center: [0, 0, 0],
    retrograde: true,
  },
  {
    node: 3,
    name: 'Orbit Bumi',
    period: EARTH_ORBIT_PERIOD,
    radius: ORBIT_RADII.earth,
    center: [0, 0, 0],
    retrograde: true,
  },
  {
    node: 56,
    name: 'Orbit Bulan mengitari Bumi',
    period: 14,
    retrograde: true,
    moonAroundEarth: true,
  },
  {
    node: 13,
    name: 'Orbit Mars',
    period: 56,
    radius: ORBIT_RADII.mars,
    center: [0, 0, 0],
    retrograde: true,
  },
  {
    node: 8,
    name: 'Orbit Jupiter',
    period: 84,
    radius: ORBIT_RADII.jupiter,
    center: [0, 0, 0],
    retrograde: true,
  },
  {
    node: 38,
    name: 'Orbit Saturnus',
    period: 112,
    radius: ORBIT_RADII.saturn,
    center: [0, 0, 0],
    retrograde: true,
  },
  {
    node: 45,
    name: 'Orbit Uranus',
    period: 168,
    radius: ORBIT_RADII.uranus,
    center: [0, 0, 0],
    retrograde: true,
  },
  {
    node: 26,
    name: 'Orbit Neptunus',
    period: 168,
    radius: ORBIT_RADII.neptune,
    center: [0, 0, 0],
    retrograde: true,
  },
];

const solarOrbitLines = [
  { name: 'Garis Orbit Merkurius', radius: ORBIT_RADII.mercury },
  { name: 'Garis Orbit Venus', radius: ORBIT_RADII.venus },
  { name: 'Garis Orbit Bumi', radius: EARTH_ORBIT_RADIUS },
  { name: 'Garis Orbit Mars', radius: ORBIT_RADII.mars },
  { name: 'Garis Orbit Jupiter', radius: ORBIT_RADII.jupiter },
  { name: 'Garis Orbit Saturnus', radius: ORBIT_RADII.saturn },
  { name: 'Garis Orbit Uranus', radius: ORBIT_RADII.uranus },
  { name: 'Garis Orbit Neptunus', radius: ORBIT_RADII.neptune },
];

function align4(length) {
  return (length + 3) & ~3;
}

function parseGlb(buffer) {
  if (buffer.toString('utf8', 0, 4) !== 'glTF') {
    throw new Error('Input is not a binary glTF file.');
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

function quatMultiply(a, b) {
  const [ax, ay, az, aw] = a;
  const [bx, by, bz, bw] = b;
  return [
    aw * bx + ax * bw + ay * bz - az * by,
    aw * by - ax * bz + ay * bw + az * bx,
    aw * bz + ax * by - ay * bx + az * bw,
    aw * bw - ax * bx - ay * by - az * bz,
  ];
}

function quatFromAxisAngle(axis, angle) {
  const half = angle / 2;
  const s = Math.sin(half);
  return [axis[0] * s, axis[1] * s, axis[2] * s, Math.cos(half)];
}

function normalizedQuat(q) {
  const len = Math.hypot(q[0], q[1], q[2], q[3]) || 1;
  return q.map((value) => value / len);
}

function makeTimeBuffer(duration) {
  const times = Array.from({ length: LOOP_STEPS }, (_, index) => (
    (duration * index) / (LOOP_STEPS - 1)
  ));
  const buffer = Buffer.alloc(times.length * 4);
  times.forEach((time, index) => buffer.writeFloatLE(time, index * 4));
  return { buffer, times };
}

function makeRotationBuffer(baseRotation, period, retrograde = false) {
  const direction = retrograde ? -1 : 1;
  const angles = Array.from({ length: LOOP_STEPS }, (_, index) => {
    const time = (LOOP_DURATION * index) / (LOOP_STEPS - 1);
    return ((Math.PI * 2 * time) / period) * direction;
  });
  const buffer = Buffer.alloc(angles.length * 4 * 4);

  angles.forEach((angle, index) => {
    const delta = quatFromAxisAngle([0, 1, 0], angle);
    const quat = normalizedQuat(quatMultiply(baseRotation, delta));
    quat.forEach((value, component) => {
      buffer.writeFloatLE(value, (index * 4 + component) * 4);
    });
  });

  return { buffer, count: angles.length };
}

function makeTranslationBuffer(baseTranslation, center, period, retrograde = false) {
  const direction = retrograde ? -1 : 1;
  const offset = [
    baseTranslation[0] - center[0],
    baseTranslation[1] - center[1],
    baseTranslation[2] - center[2],
  ];
  const buffer = Buffer.alloc(LOOP_STEPS * 3 * 4);

  for (let index = 0; index < LOOP_STEPS; index += 1) {
    const time = (LOOP_DURATION * index) / (LOOP_STEPS - 1);
    const angle = ((Math.PI * 2 * time) / period) * direction;
    const cos = Math.cos(angle);
    const sin = Math.sin(angle);
    const translated = [
      center[0] + offset[0] * cos - offset[2] * sin,
      0,
      center[2] + offset[0] * sin + offset[2] * cos,
    ];

    translated.forEach((value, component) => {
      buffer.writeFloatLE(value, (index * 3 + component) * 4);
    });
  }

  return { buffer, count: LOOP_STEPS };
}

function makePlanarOrbitTranslationBuffer(radius, period, retrograde = false) {
  return makeTranslationBuffer([0, 0, radius], [0, 0, 0], period, retrograde);
}

function makeMoonTranslationBuffer(baseTranslation, period, retrograde = false) {
  const direction = retrograde ? -1 : 1;
  const earthInitial = [0, 0, EARTH_ORBIT_RADIUS];
  const moonDistance = MOON_ORBIT_RADIUS;
  const buffer = Buffer.alloc(LOOP_STEPS * 3 * 4);

  for (let index = 0; index < LOOP_STEPS; index += 1) {
    const time = (LOOP_DURATION * index) / (LOOP_STEPS - 1);
    const earthAngle = ((Math.PI * 2 * time) / EARTH_ORBIT_PERIOD) * direction;
    const moonAngle = ((Math.PI * 2 * time) / period) * direction;
    const earthCos = Math.cos(earthAngle);
    const earthSin = Math.sin(earthAngle);
    const moonCos = Math.cos(moonAngle);
    const moonSin = Math.sin(moonAngle);

    const earthPosition = [
      earthInitial[0] * earthCos - earthInitial[2] * earthSin,
      0,
      earthInitial[0] * earthSin + earthInitial[2] * earthCos,
    ];
    const moonLocal = [
      moonDistance * moonCos,
      0,
      moonDistance * moonSin,
    ];
    const translated = [
      earthPosition[0] + moonLocal[0],
      earthPosition[1] + moonLocal[1],
      earthPosition[2] + moonLocal[2],
    ];

    translated.forEach((value, component) => {
      buffer.writeFloatLE(value, (index * 3 + component) * 4);
    });
  }

  return { buffer, count: LOOP_STEPS };
}

function makeOrbitLineBuffer(radius, segments = 192) {
  const vertices = [];
  for (let index = 0; index < segments; index += 1) {
    const next = (index + 1) % segments;
    const angle = (Math.PI * 2 * index) / segments;
    const nextAngle = (Math.PI * 2 * next) / segments;
    vertices.push(Math.sin(angle) * radius, 0, Math.cos(angle) * radius);
    vertices.push(Math.sin(nextAngle) * radius, 0, Math.cos(nextAngle) * radius);
  }

  const buffer = Buffer.alloc(vertices.length * 4);
  vertices.forEach((value, index) => buffer.writeFloatLE(value, index * 4));
  return { buffer, count: vertices.length / 3 };
}

function moonOrbitRadius() {
  return MOON_ORBIT_RADIUS;
}

function appendBufferView(json, chunks, source) {
  const paddedOffset = chunks.reduce((sum, chunk) => sum + align4(chunk.length), 0);
  const padding = Buffer.alloc(paddedOffset - chunks.reduce((sum, chunk) => sum + chunk.length, 0));
  if (padding.length) chunks.push(padding);

  const bufferView = {
    buffer: 0,
    byteOffset: paddedOffset,
    byteLength: source.length,
  };
  json.bufferViews.push(bufferView);
  chunks.push(source);
  return json.bufferViews.length - 1;
}

function appendAccessor(json, bufferView, type, componentType, count, min, max) {
  const accessor = {
    bufferView,
    componentType,
    count,
    type,
  };
  if (min) accessor.min = min;
  if (max) accessor.max = max;
  json.accessors.push(accessor);
  return json.accessors.length - 1;
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
json.asset = {
  ...json.asset,
  generator: 'Codex professional solar-system animation pass',
};
json.bufferViews = json.bufferViews || [];
json.accessors = json.accessors || [];
json.animations = [];
json.extras = {
  ...(json.extras || {}),
  title: 'Model Tata Surya AR Profesional',
  description: 'Planet diberi nama Indonesia, orbit dianimasikan, dan rotasi dibuat berbeda sesuai karakter visual setiap planet.',
};

if (json.materials[4]) {
  json.materials[4].name = 'Garis orbit halus';
  json.materials[4].alphaMode = 'BLEND';
  json.materials[4].doubleSided = true;
  json.materials[4].pbrMetallicRoughness = {
    ...(json.materials[4].pbrMetallicRoughness || {}),
    baseColorFactor: [0.72, 0.84, 1.0, 0.28],
    metallicFactor: 0,
    roughnessFactor: 0.35,
  };
  json.materials[4].emissiveFactor = [0.08, 0.14, 0.22];
}

if (json.materials[8]) {
  json.materials[8].name = 'Matahari - emisi hangat';
  json.materials[8].emissiveFactor = [1.0, 0.48, 0.16];
  json.materials[8].pbrMetallicRoughness = {
    ...(json.materials[8].pbrMetallicRoughness || {}),
    roughnessFactor: 0.85,
  };
}

if (json.materials[6]) {
  json.materials[6].alphaMode = 'BLEND';
  json.materials[6].doubleSided = true;
  json.materials[6].pbrMetallicRoughness = {
    ...(json.materials[6].pbrMetallicRoughness || {}),
    baseColorFactor: [1, 0.92, 0.74, 0.78],
    metallicFactor: 0,
    roughnessFactor: 0.72,
  };
}

const orbitLineMaterialIndex = json.materials.push({
  name: 'Orbit profesional biru lembut',
  alphaMode: 'BLEND',
  doubleSided: true,
  emissiveFactor: [0.22, 0.36, 0.58],
  pbrMetallicRoughness: {
    baseColorFactor: [0.58, 0.78, 1, 0.62],
    metallicFactor: 0,
    roughnessFactor: 0.25,
  },
}) - 1;

planetLabels.forEach((label, index) => {
  if (json.nodes[index]) {
    json.nodes[index].name = label;
    json.nodes[index].extras = {
      ...(json.nodes[index].extras || {}),
      planetName: label,
    };
  }
});

hiddenNodes.forEach((index) => {
  if (json.nodes[index]) {
    json.nodes[index].scale = [0.0001, 0.0001, 0.0001];
    json.nodes[index].extras = {
      ...(json.nodes[index].extras || {}),
      hiddenForEightPlanetModel: true,
    };
  }
});

detachedPlanarNodes.forEach((radius, index) => {
  json.nodes.forEach((node) => {
    if (!node.children) return;
    node.children = node.children.filter((child) => child !== index);
  });

  const scene = json.scenes[json.scene || 0];
  scene.nodes = scene.nodes || [];
  if (!scene.nodes.includes(index)) {
    scene.nodes.push(index);
  }

  if (json.nodes[index]) {
    json.nodes[index].rotation = [0, 0, 0, 1];
    json.nodes[index].translation = [0, 0, radius];
    json.nodes[index].extras = {
      ...(json.nodes[index].extras || {}),
      planarRoot: true,
    };
  }
});

visualScales.forEach((scale, index) => {
  if (!json.nodes[index]) return;
  json.nodes[index].scale = scale;
  json.nodes[index].extras = {
    ...(json.nodes[index].extras || {}),
    visualScaleAdjusted: true,
  };
});

translationOrbitNodes.forEach((item) => {
  if (!json.nodes[item.node] || typeof item.radius !== 'number') return;
  json.nodes[item.node].translation = [0, 0, item.radius];
});

if (json.nodes[56]) {
  json.nodes[56].translation = [MOON_ORBIT_RADIUS, 0, EARTH_ORBIT_RADIUS];
}

const chunks = [bin];
const animation = {
  name: 'Rotasi dan orbit tata surya',
  samplers: [],
  channels: [],
};

function addOrbitLineNode(item) {
  const orbitLine = makeOrbitLineBuffer(item.radius);
  const orbitLineView = appendBufferView(json, chunks, orbitLine.buffer);
  const orbitLineAccessor = appendAccessor(
    json,
    orbitLineView,
    'VEC3',
    5126,
    orbitLine.count,
    [-item.radius, 0, -item.radius],
    [item.radius, 0, item.radius],
  );
  const meshIndex = json.meshes.push({
    name: item.name,
    primitives: [
      {
        attributes: {
          POSITION: orbitLineAccessor,
        },
        mode: 1,
        material: orbitLineMaterialIndex,
      },
    ],
  }) - 1;
  const nodeIndex = json.nodes.push({
    name: item.name,
    mesh: meshIndex,
    translation: item.translation,
    extras: {
      generatedOrbitGuide: true,
      radius: item.radius,
      parentAligned: item.parent ?? null,
    },
  }) - 1;

  if (typeof item.parent === 'number' && json.nodes[item.parent]) {
    json.nodes[item.parent].children = json.nodes[item.parent].children || [];
    json.nodes[item.parent].children.push(nodeIndex);
  } else {
    json.scenes[json.scene || 0].nodes.push(nodeIndex);
  }

  return nodeIndex;
}

solarOrbitLines.forEach(addOrbitLineNode);
const moonOrbitGuideNode = addOrbitLineNode({
  name: 'Garis Orbit Bulan',
  radius: moonOrbitRadius(),
  translation: [
    0,
    0,
    EARTH_ORBIT_RADIUS,
  ],
});

function addRotationChannel(item) {
  const node = json.nodes[item.node];
  if (!node) return;

  const time = makeTimeBuffer(LOOP_DURATION);
  const timeView = appendBufferView(json, chunks, time.buffer);
  const timeAccessor = appendAccessor(
    json,
    timeView,
    'SCALAR',
    5126,
    time.times.length,
    [time.times[0]],
    [time.times[time.times.length - 1]],
  );

  const baseRotation = node.rotation || [0, 0, 0, 1];
  const rotation = makeRotationBuffer(baseRotation, item.period, item.retrograde);
  const rotationView = appendBufferView(json, chunks, rotation.buffer);
  const rotationAccessor = appendAccessor(json, rotationView, 'VEC4', 5126, rotation.count);

  const samplerIndex = animation.samplers.push({
    input: timeAccessor,
    interpolation: 'LINEAR',
    output: rotationAccessor,
  }) - 1;

  animation.channels.push({
    sampler: samplerIndex,
    target: {
      node: item.node,
      path: 'rotation',
    },
  });

  node.extras = {
    ...(node.extras || {}),
    animation: item.name,
    periodSeconds: item.period,
  };
}

orbitNodes.forEach(addRotationChannel);
spinNodes.forEach(addRotationChannel);

function addTranslationChannel(item) {
  const node = json.nodes[item.node];
  if (!node) return;

  const time = makeTimeBuffer(LOOP_DURATION);
  const timeView = appendBufferView(json, chunks, time.buffer);
  const timeAccessor = appendAccessor(
    json,
    timeView,
    'SCALAR',
    5126,
    time.times.length,
    [time.times[0]],
    [time.times[time.times.length - 1]],
  );

  const translation = item.moonAroundEarth
    ? makeMoonTranslationBuffer(
        node.translation || [0, 0, 0],
        item.period,
        item.retrograde,
      )
    : typeof item.radius === 'number'
      ? makePlanarOrbitTranslationBuffer(
          item.radius,
          item.period,
          item.retrograde,
        )
    : makeTranslationBuffer(
        node.translation || [0, 0, 0],
        item.center,
        item.period,
        item.retrograde,
      );
  const translationView = appendBufferView(json, chunks, translation.buffer);
  const translationAccessor = appendAccessor(
    json,
    translationView,
    'VEC3',
    5126,
    translation.count,
  );

  const samplerIndex = animation.samplers.push({
    input: timeAccessor,
    interpolation: 'LINEAR',
    output: translationAccessor,
  }) - 1;

  animation.channels.push({
    sampler: samplerIndex,
    target: {
      node: item.node,
      path: 'translation',
    },
  });

  node.extras = {
    ...(node.extras || {}),
    animation: item.name,
    periodSeconds: item.period,
  };
}

translationOrbitNodes.forEach(addTranslationChannel);
addTranslationChannel({
  node: moonOrbitGuideNode,
  name: 'Garis Orbit Bulan mengikuti Bumi',
  period: EARTH_ORBIT_PERIOD,
  center: [0, 0, 0],
  retrograde: true,
});

json.animations.push(animation);
json.buffers[0].byteLength = chunks.reduce((sum, chunk) => sum + chunk.length, 0);

writeGlb(json, Buffer.concat(chunks));
console.log(`Created ${outputPath}`);
