import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Converts relative barrel imports to package imports.
///
/// Improves code clarity and refactoring safety by using package imports
/// instead of relative paths. For example, converts
/// `import '../../feature_tickets/tickets.dart';` to
/// `import 'package:myapp/feature_tickets/tickets.dart';`.
class ConvertToPackageImport extends ResolvedCorrectionProducer {
  /// Creates a fix instance for the current resolution context.
  ConvertToPackageImport({required super.context});

  static const _fixKind = FixKind(
    'barrel_file_lints.fix.convertToPackageImport',
    50, // Standard priority
    'Convert to package import',
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

    // Only process relative imports
    if (!uri.startsWith('../') && !uri.startsWith('./')) return;

    // Get the current file's URI to extract package name
    final currentUri = unitResult.uri.toString();

    // Extract package name from current file URI
    final packageMatch = RegExp(r'package:([^/]+)/').firstMatch(currentUri);
    if (packageMatch == null) return;

    final packageName = packageMatch.group(1)!;

    // Build package import from relative import
    final packageImport = _convertToPackageImport(uri, packageName);
    if (packageImport == null) return;

    await builder.addDartFileEdit(file, (builder) {
      // Replace the entire import URI string (including quotes)
      final uriNode = node.uri;
      builder.addSimpleReplacement(range.node(uriNode), "'$packageImport'");
    });
  }

  /// Converts relative import to package import.
  ///
  /// For example, converts `'../../feature_tickets/tickets.dart'` to
  /// `'package:myapp/feature_tickets/tickets.dart'`.
  String? _convertToPackageImport(String relativeUri, String packageName) {
    // Remove leading ../ or ./
    var cleanPath = relativeUri;
    while (cleanPath.startsWith('../') || cleanPath.startsWith('./')) {
      cleanPath = cleanPath.replaceFirst(RegExp(r'^\.\./|^\./'), '');
    }

    // Check if it contains a feature pattern
    if (!cleanPath.contains('feature_') && !cleanPath.contains('features/')) {
      return null;
    }

    // Build package import
    return 'package:$packageName/$cleanPath';
  }
}
