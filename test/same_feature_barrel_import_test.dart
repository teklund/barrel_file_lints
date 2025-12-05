/// Tests for avoid_self_barrel_import rule
///
/// Test organization:
/// - Valid cases: Files importing other features' barrels, internal file imports
/// - Invalid cases: Files importing their own feature's barrel file
/// - Redundant paths: Complex relative paths that escape and re-enter same feature
/// - Coverage: Package imports, relative imports, deeply nested paths

import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:barrel_file_lints/barrel_file_lints.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidSelfBarrelImportTest);
  });
}

@reflectiveTest
class AvoidSelfBarrelImportTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidSelfBarrelImport();
    super.setUp();
  }

  Future<void> test_featureImportsOwnBarrel_underscore() async {
    // The barrel file
    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
export 'data/auth_service.dart';
''');

    // The service file that imports its own barrel
    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/auth.dart';

class AuthService {}
''');

    // Should trigger lint - don't import own barrel
    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/data/auth_service.dart',
      [lint(25, 45)],
    );
  }

  Future<void> test_featureImportsOwnBarrel_slash() async {
    // The barrel file
    newFile('$testPackageRootPath/lib/features/auth/auth.dart', '''
export 'data/auth_service.dart';
''');

    // The service file that imports its own barrel
    newFile('$testPackageRootPath/lib/features/auth/data/auth_service.dart', '''
// ignore: unused_import
import 'package:test/features/auth/auth.dart';

class AuthService {}
''');

    // Should trigger lint - don't import own barrel
    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/features/auth/data/auth_service.dart',
      [lint(25, 46)],
    );
  }

  Future<void> test_featureImportsInternalFile_underscore() async {
    newFile(
      '$testPackageRootPath/lib/feature_auth/data/user_repository.dart',
      '''
class UserRepository {}
''',
    );

    // Importing internal file from same feature - should be allowed
    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/data/user_repository.dart';

class AuthService {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/data/auth_service.dart',
    );
  }

  Future<void> test_featureImportsInternalFile_slash() async {
    newFile(
      '$testPackageRootPath/lib/features/auth/data/user_repository.dart',
      '''
class UserRepository {}
''',
    );

    // Importing internal file from same feature - should be allowed
    newFile('$testPackageRootPath/lib/features/auth/data/auth_service.dart', '''
// ignore: unused_import
import 'package:test/features/auth/data/user_repository.dart';

class AuthService {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/features/auth/data/auth_service.dart',
    );
  }

  Future<void> test_featureImportsDifferentFeatureBarrel() async {
    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
export 'data/auth_service.dart';
''');

    // Importing different feature's barrel - should be allowed
    newFile('$testPackageRootPath/lib/feature_home/ui/home_page.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/auth.dart';

class HomePage {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_home/ui/home_page.dart',
    );
  }

  Future<void> test_barrelFileItself() async {
    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
class AuthService {}
''');

    // The barrel file itself should not trigger
    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
export 'data/auth_service.dart';
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/auth.dart',
    );
  }

  Future<void> test_relativeImportOwnBarrel_underscore() async {
    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
export 'data/auth_service.dart';
''');

    // Using relative import to own barrel - should now be detected
    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
// ignore: unused_import
import '../auth.dart';

class AuthService {}
''');

    // Should trigger lint - importing own barrel via relative path
    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/data/auth_service.dart',
      [lint(25, 22)],
    );
  }

  Future<void> test_relativeImportOwnBarrel_slash() async {
    newFile('$testPackageRootPath/lib/features/catalog/catalog.dart', '''
export 'data/catalog_service.dart';
''');

    // Using relative import to own barrel from subdirectory
    newFile(
      '$testPackageRootPath/lib/features/catalog/ui/catalog_page.dart',
      '''
// ignore: unused_import
import '../catalog.dart';

class CatalogPage {}
''',
    );

    // Should trigger lint - importing own barrel via relative path
    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/features/catalog/ui/catalog_page.dart',
      [lint(25, 25)],
    );
  }

  Future<void> test_relativeImportInternalFile_allowed() async {
    newFile(
      '$testPackageRootPath/lib/feature_auth/data/user_repository.dart',
      '''
class UserRepository {}
''',
    );

    // Using relative import to internal file (not barrel) - should be allowed
    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
// ignore: unused_import
import 'user_repository.dart';

class AuthService {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/data/auth_service.dart',
    );
  }

  Future<void> test_redundantRelativePath_underscore() async {
    newFile(
      '$testPackageRootPath/lib/feature_order/data/extensions/order_extensions.dart',
      '''
class OrderExtensions {}
''',
    );

    // Using unnecessarily complex relative path that escapes and re-enters same feature
    newFile(
      '$testPackageRootPath/lib/feature_order/data/order_service.dart',
      '''
// ignore: unused_import
import '../../feature_order/data/extensions/order_extensions.dart';

class OrderService {}
''',
    );

    // Should trigger lint - unnecessarily complex relative path
    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_order/data/order_service.dart',
      [lint(25, 67)],
    );
  }

  Future<void> test_redundantRelativePath_slash() async {
    // Create the barrel file
    newFile('$testPackageRootPath/lib/features/auth/auth.dart', '''
export 'data/auth_service.dart';
export 'data/extensions/auth_extensions.dart';
''');

    // Create the extensions file
    newFile(
      '$testPackageRootPath/lib/features/auth/data/extensions/auth_extensions.dart',
      '''
class AuthExtensions {}
''',
    );

    // Create auth_service
    newFile('$testPackageRootPath/lib/features/auth/data/auth_service.dart', '''
class AuthService {}
''');

    // Create UI file that uses the redundant path
    newFile('$testPackageRootPath/lib/features/auth/ui/login_page.dart', '''
// ignore: unused_import
import '../../features/auth/data/extensions/auth_extensions.dart';

class LoginPage {}
''');

    // Should trigger lint - unnecessarily complex relative path
    // Note: The analyzer also reports URI_DOES_NOT_EXIST due to path resolution complexity
    final uriDoesNotExist = errorCodeByUniqueName(
      'CompileTimeErrorCode.URI_DOES_NOT_EXIST',
    )!;
    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/features/auth/ui/login_page.dart',
      [lint(25, 66), error(uriDoesNotExist, 32, 58)],
    );
  }

  Future<void> test_simpleRelativePathWithinFeature_allowed() async {
    newFile(
      '$testPackageRootPath/lib/feature_auth/data/extensions/auth_extensions.dart',
      '''
class AuthExtensions {}
''',
    );

    // Simple relative import within same feature - should be allowed
    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
// ignore: unused_import
import 'extensions/auth_extensions.dart';

class AuthService {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/data/auth_service.dart',
    );
  }

  Future<void> test_relativeImportFromUiToData_allowed() async {
    newFile('$testPackageRootPath/lib/feature_user/data/models/user.dart', '''
class User {}
''');

    // Direct relative import from ui/ to data/ within same feature - should be allowed
    // This is a normal case: ui folder accessing data models
    newFile('$testPackageRootPath/lib/feature_user/ui/user_page.dart', '''
// ignore: unused_import
import '../data/models/user.dart';

class UserPage {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_user/ui/user_page.dart',
    );
  }

  Future<void> test_relativeImportFromNestedUiToData_allowed() async {
    newFile(
      '$testPackageRootPath/lib/feature_profile/data/models/user_profile.dart',
      '''
class UserProfile {}
''',
    );

    // Direct relative import from nested ui/parts/ to data/models/ - should be allowed
    // Even with ../../ it's still a valid cross-directory import within same feature
    newFile(
      '$testPackageRootPath/lib/feature_profile/ui/parts/profile_widget.dart',
      '''
// ignore: unused_import
import '../../data/models/user_profile.dart';

class ProfileWidget {}
''',
    );

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_profile/ui/parts/profile_widget.dart',
    );
  }

  // Tests for split barrel self-imports
  Future<void> test_dataLayerImportsOwnDataBarrel_violation() async {
    newFile('$testPackageRootPath/lib/feature_auth/auth_data.dart', '''
export 'data/auth_repository.dart';
''');

    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/auth_data.dart';

class AuthService {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/data/auth_service.dart',
      [lint(25, 50)],
    );
  }

  Future<void> test_domainLayerImportsOwnDomainBarrel_violation() async {
    newFile('$testPackageRootPath/lib/feature_auth/auth_domain.dart', '''
export 'domain/auth_entity.dart';
''');

    newFile(
      '$testPackageRootPath/lib/feature_auth/domain/auth_use_case.dart',
      '''
// ignore: unused_import
import 'package:test/feature_auth/auth_domain.dart';

class AuthUseCase {}
''',
    );

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/domain/auth_use_case.dart',
      [lint(25, 52)],
    );
  }

  Future<void> test_uiLayerImportsOwnUiBarrel_violation() async {
    newFile('$testPackageRootPath/lib/feature_auth/auth_ui.dart', '''
export 'ui/login_screen.dart';
''');

    newFile('$testPackageRootPath/lib/feature_auth/ui/login_widget.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/auth_ui.dart';

class LoginWidget {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/ui/login_widget.dart',
      [lint(25, 48)],
    );
  }

  Future<void> test_relativeSplitBarrelImport_violation() async {
    newFile('$testPackageRootPath/lib/feature_auth/auth_data.dart', '''
export 'data/auth_repository.dart';
''');

    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
// ignore: unused_import
import '../auth_data.dart';

class AuthService {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/data/auth_service.dart',
      [lint(25, 27)],
    );
  }

  Future<void> test_dataLayerImportsOtherSplitBarrel_allowed() async {
    // Data layer can import domain barrel from same feature
    newFile('$testPackageRootPath/lib/feature_auth/auth_domain.dart', '''
export 'domain/auth_entity.dart';
''');

    newFile(
      '$testPackageRootPath/lib/feature_auth/data/auth_repository.dart',
      '''
// ignore: unused_import
import 'package:test/feature_auth/auth_domain.dart';

class AuthRepository {}
''',
    );

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/data/auth_repository.dart',
    );
  }

  Future<void> test_uiLayerImportsDataBarrel_allowed() async {
    // UI layer can import data barrel from same feature
    newFile('$testPackageRootPath/lib/feature_auth/auth_data.dart', '''
export 'data/auth_repository.dart';
''');

    newFile('$testPackageRootPath/lib/feature_auth/ui/login_screen.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/auth_data.dart';

class LoginScreen {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/ui/login_screen.dart',
    );
  }

  Future<void> test_slashStyle_splitBarrelSelfImport_violation() async {
    newFile('$testPackageRootPath/lib/features/auth/auth_data.dart', '''
export 'data/auth_repository.dart';
''');

    newFile('$testPackageRootPath/lib/features/auth/data/auth_service.dart', '''
// ignore: unused_import
import 'package:test/features/auth/auth_data.dart';

class AuthService {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/features/auth/data/auth_service.dart',
      [lint(25, 51)],
    );
  }

  Future<void> test_slashStyle_domainBarrelSelfImport_violation() async {
    newFile('$testPackageRootPath/lib/features/auth/auth_domain.dart', '''
export 'domain/auth_entity.dart';
''');

    newFile(
      '$testPackageRootPath/lib/features/auth/domain/auth_use_case.dart',
      '''
// ignore: unused_import
import 'package:test/features/auth/auth_domain.dart';

class AuthUseCase {}
''',
    );

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/features/auth/domain/auth_use_case.dart',
      [lint(25, 53)],
    );
  }

  Future<void> test_slashStyle_uiBarrelSelfImport_violation() async {
    newFile('$testPackageRootPath/lib/features/auth/auth_ui.dart', '''
export 'ui/login_screen.dart';
''');

    newFile('$testPackageRootPath/lib/features/auth/ui/login_widget.dart', '''
// ignore: unused_import
import 'package:test/features/auth/auth_ui.dart';

class LoginWidget {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/features/auth/ui/login_widget.dart',
      [lint(25, 49)],
    );
  }

  Future<void> test_slashStyle_relativeSplitBarrel_violation() async {
    newFile('$testPackageRootPath/lib/features/auth/auth_domain.dart', '''
export 'domain/auth_entity.dart';
''');

    newFile(
      '$testPackageRootPath/lib/features/auth/domain/auth_use_case.dart',
      '''
// ignore: unused_import
import '../auth_domain.dart';

class AuthUseCase {}
''',
    );

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/features/auth/domain/auth_use_case.dart',
      [lint(25, 29)],
    );
  }

  Future<void> test_uiImportsDomainBarrel_allowed() async {
    // UI layer can import domain barrel from same feature
    newFile('$testPackageRootPath/lib/feature_auth/auth_domain.dart', '''
export 'domain/auth_entity.dart';
''');

    newFile('$testPackageRootPath/lib/feature_auth/ui/login_screen.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/auth_domain.dart';

class LoginScreen {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/ui/login_screen.dart',
    );
  }

  Future<void> test_dataImportsDomainBarrel_relative_allowed() async {
    // Data layer can import domain barrel via relative import
    newFile('$testPackageRootPath/lib/feature_auth/auth_domain.dart', '''
export 'domain/auth_entity.dart';
''');

    newFile(
      '$testPackageRootPath/lib/feature_auth/data/auth_repository.dart',
      '''
// ignore: unused_import
import '../auth_domain.dart';

class AuthRepository {}
''',
    );

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/data/auth_repository.dart',
    );
  }

  Future<void> test_uiImportsDataBarrel_relative_allowed() async {
    // UI layer can import data barrel via relative import
    newFile('$testPackageRootPath/lib/feature_auth/auth_data.dart', '''
export 'data/auth_repository.dart';
''');

    newFile('$testPackageRootPath/lib/feature_auth/ui/login_screen.dart', '''
// ignore: unused_import
import '../auth_data.dart';

class LoginScreen {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/ui/login_screen.dart',
    );
  }

  Future<void> test_slashStyle_dataImportsDomain_allowed() async {
    // Slash style: data can import domain barrel
    newFile('$testPackageRootPath/lib/features/auth/auth_domain.dart', '''
export 'domain/auth_entity.dart';
''');

    newFile(
      '$testPackageRootPath/lib/features/auth/data/auth_repository.dart',
      '''
// ignore: unused_import
import 'package:test/features/auth/auth_domain.dart';

class AuthRepository {}
''',
    );

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/features/auth/data/auth_repository.dart',
    );
  }

  Future<void> test_slashStyle_uiImportsData_allowed() async {
    // Slash style: UI can import data barrel
    newFile('$testPackageRootPath/lib/features/auth/auth_data.dart', '''
export 'data/auth_repository.dart';
''');

    newFile('$testPackageRootPath/lib/features/auth/ui/login_screen.dart', '''
// ignore: unused_import
import 'package:test/features/auth/auth_data.dart';

class LoginScreen {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/features/auth/ui/login_screen.dart',
    );
  }

  Future<void> test_relativeUiImportOwnUiBarrel_violation() async {
    // Relative import: UI importing own UI barrel
    newFile('$testPackageRootPath/lib/feature_auth/auth_ui.dart', '''
export 'ui/login_screen.dart';
''');

    newFile('$testPackageRootPath/lib/feature_auth/ui/login_widget.dart', '''
// ignore: unused_import
import '../auth_ui.dart';

class LoginWidget {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/ui/login_widget.dart',
      [lint(25, 25)],
    );
  }

  Future<void> test_relativeDomainImportOwnDomainBarrel_violation() async {
    // Relative import: Domain importing own domain barrel
    newFile('$testPackageRootPath/lib/feature_auth/auth_domain.dart', '''
export 'domain/auth_entity.dart';
''');

    newFile(
      '$testPackageRootPath/lib/feature_auth/domain/auth_use_case.dart',
      '''
// ignore: unused_import
import '../auth_domain.dart';

class AuthUseCase {}
''',
    );

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/domain/auth_use_case.dart',
      [lint(25, 29)],
    );
  }

  Future<void> test_domainImportsUiBarrel_shouldBeBlockedByLayerRule() async {
    // Domain layer should NOT be able to import UI barrel - this should be caught
    // by avoid_improper_layer_import rule, not this rule
    // This test verifies avoid_self_barrel_import doesn't interfere
    newFile('$testPackageRootPath/lib/feature_auth/auth_ui.dart', '''
export 'ui/login_screen.dart';
''');

    newFile(
      '$testPackageRootPath/lib/feature_auth/domain/auth_use_case.dart',
      '''
// ignore: unused_import
import 'package:test/feature_auth/auth_ui.dart';

class AuthUseCase {}
''',
    );

    // This should NOT trigger avoid_self_barrel_import (different layers)
    // It WILL trigger avoid_improper_layer_import
    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/domain/auth_use_case.dart',
    );
  }

  Future<void> test_domainImportsDataBarrel_shouldBeBlockedByLayerRule() async {
    // Domain layer should NOT be able to import Data barrel - this should be caught
    // by avoid_improper_layer_import rule, not this rule
    newFile('$testPackageRootPath/lib/feature_auth/auth_data.dart', '''
export 'data/auth_repository.dart';
''');

    newFile(
      '$testPackageRootPath/lib/feature_auth/domain/auth_use_case.dart',
      '''
// ignore: unused_import
import 'package:test/feature_auth/auth_data.dart';

class AuthUseCase {}
''',
    );

    // This should NOT trigger avoid_self_barrel_import (different layers)
    // It WILL trigger avoid_improper_layer_import
    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/domain/auth_use_case.dart',
    );
  }
}
