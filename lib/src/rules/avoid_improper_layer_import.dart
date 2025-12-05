/// Lint rule: Enforce clean architecture layer boundaries for barrel imports
library;

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:barrel_file_lints/src/utils/feature_pattern_utils.dart';

/// Lint rule: Enforce clean architecture layer boundaries for barrel imports
///
/// Prevents layer violations by detecting when:
/// - Domain layer imports barrels that export Data or UI layer (Domain is innermost)
/// - Data layer imports barrels that export UI layer
///
/// Supports both monolithic and split barrel files:
/// - Monolithic: feature_xxx/xxx.dart (analyzes exports to detect layers)
/// - Split: feature_xxx/xxx_data.dart, xxx_domain.dart, xxx_ui.dart
///
/// ✅ Correct:
/// ```dart
/// // In feature_a/data/repository_impl.dart
/// import 'package:myapp/feature_b/b_domain.dart'; // Data can import Domain
/// import 'package:myapp/feature_c/c_data.dart';   // Data can import Data
///
/// // In feature_a/presentation/screen.dart
/// import 'package:myapp/feature_b/b_domain.dart'; // UI can import anything
/// import 'package:myapp/feature_c/c_data.dart';
/// ```
///
/// ❌ Wrong:
/// ```dart
/// // In feature_a/domain/use_case.dart
/// import 'package:myapp/feature_b/b_data.dart';   // Domain CANNOT import Data
/// import 'package:myapp/feature_c/c_ui.dart';     // Domain CANNOT import UI
///
/// // In feature_a/data/repository_impl.dart
/// import 'package:myapp/feature_b/b_ui.dart';     // Data CANNOT import UI
/// ```
class AvoidImproperLayerImport extends AnalysisRule {
  /// Creates a new instance of [AvoidImproperLayerImport]
  AvoidImproperLayerImport()
    : super(
        name: 'avoid_improper_layer_import',
        description:
            'Enforce clean architecture layer boundaries for barrel imports',
      );

  /// The lint code for this rule
  static const LintCode code = LintCode(
    'avoid_improper_layer_import',
    "Layer violation: {0} layer cannot import barrel '{1}' which exports {2} layer.",
    correctionMessage:
        'Use a layer-specific barrel file (e.g., xxx_data.dart) or ensure the barrel only exports appropriate layers.',
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addImportDirective(this, _LayerImportVisitor(this, context));
  }
}

/// Visitor that detects improper layer imports.
class _LayerImportVisitor extends SimpleAstVisitor<void> {
  /// Creates a visitor for detecting layer violations.
  _LayerImportVisitor(this.rule, this.context);

  /// The rule that created this visitor.
  final AnalysisRule rule;

  /// The context for the current analysis.
  final RuleContext context;

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue;
    if (uri == null) return;

    // Get the current file's path and layer
    final currentPath = context.libraryElement?.uri.toString() ?? '';

    // Skip test files
    if (isTestFile(currentPath)) return;

    // Get current file's feature and layer
    final currentFeature = extractFeature(currentPath);
    if (currentFeature == null) return;

    final currentLayer = getLayerFromPath(currentPath);
    if (currentLayer == ArchLayer.unknown || currentLayer == ArchLayer.ui) {
      // UI layer can import anything, unknown layers have no restrictions
      return;
    }

    // Check if importing from a different feature's barrel
    final importedFeature = extractFeature(uri);
    if (importedFeature == null) return;

    // Only check cross-feature imports
    if (importedFeature.featureDir == currentFeature.featureDir) return;

    // Determine the barrel type being imported
    final barrelType = getBarrelType(uri, importedFeature);

    // Check split barrels first
    switch (barrelType) {
      case BarrelType.splitData:
        // Data barrel - check if current layer can import it
        const importedLayer = ArchLayer.data;
        if (!isLayerImportAllowed(currentLayer, importedLayer)) {
          _reportViolation(node, currentLayer, uri, importedLayer);
        }
        return;
      case BarrelType.splitDomain:
        // Domain barrel - check if current layer can import it
        const importedLayer = ArchLayer.domain;
        if (!isLayerImportAllowed(currentLayer, importedLayer)) {
          _reportViolation(node, currentLayer, uri, importedLayer);
        }
        return;
      case BarrelType.splitUi:
        // UI barrel - check if current layer can import it
        const importedLayer = ArchLayer.ui;
        if (!isLayerImportAllowed(currentLayer, importedLayer)) {
          _reportViolation(node, currentLayer, uri, importedLayer);
        }
        return;
      case BarrelType.monolithic:
        // Monolithic barrels are not analyzed for layer violations
        // due to complexity of file system access in analysis rules.
        // Recommend using split barrels for strict layer enforcement.
        return;
      case BarrelType.notBarrel:
        // Not a barrel import, skip
        return;
    }
  }

  /// Report a layer violation
  void _reportViolation(
    ImportDirective node,
    ArchLayer currentLayer,
    String uri,
    ArchLayer violatingLayer,
  ) {
    rule.reportAtNode(
      node,
      arguments: [_layerName(currentLayer), uri, _layerName(violatingLayer)],
    );
  }

  /// Get a human-readable layer name
  String _layerName(ArchLayer layer) {
    switch (layer) {
      case ArchLayer.data:
        return 'Data';
      case ArchLayer.domain:
        return 'Domain';
      case ArchLayer.ui:
        return 'UI';
      case ArchLayer.unknown:
        return 'Unknown';
    }
  }
}
