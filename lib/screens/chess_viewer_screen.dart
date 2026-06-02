import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ChessViewerScreen extends StatefulWidget {
  const ChessViewerScreen({super.key});

  @override
  State<ChessViewerScreen> createState() => _ChessViewerScreenState();
}

class _ChessViewerScreenState extends State<ChessViewerScreen> {
  static const _initial = [
    'br', 'bn', 'bb', 'bq', 'bk', 'bb', 'bn', 'br',
    'bp', 'bp', 'bp', 'bp', 'bp', 'bp', 'bp', 'bp',
    '', '', '', '', '', '', '', '',
    '', '', '', '', '', '', '', '',
    '', '', '', '', '', '', '', '',
    '', '', '', '', '', '', '', '',
    'wp', 'wp', 'wp', 'wp', 'wp', 'wp', 'wp', 'wp',
    'wr', 'wn', 'wb', 'wq', 'wk', 'wb', 'wn', 'wr',
  ];
  final List<String> _board = List.of(_initial);
  final List<_Move> _history = [];
  dynamic _webViewController;
  int? _selected;
  bool _whiteTurn = true;
  bool _modelReady = false;
  String _modelStatus = 'Menyiapkan 32 bidak 3D...';
  int? _enPassantTarget;
  final Set<String> _castlingRights = {'K', 'Q', 'k', 'q'};

