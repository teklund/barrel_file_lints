/// Barrel file lints for enforcing feature-based architecture patterns
library;

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Plugin for enforcing barrel file import rules between features
class BarrelFileLintPlugin extends Plugin {
  @override
  String get name => 'barrel_file_lints';

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerLintRule(AvoidInternalFeatureImports())
      ..registerLintRule(AvoidCoreImportingFeatures())
      // Register quick fixes
      ..registerFixForRule(
        AvoidInternalFeatureImports.code,
        ReplaceWithBarrelImport.new,
      )
      ..registerFixForRule(
        AvoidCoreImportingFeatures.code,
        RemoveFeatureImport.new,
      );
  }
}

// =============================================================================
// Feature Pattern Utilities
// =============================================================================

/// Represents a parsed feature path.
///
/// Contains the feature directory name, feature name, and architectural style.
class _FeatureMatch {
  /// Creates a feature match with the given directory, name, and style.
  _FeatureMatch({
    required this.featureDir,
    required this.featureName,
    required this.style,
  });

  /// The full feature directory name (e.g., 'feature_auth' or 'features/auth')
  final String featureDir;

  /// The short feature name (e.g., 'auth')
  final String featureName;

  /// The pattern style: 'underscore' for feature_xxx, 'slash' for features/xxx
  final String style;
}

/// Extract feature information from a path or URI
/// Supports both patterns:
/// - feature_xxx/ (underscore style)
/// - features/xxx/ (clean architecture style)
_FeatureMatch? _extractFeature(String path) {
  // Try underscore style first: feature_xxx
  final underscoreMatch = RegExp(r'feature_([^/]+)').firstMatch(path);
  if (underscoreMatch != null) {
    final name = underscoreMatch.group(1)!;
    return _FeatureMatch(
      featureDir: 'feature_$name',
      featureName: name,
      style: 'underscore',
    );
  }

  // Try clean architecture style: features/xxx
  final slashMatch = RegExp(r'features/([^/]+)').firstMatch(path);
  if (slashMatch != null) {
    final name = slashMatch.group(1)!;
    return _FeatureMatch(
      featureDir: 'features/$name',
      featureName: name,
      style: 'slash',
    );
  }

  return null;
}

/// Check if a path/URI contains any feature pattern
bool _containsFeaturePattern(String path) =>
    path.contains('feature_') || path.contains('features/');

// =============================================================================
// Lint Rules
// =============================================================================

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
    if (_isTestFile(currentPath)) return;

    final currentFeature = _extractFeature(currentPath);

    // Check if this is an import from a different feature's internal files
    final importedFeature = _extractFeature(uri);
    if (importedFeature == null) return;

    // If importing from a different feature
    if (importedFeature.featureDir != currentFeature?.featureDir) {
      // Check if it's an internal import (contains /data/ or /ui/)
      if (_isInternalImport(uri)) {
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

  /// Check if file is a test file
  bool _isTestFile(String path) =>
      path.contains('/test/') ||
      path.contains('/test_driver/') ||
      path.contains('/integration_test/') ||
      path.endsWith('_test.dart');

  /// Check if import points to internal files (data/ or ui/ subdirectories)
  bool _isInternalImport(String uri) =>
      uri.contains('/data/') ||
      uri.contains('/ui/') ||
      uri.contains('/models/') ||
      uri.contains('/exceptions/') ||
      uri.contains('/extensions/') ||
      uri.contains('/domain/') ||
      uri.contains('/presentation/') ||
      uri.contains('/application/') ||
      uri.contains('/infrastructure/');
}

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
    if (_containsFeaturePattern(uri)) {
      final feature = _extractFeature(uri);
      rule.reportAtNode(node, arguments: [feature?.featureDir ?? 'feature']);
    }
  }

  /// Check if file is in core/ directory
  bool _isInCore(String path) =>
      path.contains('/core/') || path.contains('/lib/core/');
}

// =============================================================================
// Quick Fixes
// =============================================================================

