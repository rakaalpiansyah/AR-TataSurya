import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ChessViewerScreen extends StatefulWidget {
  const ChessViewerScreen({super.key});

  @override
  State<ChessViewerScreen> createState() => _ChessViewerScreenState();
}

enum _NetworkRole { local, host, guest }

class _ChessViewerScreenState extends State<ChessViewerScreen> {
  static const _lanPort = 40464;
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
  final Random _random = Random();
  ServerSocket? _lanServer;
  Socket? _lanSocket;
  StreamSubscription<Socket>? _lanServerSubscription;
  StreamSubscription<String>? _lanSocketSubscription;
  dynamic _webViewController;
  int _sceneRevision = 0;
  int _gameGeneration = 0;
  int? _selected;
  bool _whiteTurn = true;
  bool _playVsBot = false;
  bool _botThinking = false;
  bool _closingLan = false;
  bool _disposed = false;
  _NetworkRole _networkRole = _NetworkRole.local;
  String _networkStatus = 'Offline';
  bool _modelReady = false;
  String _modelStatus = 'Menyiapkan 32 bidak 3D...';
  int? _enPassantTarget;
  final Set<String> _castlingRights = {'K', 'Q', 'k', 'q'};

  bool get _isNetworkGame => _networkRole != _NetworkRole.local;
  bool get _isLanConnected => _lanSocket != null;
  String get _modeLabel {
    if (_networkRole == _NetworkRole.host) return 'Wi-Fi Host Putih';
    if (_networkRole == _NetworkRole.guest) return 'Wi-Fi Tamu Hitam';
    return _playVsBot ? 'Mode Bot' : 'Mode Teman';
  }
  bool get _isLocalNetworkTurn {
    if (_networkRole == _NetworkRole.local) return true;
    if (!_isLanConnected) return false;
    return _networkRole == _NetworkRole.host ? _whiteTurn : !_whiteTurn;
  }

