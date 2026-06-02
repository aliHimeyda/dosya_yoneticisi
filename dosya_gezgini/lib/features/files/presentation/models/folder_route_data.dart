import 'package:dosya_gezgini/features/files/state/folderleragaci.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as pathinfo;

class FolderRouteData {
  const FolderRouteData({
    required this.name,
    required this.path,
    this.isVirtual = false,
    this.allowedExtensions = const {},
    this.folderNode,
  });

  final String name;
  final String path;
  final bool isVirtual;
  final Set<String> allowedExtensions;
  final FolderNode? folderNode;

  factory FolderRouteData.fromFolderNode(FolderNode folderNode) {
    return FolderRouteData(
      name: folderNode.name,
      path: folderNode.path,
      isVirtual: folderNode.isVirtual,
      allowedExtensions: folderNode.allowedExtensions,
      folderNode: folderNode,
    );
  }

  factory FolderRouteData.fromPath(
    String path, {
    String? name,
    bool isVirtual = false,
    Set<String> allowedExtensions = const {},
    FolderNode? folderNode,
  }) {
    return FolderRouteData(
      name: name ?? _resolveName(path),
      path: path,
      isVirtual: isVirtual || path.startsWith('virtual:'),
      allowedExtensions: allowedExtensions,
      folderNode: folderNode,
    );
  }

  static FolderRouteData? fromExtra(Object? extra) {
    if (extra is FolderRouteData) {
      return extra;
    }

    if (extra is String) {
      return FolderRouteData.fromPath(extra);
    }

    return null;
  }

  static FolderRouteData? fromState(GoRouterState state) {
    final routeFromExtra = fromExtra(state.extra);
    final pathFromQuery = state.uri.queryParameters['path']?.trim();

    if (pathFromQuery == null || pathFromQuery.isEmpty) {
      return routeFromExtra;
    }

    if (routeFromExtra != null && routeFromExtra.path == pathFromQuery) {
      return routeFromExtra;
    }

    final folderNode =
        routeFromExtra?.folderNode?.path == pathFromQuery
            ? routeFromExtra!.folderNode
            : null;

    return FolderRouteData.fromPath(
      pathFromQuery,
      name: routeFromExtra?.path == pathFromQuery ? routeFromExtra?.name : null,
      isVirtual:
          routeFromExtra?.isVirtual ?? pathFromQuery.startsWith('virtual:'),
      allowedExtensions: routeFromExtra?.allowedExtensions ?? const {},
      folderNode: folderNode,
    );
  }

  static String _resolveName(String path) {
    if (path.startsWith('virtual:')) {
      return path.substring('virtual:'.length);
    }

    final baseName = pathinfo.basename(path);
    return baseName.isEmpty ? path : baseName;
  }

  FolderNode resolveFolderNode({FileTree? fileTree}) {
    final currentFolderNode = folderNode;
    if (currentFolderNode != null) {
      return currentFolderNode;
    }

    final knownFolder = fileTree?.findKnownFolder(path);
    if (knownFolder != null) {
      return knownFolder;
    }

    return FolderNode(
      name,
      path,
      [],
      [],
      null,
      isVirtual: isVirtual,
      allowedExtensions: allowedExtensions,
    );
  }
}
