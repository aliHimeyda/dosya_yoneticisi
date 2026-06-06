import 'package:intl/intl.dart';

const String unknownFileMetadataPlaceholder = '— | —';

String formatFileSize(int sizeBytes) {
  const int kb = 1024;
  const int mb = kb * 1024;
  const int gb = mb * 1024;

  if (sizeBytes >= gb) {
    return '${(sizeBytes / gb).toStringAsFixed(2)} GB';
  }

  if (sizeBytes >= mb) {
    return '${(sizeBytes / mb).toStringAsFixed(2)} MB';
  }

  if (sizeBytes >= kb) {
    return '${(sizeBytes / kb).toStringAsFixed(2)} KB';
  }

  return '$sizeBytes Byte';
}

String formatModifiedDate(DateTime date) {
  return DateFormat('dd.MM.yyyy HH:mm').format(date);
}

String formatFileSubtitle({
  required int sizeBytes,
  required DateTime modifiedAt,
}) {
  return '${formatFileSize(sizeBytes)} | ${formatModifiedDate(modifiedAt)}';
}
