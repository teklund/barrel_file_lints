import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:barrel_file_lints/src/utils/feature_pattern_utils.dart';

/// Encourages package imports for cross-feature barrels.
///
/// Recommends using package imports instead of relative imports when importing
/// barrel files from other features. Package imports improve code clarity,
/// safety, and IDE support compared to relative paths like
/// `../../feature_tickets/tickets.dart`.
class AvoidRelativeBarrelImports extends AnalysisRule {
  /// Creates a rule instance with default configuration.
  AvoidRelativeBarrelImports()
    : super(
        name: 'avoid_relative_barrel_imports',
        description: 'Cross-feature barrel imports should use package imports',
      );

  /// Diagnostic code reported when using relative imports for barrel files.
  static const LintCode code = LintCode(
    'avoid_relative_barrel_imports',
    "Use package import 'package:{0}' instead of relative import for "
        'cross-feature barrel.',
    correctionMessage:
        'Package imports improve clarity and refactoring safety for '
        'cross-feature dependencies.',
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
      _RelativeBarrelImportVisitor(this, context),
    );
  }
}

/// Visitor that detects relative barrel imports.
class _RelativeBarrelImportVisitor extends SimpleAstVisitor<void> {
  _RelativeBarrelImportVisitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue;
    if (uri == null) return;

    // Only check relative imports
    if (!isRelativeUri(uri)) return;

    // Get the current file's feature
    final currentPath = context.libraryElement?.uri.toString() ?? '';

    // Skip test files
    if (isTestFile(currentPath)) return;

    final currentFeature = extractFeature(currentPath);

    // Check if this is an import from a different feature
    final importedFeature = extractFeature(uri);
    if (importedFeature == null) return;

    // Only flag if importing from a different feature
    if (importedFeature.featureDir == currentFeature?.featureDir) return;

    // Check if it's a barrel file import
    final barrelType = getBarrelType(uri, importedFeature);
    if (barrelType == BarrelType.notBarrel) return;

    // This is a relative import to another feature's barrel file
    // Extract package name and suggest package import
    final packageImport = _buildSuggestedPackageImport(
      currentPath,
      uri,
      importedFeature,
    );
    if (packageImport != null) {
      rule.reportAtNode(node, arguments: [packageImport]);
    }
  }

  /// Builds the suggested package import from a relative import.
  ///
  /// Extracts the package name from the current file's URI and constructs
  /// the appropriate package import path.
  String? _buildSuggestedPackageImport(
    String currentPath,
    String relativeUri,
    FeatureMatch importedFeature,
  ) {
    // Extract package name from current path
    // e.g., 'package:myapp/feature_x/file.dart' -> 'myapp'
    final packageMatch = RegExp(r'package:([^/]+)/').firstMatch(currentPath);
    if (packageMatch == null) return null;

    final packageName = packageMatch.group(1)!;

    // Determine the barrel file name based on type
    final barrelType = getBarrelType(relativeUri, importedFeature);
    final barrelFileName = _getBarrelFileName(importedFeature, barrelType);

    // Construct package import
    return '$packageName/${importedFeature.featureDir}/$barrelFileName';
  }

  /// Gets the barrel file name based on type.
  String _getBarrelFileName(FeatureMatch feature, BarrelType type) {
    final layer = switch (type) {
      BarrelType.splitData => ArchLayer.data,
      BarrelType.splitDomain => ArchLayer.domain,
      BarrelType.splitUi => ArchLayer.ui,
      BarrelType.monolithic || BarrelType.notBarrel => ArchLayer.unknown,
    };
    return getBarrelFileName(feature.featureName, layer);
  }
}
