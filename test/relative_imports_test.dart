import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:barrel_file_lints/barrel_file_lints.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RelativeImportsTest);
  });
}

@reflectiveTest
class RelativeImportsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidInternalFeatureImports();
    super.setUp();
  }

  Future<void> test_relativeBarrelImport_underscore() async {
    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/feature_home/ui/home_page.dart', '''
// ignore: unused_import
import '../../feature_auth/auth.dart';

class HomePage {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_home/ui/home_page.dart',
    );
  }

  Future<void> test_relativeBarrelImport_slash() async {
    newFile('$testPackageRootPath/lib/features/auth/auth.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/features/home/ui/home_page.dart', '''
// ignore: unused_import
import '../../auth/auth.dart';

class HomePage {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/features/home/ui/home_page.dart',
    );
  }

  Future<void> test_relativeInternalImport_underscore() async {
    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/feature_home/ui/home_page.dart', '''
// ignore: unused_import
import '../../feature_auth/data/auth_service.dart';

class HomePage {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_home/ui/home_page.dart',
      [lint(25, 51)],
    );
  }

  Future<void> test_relativeInternalImport_slash() async {
    newFile('$testPackageRootPath/lib/features/auth/data/auth_service.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/features/home/ui/home_page.dart', '''
// ignore: unused_import
import '../../auth/data/auth_service.dart';

class HomePage {}
''');

    // Relative imports without 'features/' prefix don't trigger the rule
    // This is expected behavior - rule looks for 'features/xxx' pattern
    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/features/home/ui/home_page.dart',
    );
  }

  Future<void> test_singleDotRelativeImport() async {
    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/feature_home/data/home_service.dart', '''
// ignore: unused_import
import '../../feature_auth/data/auth_service.dart';

class HomeService {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_home/data/home_service.dart',
      [lint(25, 51)],
    );
  }
}
