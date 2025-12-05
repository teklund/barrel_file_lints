import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:barrel_file_lints/src/utils/feature_pattern_utils.dart';

/// Enforces Clean Architecture layer boundaries.
///
/// Prevents layer violations by detecting when domain layer imports barrels
/// that export data or UI layer, or when data layer imports barrels that
/// export UI layer. The dependency direction must be: UI → Data → Domain.
///
/// Supports both monolithic barrels (analyzes exports to detect layers) and
/// split barrels with layer-specific files like `xxx_data.dart`,
/// `xxx_domain.dart`, and `xxx_ui.dart`.
///
/// For example, in `feature_a/data/repository_impl.dart`, importing
/// `package:myapp/feature_b/b_domain.dart` is allowed (data can import domain),
/// but importing `package:myapp/feature_b/b_ui.dart` is not allowed (data
/// cannot import UI).
class AvoidImproperLayerImport extends AnalysisRule {
  /// Creates a rule instance with default configuration.
  AvoidImproperLayerImport()
    : super(
        name: 'avoid_improper_layer_import',
        description:
            'Enforce clean architecture layer boundaries for barrel imports',
      );

  /// Diagnostic code reported when a layer import violates architecture boundaries.
  static const LintCode code = LintCode(
    'avoid_improper_layer_import',
    "Layer violation: {0} layer should not import '{1}'. Use '{2}' instead.",
    correctionMessage:
        'Use layer-specific barrel files to maintain proper architectural boundaries.',
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addImportDirective(
      this,
      _ImproperLayerImportVisitor(this, context),
    );
  }
}

/// Visitor that detects improper layer imports.
class _ImproperLayerImportVisitor extends SimpleAstVisitor<void> {
  _ImproperLayerImportVisitor(this.rule, this.context);

  final AnalysisRule rule;
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
        // For monolithic barrels, warn data/domain layers to use split barrels
        // Data layer should use xxx_data.dart, domain should use xxx_domain.dart
        if (currentLayer == ArchLayer.data ||
            currentLayer == ArchLayer.domain) {
          _reportMonolithicBarrelUsage(node, currentLayer, importedFeature);
        }
        return;
      case BarrelType.notBarrel:
        // Not a barrel import, skip
        return;
    }
  }

  /// Reports a layer violation.
  void _reportViolation(
    ImportDirective node,
    ArchLayer currentLayer,
    String uri,
    ArchLayer violatingLayer,
  ) {
    // For split barrel violations, suggest using appropriate layer barrel
    // This shouldn't normally happen since split barrels are explicit
    rule.reportAtNode(
      node,
      arguments: [_layerName(currentLayer), uri, 'a layer-appropriate barrel'],
    );
  }

  /// Reports monolithic barrel usage from data/domain layers.
  void _reportMonolithicBarrelUsage(
    ImportDirective node,
    ArchLayer currentLayer,
    FeatureMatch importedFeature,
  ) {
    final suggestedBarrel = getBarrelFileName(
      importedFeature.featureName,
      currentLayer,
    );

    rule.reportAtNode(
      node,
      arguments: [
        _layerName(currentLayer),
        '${importedFeature.featureDir}/${importedFeature.featureName}.dart',
        '${importedFeature.featureDir}/$suggestedBarrel',
      ],
    );
  }

  /// Gets a human-readable layer name.
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
