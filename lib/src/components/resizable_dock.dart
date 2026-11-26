import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/// Dock item for [ResizableDock].
class DockItem {
  const DockItem({required this.id, required this.label, required this.icon, this.onTap});
  final String id;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
}
