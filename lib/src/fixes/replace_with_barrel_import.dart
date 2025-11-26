/// Quick fix: Replace internal feature import with barrel file import
library;

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

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
