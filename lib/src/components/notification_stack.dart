import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/sound/sound.dart';
import '../core/spring.dart';
import '../core/springs.dart';
import '../core/theme.dart';

/// Item in a [NotificationStack].
class KipluoNotification {
  const KipluoNotification({required this.id, required this.title, this.body = ''});
  final String id;
  final String title;
  final String body;
}

/// Controller for pushing or clearing notifications on [NotificationStack].
class NotificationStackController extends ChangeNotifier {
  final List<KipluoNotification> items = [];

  void push(KipluoNotification item) {
    items.insert(0, item);
    notifyListeners();
  }

  void dismiss(String id) {
    items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}

double clampStack(double v) => math.max(0.0, v);
