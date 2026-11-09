import 'package:flutter/foundation.dart';
import 'package:sipintar/data/dummy/dummy_data.dart';
import 'package:sipintar/data/models/misc_models.dart';

class NotificationStore extends ChangeNotifier {
  final List<AppNotification> items = DummyData.notifications();
  int _n = 100;

  List<AppNotification> forUser(String id) =>
      items.where((n) => n.userId == id).toList()
        ..sort((a, b) => b.time.compareTo(a.time));
  int unread(String id) => items.where((n) => n.userId == id && !n.read).length;

  void add(String userId, NotifType type, String title, String body,
      {String? refId, bool loan = true}) {
    items.add(AppNotification(
        id: 'n${_n++}',
        userId: userId,
        type: type,
        title: title,
        body: body,
        time: DateTime.now(),
        refId: refId,
        refIsLoan: loan));
    notifyListeners();
  }

  void markRead(String id) {
    for (final n in items) {
      if (n.id == id && !n.read) {
        n.read = true;
        notifyListeners();
      }
    }
  }

  void markAllRead(String userId) {
    for (final n in items) {
      if (n.userId == userId) n.read = true;
    }
    notifyListeners();
  }

  void markAll(String userId) => markAllRead(userId);
}
