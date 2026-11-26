import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/// Item entry for [SortableList].
class SortableListItem<T> {
  const SortableListItem({required this.id, required this.data});
  final String id;
  final T data;
}
