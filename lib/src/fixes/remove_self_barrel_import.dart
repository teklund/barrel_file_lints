import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Removes self-barrel imports from files within a feature.
///
/// Deletes circular imports where a feature imports its own barrel file.
/// Files within a feature should use direct imports instead to avoid
/// circular dependencies.
class RemoveSelfBarrelImport extends ResolvedCorrectionProducer {
  /// Creates a fix instance for the current resolution context.
  RemoveSelfBarrelImport({required super.context});

  static const _fixKind = FixKind(
    'barrel_file_lints.fix.removeSelfBarrelImport',
    50,
    'Remove self-barrel import',
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

    await builder.addDartFileEdit(file, (builder) {
      // Remove the entire import directive including any leading/trailing whitespace
      final nodeToRemove = node;
      final lineInfo = unitResult.lineInfo;

      // Get the line containing this import
      final startLine = lineInfo.getLocation(nodeToRemove.offset).lineNumber;
      final endLine = lineInfo.getLocation(nodeToRemove.end).lineNumber;

      // If it's on a single line, remove the whole line including newline
      if (startLine == endLine) {
        final lineStart = lineInfo.getOffsetOfLine(startLine - 1);
        final nextLineStart = startLine < lineInfo.lineCount
            ? lineInfo.getOffsetOfLine(startLine)
            : nodeToRemove.end;
        builder.addDeletion(
          range.startOffsetEndOffset(lineStart, nextLineStart),
        );
      } else {
        // Multi-line import, just remove the node itself
        builder.addDeletion(range.node(nodeToRemove));
      }
    });
  }
}
