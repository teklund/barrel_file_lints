/// Barrel file lints for enforcing feature-based architecture patterns
library;

import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:barrel_file_lints/src/fixes/convert_to_package_import.dart';
import 'package:barrel_file_lints/src/fixes/remove_cross_feature_export.dart';
import 'package:barrel_file_lints/src/fixes/remove_feature_import.dart';
import 'package:barrel_file_lints/src/fixes/remove_self_barrel_import.dart';
import 'package:barrel_file_lints/src/fixes/replace_with_barrel_import.dart';
import 'package:barrel_file_lints/src/fixes/simplify_relative_path.dart';
import 'package:barrel_file_lints/src/fixes/use_layer_specific_barrel.dart';
import 'package:barrel_file_lints/src/rules/avoid_core_importing_features.dart';
import 'package:barrel_file_lints/src/rules/avoid_cross_feature_barrel_exports.dart';
import 'package:barrel_file_lints/src/rules/avoid_improper_layer_import.dart';
import 'package:barrel_file_lints/src/rules/avoid_internal_feature_imports.dart';
import 'package:barrel_file_lints/src/rules/avoid_relative_barrel_imports.dart';
import 'package:barrel_file_lints/src/rules/avoid_self_barrel_import.dart';
import 'package:barrel_file_lints/src/rules/avoid_ui_framework_in_logic.dart';

export 'src/fixes/convert_to_package_import.dart';
export 'src/fixes/remove_cross_feature_export.dart';
export 'src/fixes/remove_feature_import.dart';
export 'src/fixes/remove_self_barrel_import.dart';
export 'src/fixes/replace_with_barrel_import.dart';
export 'src/fixes/simplify_relative_path.dart';
export 'src/fixes/use_layer_specific_barrel.dart';
export 'src/rules/avoid_core_importing_features.dart';
export 'src/rules/avoid_cross_feature_barrel_exports.dart';
export 'src/rules/avoid_improper_layer_import.dart';
export 'src/rules/avoid_internal_feature_imports.dart';
export 'src/rules/avoid_relative_barrel_imports.dart';
export 'src/rules/avoid_self_barrel_import.dart';
export 'src/rules/avoid_ui_framework_in_logic.dart';
export 'src/utils/feature_pattern_utils.dart';

/// Plugin for enforcing barrel file import rules between features
class BarrelFileLintPlugin extends Plugin {
  @override
  String get name => 'barrel_file_lints';

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerLintRule(AvoidInternalFeatureImports())
      ..registerLintRule(AvoidCoreImportingFeatures())
      ..registerLintRule(AvoidSelfBarrelImport())
      ..registerLintRule(AvoidCrossFeatureBarrelExports())
      ..registerLintRule(AvoidImproperLayerImport())
      ..registerLintRule(AvoidUiFrameworkInLogic())
      ..registerLintRule(AvoidRelativeBarrelImports())
      // Register quick fixes
      ..registerFixForRule(
        AvoidInternalFeatureImports.code,
        ReplaceWithBarrelImport.new,
      )
      ..registerFixForRule(
        AvoidCoreImportingFeatures.code,
        RemoveFeatureImport.new,
      )
      ..registerFixForRule(
        AvoidCrossFeatureBarrelExports.code,
        RemoveCrossFeatureExport.new,
      )
      ..registerFixForRule(
        AvoidSelfBarrelImport.code,
        RemoveSelfBarrelImport.new,
      )
      ..registerFixForRule(AvoidSelfBarrelImport.code, SimplifyRelativePath.new)
      ..registerFixForRule(
        AvoidImproperLayerImport.code,
        UseLayerSpecificBarrel.new,
      )
      ..registerFixForRule(
        AvoidRelativeBarrelImports.code,
        ConvertToPackageImport.new,
      );
  }
}
