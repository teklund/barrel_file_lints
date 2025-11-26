/// Quick fix to simplify redundant relative paths within the same feature
library;

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import 'package:barrel_file_lints/src/utils/feature_pattern_utils.dart';

/// Quick fix to simplify redundant relative paths within the same feature
///
/// Changes: import '../../feature_auth/data/auth_service.dart';
/// To:      import 'auth_service.dart'; (if in same directory)
/// Or:      import 'data/auth_service.dart'; (if in different directory)
class SimplifyRelativePath extends ResolvedCorrectionProducer {
  /// Quick fix to simplify redundant relative paths
  SimplifyRelativePath({required super.context});

  static const _fixKind = FixKind(
    'barrel_file_lints.fix.simplifyRelativePath',
    50,
    'Simplify to direct relative path',
  );

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final node = this.node;
    if (node is! ImportDirective) return;

    final uri = node.uri.stringValue;
    if (uri == null) return;

    // Get current file path - `file` is provided by base class
    final currentPath = file;
    final currentFeature = extractFeature(currentPath);
    if (currentFeature == null) return;

    // Only handle relative imports
    if (!isRelativeUri(uri)) return;

    // Extract the feature from the import path
    final importedFeature = extractFeature(uri);
    if (importedFeature == null) return;

    // Only simplify if importing from same feature
    if (importedFeature.featureDir != currentFeature.featureDir) return;

    // Calculate the simplified path
    final simplifiedPath = _calculateSimplifiedPath(uri, currentPath);
    if (simplifiedPath == null || simplifiedPath == uri) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(node.uri), "'$simplifiedPath'");
    });
  }

  /// Calculate the simplified relative path from current file to target
  String? _calculateSimplifiedPath(String importUri, String currentPath) {
    // Parse the import URI to find the target path within the feature
    // Example: '../../feature_order/data/extensions/order_extensions.dart'
    // Should become: 'extensions/order_extensions.dart' (if current is in data/)
    // Or: 'data/extensions/order_extensions.dart' (if current is in ui/)

    final importSegments = importUri.split('/');

    // Find where the feature directory appears in the import path
    int featureIndex = -1;
    for (int i = 0; i < importSegments.length; i++) {
      if (importSegments[i].startsWith('feature_') ||
          importSegments[i] == 'features') {
        featureIndex = i;
        break;
      }
    }

    if (featureIndex == -1) return null;

    // Get the path after the feature directory
    // For 'feature_xxx', the next segment is the actual path
    // For 'features/xxx', skip both 'features' and feature name
    final afterFeatureIndex =
        importSegments[featureIndex].startsWith('feature_')
        ? featureIndex + 1
        : featureIndex + 2;

    if (afterFeatureIndex >= importSegments.length) return null;

    // Get segments after the feature directory (e.g., ['data', 'extensions', 'file.dart'])
    final targetPathSegments = importSegments.sublist(afterFeatureIndex);

    // Get current file's position within the feature
    final currentSegments = currentPath.split('/');
    final currentFeatureIndex = currentSegments.indexWhere(
      (s) => s.startsWith('feature_') || s == 'features',
    );

    if (currentFeatureIndex == -1) return null;

    final currentAfterFeatureIndex =
        currentSegments[currentFeatureIndex].startsWith('feature_')
        ? currentFeatureIndex + 1
        : currentFeatureIndex + 2;

    // Get current file's directory path within feature (not including filename)
    final currentInFeatureSegments = currentSegments.sublist(
      currentAfterFeatureIndex,
      currentSegments.length - 1,
    );

    // Calculate the simplified relative path
    return _buildRelativePath(currentInFeatureSegments, targetPathSegments);
  }

  /// Build a relative path from current directory to target
  String _buildRelativePath(List<String> currentDir, List<String> targetPath) {
    // Find the common prefix
    int commonLength = 0;
    final minLength = currentDir.length < targetPath.length
        ? currentDir.length
        : targetPath.length;

    for (int i = 0; i < minLength; i++) {
      if (currentDir[i] == targetPath[i]) {
        commonLength++;
      } else {
        break;
      }
    }

    // Build the path
    final upCount = currentDir.length - commonLength;
    final downPath = targetPath.sublist(commonLength);

    final pathParts = <String>[];

    // Add '../' for each directory we need to go up
    for (int i = 0; i < upCount; i++) {
      pathParts.add('..');
    }

    // Add the remaining path
    pathParts.addAll(downPath);

    return pathParts.join('/');
  }
}
