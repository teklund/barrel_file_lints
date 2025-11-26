/// Lint rule: Files within a feature should not import their own barrel file
library;

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:barrel_file_lints/src/utils/feature_pattern_utils.dart';

/// Lint rule: Files within a feature should not import their own barrel file
///
/// ✅ Correct: import 'package:myapp/feature_auth/data/auth_service.dart';
/// ❌ Wrong: import 'package:myapp/feature_auth/auth.dart'; (from within feature_auth)
class AvoidSelfBarrelImport extends AnalysisRule {
  /// Creates a new instance of [AvoidSelfBarrelImport]
  AvoidSelfBarrelImport()
    : super(
        name: 'avoid_self_barrel_import',
        description:
            'Files within a feature should not import their own barrel file',
      );

  /// The lint code for this rule
  static const LintCode code = LintCode(
    'avoid_self_barrel_import',
    "Avoid importing your own feature's barrel file '{0}'. Use direct imports within the same feature to prevent circular dependencies.",
    correctionMessage:
        'Import the specific file you need directly instead of using the barrel file.',
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addImportDirective(this, _SelfBarrelImportVisitor(this, context));
  }
}

/// Visitor that detects self-barrel imports.
class _SelfBarrelImportVisitor extends SimpleAstVisitor<void> {
  /// Creates a visitor for detecting self-barrel imports.
  _SelfBarrelImportVisitor(this.rule, this.context);

  /// The rule that created this visitor.
  final AnalysisRule rule;

  /// The context for the current analysis.
  final RuleContext context;

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue;
    if (uri == null) return;

    // Get the current file's feature
    final currentPath = context.libraryElement?.uri.toString() ?? '';

    // Skip test files
    if (isTestFile(currentPath)) return;

    final currentFeature = extractFeature(currentPath);
    if (currentFeature == null) return;

    // Check if importing from same feature
    final importedFeature = extractFeature(uri);
    if (importedFeature == null) return;

    // If importing from the SAME feature
    if (importedFeature.featureDir == currentFeature.featureDir) {
      // Check if it's the barrel file (NOT an internal directory)
      if (!isInternalImport(uri)) {
        // This is importing the feature's own barrel file - check if it's actually the barrel
        if (_isBarrelFileImport(uri, importedFeature)) {
          rule.reportAtNode(node, arguments: [importedFeature.featureDir]);
        }
      }
    }
  }

  /// Check if the URI points to a barrel file
  /// Barrel files are typically named after the feature (e.g., auth.dart for feature_auth)
  bool _isBarrelFileImport(String uri, FeatureMatch feature) {
    // Extract just the filename from the URI
    final segments = uri.split('/');
    final fileName = segments.isNotEmpty ? segments.last : '';

    // Check if filename matches the feature name + .dart
    // e.g., for feature_auth, barrel is auth.dart
    // e.g., for features/auth, barrel is auth.dart
    return fileName == '${feature.featureName}.dart';
  }
}
