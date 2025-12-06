/// Tests for avoid_relative_barrel_imports rule
///
/// Test organization:
/// - Valid cases: Package imports, same-feature relative imports, internal imports
/// - Invalid cases: Relative imports to barrel files from other features
/// - Coverage: Both naming conventions (feature_xxx/ and features/xxx/)

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:barrel_file_lints/barrel_file_lints.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidRelativeBarrelImportsTest);
  });
}

@reflectiveTest
class AvoidRelativeBarrelImportsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidRelativeBarrelImports();
    super.setUp();
  }

  Future<void> test_packageImportToBarrel_noDiagnostic() async {
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

  Future<void> test_relativeBarrelImport_underscore_diagnostic() async {
    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/feature_home/ui/home_page.dart', '''
// ignore: unused_import
import '../../feature_auth/auth.dart';

class HomePage {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_home/ui/home_page.dart',
      [lint(25, 38)],
    );
  }

  Future<void> test_relativeBarrelImport_slash_diagnostic() async {
    newFile('$testPackageRootPath/lib/features/auth/auth.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/features/home/ui/home_page.dart', '''
// ignore: unused_import
import '../../../features/auth/auth.dart';

class HomePage {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/features/home/ui/home_page.dart',
      [lint(25, 42)],
    );
  }

  Future<void> test_relativeSplitBarrelImport_data_diagnostic() async {
    newFile('$testPackageRootPath/lib/feature_auth/auth_data.dart', '''
class AuthRepository {}
''');

    newFile(
      '$testPackageRootPath/lib/feature_home/data/home_repository.dart',
      '''
// ignore: unused_import
import '../../feature_auth/auth_data.dart';

class HomeRepository {}
''',
    );

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_home/data/home_repository.dart',
      [lint(25, 43)],
    );
  }

  Future<void> test_relativeSplitBarrelImport_domain_diagnostic() async {
    newFile('$testPackageRootPath/lib/features/auth/auth_domain.dart', '''
class AuthUseCase {}
''');

    newFile(
      '$testPackageRootPath/lib/features/home/domain/home_use_case.dart',
      '''
// ignore: unused_import
import '../../../features/auth/auth_domain.dart';

class HomeUseCase {}
''',
    );

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/features/home/domain/home_use_case.dart',
      [lint(25, 49)],
    );
  }

  Future<void> test_relativeSplitBarrelImport_ui_diagnostic() async {
    newFile('$testPackageRootPath/lib/feature_auth/auth_ui.dart', '''
class LoginScreen {}
''');

    newFile('$testPackageRootPath/lib/feature_home/ui/home_page.dart', '''
// ignore: unused_import
import '../../feature_auth/auth_ui.dart';

class HomePage {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_home/ui/home_page.dart',
      [lint(25, 41)],
    );
  }

  Future<void> test_relativeInternalImport_notBarrel_noDiagnostic() async {
    // Relative imports to internal files are not flagged by this rule
    // (they're handled by avoid_internal_feature_imports)
    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/feature_home/ui/home_page.dart', '''
// ignore: unused_import
import '../../feature_auth/data/auth_service.dart';

class HomePage {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_home/ui/home_page.dart',
    );
  }

  Future<void> test_sameFeatureRelativeImport_noDiagnostic() async {
    // Relative imports within the same feature are allowed
    newFile(
      '$testPackageRootPath/lib/feature_auth/data/auth_repository.dart',
      '''
class AuthRepository {}
''',
    );

    newFile('$testPackageRootPath/lib/feature_auth/ui/login_page.dart', '''
// ignore: unused_import
import '../data/auth_repository.dart';

class LoginPage {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/ui/login_page.dart',
    );
  }

  Future<void> test_testFileRelativeImport_noDiagnostic() async {
    // Test files can use relative imports
    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/test/feature_home_test.dart', '''
// ignore: unused_import
import '../lib/feature_auth/auth.dart';

void main() {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/test/feature_home_test.dart',
    );
  }

  Future<void> test_deepRelativePath_diagnostic() async {
    // Even deeper relative paths should be flagged
    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
class AuthService {}
''');

    newFile(
      '$testPackageRootPath/lib/feature_home/ui/screens/home_screen.dart',
      '''
// ignore: unused_import
import '../../../feature_auth/auth.dart';

class HomeScreen {}
''',
    );

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_home/ui/screens/home_screen.dart',
      [lint(25, 41)],
    );
  }

  Future<void> test_singleDotRelativePath_diagnostic() async {
    // Single dot relative paths should also be checked
    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/feature_home/home.dart', '''
// ignore: unused_import
import '../feature_auth/auth.dart';

class Home {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_home/home.dart',
      [lint(25, 35)],
    );
  }

  Future<void> test_nonFeatureRelativeImport_noDiagnostic() async {
    // Relative imports to non-feature files are not flagged
    newFile('$testPackageRootPath/lib/common/widgets.dart', '''
class CommonWidget {}
''');

    newFile('$testPackageRootPath/lib/feature_home/ui/home_page.dart', '''
// ignore: unused_import
import '../../common/widgets.dart';

class HomePage {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_home/ui/home_page.dart',
    );
  }
}
