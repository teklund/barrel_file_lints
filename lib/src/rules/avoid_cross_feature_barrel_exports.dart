import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:barrel_file_lints/src/utils/feature_pattern_utils.dart';

/// Prevents cross-feature exports in barrel files.
///
/// Barrel files should only export files from their own feature folder.
/// Exporting from other features or common folders violates feature
/// encapsulation boundaries. Each feature should only expose its own code.
class AvoidCrossFeatureBarrelExports extends AnalysisRule {
  /// Creates a rule instance with default configuration.
  AvoidCrossFeatureBarrelExports()
    : super(
        name: 'avoid_cross_feature_barrel_exports',
        description:
            'Barrel files must only export from their own feature folder',
      );

  /// Diagnostic code reported when barrel exports files from other features.
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
    registry.addExportDirective(
      this,
      _CrossFeatureExportVisitor(this, context),
    );
  }
}

/// Visitor that detects cross-feature exports in barrel files.
class _CrossFeatureExportVisitor extends SimpleAstVisitor<void> {
  _CrossFeatureExportVisitor(this.rule, this.context);

  final AnalysisRule rule;
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
