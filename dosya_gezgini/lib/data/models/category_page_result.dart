import 'package:dosya_gezgini/data/models/indexed_file_model.dart';

class CategoryPageResult {
  const CategoryPageResult({
    required this.items,
    required this.totalCount,
    required this.nextOffset,
    required this.hasMore,
  });

  final List<IndexedFileModel> items;
  final int totalCount;
  final int nextOffset;
  final bool hasMore;
}
