import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../models/chess_move.dart';
import '../models/network_role.dart';
import '../services/chess_bot_engine.dart';
import '../services/chess_rules.dart';
import 'chess_learning_ar_screen.dart';
import '../viewer/chess_model_viewer_js.dart';
import '../widgets/chess_status_panel.dart';
import '../widgets/lan_dialog.dart';

class ChessViewerScreen extends StatefulWidget {
  const ChessViewerScreen({super.key});

  @override
  State<ChessViewerScreen> createState() => _ChessViewerScreenState();
}

class _ChessViewerScreenState extends State<ChessViewerScreen> {
  static const _lanPort = 40464;
  final ChessRules _rules = const ChessRules();
  final List<String> _board = List.of(ChessRules.initialBoard);
  final List<ChessMove> _history = [];
  final Random _random = Random();
  late final ChessBotEngine _bot = ChessBotEngine(random: _random);
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
  bool _showLearningPanel = true;
  bool _closingLan = false;
  bool _disposed = false;
  NetworkRole _networkRole = NetworkRole.local;
  String _networkStatus = 'Offline';
  bool _modelReady = false;
  String _modelStatus = 'Menyiapkan 32 bidak 3D...';
  int? _enPassantTarget;
  final Set<String> _castlingRights = {'K', 'Q', 'k', 'q'};

  bool get _isNetworkGame => _networkRole != NetworkRole.local;
  bool get _isLanConnected => _lanSocket != null;
  String get _modeLabel {
    if (_networkRole == NetworkRole.host) return 'Wi-Fi Host Putih';
    if (_networkRole == NetworkRole.guest) return 'Wi-Fi Tamu Hitam';
    return _playVsBot ? 'Mode Bot' : 'Mode Teman';
  }
  bool get _isLocalNetworkTurn {
    if (_networkRole == NetworkRole.local) return true;
    if (!_isLanConnected) return false;
    return _networkRole == NetworkRole.host ? _whiteTurn : !_whiteTurn;
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
            tooltip: 'Mode belajar AR',
            onPressed: _openLearningAr,
            icon: const Icon(Icons.school_rounded),
          ),
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
            ar: false,
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
            relatedJs: chessModelViewerJs,
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
                        ? 'Gameplay 3D siap | AR untuk belajar'
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
            child: ChessStatusPanel(
              whiteTurn: _whiteTurn,
              moveCount: _history.length,
              canUndo: _history.isNotEmpty && !_isNetworkGame,
              onUndo: _undo,
              status: status,
              networkStatus: _networkStatus,
            ),
          ),
          if (_selected == null && _showLearningPanel)
            Positioned(
              left: 14,
              right: 14,
              bottom: 24,
              child: _LearningPanel(
                onClose: () => setState(() => _showLearningPanel = false),
                onDetail: _openLearningAr,
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

  void _openLearningAr() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChessLearningArScreen()),
    );
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
    final move = ChessMove(
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
      _board.setAll(0, ChessRules.initialBoard);
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
      _board.setAll(0, ChessRules.initialBoard);
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
    final action = await showDialog<LanDialogAction>(
      context: context,
      builder: (context) => LanDialog(
        isNetworkGame: _isNetworkGame,
        networkStatus: _networkStatus,
      ),
    );
    if (!mounted || action == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (action.type == LanDialogActionType.host) {
        _startLanHost();
      } else if (action.type == LanDialogActionType.join && action.ip.isNotEmpty) {
        _joinLanGame(action.ip);
      } else if (action.type == LanDialogActionType.disconnect) {
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
        _attachLanSocket(socket, NetworkRole.host);
        _sendLan({'type': 'hello', 'role': 'host'});
      });
      setState(() {
        _playVsBot = false;
        _networkRole = NetworkRole.host;
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
      _attachLanSocket(socket, NetworkRole.guest);
      _sendLan({'type': 'hello', 'role': 'guest'});
      setState(() {
        _playVsBot = false;
        _networkRole = NetworkRole.guest;
        _networkStatus = 'Terhubung ke host $ip:$_lanPort | Kamu bermain hitam';
      });
      _reset(sendNetwork: false);
    } catch (error) {
      setState(() => _networkStatus = 'Gagal join Wi-Fi: $error');
    }
  }

  void _attachLanSocket(Socket socket, NetworkRole role) {
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
        _networkStatus = role == NetworkRole.host
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
          _networkStatus = _networkRole == NetworkRole.host
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
        _networkRole = NetworkRole.local;
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
      final move = _bot.chooseMove(
        board: _board,
        whiteTurn: _whiteTurn,
        enPassantTarget: _enPassantTarget,
        castlingRights: _castlingRights,
      );
      if (move != null && mounted && generation == _gameGeneration) {
        await _move(move.from, move.to, byBot: true);
      }
      if (mounted) {
        setState(() => _botThinking = false);
        _sync3dHighlights();
      }
    });
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
    return _rules.legalMovesFor(
      board: _board,
      from: from,
      enPassantTarget: _enPassantTarget,
      castlingRights: _castlingRights,
    );
  }

  void _updateCastlingRights(ChessMove move) {
    _rules.updateCastlingRights(_castlingRights, move);
  }

  String _gameStatus() {
    return _rules.gameStatus(
      whiteTurn: _whiteTurn,
      board: _board,
      enPassantTarget: _enPassantTarget,
      castlingRights: _castlingRights,
    );
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

class _LearningPanel extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onDetail;

  const _LearningPanel({required this.onClose, required this.onDetail});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
    decoration: BoxDecoration(
      color: const Color(0xE6171711),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.amberAccent.withValues(alpha: .45)),
      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 18)],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.school_rounded, color: Colors.amberAccent, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Mode kamera AR = belajar catur',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Buka mode belajar AR untuk melihat papan statis di ruang nyata dan membaca dasar gerakan. Gameplay tetap di mode 3D aplikasi.',
                style: TextStyle(color: Colors.white.withValues(alpha: .72), fontSize: 11, height: 1.25),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: onDetail,
                child: const Text(
                  'Buka mode belajar AR',
                  style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
          constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          padding: EdgeInsets.zero,
        ),
      ],
    ),
  );
}

