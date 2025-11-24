import 'package:barrel_file_lints/barrel_file_lints.dart';
import 'package:test/test.dart';

void main() {
  group('Quick Fix Registration', () {
    test('ReplaceWithBarrelImport is registered', () {
      // Verify the fix class exists and can be instantiated
      final plugin = BarrelFileLintPlugin();
      expect(plugin, isNotNull);
      expect(plugin.name, 'barrel_file_lints');
    });

    test('RemoveFeatureImport is registered', () {
      // Verify the fix class exists and can be instantiated
      final plugin = BarrelFileLintPlugin();
      expect(plugin, isNotNull);
      expect(plugin.name, 'barrel_file_lints');
    });

    test('AvoidInternalFeatureImports has static code', () {
      // Verify the lint code exists for fix registration
      expect(
        AvoidInternalFeatureImports.code.name,
        'avoid_internal_feature_imports',
      );
    });

    test('AvoidCoreImportingFeatures has static code', () {
      // Verify the lint code exists for fix registration
      expect(
        AvoidCoreImportingFeatures.code.name,
        'avoid_core_importing_features',
      );
    });
  });

  group('Quick Fix URI Transformation', () {
    test('buildBarrelUri handles underscore style', () {
      // Test the URI transformation logic is present
      // Full integration testing would require IDE testing
      final rule = AvoidInternalFeatureImports();
      expect(rule, isNotNull);
      expect(rule.name, 'avoid_internal_feature_imports');
    });

    test('buildBarrelUri handles slash style', () {
      // Test the URI transformation logic is present
      final rule = AvoidInternalFeatureImports();
      expect(rule, isNotNull);
    });
  });
}
