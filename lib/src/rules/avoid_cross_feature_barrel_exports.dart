/// Lint rule: Barrel files must only export from their own feature folder
library;

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:barrel_file_lints/src/utils/feature_pattern_utils.dart';

/// Lint rule: Barrel files must only export from their own feature folder
///
/// ✅ Correct: export 'data/auth_service.dart'; (in feature_auth/auth.dart)
/// ✅ Correct: export 'ui/login_page.dart'; (in feature_auth/auth.dart)
/// ❌ Wrong: export '../feature_users/data/user.dart'; (in feature_auth/auth.dart)
/// ❌ Wrong: export '../common/widgets.dart'; (in feature_auth/auth.dart)
class AvoidCrossFeatureBarrelExports extends AnalysisRule {
  /// Creates a new instance of [AvoidCrossFeatureBarrelExports]
  AvoidCrossFeatureBarrelExports()
    : super(
        name: 'avoid_cross_feature_barrel_exports',
        description:
            'Barrel files must only export from their own feature folder',
      );

  /// The lint code for this rule
  static const LintCode code = LintCode(
    'avoid_cross_feature_barrel_exports',
    "Barrel file cannot export '{0}' from outside its own feature. Barrel files should only export their own feature's files.",
    correctionMessage:
        'Remove this export or move the file into this feature. Each feature should only expose its own code.',
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addExportDirective(this, _BarrelExportVisitor(this, context));
  }
}

/// Visitor that detects cross-feature exports in barrel files.
class _BarrelExportVisitor extends SimpleAstVisitor<void> {
  /// Creates a visitor for detecting cross-feature exports.
  _BarrelExportVisitor(this.rule, this.context);

  /// The rule that created this visitor.
  final AnalysisRule rule;

  /// The context for the current analysis.
  final RuleContext context;

  @override
  void visitExportDirective(ExportDirective node) {
    final uri = node.uri.stringValue;
    if (uri == null) return;

    // Get the current file's path
    final currentPath = context.libraryElement?.uri.toString() ?? '';

    // Skip test files
    if (isTestFile(currentPath)) return;

    // Check if current file is a barrel file
    final currentFeature = extractFeature(currentPath);
    if (currentFeature == null) return;

    // Check if this file is actually the barrel file
    if (!isBarrelFile(currentPath, currentFeature)) return;

    // Now check the export URI
    // For relative imports, check if they escape the feature directory
    if (isRelativeUri(uri)) {
      // Check if it goes up and out of the feature folder
      if (escapesFeatureFolder(uri)) {
        rule.reportAtNode(node, arguments: [uri]);
        return;
      }
    } else {
      // For absolute package imports, check if they reference another feature
      final exportedFeature = extractFeature(uri);
      if (exportedFeature != null &&
          exportedFeature.featureDir != currentFeature.featureDir) {
        rule.reportAtNode(node, arguments: [uri]);
        return;
      }
    }
  }
}
