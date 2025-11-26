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
/// or use unnecessarily complex relative paths within the same feature
///
/// ✅ Correct: import 'package:myapp/feature_auth/data/auth_service.dart';
/// ✅ Correct: import 'extensions/trip_extensions.dart'; (within same directory)
/// ❌ Wrong: import 'package:myapp/feature_auth/auth.dart'; (from within feature_auth)
/// ❌ Wrong: import '../../feature_trip/data/extensions/file.dart'; (from within feature_trip)
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

    // Handle relative imports (e.g., '../trip.dart' from 'feature_trip/ui/file.dart')
    if (isRelativeUri(uri)) {
      // Check if it's a relative path to the barrel file
      if (_isRelativeBarrelImport(uri, currentFeature)) {
        rule.reportAtNode(node, arguments: [currentFeature.featureDir]);
        return;
      }

      // Check if it's a complex relative path that re-enters the same feature
      // e.g., '../../feature_trip/data/file.dart' from within feature_trip
      if (_isRedundantRelativePath(uri, currentFeature)) {
        rule.reportAtNode(node, arguments: [currentFeature.featureDir]);
        return;
      }
    }

    // Handle absolute package imports
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

  /// Check if a relative URI points to the barrel file
  /// e.g., '../trip.dart' from 'feature_trip/ui/file.dart' should be detected
  bool _isRelativeBarrelImport(String uri, FeatureMatch feature) {
    // Remove any './' or '../' segments to get the filename
    final fileName = uri.split('/').last;

    // Check if filename matches the feature's barrel file name
    return fileName == '${feature.featureName}.dart';
  }

  /// Check if a relative path unnecessarily escapes and re-enters the same feature
  /// e.g., '../../feature_trip/data/extensions/file.dart' from within feature_trip
  bool _isRedundantRelativePath(String uri, FeatureMatch currentFeature) {
    // Only check paths that go up with ../
    if (!uri.contains('../')) return false;

    // Extract the feature pattern from the relative path
    // Look for feature_xxx or features/xxx in the path
    final importedFeature = extractFeature(uri);
    if (importedFeature == null) return false;

    // If the relative path references the same feature we're already in, it's redundant
    return importedFeature.featureDir == currentFeature.featureDir;
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
