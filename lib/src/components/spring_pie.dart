import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/// Data item for [SpringPie].
class PieSlice {
  const PieSlice({required this.label, required this.value, this.color});
  final String label;
  final double value;
  final Color? color;
}
