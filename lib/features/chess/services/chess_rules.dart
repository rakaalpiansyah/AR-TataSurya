import '../models/chess_move.dart';

class ChessRules {
  static const initialBoard = [
    'br', 'bn', 'bb', 'bq', 'bk', 'bb', 'bn', 'br',
    'bp', 'bp', 'bp', 'bp', 'bp', 'bp', 'bp', 'bp',
    '', '', '', '', '', '', '', '',
    '', '', '', '', '', '', '', '',
    '', '', '', '', '', '', '', '',
    '', '', '', '', '', '', '', '',
    'wp', 'wp', 'wp', 'wp', 'wp', 'wp', 'wp', 'wp',
    'wr', 'wn', 'wb', 'wq', 'wk', 'wb', 'wn', 'wr',
  ];

  const ChessRules();

  List<int> legalMovesFor({
    required List<String> board,
    required int from,
    required int? enPassantTarget,
    required Set<String> castlingRights,
  }) {
    final piece = board[from];
    if (piece.isEmpty) return [];
    return pseudoMovesFor(
      board: board,
      from: from,
      enPassantTarget: enPassantTarget,
      castlingRights: castlingRights,
    ).where((to) {
      final snapshot = List<String>.of(board);
      applySimulation(snapshot, from, to, enPassantTarget);
      return !isKingAttacked(
        color: piece[0],
        board: snapshot,
        enPassantTarget: enPassantTarget,
        castlingRights: castlingRights,
      );
    }).toList();
  }

  List<int> pseudoMovesFor({
    required List<String> board,
    required int from,
    required int? enPassantTarget,
    required Set<String> castlingRights,
    bool attacksOnly = false,
    bool allowCastling = true,
  }) {
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
          final square = r * 8 + c;
          final target = board[square];
          if (attacksOnly || (target.isNotEmpty && target[0] != color) || square == enPassantTarget) {
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
      if (!attacksOnly && allowCastling && !isKingAttacked(
        color: color,
        board: board,
        enPassantTarget: enPassantTarget,
        castlingRights: castlingRights,
      )) {
        final home = color == 'w' ? 60 : 4;
        if (from == home) {
          final kingSide = color == 'w' ? 'K' : 'k';
          final queenSide = color == 'w' ? 'Q' : 'q';
          if (castlingRights.contains(kingSide) &&
              board[home + 1].isEmpty && board[home + 2].isEmpty &&
              !isSquareAttacked(square: home + 1, defendingColor: color, board: board, enPassantTarget: enPassantTarget, castlingRights: castlingRights) &&
              !isSquareAttacked(square: home + 2, defendingColor: color, board: board, enPassantTarget: enPassantTarget, castlingRights: castlingRights)) {
            moves.add(home + 2);
          }
          if (castlingRights.contains(queenSide) &&
              board[home - 1].isEmpty && board[home - 2].isEmpty && board[home - 3].isEmpty &&
              !isSquareAttacked(square: home - 1, defendingColor: color, board: board, enPassantTarget: enPassantTarget, castlingRights: castlingRights) &&
              !isSquareAttacked(square: home - 2, defendingColor: color, board: board, enPassantTarget: enPassantTarget, castlingRights: castlingRights)) {
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

  void applySimulation(List<String> board, int from, int to, int? enPassantTarget) {
    final piece = board[from];
    final isEnPassant = piece[1] == 'p' && to == enPassantTarget && board[to].isEmpty;
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

  bool isKingAttacked({
    required String color,
    required List<String> board,
    required int? enPassantTarget,
    required Set<String> castlingRights,
  }) {
    final king = board.indexOf('${color}k');
    return king == -1 || isSquareAttacked(
      square: king,
      defendingColor: color,
      board: board,
      enPassantTarget: enPassantTarget,
      castlingRights: castlingRights,
    );
  }

  bool isSquareAttacked({
    required int square,
    required String defendingColor,
    required List<String> board,
    required int? enPassantTarget,
    required Set<String> castlingRights,
  }) {
    for (var index = 0; index < 64; index++) {
      final piece = board[index];
      if (piece.isNotEmpty && piece[0] != defendingColor) {
        if (pseudoMovesFor(
          board: board,
          from: index,
          enPassantTarget: enPassantTarget,
          castlingRights: castlingRights,
          attacksOnly: true,
          allowCastling: false,
        ).contains(square)) {
          return true;
        }
      }
    }
    return false;
  }

  void updateCastlingRights(Set<String> castlingRights, ChessMove move) {
    if (move.piece == 'wk') castlingRights.removeAll({'K', 'Q'});
    if (move.piece == 'bk') castlingRights.removeAll({'k', 'q'});
    const rookRights = {56: 'Q', 63: 'K', 0: 'q', 7: 'k'};
    final moved = rookRights[move.from];
    final captured = rookRights[move.captureSquare];
    if (moved != null) castlingRights.remove(moved);
    if (captured != null) castlingRights.remove(captured);
  }

  String gameStatus({
    required bool whiteTurn,
    required List<String> board,
    required int? enPassantTarget,
    required Set<String> castlingRights,
  }) {
    final color = whiteTurn ? 'w' : 'b';
    final checked = isKingAttacked(
      color: color,
      board: board,
      enPassantTarget: enPassantTarget,
      castlingRights: castlingRights,
    );
    final hasMove = List.generate(64, (index) => index).any((index) =>
      board[index].startsWith(color) &&
      legalMovesFor(
        board: board,
        from: index,
        enPassantTarget: enPassantTarget,
        castlingRights: castlingRights,
      ).isNotEmpty);
    if (!hasMove) return checked ? 'Skakmat' : 'Remis - pat';
    return checked ? 'Skak' : 'Pertandingan berlangsung';
  }
}
