import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:barrel_file_lints/src/utils/feature_pattern_utils.dart';

/// Prevents core from importing feature modules.
///
/// Core modules must remain independent of features. They can import from
/// common directories or external packages, but importing from feature
/// modules creates unwanted dependencies that violate architectural
/// boundaries.
class AvoidCoreImportingFeatures extends AnalysisRule {
  /// Creates a rule instance with default configuration.
  AvoidCoreImportingFeatures()
    : super(
        name: 'avoid_core_importing_features',
        description: 'Core module must not import from feature modules',
      );

  /// Diagnostic code reported when core module imports from features.
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
  _CoreImportVisitor(this.rule, this.context);

  final AnalysisRule rule;
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
