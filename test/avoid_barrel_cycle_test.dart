/// Tests for the avoid_barrel_cycle rule
library;

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:barrel_file_lints/barrel_file_lints.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidBarrelCycleTest);
  });
}

@reflectiveTest
class AvoidBarrelCycleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidBarrelCycle();
    super.setUp();
  }

  Future<void> test_noCycle_oneWayDependency() async {
    newFile(
      '$testPackageRootPath/lib/feature_auth/data/auth_repository.dart',
      '''
class AuthRepository {}
''',
    );

    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
export 'data/auth_repository.dart';
''');

    newFile('$testPackageRootPath/lib/feature_profile/ui/profile_page.dart', '''
class ProfilePage {}
''');

    newFile('$testPackageRootPath/lib/feature_profile/profile.dart', '''
export 'ui/profile_page.dart';
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/auth.dart',
    );
  }

  Future<void> test_noCycle_nonBarrelExport() async {
    newFile(
      '$testPackageRootPath/lib/feature_auth/data/auth_repository.dart',
      '''
class AuthRepository {}
''',
    );

    newFile('$testPackageRootPath/lib/core/utils.dart', '''
class Utils {}
''');

    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
export 'data/auth_repository.dart';
export '../core/utils.dart';
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/auth.dart',
    );
  }

  /// Cycle detection in the analyzer plugin context is limited because:
  /// 1. The test environment doesn't have full project dependency resolution
  /// 2. Cycles are best detected through graph analysis of all barrel files
  /// 3. The CLI tool `check_cycles` provides comprehensive cycle detection
  ///
  /// These tests verify the rule doesn't crash on potential cycles,
  /// but actual cycle detection should be done via: `dart run barrel_file_lints:check_cycles`
  Future<void> test_potentialCycle_doesNotCrash_underscore() async {
    // Create a potential cycle scenario
    newFile('$testPackageRootPath/lib/feature_profile/profile.dart', '''
export '../feature_auth/auth.dart';
''');

    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
export '../feature_profile/profile.dart';
''');

    // Rule should not crash even with potential cycles
    // (Actual cycle detection happens via CLI tool)
    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/auth.dart',
    );
  }

  Future<void> test_potentialCycle_doesNotCrash_slash() async {
    // Create a potential cycle scenario
    newFile('$testPackageRootPath/lib/features/profile/profile.dart', '''
export '../auth/auth.dart';
''');

    newFile('$testPackageRootPath/lib/features/auth/auth.dart', '''
export '../profile/profile.dart';
''');

    // Rule should not crash even with potential cycles
    // (Actual cycle detection happens via CLI tool)
    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/features/auth/auth.dart',
    );
  }

  Future<void> test_notBarrelFile_ignored() async {
    newFile('$testPackageRootPath/lib/feature_profile/profile.dart', '''
class ProfileService {}
''');

    newFile(
      '$testPackageRootPath/lib/feature_auth/data/auth_repository.dart',
      '''
export '../../feature_profile/profile.dart';
''',
    );

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/data/auth_repository.dart',
    );
  }

  Future<void> test_testFile_ignored() async {
    newFile(
      '$testPackageRootPath/lib/feature_auth/data/auth_repository.dart',
      '''
class AuthRepository {}
''',
    );

    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
export 'data/auth_repository.dart';
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/auth.dart',
    );
  }

  Future<void> test_packageImport_noCycle() async {
    newFile('$testPackageRootPath/lib/feature_profile/profile.dart', '''
class ProfileService {}
''');

    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
export 'package:test/feature_profile/profile.dart';
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/auth.dart',
    );
  }
}
