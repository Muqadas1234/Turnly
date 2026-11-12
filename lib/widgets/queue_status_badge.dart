import 'package:flutter/material.dart';

class QueueStatusBadge extends StatelessWidget {
  final String status; // waiting | serving | done
  const QueueStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'serving' => Colors.green,
      'done' => Colors.grey,
      _ => Colors.orange,
    };
    return Chip(
      label: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11)),
      backgroundColor: color,
    );
  }
}
