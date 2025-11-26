/// Tests for avoid_internal_feature_imports rule
///
/// Test organization:
/// - Valid cases: Barrel file imports and same-feature imports
/// - Invalid cases: Cross-feature internal imports (data/, ui/, domain/, etc.)
/// - Coverage: Both naming conventions (feature_xxx and features/xxx)
library;

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:barrel_file_lints/barrel_file_lints.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidInternalFeatureImportsTest);
  });
}

@reflectiveTest
class AvoidInternalFeatureImportsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidInternalFeatureImports();
    super.setUp();
  }

  // ==========================================================================
  // Valid cases - no diagnostics expected (only unused import warnings)
  // ==========================================================================

  Future<void> test_barrelFileImport_underscore() async {
    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/feature_home/ui/home_page.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/auth.dart';

class HomePage {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_home/ui/home_page.dart',
    );
  }

  Future<void> test_barrelFileImport_slash() async {
    newFile('$testPackageRootPath/lib/features/auth/auth.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/features/home/ui/home_page.dart', '''
// ignore: unused_import
import 'package:test/features/auth/auth.dart';

class HomePage {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/features/home/ui/home_page.dart',
    );
  }

  Future<void> test_sameFeatureInternalImport() async {
    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/feature_auth/ui/login_page.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/data/auth_service.dart';

class LoginPage {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/ui/login_page.dart',
    );
  }

  Future<void> test_testFileAllowed() async {
    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/test/feature_auth/auth_service_test.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/data/auth_service.dart';

void main() {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/test/feature_auth/auth_service_test.dart',
    );
  }

  // ==========================================================================
  // Invalid cases - diagnostics expected
  // ==========================================================================

  Future<void> test_internalDataImport_underscore() async {
    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/feature_home/ui/home_page.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/data/auth_service.dart';

class HomePage {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_home/ui/home_page.dart',
      [lint(25, 58)],
    );
  }

  Future<void> test_internalUiImport_underscore() async {
    newFile('$testPackageRootPath/lib/feature_auth/ui/login_page.dart', '''
class LoginPage {}
''');

    newFile('$testPackageRootPath/lib/feature_home/ui/home_page.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/ui/login_page.dart';

class HomePage {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_home/ui/home_page.dart',
      [lint(25, 54)],
    );
  }

  Future<void> test_internalModelsImport() async {
    newFile('$testPackageRootPath/lib/feature_auth/models/user.dart', '''
class User {}
''');

    newFile('$testPackageRootPath/lib/feature_home/ui/home_page.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/models/user.dart';

class HomePage {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_home/ui/home_page.dart',
      [lint(25, 52)],
    );
  }

  Future<void> test_internalImport_slash() async {
    newFile('$testPackageRootPath/lib/features/auth/data/auth_service.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/features/home/ui/home_page.dart', '''
// ignore: unused_import
import 'package:test/features/auth/data/auth_service.dart';

class HomePage {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/features/home/ui/home_page.dart',
      [lint(25, 59)],
    );
  }

  Future<void> test_internalDomainImport() async {
    newFile(
      '$testPackageRootPath/lib/features/auth/domain/user_entity.dart',
      '''
class UserEntity {}
''',
    );

    newFile('$testPackageRootPath/lib/features/home/ui/home_page.dart', '''
// ignore: unused_import
import 'package:test/features/auth/domain/user_entity.dart';

class HomePage {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/features/home/ui/home_page.dart',
      [lint(25, 60)],
    );
  }

  Future<void> test_internalPresentationImport() async {
    newFile(
      '$testPackageRootPath/lib/features/auth/presentation/login_page.dart',
      '''
class LoginPage {}
''',
    );

    newFile('$testPackageRootPath/lib/features/home/ui/home_page.dart', '''
// ignore: unused_import
import 'package:test/features/auth/presentation/login_page.dart';

class HomePage {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/features/home/ui/home_page.dart',
      [lint(25, 65)],
    );
  }
}
