/// Lint rule: Core module must not import from features
library;

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:barrel_file_lints/src/utils/feature_pattern_utils.dart';

/// Lint rule: Core module must not import from features
///
/// ✅ Correct: Core can import from common/ or external packages
/// ❌ Wrong: import 'package:myapp/feature_auth/auth.dart';
class AvoidCoreImportingFeatures extends AnalysisRule {
  /// Creates a new instance of [AvoidCoreImportingFeatures]
  AvoidCoreImportingFeatures()
    : super(
        name: 'avoid_core_importing_features',
        description: 'Core module must not import from feature modules',
      );

  /// The lint code for this rule
  static const LintCode code = LintCode(
    'avoid_core_importing_features',
    "Core module cannot import from '{0}'. Core must remain independent of features.",
    correctionMessage:
        "Move shared code to 'common/' or extract to a separate core utility.",
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addImportDirective(this, _CoreImportVisitor(this, context));
  }
}

/// Visitor that detects feature imports from core modules.
class _CoreImportVisitor extends SimpleAstVisitor<void> {
  /// Creates a visitor for detecting core-to-feature imports.
  _CoreImportVisitor(this.rule, this.context);

  /// The rule that created this visitor.
  final AnalysisRule rule;

  /// The context for the current analysis.
  final RuleContext context;

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue;
    if (uri == null) return;

    // Check if current file is in core/
    final currentPath = context.libraryElement?.uri.toString() ?? '';
    if (!_isInCore(currentPath)) return;

    // Check if importing from a feature
    if (containsFeaturePattern(uri)) {
      final feature = extractFeature(uri);
      rule.reportAtNode(node, arguments: [feature?.featureDir ?? 'feature']);
    }
  }

  /// Check if file is in core/ directory
  bool _isInCore(String path) =>
      path.contains('/core/') || path.contains('/lib/core/');
}
