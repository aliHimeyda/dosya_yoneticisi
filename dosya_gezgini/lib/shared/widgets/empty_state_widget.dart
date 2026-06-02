import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.message,
    this.icon = Icons.folder_open_rounded,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 56, color: color),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