  @override
  Widget build(BuildContext context) {
    final legalTargets = _selected == null ? <int>{} : _legalMovesFor(_selected!).toSet();
    final status = _gameStatus();
    return Scaffold(
      backgroundColor: const Color(0xFF070706),
      appBar: AppBar(
        title: const Text('AR Chess Arena', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFF11110F),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(tooltip: 'Ulangi pertandingan', onPressed: _reset, icon: const Icon(Icons.restart_alt_rounded)),
        ],
      ),
      body: Stack(
        children: [
          ModelViewer(
            src: 'assets/models/chess-interactive.glb',
            ar: true,
            autoPlay: false,
            autoRotate: false,
            cameraControls: true,
            disableZoom: false,
            cameraOrbit: '35deg 68deg 7.5m',
            cameraTarget: '0m 0m 0m',
            exposure: 1.1,
            shadowIntensity: 1,
            shadowSoftness: 0.35,
            interactionPrompt: InteractionPrompt.none,
            onWebViewCreated: (controller) => _webViewController = controller,
            relatedJs: _chessJs,
            javascriptChannels: {
              JavascriptChannel(
                'ChessTapChannel',
                onMessageReceived: (message) {
                  debugPrint('[AR Chess Tap] square=${message.message}');
                  final index = int.tryParse(message.message);
                  if (index != null && index >= 0 && index < 64) {
                    _tapSquare(index);
                  }
                },
              ),
              JavascriptChannel(
                'ChessReadyChannel',
                onMessageReceived: (message) {
                  debugPrint('[AR Chess JS] ${message.message}');
                  if (!mounted) return;
                  setState(() {
                    _modelReady = message.message == 'ready';
                    _modelStatus = _modelReady
                        ? 'Pertandingan berlangsung'
                        : message.message;
                  });
                  if (_modelReady) {
                    _sync3dHighlights();
                    Future<void>.delayed(const Duration(milliseconds: 350), () {
                      if (mounted) _sync3dHighlights();
                    });
                  }
                },
              ),
            },
          ),
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: _StatusPanel(
              whiteTurn: _whiteTurn,
              moveCount: _history.length,
              canUndo: _history.isNotEmpty,
              onUndo: _undo,
              status: _modelReady ? status : _modelStatus,
            ),
          ),
          Positioned(
            top: 92,
            left: 14,
            right: 14,
            child: IgnorePointer(
              child: Text(
                'Sentuh bidak 3D, lalu pilih petak bercahaya pada papan 3D.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .76),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
            ),
          ),
          if (_selected != null)
            Positioned(
              left: 14,
              right: 14,
              bottom: 24,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 7, 8, 7),
                  decoration: BoxDecoration(
                    color: const Color(0xE6171711),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.amberAccent.withValues(alpha: .65)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Pilih petak cyan pada papan 3D',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          setState(() => _selected = null);
                          _sync3dHighlights();
                        },
                        child: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _tapSquare(int index) {
    if (!_modelReady) return;
    final piece = _board[index];
    if (_selected != null && _legalMovesFor(_selected!).contains(index)) {
      _move(_selected!, index);
      return;
    }
    final ownPiece = piece.isNotEmpty && (piece[0] == 'w') == _whiteTurn;
    setState(() => _selected = ownPiece ? index : null);
    _sync3dHighlights();
  }

  Future<void> _move(int from, int to) async {
    final piece = _board[from];
    final isCastle = piece[1] == 'k' && (to - from).abs() == 2;
    final rookFrom = isCastle ? (to > from ? from + 3 : from - 4) : null;
    final rookTo = isCastle ? (to > from ? from + 1 : from - 1) : null;
    final isEnPassant = piece[1] == 'p' && to == _enPassantTarget && _board[to].isEmpty;
    final captureSquare = isEnPassant ? to + (piece[0] == 'w' ? 8 : -8) : to;
    var promotedPiece = piece;
    if (piece[1] == 'p' && (to ~/ 8 == 0 || to ~/ 8 == 7)) {
      promotedPiece = await _choosePromotion(piece[0]) ?? '${piece[0]}q';
      if (!mounted) return;
    }
    final move = _Move(
      from: from,
      to: to,
      piece: piece,
      captured: _board[captureSquare],
      captureSquare: captureSquare,
      rookFrom: rookFrom,
      rookTo: rookTo,
      previousEnPassantTarget: _enPassantTarget,
      previousCastlingRights: Set.of(_castlingRights),
    );
    setState(() {
      _history.add(move);
      _board[to] = promotedPiece;
      _board[from] = '';
      if (captureSquare != to) _board[captureSquare] = '';
      if (rookFrom != null && rookTo != null) {
        _board[rookTo] = _board[rookFrom];
        _board[rookFrom] = '';
      }
      _updateCastlingRights(move);
      _enPassantTarget = piece[1] == 'p' && (to - from).abs() == 16
          ? (from + to) ~/ 2
          : null;
      _selected = null;
      _whiteTurn = !_whiteTurn;
    });
    _runJs('window.moveChessPiece?.($from, $to, $captureSquare, ${rookFrom ?? 'null'}, ${rookTo ?? 'null'});');
    _sync3dHighlights();
  }

  void _undo() {
    if (_history.isEmpty) return;
    final move = _history.removeLast();
    setState(() {
      _board[move.from] = move.piece;
      _board[move.to] = '';
      _board[move.captureSquare] = move.captured;
      if (move.rookFrom != null && move.rookTo != null) {
        _board[move.rookFrom!] = _board[move.rookTo!];
        _board[move.rookTo!] = '';
      }
      _enPassantTarget = move.previousEnPassantTarget;
      _castlingRights
        ..clear()
        ..addAll(move.previousCastlingRights);
      _selected = null;
      _whiteTurn = !_whiteTurn;
    });
    _runJs('window.undoChessMove?.();');
    _sync3dHighlights();
  }

  void _reset() {
    setState(() {
      _board.setAll(0, _initial);
      _history.clear();
      _selected = null;
      _whiteTurn = true;
      _enPassantTarget = null;
      _castlingRights
        ..clear()
        ..addAll({'K', 'Q', 'k', 'q'});
    });
    _runJs('window.resetChessBoard?.();');
    _sync3dHighlights();
  }

  void _runJs(String command) {
    _webViewController?.runJavaScript(command);
  }

  void _sync3dHighlights() {
    final legal = _selected == null ? <int>[] : _legalMovesFor(_selected!);
    final color = _whiteTurn ? 'w' : 'b';
    final selectable = List.generate(64, (index) => index)
        .where((index) => _board[index].startsWith(color))
        .toList();
    _runJs('window.setChessHighlights?.(${_selected ?? 'null'}, ${legal.toString()}, ${selectable.toString()});');
  }

  List<int> _legalMovesFor(int from) {
    final piece = _board[from];
    if (piece.isEmpty) return [];
    return _pseudoMovesFor(from).where((to) {
      final snapshot = List<String>.of(_board);
      _applySimulation(snapshot, from, to);
      return !_isKingAttacked(piece[0], snapshot);
    }).toList();
  }

  List<int> _pseudoMovesFor(int from, {bool attacksOnly = false, List<String>? position}) {
    final board = position ?? _board;
    final piece = board[from];
    if (piece.isEmpty) return [];
    final color = piece[0];
    final type = piece[1];
    final row = from ~/ 8;
    final col = from % 8;
    final moves = <int>[];
    void add(int r, int c) {
      if (r < 0 || r > 7 || c < 0 || c > 7) return;
      final target = board[r * 8 + c];
      if (target.isEmpty || target[0] != color) moves.add(r * 8 + c);
    }
    void slide(int dr, int dc) {
      var r = row + dr;
      var c = col + dc;
      while (r >= 0 && r < 8 && c >= 0 && c < 8) {
        final target = board[r * 8 + c];
        if (target.isEmpty) {
          moves.add(r * 8 + c);
        } else {
          if (target[0] != color) moves.add(r * 8 + c);
          break;
        }
        r += dr;
        c += dc;
      }
    }
    if (type == 'p') {
      final direction = color == 'w' ? -1 : 1;
      final startRow = color == 'w' ? 6 : 1;
      final one = (row + direction) * 8 + col;
      if (!attacksOnly && row + direction >= 0 && row + direction < 8 && board[one].isEmpty) {
        moves.add(one);
        final two = (row + direction * 2) * 8 + col;
        if (row == startRow && board[two].isEmpty) moves.add(two);
      }
      for (final dc in [-1, 1]) {
        final r = row + direction;
        final c = col + dc;
        if (r >= 0 && r < 8 && c >= 0 && c < 8) {
          final target = board[r * 8 + c];
          if (attacksOnly || (target.isNotEmpty && target[0] != color) || r * 8 + c == _enPassantTarget) {
            moves.add(r * 8 + c);
          }
        }
      }
    } else if (type == 'n') {
      for (final delta in const [[-2,-1],[-2,1],[-1,-2],[-1,2],[1,-2],[1,2],[2,-1],[2,1]]) {
        add(row + delta[0], col + delta[1]);
      }
    } else if (type == 'k') {
      for (final dr in [-1, 0, 1]) {
        for (final dc in [-1, 0, 1]) {
          if (dr != 0 || dc != 0) add(row + dr, col + dc);
        }
      }
      if (!attacksOnly && position == null && !_isKingAttacked(color, board)) {
        final home = color == 'w' ? 60 : 4;
        if (from == home) {
          final kingSide = color == 'w' ? 'K' : 'k';
          final queenSide = color == 'w' ? 'Q' : 'q';
          if (_castlingRights.contains(kingSide) &&
              board[home + 1].isEmpty && board[home + 2].isEmpty &&
              !_isSquareAttacked(home + 1, color, board) && !_isSquareAttacked(home + 2, color, board)) {
            moves.add(home + 2);
          }
          if (_castlingRights.contains(queenSide) &&
              board[home - 1].isEmpty && board[home - 2].isEmpty && board[home - 3].isEmpty &&
              !_isSquareAttacked(home - 1, color, board) && !_isSquareAttacked(home - 2, color, board)) {
            moves.add(home - 2);
          }
        }
      }
    } else {
      if (type == 'r' || type == 'q') {
        for (final d in const [[-1,0],[1,0],[0,-1],[0,1]]) slide(d[0], d[1]);
      }
      if (type == 'b' || type == 'q') {
        for (final d in const [[-1,-1],[-1,1],[1,-1],[1,1]]) slide(d[0], d[1]);
      }
    }
    return moves;
  }

  void _applySimulation(List<String> board, int from, int to) {
    final piece = board[from];
    final isEnPassant = piece[1] == 'p' && to == _enPassantTarget && board[to].isEmpty;
    if (isEnPassant) board[to + (piece[0] == 'w' ? 8 : -8)] = '';
    board[to] = piece;
    board[from] = '';
    if (piece[1] == 'k' && (to - from).abs() == 2) {
      final rookFrom = to > from ? from + 3 : from - 4;
      final rookTo = to > from ? from + 1 : from - 1;
      board[rookTo] = board[rookFrom];
      board[rookFrom] = '';
    }
  }

  bool _isKingAttacked(String color, List<String> board) {
    final king = board.indexOf('${color}k');
    return king == -1 || _isSquareAttacked(king, color, board);
  }

  bool _isSquareAttacked(int square, String defendingColor, List<String> board) {
    for (var index = 0; index < 64; index++) {
      final piece = board[index];
      if (piece.isNotEmpty && piece[0] != defendingColor) {
        if (_pseudoMovesFor(index, attacksOnly: true, position: board).contains(square)) return true;
      }
    }
    return false;
  }

  void _updateCastlingRights(_Move move) {
    if (move.piece == 'wk') _castlingRights.removeAll({'K', 'Q'});
    if (move.piece == 'bk') _castlingRights.removeAll({'k', 'q'});
    const rookRights = {56: 'Q', 63: 'K', 0: 'q', 7: 'k'};
    final moved = rookRights[move.from];
    final captured = rookRights[move.captureSquare];
    if (moved != null) _castlingRights.remove(moved);
    if (captured != null) _castlingRights.remove(captured);
  }

  String _gameStatus() {
    final color = _whiteTurn ? 'w' : 'b';
    final checked = _isKingAttacked(color, _board);
    final hasMove = List.generate(64, (index) => index).any((index) =>
      _board[index].startsWith(color) && _legalMovesFor(index).isNotEmpty);
    if (!hasMove) return checked ? 'Skakmat' : 'Remis - pat';
    return checked ? 'Skak' : 'Pertandingan berlangsung';
  }

  Future<String?> _choosePromotion(String color) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Promosi pion'),
        content: const Text('Pilih bidak pengganti untuk pion Anda.'),
        actions: [
          for (final type in const ['q', 'r', 'b', 'n'])
            TextButton(
              onPressed: () => Navigator.pop(context, '$color$type'),
              child: Text({'q': 'Menteri', 'r': 'Benteng', 'b': 'Gajah', 'n': 'Kuda'}[type]!),
            ),
        ],
      ),
    );
  }
}

