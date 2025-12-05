import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:barrel_file_lints/src/utils/feature_pattern_utils.dart';

/// Replaces monolithic barrel imports with layer-specific barrels.
///
/// Enforces proper layer boundaries by using appropriate split barrel files
/// based on the importing file's architectural layer. For example, a file in
/// the data layer importing from another feature will use the `_data.dart`
/// barrel instead of the monolithic barrel.
class UseLayerSpecificBarrel extends ResolvedCorrectionProducer {
  /// Creates a fix instance for the current resolution context.
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

    // Can't determine layer, skip
    if (currentLayer == ArchLayer.unknown) {
      return;
    }

    // Get the appropriate barrel filename for this layer
    final barrelFileName = getBarrelFileName(
      importedFeature.featureName,
      currentLayer,
    );

    // Build the new import URI with layer-specific barrel
    final newUri = uri.replaceAll(
      '/${importedFeature.featureName}.dart',
      '/$barrelFileName',
    );

    // Replace the import URI
    await builder.addDartFileEdit(file, (builder) {
      final uriNode = node.uri;
      builder.addSimpleReplacement(range.node(uriNode), "'$newUri'");
    });
  }
}
