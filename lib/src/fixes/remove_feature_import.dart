import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Comments out feature imports from core with a TODO marker.
///
/// Converts illegal feature imports into commented code with a refactoring
/// reminder. The import is preserved as a comment to indicate that this
/// dependency needs to be moved out of the core module.
class RemoveFeatureImport extends ResolvedCorrectionProducer {
  /// Creates a fix instance for the current resolution context.
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
