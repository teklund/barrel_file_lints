/// Tests for avoid_core_importing_features rule
///
/// Test organization:
/// - Valid cases: Core imports non-feature modules, features import core
/// - Invalid cases: Core imports feature modules (violates dependency direction)
/// - Coverage: Both naming conventions (feature_xxx and features/xxx)

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:barrel_file_lints/barrel_file_lints.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidCoreImportingFeaturesTest);
  });
}

@reflectiveTest
class AvoidCoreImportingFeaturesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidCoreImportingFeatures();
    super.setUp();
  }

  // ==========================================================================
  // Valid cases - no diagnostics expected
  // ==========================================================================

  Future<void> test_coreImportsCommon() async {
    newFile('$testPackageRootPath/lib/common/utils.dart', '''
class Utils {}
''');

    newFile('$testPackageRootPath/lib/core/network/api_client.dart', '''
// ignore: unused_import
import 'package:test/common/utils.dart';

class ApiClient {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/core/network/api_client.dart',
    );
  }

  Future<void> test_coreImportsCoreInternal() async {
    newFile('$testPackageRootPath/lib/core/utils/logger.dart', '''
class Logger {}
''');

    newFile('$testPackageRootPath/lib/core/network/api_client.dart', '''
// ignore: unused_import
import 'package:test/core/utils/logger.dart';

class ApiClient {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/core/network/api_client.dart',
    );
  }

  Future<void> test_featureImportsFeature() async {
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

  Future<void> test_featureImportsCore() async {
    newFile('$testPackageRootPath/lib/core/network/api_client.dart', '''
class ApiClient {}
''');

    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
// ignore: unused_import
import 'package:test/core/network/api_client.dart';

class AuthService {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/data/auth_service.dart',
    );
  }

  Future<void> test_nonCoreFile() async {
    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/utils/helper.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/auth.dart';

class Helper {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/utils/helper.dart',
    );
  }

  // ==========================================================================
  // Invalid cases - diagnostics expected
  // ==========================================================================

  Future<void> test_coreImportsFeature_underscore() async {
    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/core/network/api_client.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/auth.dart';

class ApiClient {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/core/network/api_client.dart',
      [lint(25, 45)],
    );
  }

  Future<void> test_coreImportsFeature_slash() async {
    newFile('$testPackageRootPath/lib/features/auth/auth.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/core/network/api_client.dart', '''
// ignore: unused_import
import 'package:test/features/auth/auth.dart';

class ApiClient {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/core/network/api_client.dart',
      [lint(25, 46)],
    );
  }

  Future<void> test_coreImportsFeatureInternal() async {
    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/core/network/api_client.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/data/auth_service.dart';

class ApiClient {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/core/network/api_client.dart',
      [lint(25, 58)],
    );
  }

  Future<void> test_coreImportsMultipleFeatures() async {
    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/feature_home/home.dart', '''
class HomeService {}
''');

    newFile('$testPackageRootPath/lib/core/network/api_client.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/auth.dart';
// ignore: unused_import
import 'package:test/feature_home/home.dart';

class ApiClient {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/core/network/api_client.dart',
      [lint(25, 45), lint(96, 45)],
    );
  }

  Future<void> test_deepCoreImportsFeature() async {
    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
class AuthService {}
''');

    newFile(
      '$testPackageRootPath/lib/core/services/auth/token_manager.dart',
      '''
// ignore: unused_import
import 'package:test/feature_auth/auth.dart';

class TokenManager {}
''',
    );

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/core/services/auth/token_manager.dart',
      [lint(25, 45)],
    );
  }
}