  @override
  void dispose() {
    _disposed = true;
    _disconnectLan(updateState: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameStatus = _gameStatus();
    final status = !_modelReady
        ? _modelStatus
        : _botThinking
            ? 'Bot sedang berpikir...'
            : '$_modeLabel | $gameStatus';
    return Scaffold(
      backgroundColor: const Color(0xFF070706),
      appBar: AppBar(
        title: const Text('AR Chess Arena', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFF11110F),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Multiplayer Wi-Fi',
            onPressed: _showLanDialog,
            icon: Icon(_isNetworkGame ? Icons.wifi_rounded : Icons.wifi_tethering_rounded),
          ),
          PopupMenuButton<bool>(
            tooltip: 'Mode permainan',
            icon: Icon(_playVsBot ? Icons.smart_toy_rounded : Icons.groups_rounded),
            color: const Color(0xFF1C1B16),
            onSelected: _setGameMode,
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: false,
                checked: !_playVsBot,
                child: const Text('Main dengan teman', style: TextStyle(color: Colors.white)),
              ),
              CheckedPopupMenuItem(
                value: true,
                checked: _playVsBot,
                child: const Text('Lawan bot', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          IconButton(tooltip: 'Ulangi pertandingan', onPressed: _reset, icon: const Icon(Icons.restart_alt_rounded)),
        ],
      ),
      body: Stack(
        children: [
          ModelViewer(
            key: ValueKey('chess-scene-$_sceneRevision'),
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
              canUndo: _history.isNotEmpty && !_isNetworkGame,
              onUndo: _undo,
              status: status,
              networkStatus: _networkStatus,
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
    if (_botThinking || (_playVsBot && !_whiteTurn)) return;
    if (_isNetworkGame && !_isLocalNetworkTurn) return;
    final piece = _board[index];
    if (_selected != null && _legalMovesFor(_selected!).contains(index)) {
      _move(_selected!, index);
      return;
    }
    final ownPiece = piece.isNotEmpty && (piece[0] == 'w') == _whiteTurn;
    setState(() => _selected = ownPiece ? index : null);
    _sync3dHighlights();
  }

  Future<void> _move(int from, int to, {bool byBot = false, bool fromNetwork = false, String? promotionOverride}) async {
    final piece = _board[from];
    final isCastle = piece[1] == 'k' && (to - from).abs() == 2;
    final rookFrom = isCastle ? (to > from ? from + 3 : from - 4) : null;
    final rookTo = isCastle ? (to > from ? from + 1 : from - 1) : null;
    final isEnPassant = piece[1] == 'p' && to == _enPassantTarget && _board[to].isEmpty;
    final captureSquare = isEnPassant ? to + (piece[0] == 'w' ? 8 : -8) : to;
    var promotedPiece = piece;
    if (piece[1] == 'p' && (to ~/ 8 == 0 || to ~/ 8 == 7)) {
      if (promotionOverride != null) {
        promotedPiece = promotionOverride;
      } else if (byBot || fromNetwork) {
        promotedPiece = '${piece[0]}q';
      } else {
        promotedPiece = await _choosePromotion(piece[0]) ?? '${piece[0]}q';
        if (!mounted) return;
      }
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
    if (_isNetworkGame && !fromNetwork) {
      _sendLan({
        'type': 'move',
        'from': from,
        'to': to,
        'promotion': promotedPiece == piece ? null : promotedPiece,
      });
    }
    if (!byBot && !fromNetwork && !_isNetworkGame) _scheduleBotMove();
  }

  void _undo() {
    if (_history.isEmpty || _botThinking) return;
    final undoCount = _playVsBot && _whiteTurn && _history.length >= 2 ? 2 : 1;
    for (var index = 0; index < undoCount; index++) {
      _undoOne();
    }
    _sync3dHighlights();
  }

  void _undoOne() {
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
  }

  void _reset({bool sendNetwork = true}) {
    setState(() {
      _gameGeneration++;
      _sceneRevision++;
      _webViewController = null;
      _board.setAll(0, _initial);
      _history.clear();
      _selected = null;
      _whiteTurn = true;
      _botThinking = false;
      _modelReady = false;
      _modelStatus = 'Menyiapkan ulang papan 3D...';
      _enPassantTarget = null;
      _castlingRights
        ..clear()
        ..addAll({'K', 'Q', 'k', 'q'});
    });
    if (sendNetwork && _isNetworkGame) {
      _sendLan({'type': 'reset'});
    }
  }

  void _setGameMode(bool playVsBot) {
    if (_playVsBot == playVsBot) return;
    _disconnectLan(updateState: false);
    setState(() {
      _playVsBot = playVsBot;
      _gameGeneration++;
      _sceneRevision++;
      _webViewController = null;
      _board.setAll(0, _initial);
      _history.clear();
      _selected = null;
      _whiteTurn = true;
      _botThinking = false;
      _modelReady = false;
      _modelStatus = playVsBot
          ? 'Menyiapkan mode lawan bot...'
          : 'Menyiapkan mode teman...';
      _enPassantTarget = null;
      _castlingRights
        ..clear()
        ..addAll({'K', 'Q', 'k', 'q'});
    });
  }

  Future<void> _showLanDialog() async {
    final action = await showDialog<_LanDialogAction>(
      context: context,
      builder: (context) => _LanDialog(
        isNetworkGame: _isNetworkGame,
        networkStatus: _networkStatus,
      ),
    );
    if (!mounted || action == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (action.type == _LanDialogActionType.host) {
        _startLanHost();
      } else if (action.type == _LanDialogActionType.join && action.ip.isNotEmpty) {
        _joinLanGame(action.ip);
      } else if (action.type == _LanDialogActionType.disconnect) {
        _disconnectLan();
      }
    });
  }

  Future<void> _startLanHost() async {
    try {
      await _disconnectLan(updateState: false);
      final server = await ServerSocket.bind(InternetAddress.anyIPv4, _lanPort, shared: true);
      final ip = await _findLocalIp();
      _lanServer = server;
      _lanServerSubscription = server.listen((socket) {
        _attachLanSocket(socket, _NetworkRole.host);
        _sendLan({'type': 'hello', 'role': 'host'});
      });
      setState(() {
        _playVsBot = false;
        _networkRole = _NetworkRole.host;
        _networkStatus = 'Host aktif: ${ip ?? 'cek IP Wi-Fi'}:$_lanPort | Menunggu teman...';
      });
      _reset(sendNetwork: false);
    } catch (error) {
      setState(() => _networkStatus = 'Gagal host Wi-Fi: $error');
    }
  }

  Future<void> _joinLanGame(String ip) async {
    try {
      await _disconnectLan(updateState: false);
      final socket = await Socket.connect(ip, _lanPort, timeout: const Duration(seconds: 5));
      _attachLanSocket(socket, _NetworkRole.guest);
      _sendLan({'type': 'hello', 'role': 'guest'});
      setState(() {
        _playVsBot = false;
        _networkRole = _NetworkRole.guest;
        _networkStatus = 'Terhubung ke host $ip:$_lanPort | Kamu bermain hitam';
      });
      _reset(sendNetwork: false);
    } catch (error) {
      setState(() => _networkStatus = 'Gagal join Wi-Fi: $error');
    }
  }

  void _attachLanSocket(Socket socket, _NetworkRole role) {
    _lanSocketSubscription?.cancel();
    _lanSocket?.destroy();
    _lanSocket = socket;
    _lanSocketSubscription = socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          _handleLanMessage,
          onDone: _handleLanClosed,
          onError: (_) => _handleLanClosed(),
        );
    if (mounted) {
      setState(() {
        _networkRole = role;
        _networkStatus = role == _NetworkRole.host
            ? 'Teman terhubung | Kamu bermain putih'
            : _networkStatus;
      });
    }
  }

  Future<String?> _findLocalIp() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        if (address.address.startsWith('192.168.') ||
            address.address.startsWith('10.') ||
            address.address.startsWith('172.')) {
          return address.address;
        }
      }
    }
    final addresses = interfaces.expand((interface) => interface.addresses).map((address) => address.address);
    return addresses.isEmpty ? null : addresses.first;
  }

  void _sendLan(Map<String, Object?> payload) {
    final socket = _lanSocket;
    if (socket == null) return;
    socket.write('${jsonEncode(payload)}\n');
  }

  void _handleLanMessage(String line) {
    try {
      final data = jsonDecode(line);
      if (data is! Map) return;
      final type = data['type'];
      if (type == 'hello') {
        setState(() {
          _networkStatus = _networkRole == _NetworkRole.host
              ? 'Teman terhubung | Kamu bermain putih'
              : 'Terhubung ke host | Kamu bermain hitam';
        });
      } else if (type == 'move') {
        final from = data['from'];
        final to = data['to'];
        final promotion = data['promotion'];
        if (from is int && to is int) {
          _move(from, to, fromNetwork: true, promotionOverride: promotion is String ? promotion : null);
        }
      } else if (type == 'reset') {
        _reset(sendNetwork: false);
      }
    } catch (error) {
      debugPrint('[AR Chess LAN] Pesan tidak valid: $line | $error');
    }
  }

  void _handleLanClosed() {
    if (_closingLan || _disposed) return;
    _disconnectLan();
  }

  Future<void> _disconnectLan({bool updateState = true}) async {
    if (_closingLan) return;
    _closingLan = true;
    final socketSubscription = _lanSocketSubscription;
    final serverSubscription = _lanServerSubscription;
    final socket = _lanSocket;
    final server = _lanServer;
    _lanSocket = null;
    _lanServer = null;
    _lanSocketSubscription = null;
    _lanServerSubscription = null;
    await socketSubscription?.cancel();
    await serverSubscription?.cancel();
    socket?.destroy();
    await server?.close();
    _closingLan = false;
    if (updateState && mounted && !_disposed) {
      setState(() {
        _networkRole = _NetworkRole.local;
        _networkStatus = 'Offline';
      });
    }
  }

  void _scheduleBotMove() {
    if (!_playVsBot || !_modelReady || _whiteTurn || _botThinking) return;
    if (_gameStatus() == 'Skakmat' || _gameStatus().startsWith('Remis')) return;
    final generation = _gameGeneration;
    setState(() {
      _selected = null;
      _botThinking = true;
    });
    _sync3dHighlights();
    Future<void>.delayed(const Duration(milliseconds: 650), () async {
      if (!mounted || generation != _gameGeneration || !_playVsBot || _whiteTurn) {
        if (mounted) setState(() => _botThinking = false);
        return;
      }
      final move = _chooseBotMove('b');
      if (move != null && mounted && generation == _gameGeneration) {
        await _move(move.from, move.to, byBot: true);
      }
      if (mounted) {
        setState(() => _botThinking = false);
        _sync3dHighlights();
      }
    });
  }

  _BotMove? _chooseBotMove(String color) {
    final position = _BotPosition(List<String>.of(_board), _whiteTurn, _enPassantTarget, Set.of(_castlingRights));
    final moves = _generateBotMoves(position, color);
    if (moves.isEmpty) return null;
    for (final move in moves) {
      final next = _applyBotPosition(position, move);
      move.score = _searchBotPosition(next, 2, -1000000, 1000000);
    }
    moves.sort((a, b) => b.score.compareTo(a.score));
    final bestScore = moves.first.score;
    final bestMoves = moves.where((move) => move.score == bestScore).toList();
    return bestMoves[_random.nextInt(bestMoves.length)];
  }

  int _searchBotPosition(_BotPosition position, int depth, int alpha, int beta) {
    final color = position.whiteTurn ? 'w' : 'b';
    final moves = _generateBotMoves(position, color);
    if (moves.isEmpty) {
      final checked = _isKingAttackedIn(color, position);
      if (!checked) return 0;
      return color == 'b' ? -900000 - depth : 900000 + depth;
    }
    if (depth == 0) return _evaluateBotPosition(position);
    moves.sort((a, b) => _moveOrderScore(position, b).compareTo(_moveOrderScore(position, a)));
    if (color == 'b') {
      var best = -1000000;
      for (final move in moves) {
        best = max(best, _searchBotPosition(_applyBotPosition(position, move), depth - 1, alpha, beta));
        alpha = max(alpha, best);
        if (alpha >= beta) break;
      }
      return best;
    }
    var best = 1000000;
    for (final move in moves) {
      best = min(best, _searchBotPosition(_applyBotPosition(position, move), depth - 1, alpha, beta));
      beta = min(beta, best);
      if (alpha >= beta) break;
    }
    return best;
  }

  List<_BotMove> _generateBotMoves(_BotPosition position, String color) {
    final moves = <_BotMove>[];
    for (var from = 0; from < 64; from++) {
      if (!position.board[from].startsWith(color)) continue;
      for (final to in _legalBotMovesFor(position, from)) {
        moves.add(_BotMove(from, to, _moveOrderScore(position, _BotMove(from, to, 0))));
      }
    }
    return moves;
  }

  List<int> _legalBotMovesFor(_BotPosition position, int from) {
    final piece = position.board[from];
    if (piece.isEmpty) return [];
    return _pseudoMovesIn(position, from).where((to) {
      final next = _applyBotPosition(position, _BotMove(from, to, 0));
      return !_isKingAttackedIn(piece[0], next);
    }).toList();
  }

  List<int> _pseudoMovesIn(_BotPosition position, int from, {bool attacksOnly = false}) {
    final board = position.board;
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
      final oneRow = row + direction;
      if (!attacksOnly && oneRow >= 0 && oneRow < 8 && board[oneRow * 8 + col].isEmpty) {
        moves.add(oneRow * 8 + col);
        final twoRow = row + direction * 2;
        if (row == startRow && board[twoRow * 8 + col].isEmpty) moves.add(twoRow * 8 + col);
      }
      for (final dc in [-1, 1]) {
        final r = row + direction;
        final c = col + dc;
        if (r >= 0 && r < 8 && c >= 0 && c < 8) {
          final square = r * 8 + c;
          final target = board[square];
          if (attacksOnly || (target.isNotEmpty && target[0] != color) || square == position.enPassantTarget) {
            moves.add(square);
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
      if (!attacksOnly && !_isKingAttackedIn(color, position)) {
        final home = color == 'w' ? 60 : 4;
        if (from == home) {
          final kingSide = color == 'w' ? 'K' : 'k';
          final queenSide = color == 'w' ? 'Q' : 'q';
          if (position.castlingRights.contains(kingSide) &&
              board[home + 1].isEmpty && board[home + 2].isEmpty &&
              !_isSquareAttackedIn(home + 1, color, position) && !_isSquareAttackedIn(home + 2, color, position)) {
            moves.add(home + 2);
          }
          if (position.castlingRights.contains(queenSide) &&
              board[home - 1].isEmpty && board[home - 2].isEmpty && board[home - 3].isEmpty &&
              !_isSquareAttackedIn(home - 1, color, position) && !_isSquareAttackedIn(home - 2, color, position)) {
            moves.add(home - 2);
          }
        }
      }
    } else {
      if (type == 'r' || type == 'q') {
        for (final d in const [[-1,0],[1,0],[0,-1],[0,1]]) {
          slide(d[0], d[1]);
        }
      }
      if (type == 'b' || type == 'q') {
        for (final d in const [[-1,-1],[-1,1],[1,-1],[1,1]]) {
          slide(d[0], d[1]);
        }
      }
    }
    return moves;
  }

  _BotPosition _applyBotPosition(_BotPosition position, _BotMove move) {
    final board = List<String>.of(position.board);
    final castlingRights = Set<String>.of(position.castlingRights);
    final piece = board[move.from];
    final isCastle = piece[1] == 'k' && (move.to - move.from).abs() == 2;
    final rookFrom = isCastle ? (move.to > move.from ? move.from + 3 : move.from - 4) : null;
    final rookTo = isCastle ? (move.to > move.from ? move.from + 1 : move.from - 1) : null;
    final isEnPassant = piece[1] == 'p' && move.to == position.enPassantTarget && board[move.to].isEmpty;
    final captureSquare = isEnPassant ? move.to + (piece[0] == 'w' ? 8 : -8) : move.to;
    board[move.to] = piece[1] == 'p' && (move.to ~/ 8 == 0 || move.to ~/ 8 == 7) ? '${piece[0]}q' : piece;
    board[move.from] = '';
    if (captureSquare != move.to) board[captureSquare] = '';
    if (rookFrom != null && rookTo != null) {
      board[rookTo] = board[rookFrom];
      board[rookFrom] = '';
    }
    if (piece == 'wk') castlingRights.removeAll({'K', 'Q'});
    if (piece == 'bk') castlingRights.removeAll({'k', 'q'});
    const rookRights = {56: 'Q', 63: 'K', 0: 'q', 7: 'k'};
    final moved = rookRights[move.from];
    final captured = rookRights[captureSquare];
    if (moved != null) castlingRights.remove(moved);
    if (captured != null) castlingRights.remove(captured);
    final enPassant = piece[1] == 'p' && (move.to - move.from).abs() == 16
        ? (move.from + move.to) ~/ 2
        : null;
    return _BotPosition(board, !position.whiteTurn, enPassant, castlingRights);
  }

  bool _isKingAttackedIn(String color, _BotPosition position) {
    final king = position.board.indexOf('${color}k');
    return king == -1 || _isSquareAttackedIn(king, color, position);
  }

  bool _isSquareAttackedIn(int square, String defendingColor, _BotPosition position) {
    for (var index = 0; index < 64; index++) {
      final piece = position.board[index];
      if (piece.isNotEmpty && piece[0] != defendingColor) {
        if (_pseudoMovesIn(position, index, attacksOnly: true).contains(square)) return true;
      }
    }
    return false;
  }

  int _evaluateBotPosition(_BotPosition position) {
    var score = 0;
    for (var square = 0; square < 64; square++) {
      final piece = position.board[square];
      if (piece.isEmpty) continue;
      final value = _pieceValue(piece) + _pieceSquareScore(piece, square);
      score += piece[0] == 'b' ? value : -value;
    }
    if (_isKingAttackedIn('w', position)) score += 55;
    if (_isKingAttackedIn('b', position)) score -= 55;
    return score;
  }

  int _moveOrderScore(_BotPosition position, _BotMove move) {
    final piece = position.board[move.from];
    final isEnPassant = piece[1] == 'p' && move.to == position.enPassantTarget && position.board[move.to].isEmpty;
    final captureSquare = isEnPassant ? move.to + (piece[0] == 'w' ? 8 : -8) : move.to;
    final captured = position.board[captureSquare];
    var score = _pieceValue(captured) * 12 - _pieceValue(piece);
    if (piece[1] == 'p' && (move.to ~/ 8 == 0 || move.to ~/ 8 == 7)) score += 850;
    if (piece[1] == 'k' && (move.to - move.from).abs() == 2) score += 80;
    return score;
  }

  int _pieceValue(String piece) {
    if (piece.isEmpty) return 0;
    return switch (piece[1]) {
      'p' => 100,
      'n' => 320,
      'b' => 330,
      'r' => 500,
      'q' => 900,
      'k' => 20000,
      _ => 0,
    };
  }

  int _pieceSquareScore(String piece, int square) {
    if (piece.isEmpty) return 0;
    final row = square ~/ 8;
    final col = square % 8;
    final center = 14 - ((row - 3).abs() + (row - 4).abs() + (col - 3).abs() + (col - 4).abs());
    final advance = piece[0] == 'w' ? 6 - row : row - 1;
    return switch (piece[1]) {
      'p' => advance * 8 + center,
      'n' || 'b' => center * 6,
      'q' => center * 2,
      'k' => _history.length < 18 ? -center * 3 : center * 2,
      _ => center,
    };
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
        for (final d in const [[-1,0],[1,0],[0,-1],[0,1]]) {
          slide(d[0], d[1]);
        }
      }
      if (type == 'b' || type == 'q') {
        for (final d in const [[-1,-1],[-1,1],[1,-1],[1,1]]) {
          slide(d[0], d[1]);
        }
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

class _BotMove {
  final int from;
  final int to;
  int score;
  _BotMove(this.from, this.to, this.score);
}

class _BotPosition {
  final List<String> board;
  final bool whiteTurn;
  final int? enPassantTarget;
  final Set<String> castlingRights;
  const _BotPosition(this.board, this.whiteTurn, this.enPassantTarget, this.castlingRights);
}

class _StatusPanel extends StatelessWidget {
  final bool whiteTurn;
  final int moveCount;
  final bool canUndo;
  final VoidCallback onUndo;
  final String status;
  final String networkStatus;
  const _StatusPanel({
    required this.whiteTurn,
    required this.moveCount,
    required this.canUndo,
    required this.onUndo,
    required this.status,
    required this.networkStatus,
  });

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
            'Giliran ${whiteTurn ? 'Putih' : 'Hitam'} | Langkah ${moveCount + 1}\n$status\nWi-Fi: $networkStatus',
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

enum _LanDialogActionType { host, join, disconnect }

class _LanDialogAction {
  final _LanDialogActionType type;
  final String ip;
  const _LanDialogAction(this.type, [this.ip = '']);
}

class _LanDialog extends StatefulWidget {
  final bool isNetworkGame;
  final String networkStatus;
  const _LanDialog({required this.isNetworkGame, required this.networkStatus});

  @override
  State<_LanDialog> createState() => _LanDialogState();
}

class _LanDialogState extends State<_LanDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: const Color(0xFF171711),
    title: const Text('Multiplayer Wi-Fi', style: TextStyle(color: Colors.white)),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.isNetworkGame
              ? widget.networkStatus
              : 'Satu HP pilih Host, HP lain pilih Join dan masukkan IP host. Keduanya harus di Wi-Fi yang sama.',
          style: const TextStyle(color: Colors.white70),
        ),
        if (!widget.isNetworkGame) ...[
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.text,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'IP host, contoh 192.168.1.12',
              labelStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amberAccent)),
            ),
          ),
        ],
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Tutup'),
      ),
      if (widget.isNetworkGame)
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            const _LanDialogAction(_LanDialogActionType.disconnect),
          ),
          child: const Text('Putuskan'),
        )
      else ...[
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            const _LanDialogAction(_LanDialogActionType.host),
          ),
          child: const Text('Host'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            _LanDialogAction(_LanDialogActionType.join, _controller.text.trim()),
          ),
          child: const Text('Join'),
        ),
      ],
    ],
  );
}

const _chessJs = r'''
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
