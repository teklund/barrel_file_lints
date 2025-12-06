/// Tests for extended internal directory detection
///
/// Verifies all internal directories are properly detected:
/// - Common: data/, ui/, domain/, models/, services/
/// - State management: bloc/, cubit/, providers/, notifiers/
/// - Clean architecture: presentation/, infrastructure/, application/
/// - Utilities: utils/, helpers/, config/, widgets/, repositories/

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:barrel_file_lints/barrel_file_lints.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AdditionalInternalDirectoriesTest);
  });
}

@reflectiveTest
class AdditionalInternalDirectoriesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidInternalFeatureImports();
    super.setUp();
  }

  Future<void> test_modelsDirectory_underscore() async {
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

  Future<void> test_exceptionsDirectory_underscore() async {
    newFile(
      '$testPackageRootPath/lib/feature_auth/exceptions/auth_exception.dart',
      '''
class AuthException {}
''',
    );

    newFile('$testPackageRootPath/lib/feature_home/ui/home_page.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/exceptions/auth_exception.dart';

class HomePage {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_home/ui/home_page.dart',
      [lint(25, 66)],
    );
  }

  Future<void> test_extensionsDirectory_underscore() async {
    newFile(
      '$testPackageRootPath/lib/feature_auth/extensions/string_ext.dart',
      '''
extension StringExt on String {}
''',
    );

    newFile('$testPackageRootPath/lib/feature_home/ui/home_page.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/extensions/string_ext.dart';

class HomePage {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_home/ui/home_page.dart',
      [lint(25, 62)],
    );
  }

  Future<void> test_applicationDirectory_slash() async {
    newFile(
      '$testPackageRootPath/lib/features/auth/application/auth_service.dart',
      '''
class AuthService {}
''',
    );

    newFile('$testPackageRootPath/lib/features/home/ui/home_page.dart', '''
// ignore: unused_import
import 'package:test/features/auth/application/auth_service.dart';

class HomePage {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/features/home/ui/home_page.dart',
      [lint(25, 66)],
    );
  }

  Future<void> test_infrastructureDirectory_slash() async {
    newFile(
      '$testPackageRootPath/lib/features/auth/infrastructure/auth_repo.dart',
      '''
class AuthRepo {}
''',
    );

    newFile('$testPackageRootPath/lib/features/home/ui/home_page.dart', '''
// ignore: unused_import
import 'package:test/features/auth/infrastructure/auth_repo.dart';

class HomePage {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/features/home/ui/home_page.dart',
      [lint(25, 66)],
    );
  }
}
