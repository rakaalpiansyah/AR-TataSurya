import 'package:flutter/material.dart';

class ChessStatusPanel extends StatelessWidget {
  final bool whiteTurn;
  final int moveCount;
  final bool canUndo;
  final VoidCallback onUndo;
  final String status;
  final String networkStatus;

  const ChessStatusPanel({
    super.key,
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
        Icon(
          Icons.circle,
          size: 14,
          color: whiteTurn ? Colors.white : Colors.black,
          shadows: const [Shadow(color: Colors.white54, blurRadius: 2)],
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            'Giliran ${whiteTurn ? 'Putih' : 'Hitam'} | Langkah ${moveCount + 1}\n$status\nWi-Fi: $networkStatus',
            maxLines: 5,
            overflow: TextOverflow.visible,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          onPressed: canUndo ? onUndo : null,
          tooltip: 'Batalkan langkah',
          icon: const Icon(Icons.undo_rounded),
          color: Colors.amberAccent,
        ),
      ],
    ),
  );
}
