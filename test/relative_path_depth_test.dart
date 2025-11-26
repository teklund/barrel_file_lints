/// Tests for relative imports at different directory depths
library;

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:barrel_file_lints/barrel_file_lints.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RelativePathDepthTest);
  });
}

@reflectiveTest
class RelativePathDepthTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidSelfBarrelImport();
    super.setUp();
  }

  /// Test that '../item.dart' from legacy subfolder is allowed
  /// (importing sibling model file, not barrel)
  Future<void> test_relativeImportFromDeepSubfolder_allowed() async {
    // The target file being imported
    newFile('$testPackageRootPath/lib/feature_store/data/models/item.dart', '''
class Item {
  Item();
}
''');

    // The file in a deeper subfolder importing '../item.dart'
    newFile(
      '$testPackageRootPath/lib/feature_store/data/models/legacy/old_item.dart',
      '''
import '../item.dart'; // This imports models/item.dart, NOT the barrel

class OldItem extends Item {
  OldItem();
}
''',
    );

    // Should NOT trigger - this is importing a sibling file, not the barrel
    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_store/data/models/legacy/old_item.dart',
    );
  }

  /// Test that '../store.dart' from ui folder correctly triggers
  /// (this IS importing the barrel)
  Future<void> test_relativeBarrelImportFromUi_triggers() async {
    // The barrel file
    newFile('$testPackageRootPath/lib/feature_store/store.dart', '''
export 'data/store_repository.dart';
export 'ui/store_page.dart';
''');

    // File in ui folder importing the barrel
    newFile('$testPackageRootPath/lib/feature_store/ui/store_page.dart', '''
// ignore: unused_import
import '../store.dart'; // This imports the barrel at feature_store/store.dart

class StorePage {}
''');

    // Should trigger - this IS importing the barrel file
    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_store/ui/store_page.dart',
      [lint(25, 23)],
    );
  }

  /// Test that '../../store.dart' from nested ui folder correctly triggers
  Future<void> test_relativeBarrelImportFromNestedUi_triggers() async {
    // The barrel file
    newFile('$testPackageRootPath/lib/feature_store/store.dart', '''
export 'data/store_repository.dart';
''');

    // File in nested ui folder importing the barrel
    newFile(
      '$testPackageRootPath/lib/feature_store/ui/pages/store_details_page.dart',
      '''
// ignore: unused_import
import '../../store.dart'; // This imports the barrel

class StoreDetailsPage {}
''',
    );

    // Should trigger - this IS importing the barrel file
    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_store/ui/pages/store_details_page.dart',
      [lint(25, 26)],
    );
  }

  /// Test that '../item.dart' from deeply nested models is allowed
  /// (importing a sibling file, not the barrel)
  Future<void> test_relativeImportFromDeeplyNestedFolder_allowed() async {
    // The target file being imported (sibling in models/)
    newFile('$testPackageRootPath/lib/feature_store/data/models/item.dart', '''
class Item {
  final String id;
  Item(this.id);
}
''');

    // File in legacy subfolder importing '../item.dart' (the sibling file)
    newFile(
      '$testPackageRootPath/lib/feature_store/data/models/legacy/old_item.dart',
      '''
import '../item.dart'; // This imports models/item.dart, not the barrel

class OldItem {
  final Item item;
  OldItem(this.item);
}
''',
    );

    // Should NOT trigger - importing a file in the same directory tree, not the barrel
    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_store/data/models/legacy/old_item.dart',
    );
  }

  /// Test features/ style with same scenario
  Future<void>
  test_featuresStyleRelativeImportFromDeepSubfolder_allowed() async {
    // The target file being imported
    newFile(
      '$testPackageRootPath/lib/features/product/domain/models/product.dart',
      '''
class Product {
  Product();
}
''',
    );

    // File in legacy folder importing '../product.dart'
    newFile(
      '$testPackageRootPath/lib/features/product/domain/models/legacy/old_product.dart',
      '''
import '../product.dart'; // This imports models/product.dart, NOT the barrel

class OldProduct extends Product {
  OldProduct();
}
''',
    );

    // Should NOT trigger - importing a sibling file, not the barrel
    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/features/product/domain/models/legacy/old_product.dart',
    );
  }
}
