/// Lint rule: Features must import other features via barrel files only
library;

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:barrel_file_lints/src/utils/feature_pattern_utils.dart';

/// Lint rule: Features must import other features via barrel files only
///
/// Supports both naming conventions:
/// - feature_xxx/ (underscore style)
/// - features/xxx/ (clean architecture style)
///
/// ✅ Correct: import 'package:myapp/feature_auth/auth.dart';
/// ✅ Correct: import 'package:myapp/features/auth/auth.dart';
/// ❌ Wrong: import 'package:myapp/feature_auth/data/auth_service.dart';
/// ❌ Wrong: import 'package:myapp/features/auth/data/auth_service.dart';
class AvoidInternalFeatureImports extends AnalysisRule {
  /// Creates a new instance of [AvoidInternalFeatureImports]
  AvoidInternalFeatureImports()
    : super(
        name: 'avoid_internal_feature_imports',
        description:
            'Features must import other features via barrel files only',
      );

  /// The lint code for this rule
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
  /// Creates a visitor for detecting internal imports.
  _InternalImportVisitor(this.rule, this.context);

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

    // Skip test files - tests are allowed to import internal files
    if (isTestFile(currentPath)) return;

    final currentFeature = extractFeature(currentPath);

    // Check if this is an import from a different feature's internal files
    final importedFeature = extractFeature(uri);
    if (importedFeature == null) return;

    // If importing from a different feature
    if (importedFeature.featureDir != currentFeature?.featureDir) {
      // Check if it's an internal import (contains /data/ or /ui/)
      if (isInternalImport(uri)) {
        // Build the suggested barrel file path
        final barrelFile =
            '${importedFeature.featureDir}/${importedFeature.featureName}.dart';

        rule.reportAtNode(
          node,
          arguments: [importedFeature.featureDir, barrelFile],
        );
      }
    }
  }
}
