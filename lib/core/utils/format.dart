class Fmt {
  Fmt._();
  static const _bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  static String two(int n) => n.toString().padLeft(2, '0');
  static String monthShort(int m) => _bulan[m - 1];
  static String date(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';
  static String time(DateTime d) => '${two(d.hour)}.${two(d.minute)}';
  static String dateTime(DateTime d) => '${date(d)}, ${time(d)}';
  static String range(DateTime a, DateTime b) {
    final same = a.year == b.year && a.month == b.month && a.day == b.day;
    return same ? '${date(a)}, ${time(a)} - ${time(b)}' : '${dateTime(a)} - ${dateTime(b)}';
  }

  static String countdown(Duration d) {
    if (d.isNegative) return '00:00:00';
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  static String ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return date(d);
  }
}
