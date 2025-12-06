/// Tests for split barrel file support and layer-aware imports

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:barrel_file_lints/barrel_file_lints.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SplitBarrelImportTest);
    defineReflectiveTests(LayerViolationDetectionTest);
  });
}

@reflectiveTest
class SplitBarrelImportTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidInternalFeatureImports();
    super.setUp();
  }

  Future<void> test_splitBarrel_dataImport_allowed() async {
    newFile('$testPackageRootPath/lib/feature_b/b_data.dart', '''
export 'data/repository.dart';
''');

    newFile('$testPackageRootPath/lib/feature_a/data/repository.dart', '''
// ignore: unused_import
import 'package:test/feature_b/b_data.dart';

class Repository {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_a/data/repository.dart',
    );
  }

  Future<void> test_splitBarrel_domainImport_allowed() async {
    newFile('$testPackageRootPath/lib/feature_b/b_domain.dart', '''
export 'domain/entity.dart';
''');

    newFile('$testPackageRootPath/lib/feature_a/domain/use_case.dart', '''
// ignore: unused_import
import 'package:test/feature_b/b_domain.dart';

class UseCase {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_a/domain/use_case.dart',
    );
  }

  Future<void> test_splitBarrel_uiImport_allowed() async {
    newFile('$testPackageRootPath/lib/feature_b/b_ui.dart', '''
export 'ui/widget.dart';
''');

    newFile('$testPackageRootPath/lib/feature_a/ui/screen.dart', '''
// ignore: unused_import
import 'package:test/feature_b/b_ui.dart';

class Screen {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_a/ui/screen.dart',
    );
  }

  Future<void> test_monolithicBarrel_allowed() async {
    newFile('$testPackageRootPath/lib/feature_b/b.dart', '''
export 'data/repository.dart';
''');

    newFile('$testPackageRootPath/lib/feature_a/data/repository.dart', '''
// ignore: unused_import
import 'package:test/feature_b/b.dart';

class Repository {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_a/data/repository.dart',
    );
  }

  Future<void> test_internalImport_stillFlagged() async {
    newFile('$testPackageRootPath/lib/feature_b/data/b_repository.dart', '''
class BRepository {}
''');

    newFile('$testPackageRootPath/lib/feature_a/data/repository.dart', '''
// ignore: unused_import
import 'package:test/feature_b/data/b_repository.dart';

class Repository {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_a/data/repository.dart',
      [error(AvoidInternalFeatureImports.code, 25, 55)],
    );
  }

  Future<void> test_splitBarrel_cleanArchitectureStyle() async {
    newFile('$testPackageRootPath/lib/features/profile/profile_data.dart', '''
export 'data/repository.dart';
''');

    newFile('$testPackageRootPath/lib/features/auth/data/repository.dart', '''
// ignore: unused_import
import 'package:test/features/profile/profile_data.dart';

class Repository {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/features/auth/data/repository.dart',
    );
  }
}

@reflectiveTest
class LayerViolationDetectionTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidImproperLayerImport();
    super.setUp();
  }

  Future<void> test_dataLayer_importsSplitUiBarrel_violation() async {
    newFile('$testPackageRootPath/lib/feature_b/b_ui.dart', '''
export 'ui/widget.dart';
''');

    newFile('$testPackageRootPath/lib/feature_a/data/repository.dart', '''
// ignore: unused_import
import 'package:test/feature_b/b_ui.dart';

class Repository {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_a/data/repository.dart',
      [error(AvoidImproperLayerImport.code, 25, 42)],
    );
  }

  Future<void> test_dataLayer_importsSplitDataBarrel_allowed() async {
    newFile('$testPackageRootPath/lib/feature_b/b_data.dart', '''
export 'data/repository.dart';
''');

    newFile('$testPackageRootPath/lib/feature_a/data/repository.dart', '''
// ignore: unused_import
import 'package:test/feature_b/b_data.dart';

class Repository {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_a/data/repository.dart',
    );
  }

  Future<void> test_dataLayer_importsSplitDomainBarrel_allowed() async {
    newFile('$testPackageRootPath/lib/feature_b/b_domain.dart', '''
export 'domain/entity.dart';
''');

    newFile('$testPackageRootPath/lib/feature_a/data/repository.dart', '''
// ignore: unused_import
import 'package:test/feature_b/b_domain.dart';

class Repository {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_a/data/repository.dart',
    );
  }

  Future<void> test_domainLayer_importsSplitUiBarrel_violation() async {
    newFile('$testPackageRootPath/lib/feature_b/b_ui.dart', '''
export 'ui/widget.dart';
''');

    newFile('$testPackageRootPath/lib/feature_a/domain/use_case.dart', '''
// ignore: unused_import
import 'package:test/feature_b/b_ui.dart';

class UseCase {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_a/domain/use_case.dart',
      [error(AvoidImproperLayerImport.code, 25, 42)],
    );
  }

  Future<void> test_domainLayer_importsSplitDataBarrel_violation() async {
    newFile('$testPackageRootPath/lib/feature_b/b_data.dart', '''
export 'data/repository.dart';
''');

    newFile('$testPackageRootPath/lib/feature_a/domain/use_case.dart', '''
// ignore: unused_import
import 'package:test/feature_b/b_data.dart';

class UseCase {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_a/domain/use_case.dart',
      [error(AvoidImproperLayerImport.code, 25, 44)],
    );
  }

  Future<void> test_domainLayer_importsSplitDomainBarrel_allowed() async {
    newFile('$testPackageRootPath/lib/feature_b/b_domain.dart', '''
export 'domain/entity.dart';
''');

    newFile('$testPackageRootPath/lib/feature_a/domain/use_case.dart', '''
// ignore: unused_import
import 'package:test/feature_b/b_domain.dart';

class UseCase {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_a/domain/use_case.dart',
    );
  }

  Future<void> test_uiLayer_importsAnyBarrel_allowed() async {
    newFile('$testPackageRootPath/lib/feature_b/b_ui.dart', '''
export 'ui/widget.dart';
''');
    newFile('$testPackageRootPath/lib/feature_c/c_data.dart', '''
export 'data/repository.dart';
''');
    newFile('$testPackageRootPath/lib/feature_d/d_domain.dart', '''
export 'domain/entity.dart';
''');

    newFile('$testPackageRootPath/lib/feature_a/ui/screen.dart', '''
// ignore: unused_import
import 'package:test/feature_b/b_ui.dart';
// ignore: unused_import
import 'package:test/feature_c/c_data.dart';
// ignore: unused_import
import 'package:test/feature_d/d_domain.dart';

class Screen {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_a/ui/screen.dart',
    );
  }

  Future<void> test_cleanArchitectureStyle_dataImportingUi_violation() async {
    newFile('$testPackageRootPath/lib/features/profile/profile_ui.dart', '''
export 'ui/widget.dart';
''');

    newFile('$testPackageRootPath/lib/features/auth/data/repository.dart', '''
// ignore: unused_import
import 'package:test/features/profile/profile_ui.dart';

class Repository {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/features/auth/data/repository.dart',
      [error(AvoidImproperLayerImport.code, 25, 55)],
    );
  }

  Future<void> test_cleanArchitectureStyle_infrastructure_isDataLayer() async {
    newFile('$testPackageRootPath/lib/features/profile/profile_ui.dart', '''
export 'ui/widget.dart';
''');

    newFile(
      '$testPackageRootPath/lib/features/auth/infrastructure/api_client.dart',
      '''
// ignore: unused_import
import 'package:test/features/profile/profile_ui.dart';

class ApiClient {}
''',
    );

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/features/auth/infrastructure/api_client.dart',
      [error(AvoidImproperLayerImport.code, 25, 55)],
    );
  }

  Future<void> test_cleanArchitectureStyle_presentation_isUiLayer() async {
    newFile('$testPackageRootPath/lib/features/profile/profile_ui.dart', '''
export 'ui/widget.dart';
''');
    newFile('$testPackageRootPath/lib/features/users/users_data.dart', '''
export 'data/repository.dart';
''');

    newFile(
      '$testPackageRootPath/lib/features/auth/presentation/login_page.dart',
      '''
// ignore: unused_import
import 'package:test/features/profile/profile_ui.dart';
// ignore: unused_import
import 'package:test/features/users/users_data.dart';

class LoginPage {}
''',
    );

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/features/auth/presentation/login_page.dart',
    );
  }

  Future<void> test_sameFeature_noLayerCheck() async {
    newFile('$testPackageRootPath/lib/feature_auth/ui/login_page.dart', '''
class LoginPage {}
''');

    newFile('$testPackageRootPath/lib/feature_auth/data/repository.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/ui/login_page.dart';

class Repository {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_auth/data/repository.dart',
    );
  }

  Future<void> test_testFile_exemptFromLayerChecks() async {
    newFile('$testPackageRootPath/lib/feature_b/b_ui.dart', '''
export 'ui/widget.dart';
''');

    newFile('$testPackageRootPath/test/feature_a/data/repository_test.dart', '''
// ignore: unused_import
import 'package:test/feature_b/b_ui.dart';

void main() {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/test/feature_a/data/repository_test.dart',
    );
  }

  Future<void> test_unknownLayer_noRestrictions() async {
    newFile('$testPackageRootPath/lib/feature_b/b_ui.dart', '''
export 'ui/widget.dart';
''');

    newFile('$testPackageRootPath/lib/feature_a/utils/helper.dart', '''
// ignore: unused_import
import 'package:test/feature_b/b_ui.dart';

class Helper {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_a/utils/helper.dart',
    );
  }

  Future<void> test_monolithicBarrel_dataLayer_violation() async {
    // Data layer importing monolithic barrel should be flagged
    // to encourage using split barrels instead
    newFile('$testPackageRootPath/lib/feature_b/b.dart', '''
export 'data/repository.dart';
export 'ui/screen.dart';
''');

    newFile('$testPackageRootPath/lib/feature_a/data/repository.dart', '''
// ignore: unused_import
import 'package:test/feature_b/b.dart';

class ARepository {}
''');

    // Should suggest using b_data.dart instead
    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_a/data/repository.dart',
      [lint(25, 39)],
    );
  }

  Future<void> test_monolithicBarrel_domainLayer_violation() async {
    // Domain layer importing monolithic barrel should be flagged
    newFile('$testPackageRootPath/lib/feature_b/b.dart', '''
export 'domain/entity.dart';
export 'ui/screen.dart';
''');

    newFile('$testPackageRootPath/lib/feature_a/domain/use_case.dart', '''
// ignore: unused_import
import 'package:test/feature_b/b.dart';

class AUseCase {}
''');

    // Should suggest using b_domain.dart instead
    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_a/domain/use_case.dart',
      [lint(25, 39)],
    );
  }

  Future<void> test_monolithicBarrel_uiLayer_allowed() async {
    // UI layer can import monolithic barrels
    newFile('$testPackageRootPath/lib/feature_b/b.dart', '''
export 'data/repository.dart';
export 'ui/screen.dart';
''');

    newFile('$testPackageRootPath/lib/feature_a/ui/screen.dart', '''
// ignore: unused_import
import 'package:test/feature_b/b.dart';

class AScreen {}
''');

    // UI layer can import anything - no diagnostic
    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_a/ui/screen.dart',
    );
  }
}
