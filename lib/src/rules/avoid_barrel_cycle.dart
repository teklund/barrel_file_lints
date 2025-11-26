/// Lint rule: Barrel files should not create immediate circular dependencies
library;

import 'dart:io';

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:barrel_file_lints/src/utils/feature_pattern_utils.dart';
import 'package:path/path.dart' as path;

/// Lint rule: Barrel files should not create immediate circular dependencies
///
/// This rule detects direct back-and-forth cycles between barrel files:
/// - feature_a/a.dart exports feature_b/b.dart
/// - feature_b/b.dart exports feature_a/a.dart
///
/// ✅ Correct: One-way dependencies between barrels
/// ❌ Wrong: Mutual exports between barrels (creates circular dependency)
///
/// Note: This only detects immediate (2-node) cycles. For transitive cycles
/// (A → B → C → A), use the CLI tool: `dart run barrel_file_lints:check_cycles`
class AvoidBarrelCycle extends AnalysisRule {
  /// Creates a new instance of [AvoidBarrelCycle]
  AvoidBarrelCycle()
    : super(
        name: 'avoid_barrel_cycle',
        description:
            'Barrel files should not create immediate circular dependencies',
      );

  /// The lint code for this rule
  static const LintCode code = LintCode(
    'avoid_barrel_cycle',
    "Barrel file has circular dependency with '{0}'. Both barrels export each other, creating a dependency cycle.",
    correctionMessage:
        'Remove one of the exports to break the cycle. Consider restructuring to have one-way dependencies.',
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addExportDirective(this, _BarrelCycleVisitor(this, context));
  }
}

/// Visitor that detects immediate barrel-to-barrel cycles.
class _BarrelCycleVisitor extends SimpleAstVisitor<void> {
  /// Creates a visitor for detecting barrel cycles.
  _BarrelCycleVisitor(this.rule, this.context);

  /// The rule that created this visitor.
  final AnalysisRule rule;

  /// The context for the current analysis.
  final RuleContext context;

  @override
  void visitExportDirective(ExportDirective node) {
    final uri = node.uri.stringValue;
    if (uri == null) return;

    // Get the current file's path
    final libraryElement = context.libraryElement;
    if (libraryElement == null) return;
    final currentPath = libraryElement.uri.toString();

    // Skip test files
    if (isTestFile(currentPath)) return;

    // Check if current file is a barrel file
    final currentFeature = extractFeature(currentPath);
    if (currentFeature == null) return;

    // Check if this file is actually the barrel file
    if (!isBarrelFile(currentPath, currentFeature)) return;

    // Check if we're exporting another barrel file
    final exportedFeature = extractFeature(uri);
    if (exportedFeature == null) return;

    // Try to resolve the exported file and check for reverse export
    // We use a simple heuristic: read the file if it exists
    final exportedBarrelPath = _resolveBarrelPath(uri, exportedFeature);
    if (exportedBarrelPath == null) return;

    // Check if the exported barrel exports back to us
    if (_hasReverseExport(exportedBarrelPath, currentFeature)) {
      rule.reportAtNode(node, arguments: [exportedFeature.featureDir]);
    }
  }

  /// Resolve the exported URI to a file system path
  String? _resolveBarrelPath(String uri, FeatureMatch feature) {
    try {
      // Get current file path from LibraryElement
      final libraryElement = context.libraryElement;
      if (libraryElement == null) return null;
      final currentUri = libraryElement.uri;
      if (currentUri.scheme != 'file' && currentUri.scheme != 'package') {
        return null;
      }

      // For package: URIs, we need to find the actual file
      if (uri.startsWith('package:')) {
        // Extract the relative path after package name
        final match = RegExp(r'package:[^/]+/(.+)').firstMatch(uri);
        if (match == null) return null;

        final relativePath = match.group(1)!;

        // Try to construct barrel file path
        // This is heuristic-based: assume lib/ directory structure
        if (currentUri.scheme == 'file') {
          final currentPath = currentUri.toFilePath();
          final libIndex = currentPath.lastIndexOf('/lib/');
          if (libIndex == -1) return null;

          final libPath = currentPath.substring(
            0,
            libIndex + 5,
          ); // Include '/lib/'
          return '$libPath$relativePath';
        }
      }

      // For relative URIs, resolve from current file
      if (isRelativeUri(uri)) {
        if (currentUri.scheme != 'file') return null;

        final currentPath = currentUri.toFilePath();
        final currentDir = path.dirname(currentPath);
        final resolved = path.normalize(path.join(currentDir, uri));
        return resolved;
      }

      return null;
    } on Exception {
      return null;
    }
  }

  /// Check if the target barrel file exports back to the current feature
  bool _hasReverseExport(String targetBarrelPath, FeatureMatch currentFeature) {
    try {
      final file = File(targetBarrelPath);
      if (!file.existsSync()) return false;

      // Read and parse the target file
      final content = file.readAsStringSync();

      // Simple check: look for export statements that reference our feature
      // This is a heuristic - not perfect but catches most cases
      final exportPattern = RegExp(
        r'''export\s+['"]([^'"]+)['"]''',
        multiLine: true,
      );

      final matches = exportPattern.allMatches(content);
      for (final match in matches) {
        final exportUri = match.group(1);
        if (exportUri == null) continue;

        // Check if this export references our current feature
        if (exportUri.contains(currentFeature.featureDir) ||
            exportUri.contains('/${currentFeature.featureName}.dart')) {
          // Found a reverse reference - likely a cycle
          return true;
        }
      }

      return false;
    } on Exception {
      // If we can't read/parse the file, assume no cycle
      // Better to have false negatives than false positives
      return false;
    }
  }
}