class _Move {
  final int from;
  final int to;
  final String piece;
  final String captured;
  final int captureSquare;
  final int? rookFrom;
  final int? rookTo;
  final int? previousEnPassantTarget;
  final Set<String> previousCastlingRights;
  const _Move({
    required this.from,
    required this.to,
    required this.piece,
    required this.captured,
    required this.captureSquare,
    required this.rookFrom,
    required this.rookTo,
    required this.previousEnPassantTarget,
    required this.previousCastlingRights,
  });
}

class _StatusPanel extends StatelessWidget {
  final bool whiteTurn;
  final int moveCount;
  final bool canUndo;
  final VoidCallback onUndo;
  final String status;
  const _StatusPanel({required this.whiteTurn, required this.moveCount, required this.canUndo, required this.onUndo, required this.status});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xDD171711),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white24),
    ),
    child: Row(
      children: [
        Icon(Icons.circle, size: 14, color: whiteTurn ? Colors.white : Colors.black, shadows: const [Shadow(color: Colors.white54, blurRadius: 2)]),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            'Giliran ${whiteTurn ? 'Putih' : 'Hitam'} | Langkah ${moveCount + 1}\n$status',
            maxLines: 5,
            overflow: TextOverflow.visible,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(onPressed: canUndo ? onUndo : null, tooltip: 'Batalkan langkah', icon: const Icon(Icons.undo_rounded), color: Colors.amberAccent),
      ],
    ),
  );
}

