import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:barrel_file_lints/src/utils/feature_pattern_utils.dart';

/// Enforces barrel file imports between features.
///
/// Prevents direct imports into a feature's internal implementation and
/// maintains feature encapsulation by requiring barrel file imports.
/// Supports both `feature_xxx/` (underscore) and `features/xxx/` (clean
/// architecture) naming conventions.
///
/// For example, instead of importing
/// `package:myapp/feature_auth/data/auth_service.dart`, use the barrel file
/// `package:myapp/feature_auth/auth.dart`.
class AvoidInternalFeatureImports extends AnalysisRule {
  /// Creates a rule instance with default configuration.
  AvoidInternalFeatureImports()
    : super(
        name: 'avoid_internal_feature_imports',
        description:
            'Features must import other features via barrel files only',
      );

  /// Diagnostic code reported when importing internal feature files directly.
  static const LintCode code = LintCode(
    'avoid_internal_feature_imports',
    "Import '{0}' via its barrel file '{1}' instead of internal path.",
    correctionMessage:
        'Use the barrel file to maintain proper feature boundaries.',
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addImportDirective(this, _InternalImportVisitor(this, context));
  }
}

/// Visitor that detects internal feature imports.
class _InternalImportVisitor extends SimpleAstVisitor<void> {
  _InternalImportVisitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue;
    if (uri == null) return;

    // Get the current file's feature
    final currentPath = context.libraryElement?.uri.toString() ?? '';

    // Skip test files - tests are allowed to import internal files
    if (isTestFile(currentPath)) return;

    final currentFeature = extractFeature(currentPath);

    // Check if this is an import from a different feature's internal files
    final importedFeature = extractFeature(uri);
    if (importedFeature == null) return;

    // If importing from a different feature
    if (importedFeature.featureDir != currentFeature?.featureDir) {
      // Check if it's a split barrel import - these are allowed
      final barrelType = getBarrelType(uri, importedFeature);
      if (barrelType == BarrelType.splitData ||
          barrelType == BarrelType.splitDomain ||
          barrelType == BarrelType.splitUi ||
          barrelType == BarrelType.monolithic) {
        // This is a barrel import, allowed
        return;
      }

      // Check if it's an internal import (contains /data/ or /ui/)
      if (isInternalImport(uri)) {
        // Determine the layer to suggest appropriate barrel
        final importLayer = getLayerFromPath(uri);
        final barrelFileName = getBarrelFileName(
          importedFeature.featureName,
          importLayer,
        );

        final barrelFile = '${importedFeature.featureDir}/$barrelFileName';

        rule.reportAtNode(
          node,
          arguments: [importedFeature.featureDir, barrelFile],
        );
      }
    }
  }
}
