/// Tests for test file exclusions
///
/// Verifies that files in test directories are exempt from lint rules:
/// - test/ directory
/// - test_driver/ directory
/// - integration_test/ directory
/// - Files ending with _test.dart

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:barrel_file_lints/barrel_file_lints.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TestFileVariationsTest);
  });
}

@reflectiveTest
class TestFileVariationsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidInternalFeatureImports();
    super.setUp();
  }

  Future<void> test_testDriverDirectory() async {
    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/test_driver/auth_integration_test.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/data/auth_service.dart';

void main() {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/test_driver/auth_integration_test.dart',
    );
  }

  Future<void> test_integrationTestDirectory() async {
    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/integration_test/auth_flow_test.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/data/auth_service.dart';

void main() {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/integration_test/auth_flow_test.dart',
    );
  }

  Future<void> test_testSuffixFile() async {
    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/feature_home/ui/home_page_test.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/data/auth_service.dart';

void main() {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_home/ui/home_page_test.dart',
    );
  }

  Future<void> test_regularTestDirectory() async {
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
}
