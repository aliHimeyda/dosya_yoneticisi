import 'dart:async';

import 'package:flutter/material.dart';

class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
  });

  final String message;
  final FutureOr<void> Function()? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: 56,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              onRetry?.call();
            },
            child: Text(retryLabel ?? 'Retry'),
          ),
        ],
      ],
    );
  }
}
