/// Quick fix: Remove cross-feature export from barrel file
library;

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// A correction processor that removes cross-feature exports from barrel files.
///
/// This fix handles the `avoid_cross_feature_barrel_exports` lint by removing
/// export directives that reference files outside the barrel's own feature.
class RemoveCrossFeatureExport extends ResolvedCorrectionProducer {
  /// Creates a new instance of [RemoveCrossFeatureExport]
  RemoveCrossFeatureExport({required super.context});

  static const _fixKind = FixKind(
    'barrel_file_lints.fix.removeCrossFeatureExport',
    50, // Standard priority
    'Remove cross-feature export',
  );

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final node = this.node;
    if (node is! ExportDirective) return;

    await builder.addDartFileEdit(file, (builder) {
      // Remove the entire export directive
      builder.addDeletion(range.node(node));
    });
  }
}