/// Quick fix: Replace internal feature import with barrel file import
///
/// Changes: import 'package:myapp/feature_auth/data/auth_service.dart';
/// To:      import 'package:myapp/feature_auth/auth.dart';
class ReplaceWithBarrelImport extends ResolvedCorrectionProducer {
  /// Creates a quick fix for replacing internal imports with barrel imports.
  ReplaceWithBarrelImport({required super.context});

  static const _fixKind = FixKind(
    'barrel_file_lints.fix.replaceWithBarrelImport',
    50, // Standard priority
    'Replace with barrel file import',
  );

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final node = this.node;
    if (node is! ImportDirective) return;

    final uri = node.uri.stringValue;
    if (uri == null) return;

    // Extract feature name and build barrel file path
    final barrelUri = _buildBarrelUri(uri);
    if (barrelUri == null) return;

    await builder.addDartFileEdit(file, (builder) {
      // Replace the entire import URI string (including quotes)
      final uriNode = node.uri;
      builder.addSimpleReplacement(range.node(uriNode), "'$barrelUri'");
    });
  }

  /// Build barrel file URI from internal import
  /// Supports both patterns and both absolute/relative imports:
  /// - 'package:myapp/feature_auth/data/auth_service.dart'
  ///    -> 'package:myapp/feature_auth/auth.dart'
  /// - '../feature_auth/data/auth_service.dart'
  ///    -> '../feature_auth/auth.dart'
  /// - 'package:myapp/features/auth/data/auth_service.dart'
  ///    -> 'package:myapp/features/auth/auth.dart'
  /// - '../../features/auth/data/auth_service.dart'
  ///    -> '../../features/auth/auth.dart'
  String? _buildBarrelUri(String uri) {
    // Try underscore style: feature_xxx/...
    // Matches: package:name/feature_xxx/..., ../feature_xxx/..., feature_xxx/...
    final underscoreMatch = RegExp(
      r'^(.*?)(feature_([^/]+))/.+$',
    ).firstMatch(uri);
    if (underscoreMatch != null) {
      final prefix = underscoreMatch.group(1)!; // e.g., 'package:myapp/', '../'
      final featureDir = underscoreMatch.group(2)!; // e.g., 'feature_auth'
      final featureName = underscoreMatch.group(3)!; // e.g., 'auth'
      return '$prefix$featureDir/$featureName.dart';
    }

    // Try clean architecture style: features/xxx/...
    // Matches: package:name/features/xxx/..., ../features/xxx/..., features/xxx/...
    final slashMatch = RegExp(r'^(.*?)(features/([^/]+))/.+$').firstMatch(uri);
    if (slashMatch != null) {
      final prefix = slashMatch.group(1)!; // e.g., 'package:myapp/', '../../'
      final featureDir = slashMatch.group(2)!; // e.g., 'features/auth'
      final featureName = slashMatch.group(3)!; // e.g., 'auth'
      return '$prefix$featureDir/$featureName.dart';
    }

    return null;
  }
}

/// Quick fix: Remove feature import from core (with comment)
///
/// Changes: import 'package:myapp/feature_auth/auth.dart';
/// To:      // TODO: Move this dependency out of core
///          // import 'package:myapp/feature_auth/auth.dart';
class RemoveFeatureImport extends ResolvedCorrectionProducer {
  /// Creates a quick fix for commenting out feature imports from core.
  RemoveFeatureImport({required super.context});

  static const _fixKind = FixKind(
    'barrel_file_lints.fix.removeFeatureImport',
    50, // Standard priority
    'Comment out import (needs refactoring)',
  );

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final node = this.node;
    if (node is! ImportDirective) return;

    // Get the import URI for the comment
    final uri = node.uri.stringValue ?? '';

    await builder.addDartFileEdit(file, (builder) {
      // Replace with commented version + TODO
      builder.addSimpleReplacement(
        range.node(node),
        '// TODO: Move this dependency out of core - core should not import features\n'
        "// import '$uri';",
      );
    });
  }
}
