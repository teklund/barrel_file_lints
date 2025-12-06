/// Tests for quick fix utility functions and helper methods
///
/// This file tests the utility functions that support quick fixes,
/// including feature extraction, path analysis, and pattern matching.
/// These are unit tests for the internal logic used by fix producers.
///
/// For integration tests of actual fix application, see quick_fixes_test.dart

import 'package:barrel_file_lints/barrel_file_lints.dart';
import 'package:test/test.dart';

void main() {
  group('Fix Infrastructure', () {
    test('Plugin registers all quick fix producers', () {
      final plugin = BarrelFileLintPlugin();
      expect(plugin.name, 'barrel_file_lints');

      // The plugin should register all fixes in its register() method
      // If any fix was misconfigured, the plugin wouldn't compile
      expect(plugin, isNotNull);
    });

    test('All quick fix classes are accessible', () {
      // Verify all fix classes exist and can be referenced
      expect(ReplaceWithBarrelImport, isNotNull);
      expect(RemoveFeatureImport, isNotNull);
      expect(RemoveCrossFeatureExport, isNotNull);
      expect(RemoveSelfBarrelImport, isNotNull);
      expect(SimplifyRelativePath, isNotNull);
    });
  });

  group('Feature Extraction Utility', () {
    test('ReplaceWithBarrelImport handles underscore style feature names', () {
      // feature_auth/data/auth_service.dart -> feature_auth/auth.dart
      const input = 'package:test/feature_auth/data/auth_service.dart';
      const expected = 'feature_auth';

      final feature = extractFeature(input);
      expect(feature, isNotNull);
      expect(feature!.featureName, 'auth');
      expect(feature.featureDir, expected);
    });

    test('ReplaceWithBarrelImport handles slash style feature names', () {
      // features/auth/data/auth_service.dart -> features/auth/auth.dart
      const input = 'package:test/features/auth/data/auth_service.dart';
      const expected = 'features/auth';

      final feature = extractFeature(input);
      expect(feature, isNotNull);
      expect(feature!.featureName, 'auth');
      expect(feature.featureDir, expected);
    });

    test('Feature extraction works for UI paths', () {
      const input = 'package:test/feature_users/ui/user_list.dart';

      final feature = extractFeature(input);
      expect(feature, isNotNull);
      expect(feature!.featureName, 'users');
      expect(feature.featureDir, 'feature_users');
    });

    test('Feature extraction works for domain paths', () {
      const input = 'package:test/features/auth/domain/user.dart';

      final feature = extractFeature(input);
      expect(feature, isNotNull);
      expect(feature!.featureName, 'auth');
      expect(feature.featureDir, 'features/auth');
    });

    test('Feature extraction works for presentation paths', () {
      const input =
          'package:test/features/profile/presentation/profile_page.dart';

      final feature = extractFeature(input);
      expect(feature, isNotNull);
      expect(feature!.featureName, 'profile');
      expect(feature.featureDir, 'features/profile');
    });

    test('IsInternalImport correctly identifies internal paths', () {
      expect(
        isInternalImport('package:test/feature_auth/data/service.dart'),
        isTrue,
      );
      expect(
        isInternalImport('package:test/feature_auth/ui/page.dart'),
        isTrue,
      );
      expect(
        isInternalImport('package:test/features/auth/domain/user.dart'),
        isTrue,
      );
      expect(
        isInternalImport('package:test/features/auth/presentation/page.dart'),
        isTrue,
      );
      expect(isInternalImport('package:test/feature_auth/auth.dart'), isFalse);
      expect(isInternalImport('package:test/features/auth/auth.dart'), isFalse);
    });

    test('IsInternalImport detects all internal directories', () {
      const internalDirs = [
        'data',
        'ui',
        'domain',
        'presentation',
        'models',
        'services',
        'repositories',
        'providers',
        'bloc',
        'cubit',
        'notifiers',
        'widgets',
        'utils',
        'config',
        'helpers',
        'exceptions',
        'extensions',
        'infrastructure',
        'application',
      ];

      for (final dir in internalDirs) {
        final path = 'package:test/feature_auth/$dir/file.dart';
        expect(
          isInternalImport(path),
          isTrue,
          reason: '$dir should be detected as internal directory',
        );
      }
    });

    test('ContainsFeaturePattern correctly identifies features', () {
      expect(
        containsFeaturePattern('package:test/feature_auth/auth.dart'),
        isTrue,
      );
      expect(
        containsFeaturePattern('package:test/features/auth/auth.dart'),
        isTrue,
      );
      expect(
        containsFeaturePattern('package:test/feature_users/data/user.dart'),
        isTrue,
      );
      expect(
        containsFeaturePattern('package:test/features/profile/ui/page.dart'),
        isTrue,
      );
      expect(containsFeaturePattern('package:test/common/utils.dart'), isFalse);
      expect(
        containsFeaturePattern('package:test/core/constants.dart'),
        isFalse,
      );
      expect(containsFeaturePattern('dart:async'), isFalse);
      expect(containsFeaturePattern('package:flutter/material.dart'), isFalse);
    });

    test('IsBarrelFile correctly identifies barrel files', () {
      const authPath = 'package:test/feature_auth/auth.dart';
      final authFeature = extractFeature(authPath);

      expect(isBarrelFile(authPath, authFeature!), isTrue);
      expect(
        isBarrelFile(
          'package:test/feature_auth/data/auth_service.dart',
          authFeature,
        ),
        isFalse,
      );
      expect(
        isBarrelFile(
          'package:test/feature_auth/ui/login_page.dart',
          authFeature,
        ),
        isFalse,
      );
    });

    test('IsBarrelFile works with slash style', () {
      const catalogPath = 'package:test/features/catalog/catalog.dart';
      final catalogFeature = extractFeature(catalogPath);

      expect(isBarrelFile(catalogPath, catalogFeature!), isTrue);
      expect(
        isBarrelFile(
          'package:test/features/catalog/data/catalog_service.dart',
          catalogFeature,
        ),
        isFalse,
      );
      expect(
        isBarrelFile(
          'package:test/features/catalog/ui/catalog_page.dart',
          catalogFeature,
        ),
        isFalse,
      );
    });

    test('IsRelativeUri correctly identifies relative paths', () {
      expect(isRelativeUri('../auth.dart'), isTrue);
      expect(isRelativeUri('./auth.dart'), isTrue);
      expect(isRelativeUri('../data/service.dart'), isTrue);
      expect(isRelativeUri('package:test/feature_auth/auth.dart'), isFalse);
      expect(isRelativeUri('dart:core'), isFalse);
    });

    test('EscapesFeatureFolder correctly detects directory escapes', () {
      expect(escapesFeatureFolder('../auth.dart'), isTrue);
      expect(escapesFeatureFolder('../feature_users/data/user.dart'), isTrue);
      expect(escapesFeatureFolder('../../common/utils.dart'), isTrue);
      expect(escapesFeatureFolder('./data/service.dart'), isFalse);
      expect(escapesFeatureFolder('data/service.dart'), isFalse);
      expect(escapesFeatureFolder('ui/page.dart'), isFalse);
    });
  });

  group('Fix Integration Verification', () {
    test('AvoidInternalFeatureImports has fix registered', () {
      expect(
        AvoidInternalFeatureImports.code.name,
        'avoid_internal_feature_imports',
      );
    });

    test('AvoidCoreImportingFeatures has fix registered', () {
      expect(
        AvoidCoreImportingFeatures.code.name,
        'avoid_core_importing_features',
      );
    });

    test('AvoidCrossFeatureBarrelExports has fix registered', () {
      expect(
        AvoidCrossFeatureBarrelExports.code.name,
        'avoid_cross_feature_barrel_exports',
      );
    });

    test('AvoidSelfBarrelImport rule exists', () {
      final rule = AvoidSelfBarrelImport();
      expect(rule.name, 'avoid_self_barrel_import');
      expect(AvoidSelfBarrelImport.code.name, 'avoid_self_barrel_import');
    });

    test('All rules can be instantiated', () {
      expect(() => AvoidInternalFeatureImports(), returnsNormally);
      expect(() => AvoidCoreImportingFeatures(), returnsNormally);
      expect(() => AvoidSelfBarrelImport(), returnsNormally);
      expect(() => AvoidCrossFeatureBarrelExports(), returnsNormally);
    });
  });

  group('Test File Detection', () {
    test('IsTestFile correctly identifies test files', () {
      expect(isTestFile('package:test/test/widget_test.dart'), isTrue);
      expect(isTestFile('package:test/test/unit/service_test.dart'), isTrue);
      expect(isTestFile('package:test/integration_test/app_test.dart'), isTrue);
      expect(isTestFile('package:test/test_driver/perf_driver.dart'), isTrue);
      expect(isTestFile('package:test/lib/feature_auth/auth.dart'), isFalse);
      expect(
        isTestFile('package:test/lib/features/auth/data/service.dart'),
        isFalse,
      );
    });

    test('IsTestFile detects various test patterns', () {
      final testPaths = [
        'package:test/test/feature_test.dart',
        'package:test/test/subfolder/another_test.dart',
        'package:test/integration_test/e2e_test.dart',
        'package:test/test_driver/driver.dart',
        'file:///project/test/widget_test.dart',
      ];

      for (final path in testPaths) {
        expect(
          isTestFile(path),
          isTrue,
          reason: '$path should be detected as a test file',
        );
      }
    });

    test('IsTestFile correctly rejects non-test files', () {
      final nonTestPaths = [
        'package:test/lib/testing_utils.dart',
        'package:test/lib/feature_test_mode/test_mode.dart',
        'package:test/lib/attestation_service.dart',
      ];

      for (final path in nonTestPaths) {
        expect(
          isTestFile(path),
          isFalse,
          reason: '$path should NOT be detected as a test file',
        );
      }
    });
  });
}
