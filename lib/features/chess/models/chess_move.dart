class ChessMove {
  final int from;
  final int to;
  final String piece;
  final String captured;
  final int captureSquare;
  final int? rookFrom;
  final int? rookTo;
  final int? previousEnPassantTarget;
  final Set<String> previousCastlingRights;

  const ChessMove({
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
