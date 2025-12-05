import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:barrel_file_lints/src/utils/feature_pattern_utils.dart';

/// Enforces framework independence in Domain and Data layers.
///
/// Prevents Flutter framework imports in business logic and infrastructure
/// layers. Domain layer should contain pure business logic without UI
/// dependencies. Data layer should implement domain interfaces without UI
/// framework coupling.
///
/// Allowed imports include Dart core libraries (`dart:*`), annotations
/// (`package:meta/meta.dart`), internal feature imports, and external
/// non-Flutter packages. Forbidden imports include `package:flutter/material.dart`,
/// `package:flutter/widgets.dart`, and other Flutter framework packages.
class AvoidFlutterInDomain extends AnalysisRule {
  /// Creates a rule instance with default configuration.
  AvoidFlutterInDomain()
    : super(
        name: 'avoid_flutter_in_domain',
        description: 'Domain and Data layers must not import Flutter framework',
      );

  /// Diagnostic code reported when domain/data layers import Flutter framework.
  static const LintCode code = LintCode(
    'avoid_flutter_in_domain',
    "'{0}' layer cannot import '{1}'. Domain and Data layers must remain framework-independent.",
    correctionMessage:
        'Remove Flutter imports from domain/data layers. Use pure Dart types and domain interfaces instead. UI framework dependencies belong only in the presentation layer.',
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addImportDirective(this, _FlutterImportVisitor(this, context));
  }
}

/// Visitor that detects Flutter framework imports in domain/data layers.
class _FlutterImportVisitor extends SimpleAstVisitor<void> {
  _FlutterImportVisitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue;
    if (uri == null) return;

    // Only check Flutter framework imports
    if (!_isFlutterFrameworkImport(uri)) return;

    // Get the current file's path and layer
    final currentPath = context.libraryElement?.uri.toString() ?? '';

    // Skip test files - they can import flutter_test
    if (isTestFile(currentPath)) return;

    // Get current file's layer
    final currentLayer = getLayerFromPath(currentPath);

    // Only enforce in Domain and Data layers
    if (currentLayer != ArchLayer.domain && currentLayer != ArchLayer.data) {
      return;
    }

    // Report violation
    rule.reportAtNode(node, arguments: [_layerName(currentLayer), uri]);
  }

  /// Checks if URI is a Flutter framework import.
  bool _isFlutterFrameworkImport(String uri) {
    // Flutter framework packages that should not be in domain/data
    final flutterPackages = [
      'package:flutter/material.dart',
      'package:flutter/widgets.dart',
      'package:flutter/cupertino.dart',
      'package:flutter/foundation.dart',
      'package:flutter/rendering.dart',
      'package:flutter/gestures.dart',
      'package:flutter/painting.dart',
      'package:flutter/animation.dart',
      'package:flutter/scheduler.dart',
      'package:flutter/semantics.dart',
      'package:flutter/services.dart',
    ];

    // Check exact matches first
    if (flutterPackages.contains(uri)) return true;

    // Check if it starts with package:flutter/ (catch-all)
    // But allow flutter_test in test files (checked separately)
    if (uri.startsWith('package:flutter/') &&
        !uri.startsWith('package:flutter_test/')) {
      return true;
    }

    return false;
  }

  /// Gets a human-readable layer name.
  String _layerName(ArchLayer layer) {
    switch (layer) {
      case ArchLayer.data:
        return 'Data';
      case ArchLayer.domain:
        return 'Domain';
      case ArchLayer.ui:
        return 'UI';
      case ArchLayer.unknown:
        return 'Unknown';
    }
  }
}