const _chessJs = r'''
(() => {
  const viewer = document.querySelector('model-viewer');
  if (!viewer || window._chessReady) return;
  window._chessReady = true;
  const clipInitialNames = [
    'Circle.036', 'Circle.034', 'Circle.028', 'Circle.029',
    'Circle.035', 'Circle.027', 'Circle.030', 'Circle.026',
    'Circle.011', 'Circle.012', 'Circle.013', 'Circle.014',
    'Circle.015', 'Circle.016', 'Circle.017', 'Circle.018',
    null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null,
    'Circle.025', 'Circle', 'Circle.019', 'Circle.020',
    'Circle.021', 'Circle.022', 'Circle.023', 'Circle.024',
    'Circle.031', 'Circle.033', 'Circle.032', 'Circle.008',
    'Circle.007', 'Circle.003', 'Circle.009', 'Circle.001',
  ];
  const clipState = {
    squares: [...clipInitialNames],
    origins: new Map(),
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
  const playAction = (name, clipName, actionType) => {
    const symbols = Object.getOwnPropertySymbols(viewer);
    const sceneSymbol = symbols.find((symbol) => symbol.description === 'scene');
    const scene = sceneSymbol ? viewer[sceneSymbol] : null;
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
    console.log('[AR Chess] Clip GLB siap digunakan.');
    if (window.ChessReadyChannel) window.ChessReadyChannel.postMessage('ready');
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
    'Circle.036', 'Circle.034', 'Circle.028', 'Circle.029',
    'Circle.035', 'Circle.027', 'Circle.030', 'Circle.026',
    'Circle.011', 'Circle.012', 'Circle.013', 'Circle.014',
    'Circle.015', 'Circle.016', 'Circle.017', 'Circle.018',
    null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null,
    'Circle.025', 'Circle', 'Circle.019', 'Circle.020',
    'Circle.021', 'Circle.022', 'Circle.023', 'Circle.024',
    'Circle.031', 'Circle.033', 'Circle.032', 'Circle.008',
    'Circle.007', 'Circle.003', 'Circle.009', 'Circle.001',
  ];
  const initialMeshNames = [
    'Circle.036_black_0', 'Circle.034_black_0', 'Circle.028_black_0', 'Circle.029_black_0',
    'Circle.035_black_0', 'Circle.027_black_0', 'Circle.030_black_0', 'Circle.026_black_0',
    'Circle.011_black_0', 'Circle.012_black_0', 'Circle.013_black_0', 'Circle.014_black_0',
    'Circle.015_black_0', 'Circle.016_black_0', 'Circle.017_black_0', 'Circle.018_black_0',
    null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null,
    'Circle.025_white_0', 'Circle_white_0', 'Circle.019_white_0', 'Circle.020_white_0',
    'Circle.021_white_0', 'Circle.022_white_0', 'Circle.023_white_0', 'Circle.024_white_0',
    'Circle.031_white_0', 'Circle.033_white_0', 'Circle.032_white_0', 'Circle.008_white_0',
    'Circle.007_white_0', 'Circle.003_white_0', 'Circle.009_white_0', 'Circle.001_white_0',
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
