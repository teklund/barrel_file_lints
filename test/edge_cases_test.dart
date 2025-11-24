import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:barrel_file_lints/barrel_file_lints.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EdgeCasesTest);
  });
}

@reflectiveTest
class EdgeCasesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidInternalFeatureImports();
    super.setUp();
  }

  Future<void> test_deeplyNestedInternalPath() async {
    newFile(
      '$testPackageRootPath/lib/feature_auth/data/models/dto/user_dto.dart',
      '''
class UserDto {}
''',
    );

    newFile('$testPackageRootPath/lib/feature_home/ui/home_page.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/data/models/dto/user_dto.dart';

class HomePage {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_home/ui/home_page.dart',
      [lint(25, 65)],
    );
  }

  Future<void> test_sameFeatureDeeplyNested() async {
    newFile(
      '$testPackageRootPath/lib/feature_auth/data/local/cache/user_cache.dart',
      '''
class UserCache {}
''',
    );

    newFile('$testPackageRootPath/lib/feature_auth/ui/login_page.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/data/local/cache/user_cache.dart';

class LoginPage {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/ui/login_page.dart',
    );
  }

  Future<void> test_mixedConventions_underscoreImportsSlash() async {
    newFile('$testPackageRootPath/lib/features/auth/data/auth_service.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/feature_home/ui/home_page.dart', '''
// ignore: unused_import
import 'package:test/features/auth/data/auth_service.dart';

class HomePage {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_home/ui/home_page.dart',
      [lint(25, 59)],
    );
  }

  Future<void> test_mixedConventions_slashImportsUnderscore() async {
    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/features/home/ui/home_page.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/data/auth_service.dart';

class HomePage {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/features/home/ui/home_page.dart',
      [lint(25, 58)],
    );
  }

  Future<void> test_nonFeatureDirectory() async {
    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/utils/helper.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/data/auth_service.dart';

class Helper {}
''');

    // Files outside feature directories still trigger the rule
    // since they're importing feature internals
    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/utils/helper.dart',
      [lint(25, 58)],
    );
  }

  Future<void> test_commonDirectory() async {
    newFile('$testPackageRootPath/lib/common/widgets/button.dart', '''
class Button {}
''');

    newFile('$testPackageRootPath/lib/feature_home/ui/home_page.dart', '''
// ignore: unused_import
import 'package:test/common/widgets/button.dart';

class HomePage {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_home/ui/home_page.dart',
    );
  }

  Future<void> test_coreDirectory() async {
    newFile('$testPackageRootPath/lib/core/network/api_client.dart', '''
class ApiClient {}
''');

    newFile('$testPackageRootPath/lib/feature_home/ui/home_page.dart', '''
// ignore: unused_import
import 'package:test/core/network/api_client.dart';

class HomePage {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_home/ui/home_page.dart',
    );
  }
}
