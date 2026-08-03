/// Formats a byte count for display, e.g. `2.4 MB`.
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 KB';
  const int kb = 1024;
  const int mb = kb * 1024;
  const int gb = mb * 1024;

  if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(1)} GB';
  if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
  return '${(bytes / kb).round()} KB';
}
