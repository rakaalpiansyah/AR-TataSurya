const chessModelViewerJs = r'''
(() => {
  const viewer = document.querySelector('model-viewer');
  if (!viewer || window._chessReady) return;
  window._chessReady = true;
  const clipInitialNames = [
    'Circle.036', 'Circle.034', 'Circle.028', 'Circle.035',
    'Circle.029', 'Circle.027', 'Circle.030', 'Circle.026',
    'Circle.011', 'Circle.012', 'Circle.013', 'Circle.014',
    'Circle.015', 'Circle.016', 'Circle.017', 'Circle.018',
    null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null,
    'Circle.025', 'Circle', 'Circle.019', 'Circle.020',
    'Circle.021', 'Circle.022', 'Circle.023', 'Circle.024',
    'Circle.031', 'Circle.033', 'Circle.032', 'Circle.007',
    'Circle.008', 'Circle.003', 'Circle.009', 'Circle.001',
  ];
  const clipState = {
    squares: [...clipInitialNames],
    origins: new Map(),
    startPositions: new Map(),
    objectCache: new Map(),
    moveFrames: new Map(),
    history: [],
    actions: new Map(),
  };
  clipInitialNames.forEach((name, square) => {
    if (name) clipState.origins.set(name, square);
  });
  const addBoardHotspots = () => {
    if (viewer.querySelector('[data-chess-hotspot]')) return;
    for (let square = 0; square < 64; square++) {
      const row = Math.floor(square / 8);
      const col = square % 8;
      const button = document.createElement('button');
      button.slot = `hotspot-chess-${square}`;
      button.dataset.chessHotspot = String(square);
      button.dataset.basePosition = `${-126 + col * 36}m -8m ${126 - row * 36}m`;
      button.dataset.position = button.dataset.basePosition;
      button.setAttribute('aria-label', `Petak ${square}`);
      button.addEventListener('click', (event) => {
        event.stopPropagation();
        console.log('[AR Chess] Hotspot ditekan:', square);
        window.ChessTapChannel?.postMessage(String(square));
      });
      viewer.appendChild(button);
    }
    const style = document.createElement('style');
    style.textContent = `
      [data-chess-hotspot] {
        width: 30px; height: 30px; border: 0; padding: 0;
        background: transparent; border-radius: 50%; pointer-events: none;
      }
      [data-chess-hotspot].active { pointer-events: none; }
      [data-chess-hotspot].active:not(.legal):not(.selected) {
        opacity: 0;
      }
      [data-chess-hotspot].selected {
        background: rgba(255, 193, 7, .78);
        border: 2px solid #ffd740;
        box-shadow: 0 0 10px rgba(255, 193, 7, .92);
      }
      [data-chess-hotspot].legal {
        background: rgba(0, 229, 255, .82);
        border: 2px solid #18ffff;
        box-shadow: 0 0 11px rgba(0, 229, 255, .95);
      }
      [data-chess-hotspot].legal::after {
        content: '•'; color: white; font-size: 22px; line-height: 22px; font-weight: 900;
      }
    `;
    document.head.appendChild(style);
  };
  window.setChessHighlights = (selected, legal = [], selectable = []) => {
    addBoardHotspots();
    const legalSet = new Set(legal);
    const selectableSet = new Set(selectable);
    viewer.querySelectorAll('[data-chess-hotspot]').forEach((button) => {
      const square = Number(button.dataset.chessHotspot);
      button.dataset.position = button.dataset.basePosition;
      button.classList.toggle('active', legalSet.has(square) || selectableSet.has(square));
      button.classList.toggle('selected', square === selected);
      button.classList.toggle('legal', legalSet.has(square));
    });
  };
  const squareFromHit = (hit) => {
    const point = hit?.position;
    if (!point) return null;
    // The board root applies a 10x world scale: each square is 36 scene units.
    const col = Math.floor((point.x + 144) / 36);
    const row = Math.floor((144 - point.z) / 36);
    if (row < 0 || row > 7 || col < 0 || col > 7) return null;
    return row * 8 + col;
  };
  viewer.addEventListener('click', (event) => {
    const rect = viewer.getBoundingClientRect();
    const hit =
      viewer.positionAndNormalFromPoint?.(event.clientX, event.clientY) ||
      viewer.queryHitTest?.(event.clientX - rect.left, event.clientY - rect.top);
    const square = squareFromHit(hit);
    console.log('[AR Chess] Hit-test:', square, hit?.position || null);
    if (square !== null) window.ChessTapChannel?.postMessage(String(square));
  });
  const pumpMixer = (scene, duration = 460) => {
    const started = performance.now();
    let previous = started;
    const tick = (now) => {
      const delta = Math.max(0, (now - previous) / 1000);
      previous = now;
      scene.mixer?.update?.(delta);
      scene.isDirty = true;
      viewer.requestUpdate?.();
      if (now - started < duration) requestAnimationFrame(tick);
    };
    requestAnimationFrame(tick);
  };
  const getScene = () => {
    const symbols = Object.getOwnPropertySymbols(viewer);
    const sceneSymbol = symbols.find((symbol) => symbol.description === 'scene');
    return sceneSymbol ? viewer[sceneSymbol] : null;
  };
  const findObjectByName = (name) => {
    if (!name) return null;
    const cached = clipState.objectCache.get(name);
    if (cached) return cached;
    const scene = getScene();
    const roots = [
      scene,
      scene?.model,
      scene?.model?.scene,
      scene?.modelContainer,
      scene?._model,
      scene?._currentGLTF?.scene,
      scene?.currentGLTF?.scene,
    ].filter(Boolean);
    for (const root of roots) {
      const direct = root.getObjectByName?.(name);
      if (direct) {
        clipState.objectCache.set(name, direct);
        return direct;
      }
      let found = null;
      root.traverse?.((object) => {
        if (!found && object.name === name) found = object;
      });
      if (found) {
        clipState.objectCache.set(name, found);
        return found;
      }
    }
    return null;
  };
  const captureStartPositions = () => {
    clipState.startPositions.clear();
    clipState.objectCache.clear();
    clipInitialNames.forEach((name) => {
      const object = findObjectByName(name);
      if (object?.position) clipState.startPositions.set(name, object.position.clone());
    });
    console.log('[AR Chess] Posisi awal bidak tersimpan:', clipState.startPositions.size);
  };
  const markDirty = (duration = 520) => {
    const scene = getScene();
    const started = performance.now();
    const tick = (now) => {
      if (scene) scene.isDirty = true;
      viewer.requestUpdate?.();
      if (now - started < duration) requestAnimationFrame(tick);
    };
    requestAnimationFrame(tick);
  };
  const animatePieceToSquare = (name, targetSquare) => {
    const object = findObjectByName(name);
    const startHome = clipState.startPositions.get(name);
    const origin = clipState.origins.get(name);
    if (!object?.position || !startHome || origin === undefined) return false;
    const rowDelta = Math.floor(targetSquare / 8) - Math.floor(origin / 8);
    const colDelta = (targetSquare % 8) - (origin % 8);
    const from = object.position.clone();
    const target = startHome.clone();
    target.x += colDelta * 3600;
    target.z -= rowDelta * 3600;
    cancelAnimationFrame(clipState.moveFrames.get(name));
    const started = performance.now();
    const duration = 420;
    const lift = Math.max(320, Math.min(780, from.distanceTo(target) * 0.05));
    const step = (now) => {
      const raw = Math.min(1, (now - started) / duration);
      const t = raw < 0.5 ? 2 * raw * raw : 1 - Math.pow(-2 * raw + 2, 2) / 2;
      object.position.lerpVectors(from, target, t);
      object.position.y = from.y + (target.y - from.y) * t + Math.sin(Math.PI * t) * lift;
      const scene = getScene();
      if (scene) scene.isDirty = true;
      viewer.requestUpdate?.();
      if (raw < 1) {
        clipState.moveFrames.set(name, requestAnimationFrame(step));
      } else {
        object.position.copy(target);
        clipState.moveFrames.delete(name);
        markDirty(120);
      }
    };
    clipState.actions.get(`move|${name}`)?.stop?.();
    clipState.moveFrames.set(name, requestAnimationFrame(step));
    console.log('[AR Chess] Animasi posisi langsung:', name, 'ke petak', targetSquare);
    return true;
  };
  const playAction = (name, clipName, actionType) => {
    const scene = getScene();
    const clip =
      scene?.animationsByName?.get?.(clipName) ||
      scene?.animationsByName?.[clipName];
    if (!clip || !scene?.mixer) return false;
    const actionKey = `${actionType}|${name}`;
    clipState.actions.get(actionKey)?.stop?.();
    const action = scene.mixer.clipAction(clip);
    action.reset();
    action.setLoop(2200, 1);
    action.clampWhenFinished = true;
    action.play();
    clipState.actions.set(actionKey, action);
    scene.isDirty = true;
    pumpMixer(scene);
    console.log('[AR Chess] Memutar clip:', clipName);
    return true;
  };
  const playMoveClip = (name, targetSquare) => {
    if (!name) return;
    if (animatePieceToSquare(name, targetSquare)) return;
    const origin = clipState.origins.get(name);
    const rowDelta = Math.floor(targetSquare / 8) - Math.floor(origin / 8);
    const colDelta = (targetSquare % 8) - (origin % 8);
    if (rowDelta === 0 && colDelta === 0) {
      if (playAction(name, `home|${name}`, 'move')) return;
      console.log('[AR Chess] Clip home tidak ditemukan:', name);
      return;
    }
    const clipName = `move|${name}|${rowDelta}|${colDelta}`;
    if (playAction(name, clipName, 'move')) return;
    console.log('[AR Chess] Fallback viewer.play untuk clip:', clipName);
    viewer.animationName = clipName;
    viewer.currentTime = 0;
    const result = viewer.play({ repetitions: 1 });
    if (result && typeof result.catch === 'function') result.catch(() => {});
  };
  window.selectChessSquare = () => {};
  window.moveChessPiece = (from, to, captureSquare = to, rookFrom = null, rookTo = null) => {
    const name = clipState.squares[from];
    const captured = clipState.squares[captureSquare];
    const rook = rookFrom === null ? null : clipState.squares[rookFrom];
    clipState.history.push({ from, to, name, captured, captureSquare, rook, rookFrom, rookTo });
    if (captured) playAction(captured, `hide|${captured}`, 'scale');
    playMoveClip(name, to);
    clipState.squares[to] = name;
    clipState.squares[from] = null;
    if (captureSquare !== to) clipState.squares[captureSquare] = null;
    if (rook) {
      playMoveClip(rook, rookTo);
      clipState.squares[rookTo] = rook;
      clipState.squares[rookFrom] = null;
    }
  };
  window.undoChessMove = () => {
    const move = clipState.history.pop();
    if (!move) return;
    playMoveClip(move.name, move.from);
    if (move.captured) playAction(move.captured, `show|${move.captured}`, 'scale');
    clipState.squares[move.from] = move.name;
    clipState.squares[move.to] = null;
    clipState.squares[move.captureSquare] = move.captured;
    if (move.rook) {
      playMoveClip(move.rook, move.rookFrom);
      clipState.squares[move.rookFrom] = move.rook;
      clipState.squares[move.rookTo] = null;
    }
  };
  window.resetChessBoard = () => {
    clipState.squares = [...clipInitialNames];
    clipState.history = [];
    clipState.actions.forEach((action) => action.stop?.());
    clipState.actions.clear();
    const source = viewer.src;
    viewer.src = '';
    setTimeout(() => { viewer.src = source; }, 0);
  };
  const markClipReady = () => {
    addBoardHotspots();
    const finishReady = (attempt = 0) => {
      captureStartPositions();
      if (clipState.startPositions.size < 32 && attempt < 10) {
        setTimeout(() => finishReady(attempt + 1), 80);
        return;
      }
      console.log('[AR Chess] Clip GLB siap digunakan.');
      if (window.ChessReadyChannel) window.ChessReadyChannel.postMessage('ready');
    };
    requestAnimationFrame(() => finishReady());
  };
  viewer.addEventListener('load', markClipReady, { once: true });
  if (viewer.loaded) markClipReady();
  return;
  const state = { squares: [], start: [], history: [], selected: null, ready: false };
  const report = (message, details = null) => {
    const text = details ? `${message}\n${details}` : message;
    console.log('[AR Chess]', text);
    if (window.ChessReadyChannel) window.ChessReadyChannel.postMessage(text);
  };
  const initialNodeNames = [
    'Circle.036', 'Circle.034', 'Circle.028', 'Circle.035',
    'Circle.029', 'Circle.027', 'Circle.030', 'Circle.026',
    'Circle.011', 'Circle.012', 'Circle.013', 'Circle.014',
    'Circle.015', 'Circle.016', 'Circle.017', 'Circle.018',
    null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null,
    'Circle.025', 'Circle', 'Circle.019', 'Circle.020',
    'Circle.021', 'Circle.022', 'Circle.023', 'Circle.024',
    'Circle.031', 'Circle.033', 'Circle.032', 'Circle.007',
    'Circle.008', 'Circle.003', 'Circle.009', 'Circle.001',
  ];
  const initialMeshNames = [
    'Circle.036_black_0', 'Circle.034_black_0', 'Circle.028_black_0', 'Circle.035_black_0',
    'Circle.029_black_0', 'Circle.027_black_0', 'Circle.030_black_0', 'Circle.026_black_0',
    'Circle.011_black_0', 'Circle.012_black_0', 'Circle.013_black_0', 'Circle.014_black_0',
    'Circle.015_black_0', 'Circle.016_black_0', 'Circle.017_black_0', 'Circle.018_black_0',
    null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null,
    'Circle.025_white_0', 'Circle_white_0', 'Circle.019_white_0', 'Circle.020_white_0',
    'Circle.021_white_0', 'Circle.022_white_0', 'Circle.023_white_0', 'Circle.024_white_0',
    'Circle.031_white_0', 'Circle.033_white_0', 'Circle.032_white_0', 'Circle.007_white_0',
    'Circle.008_white_0', 'Circle.003_white_0', 'Circle.009_white_0', 'Circle.001_white_0',
  ];
  const internalScene = () => {
    const isScene = (candidate) => {
      return candidate && (
        candidate.modelContainer ||
        candidate._model ||
        candidate._currentGLTF?.scene ||
        typeof candidate.traverse === 'function' ||
        candidate.model?.scene
      );
    };
    const inspect = (candidate, depth = 0, seen = new Set()) => {
      if (!candidate || depth > 2 || seen.has(candidate)) return null;
      if (isScene(candidate)) return candidate;
      if (typeof candidate !== 'object' && typeof candidate !== 'function') return null;
      seen.add(candidate);
      for (const key of Object.getOwnPropertySymbols(candidate)) {
        try {
          const found = inspect(candidate[key], depth + 1, seen);
          if (found) return found;
        } catch (_) {}
      }
      return null;
    };
    const symbols = [];
    let cursor = viewer;
    while (cursor) {
      symbols.push(...Object.getOwnPropertySymbols(cursor));
      cursor = Object.getPrototypeOf(cursor);
    }
    const exact = symbols.find((symbol) => symbol.description === 'scene');
    if (exact && isScene(viewer[exact])) return viewer[exact];
    for (const symbol of symbols) {
      try {
        const found = inspect(viewer[symbol]);
        if (found) return found;
      } catch (_) {}
    }
    return inspect(viewer);
  };
  const debugScene = (attempt) => {
    const own = Object.getOwnPropertySymbols(viewer).map((s) => s.description || String(s));
    const proto = Object.getOwnPropertySymbols(Object.getPrototypeOf(viewer) || {}).map((s) => s.description || String(s));
    const sceneSymbol = Object.getOwnPropertySymbols(viewer)
      .find((symbol) => symbol.description === 'scene');
    const rawScene = sceneSymbol ? viewer[sceneSymbol] : null;
    const rawKeys = rawScene ? Object.getOwnPropertyNames(rawScene) : [];
    const rawSymbols = rawScene ? Object.getOwnPropertySymbols(rawScene).map((s) => s.description || String(s)) : [];
    const modelKeys = rawScene?._model ? Object.getOwnPropertyNames(rawScene._model) : [];
    const gltfKeys = rawScene?._currentGLTF ? Object.getOwnPropertyNames(rawScene._currentGLTF) : [];
    const childNames = (rawScene?.children || []).map((child) => child.name || child.type || '-');
    const scene = internalScene();
    report(
      scene ? `Scene 3D ditemukan pada percobaan ${attempt}` : `Scene 3D belum siap pada percobaan ${attempt}`,
      `own symbols: ${own.join(', ') || '-'}\nprototype symbols: ${proto.join(', ') || '-'}\nscene keys: ${rawKeys.join(', ') || '-'}\nscene symbols: ${rawSymbols.join(', ') || '-'}\nmodel keys: ${modelKeys.join(', ') || '-'}\ngltf keys: ${gltfKeys.join(', ') || '-'}\nscene children: ${childNames.join(', ') || '-'}`,
    );
  };
  const squareRoots = () => {
    const result = new Array(64).fill(null);
    const scene = internalScene();
    const byMeshName = new Map();
    initialMeshNames.forEach((name, square) => {
      if (name) byMeshName.set(name, square);
    });
    initialNodeNames.forEach((name, square) => {
      if (!name || result[square]) return;
      const object = scene?.getObjectByName?.(name);
      if (object) result[square] = object;
    });
    initialMeshNames.forEach((name, square) => {
      if (!name || result[square]) return;
      const mesh = scene?.getObjectByName?.(name);
      if (mesh) result[square] = mesh.parent || mesh;
    });
    const visit = (o) => {
      if (!o) return;
      const square = byMeshName.get(o.name);
      if (square !== undefined) {
        result[square] = o.parent || o;
      }
      for (const child of o.children || []) visit(child);
    };
    visit(scene);
    if (result.filter(Boolean).length < 32) visit(scene?._model);
    if (result.filter(Boolean).length < 32) visit(scene?._currentGLTF?.scene);
    if (result.filter(Boolean).length < 32) visit(scene?.modelContainer);
    return result;
  };
  const roots = () => squareRoots().filter(Boolean);
  const animate = (object, target, duration = 380) => {
    const start = object.position.clone();
    const started = performance.now();
    const tick = (now) => {
      const t = Math.min(1, (now - started) / duration);
      const e = 1 - Math.pow(1 - t, 3);
      object.position.set(start.x + (target.x - start.x) * e, start.y + (target.y - start.y) * e, start.z + (target.z - start.z) * e);
      const scene = internalScene();
      if (scene) scene.isDirty = true;
      scene?.queueRender?.();
      viewer.requestUpdate?.();
      if (t < 1) requestAnimationFrame(tick);
    };
    requestAnimationFrame(tick);
  };
  const setup = () => {
    if (state.ready) return true;
    const pieces = roots();
    if (pieces.length !== 32) return false;
    pieces.forEach((o) => {
      o.userData.chessStart = o.position.clone();
      o.userData.visibleStart = o.visible;
    });
    // Export order in this asset is deterministic: first 16 black, then 16 white.
    state.squares = squareRoots();
    state.start = pieces.map((o) => ({ object: o, position: o.position.clone(), visible: true }));
    state.ready = state.squares.filter(Boolean).length === 32;
    if (state.ready && window.ChessReadyChannel) {
      console.log('[AR Chess] 32 bidak siap digunakan.');
      window.ChessReadyChannel.postMessage('ready');
    }
    return state.ready;
  };
  const ensureSetup = (attempt = 0) => {
    if (setup()) return;
    if (attempt === 0 || attempt === 5 || attempt === 20 || attempt === 80) {
      debugScene(attempt);
    } else if (window.ChessReadyChannel && attempt % 5 === 0) {
      const scene = internalScene();
      const found = scene ? roots() : [];
      const count = found.length;
      report(
        scene
          ? `Node bidak ditemukan: ${count}/32\nAnchor mesh aktif: ${squareRoots().map((o, index) => o ? initialMeshNames[index] : null).filter(Boolean).join(', ')}`
          : 'Scene 3D belum siap...',
      );
    }
    if (attempt >= 80) return;
    setTimeout(() => ensureSetup(attempt + 1), 150);
  };
  viewer.addEventListener('load', () => ensureSetup());
  ensureSetup();
  window.selectChessSquare = (square) => {
    state.selected = square;
  };
  const squareFromBoardPoint = (point) => {
    if (!point) return null;
    const col = Math.floor(point.x / 3.6 + 4);
    const row = Math.floor(4 - point.z / 3.6);
    if (row < 0 || row > 7 || col < 0 || col > 7) return null;
    return row * 8 + col;
  };
  const squareFromHitObject = (hitObject) => {
    let object = hitObject;
    while (object) {
      const square = state.squares.indexOf(object);
      if (square !== -1) return square;
      object = object.parent;
    }
    return null;
  };
  viewer.addEventListener('click', (event) => {
    const rect = viewer.getBoundingClientRect();
    const hit = viewer.queryHitTest?.(event.clientX - rect.left, event.clientY - rect.top);
    const pieceSquare = squareFromHitObject(hit?.object);
    const boardSquare = pieceSquare ?? squareFromBoardPoint(hit?.position);
    if (boardSquare !== null && window.ChessTapChannel) {
      window.ChessTapChannel.postMessage(String(boardSquare));
    }
  });
  const moveObject = (object, from, to) => {
    if (!object) return;
    const rowDelta = Math.floor(to / 8) - Math.floor(from / 8);
    const colDelta = (to % 8) - (from % 8);
    const target = object.position.clone();
    target.x += colDelta * 3600;
    target.z -= rowDelta * 3600;
    animate(object, target);
  };
  window.moveChessPiece = (from, to, captureSquare = to, rookFrom = null, rookTo = null) => {
    if (!state.ready) {
      ensureSetup();
      return;
    }
    const object = state.squares[from];
    if (!object) return;
    const captured = state.squares[captureSquare];
    const rook = rookFrom === null ? null : state.squares[rookFrom];
    state.history.push({ from, to, object, captured, captureSquare, rook, rookFrom, rookTo });
    if (captured) captured.visible = false;
    moveObject(object, from, to);
    state.squares[to] = object;
    state.squares[from] = null;
    state.selected = null;
    if (captureSquare !== to) state.squares[captureSquare] = null;
    if (rook) {
      moveObject(rook, rookFrom, rookTo);
      state.squares[rookTo] = rook;
      state.squares[rookFrom] = null;
    }
  };
  window.undoChessMove = () => {
    const move = state.history.pop();
    if (!move) return;
    moveObject(move.object, move.to, move.from);
    if (move.captured) move.captured.visible = true;
    state.squares[move.from] = move.object;
    state.squares[move.to] = null;
    state.squares[move.captureSquare] = move.captured;
    if (move.rook) {
      moveObject(move.rook, move.rookTo, move.rookFrom);
      state.squares[move.rookFrom] = move.rook;
      state.squares[move.rookTo] = null;
    }
    state.selected = null;
  };
  window.resetChessBoard = () => {
    state.start.forEach(({ object, position, visible }) => {
      animate(object, position);
      object.visible = visible;
    });
    state.history = [];
    state.squares = squareRoots();
    state.selected = null;
  };
})();
''';
