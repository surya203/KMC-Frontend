String formatEventDate(String iso) {
  final dt = DateTime.parse(iso).toLocal();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}

String formatDateTime(String iso) {
  final dt = DateTime.parse(iso).toLocal();
  return '${formatEventDate(iso)} · ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
