import 'dart:math';

import 'chess_rules.dart';

class BotMove {
  final int from;
  final int to;
  int score;

  BotMove(this.from, this.to, this.score);
}

class BotPosition {
  final List<String> board;
  final bool whiteTurn;
  final int? enPassantTarget;
  final Set<String> castlingRights;

  const BotPosition(this.board, this.whiteTurn, this.enPassantTarget, this.castlingRights);
}

class ChessBotEngine {
  final ChessRules rules;
  final Random random;

  const ChessBotEngine({this.rules = const ChessRules(), required this.random});

  BotMove? chooseMove({
    required List<String> board,
    required bool whiteTurn,
    required int? enPassantTarget,
    required Set<String> castlingRights,
    String color = 'b',
  }) {
    final position = BotPosition(List<String>.of(board), whiteTurn, enPassantTarget, Set.of(castlingRights));
    final moves = _generateMoves(position, color);
    if (moves.isEmpty) return null;
    for (final move in moves) {
      final next = _applyPosition(position, move);
      move.score = _searchPosition(next, 2, -1000000, 1000000);
    }
    moves.sort((a, b) => b.score.compareTo(a.score));
    final bestScore = moves.first.score;
    final bestMoves = moves.where((move) => move.score == bestScore).toList();
    return bestMoves[random.nextInt(bestMoves.length)];
  }

  int _searchPosition(BotPosition position, int depth, int alpha, int beta) {
    final color = position.whiteTurn ? 'w' : 'b';
    final moves = _generateMoves(position, color);
    if (moves.isEmpty) {
      final checked = rules.isKingAttacked(
        color: color,
        board: position.board,
        enPassantTarget: position.enPassantTarget,
        castlingRights: position.castlingRights,
      );
      if (!checked) return 0;
      return color == 'b' ? -900000 - depth : 900000 + depth;
    }
    if (depth == 0) return _evaluatePosition(position);
    moves.sort((a, b) => _moveOrderScore(position, b).compareTo(_moveOrderScore(position, a)));
    if (color == 'b') {
      var best = -1000000;
      for (final move in moves) {
        best = max(best, _searchPosition(_applyPosition(position, move), depth - 1, alpha, beta));
        alpha = max(alpha, best);
        if (alpha >= beta) break;
      }
      return best;
    }
    var best = 1000000;
    for (final move in moves) {
      best = min(best, _searchPosition(_applyPosition(position, move), depth - 1, alpha, beta));
      beta = min(beta, best);
      if (alpha >= beta) break;
    }
    return best;
  }

  List<BotMove> _generateMoves(BotPosition position, String color) {
    final moves = <BotMove>[];
    for (var from = 0; from < 64; from++) {
      if (!position.board[from].startsWith(color)) continue;
      for (final to in rules.legalMovesFor(
        board: position.board,
        from: from,
        enPassantTarget: position.enPassantTarget,
        castlingRights: position.castlingRights,
      )) {
        moves.add(BotMove(from, to, _moveOrderScore(position, BotMove(from, to, 0))));
      }
    }
    return moves;
  }

  BotPosition _applyPosition(BotPosition position, BotMove move) {
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
    return BotPosition(board, !position.whiteTurn, enPassant, castlingRights);
  }

  int _evaluatePosition(BotPosition position) {
    var score = 0;
    for (var square = 0; square < 64; square++) {
      final piece = position.board[square];
      if (piece.isEmpty) continue;
      final value = pieceValue(piece) + pieceSquareScore(piece, square);
      score += piece[0] == 'b' ? value : -value;
    }
    if (rules.isKingAttacked(
      color: 'w',
      board: position.board,
      enPassantTarget: position.enPassantTarget,
      castlingRights: position.castlingRights,
    )) {
      score += 55;
    }
    if (rules.isKingAttacked(
      color: 'b',
      board: position.board,
      enPassantTarget: position.enPassantTarget,
      castlingRights: position.castlingRights,
    )) {
      score -= 55;
    }
    return score;
  }

  int _moveOrderScore(BotPosition position, BotMove move) {
    final piece = position.board[move.from];
    final isEnPassant = piece[1] == 'p' && move.to == position.enPassantTarget && position.board[move.to].isEmpty;
    final captureSquare = isEnPassant ? move.to + (piece[0] == 'w' ? 8 : -8) : move.to;
    final captured = position.board[captureSquare];
    var score = pieceValue(captured) * 12 - pieceValue(piece);
    if (piece[1] == 'p' && (move.to ~/ 8 == 0 || move.to ~/ 8 == 7)) score += 850;
    if (piece[1] == 'k' && (move.to - move.from).abs() == 2) score += 80;
    return score;
  }

  int pieceValue(String piece) {
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

  int pieceSquareScore(String piece, int square) {
    if (piece.isEmpty) return 0;
    final row = square ~/ 8;
    final col = square % 8;
    final center = 14 - ((row - 3).abs() + (row - 4).abs() + (col - 3).abs() + (col - 4).abs());
    final advance = piece[0] == 'w' ? 6 - row : row - 1;
    return switch (piece[1]) {
      'p' => advance * 8 + center,
      'n' || 'b' => center * 6,
      'q' => center * 2,
      'k' => center * 2,
      _ => center,
    };
  }
}
