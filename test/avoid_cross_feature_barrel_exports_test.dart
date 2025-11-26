/// Tests for avoid_cross_feature_barrel_exports rule
///
/// Test organization:
/// - Valid cases: Barrel files exporting from their own feature
/// - Invalid cases: Barrel files exporting from other features/directories
/// - Edge cases: Complex paths, mixed styles, multiple violations
library;

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:barrel_file_lints/barrel_file_lints.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidCrossFeatureBarrelExportsTest);
  });
}

@reflectiveTest
class AvoidCrossFeatureBarrelExportsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidCrossFeatureBarrelExports();
    super.setUp();
  }

  // ==========================================================================
  // Valid cases - no diagnostics expected
  // ==========================================================================

  Future<void>
  test_barrelFileExportsFromOwnFeatureSubdirectories_underscore() async {
    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/feature_auth/ui/login_page.dart', '''
class LoginPage {}
''');

    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
export 'data/auth_service.dart';
export 'ui/login_page.dart';
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/auth.dart',
    );
  }

  Future<void>
  test_barrelFileExportsFromOwnFeatureSubdirectories_slash() async {
    newFile('$testPackageRootPath/lib/features/auth/domain/auth_user.dart', '''
class AuthUser {}
''');

    newFile(
      '$testPackageRootPath/lib/features/auth/presentation/login_page.dart',
      '''
class LoginPage {}
''',
    );

    newFile('$testPackageRootPath/lib/features/auth/auth.dart', '''
export 'domain/auth_user.dart';
export 'presentation/login_page.dart';
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/features/auth/auth.dart',
    );
  }

  Future<void> test_nonBarrelFileCanExportAnything() async {
    newFile('$testPackageRootPath/lib/common/widgets.dart', '''
class CommonWidget {}
''');

    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
export '../../common/widgets.dart';
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/data/auth_service.dart',
    );
  }

  Future<void> test_barrelFileWithDotSlashRelativePaths() async {
    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
export './data/auth_service.dart';
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/auth.dart',
    );
  }

  Future<void> test_barrelFileWithAbsolutePackageImportFromSameFeature() async {
    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
export 'package:test/feature_auth/data/auth_service.dart';
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/auth.dart',
    );
  }

  Future<void> test_fileNotInFeature() async {
    newFile('$testPackageRootPath/lib/core/utils.dart', '''
class Utils {}
''');

    newFile('$testPackageRootPath/lib/common/common.dart', '''
export '../core/utils.dart';
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/common/common.dart',
    );
  }

  // ==========================================================================
  // Invalid cases - diagnostics expected
  // ==========================================================================

  Future<void> test_barrelExportsFromParentDirectory_underscore() async {
    newFile('$testPackageRootPath/lib/common/widgets.dart', '''
class CommonWidget {}
''');

    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
export 'data/auth_service.dart';
export '../common/widgets.dart';
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/auth.dart',
      [lint(33, 32)],
    );
  }

  Future<void> test_barrelExportsFromDifferentFeature_underscore() async {
    newFile('$testPackageRootPath/lib/feature_users/data/user.dart', '''
class User {}
''');

    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
export 'data/auth_service.dart';
export '../feature_users/data/user.dart';
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/auth.dart',
      [lint(33, 41)],
    );
  }

  Future<void> test_barrelExportsFromDifferentFeature_slash() async {
    newFile('$testPackageRootPath/lib/features/users/domain/user.dart', '''
class User {}
''');

    newFile('$testPackageRootPath/lib/features/auth/domain/auth_user.dart', '''
class AuthUser {}
''');

    newFile('$testPackageRootPath/lib/features/auth/auth.dart', '''
export 'domain/auth_user.dart';
export '../users/domain/user.dart';
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/features/auth/auth.dart',
      [lint(32, 35)],
    );
  }

  Future<void>
  test_barrelExportsFromDifferentFeatureAbsoluteImport_underscore() async {
    newFile('$testPackageRootPath/lib/feature_users/data/user.dart', '''
class User {}
''');

    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
export 'data/auth_service.dart';
export 'package:test/feature_users/data/user.dart';
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/auth.dart',
      [lint(33, 51)],
    );
  }

  Future<void>
  test_barrelExportsFromDifferentFeatureAbsoluteImport_slash() async {
    newFile('$testPackageRootPath/lib/features/users/domain/user.dart', '''
class User {}
''');

    newFile('$testPackageRootPath/lib/features/auth/domain/auth_user.dart', '''
class AuthUser {}
''');

    newFile('$testPackageRootPath/lib/features/auth/auth.dart', '''
export 'domain/auth_user.dart';
export 'package:test/features/users/domain/user.dart';
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/features/auth/auth.dart',
      [lint(32, 54)],
    );
  }

  Future<void> test_barrelExportsFromCore() async {
    newFile('$testPackageRootPath/lib/core/utils.dart', '''
class Utils {}
''');

    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
export 'data/auth_service.dart';
export '../core/utils.dart';
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/auth.dart',
      [lint(33, 28)],
    );
  }

  Future<void> test_multipleViolationsInSameBarrel() async {
    newFile('$testPackageRootPath/lib/common/widgets.dart', '''
class CommonWidget {}
''');

    newFile('$testPackageRootPath/lib/core/constants.dart', '''
const appName = 'MyApp';
''');

    newFile('$testPackageRootPath/lib/feature_users/data/user.dart', '''
class User {}
''');

    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
export 'data/auth_service.dart';
export '../feature_users/data/user.dart';
export '../common/widgets.dart';
export '../core/constants.dart';
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/auth.dart',
      [lint(33, 41), lint(75, 32), lint(108, 32)],
    );
  }

  Future<void> test_barrelExportsWithComplexRelativePath() async {
    newFile('$testPackageRootPath/lib/core/utils.dart', '''
class Utils {}
''');

    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
export 'data/auth_service.dart';
export '../core/utils.dart';
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/auth.dart',
      [lint(33, 28)],
    );
  }

  Future<void> test_crossStyleFeatureExport() async {
    newFile('$testPackageRootPath/lib/features/users/domain/user.dart', '''
class User {}
''');

    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
export 'data/auth_service.dart';
export 'package:test/features/users/domain/user.dart';
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/auth.dart',
      [lint(33, 54)],
    );
  }
}
