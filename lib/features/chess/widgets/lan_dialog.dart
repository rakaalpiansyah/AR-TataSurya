import 'package:flutter/material.dart';

enum LanDialogActionType { host, join, disconnect }

class LanDialogAction {
  final LanDialogActionType type;
  final String ip;

  const LanDialogAction(this.type, [this.ip = '']);
}

class LanDialog extends StatefulWidget {
  final bool isNetworkGame;
  final String networkStatus;

  const LanDialog({
    super.key,
    required this.isNetworkGame,
    required this.networkStatus,
  });

  @override
  State<LanDialog> createState() => _LanDialogState();
}

class _LanDialogState extends State<LanDialog> {
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
            const LanDialogAction(LanDialogActionType.disconnect),
          ),
          child: const Text('Putuskan'),
        )
      else ...[
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            const LanDialogAction(LanDialogActionType.host),
          ),
          child: const Text('Host'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            LanDialogAction(LanDialogActionType.join, _controller.text.trim()),
          ),
          child: const Text('Join'),
        ),
      ],
    ],
  );
}
