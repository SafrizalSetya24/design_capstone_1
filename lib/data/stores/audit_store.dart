import 'package:flutter/foundation.dart';
import 'package:sipintar/data/dummy/dummy_data.dart';
import 'package:sipintar/data/models/misc_models.dart';

class AuditStore extends ChangeNotifier {
  final List<AuditEntry> entries = DummyData.audit();
  int _n = 100;

  void log(String user, String role, String type, String detail) {
    entries.insert(
        0,
        AuditEntry(
            id: 'a${_n++}',
            userName: user,
            role: role,
            type: type,
            detail: detail,
            time: DateTime.now()));
    notifyListeners();
  }
}
