/// Quick fix: Replace monolithic barrel import with layer-specific barrel
library;

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import 'package:barrel_file_lints/src/utils/feature_pattern_utils.dart';

/// Quick fix: Replace monolithic barrel import with layer-specific barrel
///
/// Replaces imports like:
/// ```dart
/// import 'package:myapp/feature_b/b.dart';
/// ```
///
/// With layer-specific imports:
/// ```dart
/// import 'package:myapp/feature_b/b_data.dart';
/// ```
class UseLayerSpecificBarrel extends ResolvedCorrectionProducer {
  /// Creates a quick fix for using layer-specific barrel imports.
  UseLayerSpecificBarrel({required super.context});

  static const _fixKind = FixKind(
    'barrel_file_lints.fix.useLayerSpecificBarrel',
    50, // Standard priority
    'Use layer-specific barrel import',
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

    // Extract the feature from the import
    final importedFeature = extractFeature(uri);
    if (importedFeature == null) return;

    // Get the current file's layer
    final currentPath = unitResult.uri.toString();
    final currentLayer = getLayerFromPath(currentPath);

    // Determine the appropriate layer suffix
    String layerSuffix;
    switch (currentLayer) {
      case ArchLayer.data:
        layerSuffix = '_data';
        break;
      case ArchLayer.domain:
        layerSuffix = '_domain';
        break;
      case ArchLayer.ui:
        layerSuffix = '_ui';
        break;
      case ArchLayer.unknown:
        // Can't determine layer, skip
        return;
    }

    // Build the new import URI with layer suffix
    final newUri = uri.replaceAll(
      '/${importedFeature.featureName}.dart',
      '/${importedFeature.featureName}$layerSuffix.dart',
    );

    // Replace the import URI
    await builder.addDartFileEdit(file, (builder) {
      final uriNode = node.uri;
      builder.addSimpleReplacement(range.node(uriNode), "'$newUri'");
    });
  }
}
