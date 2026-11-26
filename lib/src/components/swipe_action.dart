import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/// Action revealed behind a [SwipeAction] row.
class SwipeActionItem {
  const SwipeActionItem({
    required this.label,
    required this.icon,
    required this.onTrigger,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTrigger;
  final bool destructive;
}
