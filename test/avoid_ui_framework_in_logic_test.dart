/// Tests for avoid_ui_framework_in_logic rule
///
/// Test organization:
/// - Domain layer violations: Flutter imports not allowed
/// - Data layer violations: Flutter imports not allowed
/// - UI/Presentation layer: Flutter imports allowed
/// - Test files: flutter_test imports allowed
/// - Coverage: Both naming conventions (feature_xxx and features/xxx)
///
/// Note: Uses `// ignore: uri_does_not_exist` to suppress analyzer errors
/// for Flutter packages that don't exist in test environment. This keeps
/// tests focused on our lint rule's behavior, not the analyzer's built-in checks.

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:barrel_file_lints/barrel_file_lints.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidUiFrameworkInLogicTest);
  });
}

@reflectiveTest
class AvoidUiFrameworkInLogicTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUiFrameworkInLogic();
    super.setUp();
  }

  // ==========================================================================
  // Domain layer violations - underscore naming convention
  // ==========================================================================

  Future<void> test_domainLayer_importsMaterial_violation() async {
    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '');

    newFile(
      '$testPackageRootPath/lib/feature_auth/domain/use_cases/login.dart',
      '''
// ignore: uri_does_not_exist
import 'package:flutter/material.dart';

class LoginUseCase {}
''',
    );

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/domain/use_cases/login.dart',
      [lint(30, 39)],
    );
  }

  Future<void> test_domainLayer_importsWidgets_violation() async {
    newFile('$testPackageRootPath/lib/feature_profile/profile.dart', '');

    newFile(
      '$testPackageRootPath/lib/feature_profile/domain/use_cases/update.dart',
      '''
// ignore: uri_does_not_exist
import 'package:flutter/widgets.dart';

class UpdateProfileUseCase {}
''',
    );

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_profile/domain/use_cases/update.dart',
      [lint(30, 38)],
    );
  }

  Future<void> test_domainLayer_importsCupertino_violation() async {
    newFile('$testPackageRootPath/lib/feature_settings/settings.dart', '');

    newFile(
      '$testPackageRootPath/lib/feature_settings/domain/entities/settings.dart',
      '''
// ignore: uri_does_not_exist
import 'package:flutter/cupertino.dart';

class SettingsEntity {}
''',
    );

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_settings/domain/entities/settings.dart',
      [lint(30, 40)],
    );
  }

  Future<void> test_domainLayer_importsFoundation_allowed() async {
    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '');

    newFile(
      '$testPackageRootPath/lib/feature_auth/domain/repositories/auth_repository.dart',
      '''
// ignore: unused_import, uri_does_not_exist
import 'package:flutter/foundation.dart';

class AuthRepository {
  void log() {
    print('Logging');
  }
}
''',
    );

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/domain/repositories/auth_repository.dart',
    );
  }

  // ==========================================================================
  // Data layer violations - underscore naming convention
  // ==========================================================================

  Future<void> test_dataLayer_importsMaterial_violation() async {
    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '');

    newFile(
      '$testPackageRootPath/lib/feature_auth/data/repositories/auth_repository_impl.dart',
      '''
// ignore: uri_does_not_exist
import 'package:flutter/material.dart';

class AuthRepositoryImpl {}
''',
    );

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/data/repositories/auth_repository_impl.dart',
      [lint(30, 39)],
    );
  }

  Future<void> test_dataLayer_importsServices_violation() async {
    newFile('$testPackageRootPath/lib/feature_storage/storage.dart', '');

    newFile(
      '$testPackageRootPath/lib/feature_storage/data/data_sources/secure_storage.dart',
      '''
// ignore: uri_does_not_exist
import 'package:flutter/services.dart';

class SecureStorageDataSource {}
''',
    );

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_storage/data/data_sources/secure_storage.dart',
      [lint(30, 39)],
    );
  }

  // ==========================================================================
  // Clean architecture naming convention (features/xxx/)
  // ==========================================================================

  Future<void> test_domainLayerCleanArch_importsMaterial_violation() async {
    newFile('$testPackageRootPath/lib/features/auth/auth.dart', '');

    newFile(
      '$testPackageRootPath/lib/features/auth/domain/use_cases/login.dart',
      '''
// ignore: uri_does_not_exist
import 'package:flutter/material.dart';

class LoginUseCase {}
''',
    );

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/features/auth/domain/use_cases/login.dart',
      [lint(30, 39)],
    );
  }

  Future<void> test_dataLayerCleanArch_importsFoundation_allowed() async {
    newFile('$testPackageRootPath/lib/features/network/network.dart', '');

    newFile(
      '$testPackageRootPath/lib/features/network/infrastructure/data_sources/api.dart',
      '''
// ignore: unused_import, uri_does_not_exist
import 'package:flutter/foundation.dart';

class NetworkDataSource {
  Future<void> fetchData() async {
    // Can use kDebugMode, compute, etc. from foundation.dart
  }
}
''',
    );

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/features/network/infrastructure/data_sources/api.dart',
    );
  }

  // ==========================================================================
  // Allowed cases - UI/presentation layer
  // ==========================================================================

  Future<void> test_uiLayer_importsMaterial_allowed() async {
    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '');

    newFile('$testPackageRootPath/lib/feature_auth/ui/pages/login.dart', '''
// ignore: unused_import, uri_does_not_exist
import 'package:flutter/material.dart';

class LoginPage {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/ui/pages/login.dart',
    );
  }

  Future<void> test_presentationLayer_importsWidgets_allowed() async {
    newFile('$testPackageRootPath/lib/features/profile/profile.dart', '');

    newFile(
      '$testPackageRootPath/lib/features/profile/presentation/widgets/avatar.dart',
      '''
// ignore: unused_import, uri_does_not_exist
import 'package:flutter/widgets.dart';

class ProfileWidget {}
''',
    );

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/features/profile/presentation/widgets/avatar.dart',
    );
  }

  Future<void> test_uiLayer_importsCupertino_allowed() async {
    newFile('$testPackageRootPath/lib/feature_settings/settings.dart', '');

    newFile(
      '$testPackageRootPath/lib/feature_settings/ui/pages/settings.dart',
      '''
// ignore: unused_import, uri_does_not_exist
import 'package:flutter/cupertino.dart';

class SettingsPage {}
''',
    );

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_settings/ui/pages/settings.dart',
    );
  }

  // ==========================================================================
  // Allowed cases - Dart core libraries
  // ==========================================================================

  Future<void> test_domainLayer_importsDartAsync_allowed() async {
    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '');

    newFile(
      '$testPackageRootPath/lib/feature_auth/domain/use_cases/login.dart',
      '''
import 'dart:async';

class LoginUseCase {
  Future<void> execute() async {}
}
''',
    );

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/domain/use_cases/login.dart',
    );
  }

  Future<void> test_dataLayer_importsDartConvert_allowed() async {
    newFile('$testPackageRootPath/lib/feature_api/api.dart', '');

    newFile('$testPackageRootPath/lib/feature_api/data/parsers/json.dart', '''
// ignore: unused_import
import 'dart:convert';

class JsonParser {
  Map<String, dynamic> parse(String json) => {};
}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_api/data/parsers/json.dart',
    );
  }

  Future<void> test_domainLayer_importsMeta_allowed() async {
    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '');

    newFile(
      '$testPackageRootPath/lib/feature_auth/domain/requests/login.dart',
      '''
// ignore: unused_import, uri_does_not_exist
import 'package:meta/meta.dart';

class LoginRequest {
  const LoginRequest();
}
''',
    );

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/domain/requests/login.dart',
    );
  }

  // ==========================================================================
  // Test files are allowed to import flutter_test
  // ==========================================================================

  Future<void> test_domainTestFile_importsFlutterTest_allowed() async {
    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '');

    newFile(
      '$testPackageRootPath/lib/feature_auth/test/domain/use_cases/login_test.dart',
      '''
// ignore: unused_import, uri_does_not_exist
import 'package:flutter_test/flutter_test.dart';

void main() {}
''',
    );

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/test/domain/use_cases/login_test.dart',
    );
  }

  Future<void> test_dataTestFile_importsMaterial_allowed() async {
    newFile('$testPackageRootPath/lib/feature_storage/storage.dart', '');

    newFile(
      '$testPackageRootPath/lib/feature_storage/test/data/storage_test.dart',
      '''
// ignore: unused_import, uri_does_not_exist
import 'package:flutter/material.dart';
// ignore: unused_import, uri_does_not_exist
import 'package:flutter_test/flutter_test.dart';

void main() {}
''',
    );

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_storage/test/data/storage_test.dart',
    );
  }

  // ==========================================================================
  // Unknown layer - no enforcement
  // ==========================================================================

  Future<void> test_unknownLayer_importsMaterial_allowed() async {
    newFile('$testPackageRootPath/lib/app.dart', '''
// ignore: unused_import, uri_does_not_exist
import 'package:flutter/material.dart';

class AppWidget {}
''');

    await assertNoDiagnosticsInFile('$testPackageRootPath/lib/app.dart');
  }

  Future<void> test_coreModule_importsMaterial_allowed() async {
    newFile('$testPackageRootPath/lib/core/theme.dart', '''
// ignore: unused_import, uri_does_not_exist
import 'package:flutter/material.dart';

class CoreTheme {}
''');

    await assertNoDiagnosticsInFile('$testPackageRootPath/lib/core/theme.dart');
  }

  // ==========================================================================
  // Multiple imports - mixed allowed and forbidden
  // ==========================================================================

  Future<void> test_domainLayer_multipleImports_onlyFlutterViolates() async {
    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '');
    newFile(
      '$testPackageRootPath/lib/feature_auth/domain/repositories/auth_repository.dart',
      'class AuthRepository {}',
    );

    newFile(
      '$testPackageRootPath/lib/feature_auth/domain/use_cases/login.dart',
      '''
// ignore: unused_import
import 'dart:async';
// ignore: unused_import, uri_does_not_exist
import 'package:meta/meta.dart';
// ignore: uri_does_not_exist
import 'package:flutter/material.dart';
// ignore: unused_import
import '../repositories/auth_repository.dart';

class LoginUseCase {}
''',
    );

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/domain/use_cases/login.dart',
      [lint(154, 39)],
    );
  }

  Future<void>
  test_dataLayer_multipleFlutterImports_multipleViolations() async {
    newFile('$testPackageRootPath/lib/feature_network/network.dart', '');

    newFile(
      '$testPackageRootPath/lib/feature_network/data/clients/api.dart',
      '''
// ignore: uri_does_not_exist
import 'package:flutter/material.dart';
// ignore: uri_does_not_exist
import 'package:flutter/services.dart';
// foundation.dart is allowed
// ignore: uri_does_not_exist
import 'package:flutter/foundation.dart';

class ApiClient {}
''',
    );

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_network/data/clients/api.dart',
      [
        lint(30, 39),
        lint(100, 39),
      ], // Only material and services, not foundation
    );
  }
}
