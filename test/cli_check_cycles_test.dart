import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('check_cycles CLI', () {
    late Directory tempDir;
    late String libDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('barrel_cycle_test_');
      libDir = path.join(tempDir.path, 'lib');
      Directory(libDir).createSync();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('exits with 0 when no cycles exist', () async {
      // Create two features without cycles
      _createFeature(libDir, 'auth', exports: []);
      _createFeature(libDir, 'profile', exports: []);

      final result = await _runCheckCycles(libDir);

      expect(result.exitCode, 0);
      expect(result.stdout, contains('No circular dependencies found'));
    });

    test('detects simple two-feature cycle', () async {
      // feature_a exports feature_b, feature_b exports feature_a
      _createFeature(libDir, 'a', exports: ["export 'package:test/feature_b/b.dart';"]);
      _createFeature(libDir, 'b', exports: ["export 'package:test/feature_a/a.dart';"]);

      final result = await _runCheckCycles(libDir);

      expect(result.exitCode, 1);
      expect(result.stdout, contains('Found 1 circular'));
      expect(result.stdout, contains('Cycle 1:'));
    });

    test('detects transitive three-feature cycle', () async {
      // a → b → c → a
      _createFeature(libDir, 'a', exports: ["export 'package:test/feature_b/b.dart';"]);
      _createFeature(libDir, 'b', exports: ["export 'package:test/feature_c/c.dart';"]);
      _createFeature(libDir, 'c', exports: ["export 'package:test/feature_a/a.dart';"]);

      final result = await _runCheckCycles(libDir);

      expect(result.exitCode, 1);
      expect(result.stdout, contains('Found 1 circular'));
    });

    test('detects multiple independent cycles', () async {
      // Cycle 1: a ↔ b
      _createFeature(libDir, 'a', exports: ["export 'package:test/feature_b/b.dart';"]);
      _createFeature(libDir, 'b', exports: ["export 'package:test/feature_a/a.dart';"]);

      // Cycle 2: c ↔ d
      _createFeature(libDir, 'c', exports: ["export 'package:test/feature_d/d.dart';"]);
      _createFeature(libDir, 'd', exports: ["export 'package:test/feature_c/c.dart';"]);

      final result = await _runCheckCycles(libDir);

      expect(result.exitCode, 1);
      expect(result.stdout, contains('Found 2 circular'));
      expect(result.stdout, contains('Cycle 1:'));
      expect(result.stdout, contains('Cycle 2:'));
    });

    test('handles features/ naming convention', () async {
      // Create features using features/ style
      _createFeature(libDir, 'auth', exports: ["export 'package:test/features/profile/profile.dart';"], useFeaturesStyle: true);
      _createFeature(libDir, 'profile', exports: ["export 'package:test/features/auth/auth.dart';"], useFeaturesStyle: true);

      final result = await _runCheckCycles(libDir);

      expect(result.exitCode, 1);
      expect(result.stdout, contains('Found 1 circular'));
    });

    test('handles relative imports in cycle detection', () async {
      // Create cycle using relative imports
      final aDir = Directory(path.join(libDir, 'feature_a'))..createSync();
      final bDir = Directory(path.join(libDir, 'feature_b'))..createSync();

      File(path.join(aDir.path, 'a.dart')).writeAsStringSync("export '../feature_b/b.dart';");
      File(path.join(bDir.path, 'b.dart')).writeAsStringSync("export '../feature_a/a.dart';");

      final result = await _runCheckCycles(libDir);

      expect(result.exitCode, 1);
      expect(result.stdout, contains('Found 1 circular'));
    });

    test('ignores non-barrel dart files', () async {
      // Create a feature with internal files that don't form cycles
      final featureDir = Directory(path.join(libDir, 'feature_auth'))..createSync();
      File(path.join(featureDir.path, 'auth.dart')).writeAsStringSync('');

      final dataDir = Directory(path.join(featureDir.path, 'data'))..createSync();
      File(path.join(dataDir.path, 'auth_repo.dart')).writeAsStringSync(
        "export 'package:test/feature_auth/auth.dart';", // Internal file exports barrel (not a cycle)
      );

      final result = await _runCheckCycles(libDir);

      expect(result.exitCode, 0);
      expect(result.stdout, contains('No circular dependencies found'));
    });

    test('exits with 2 when lib directory does not exist', () async {
      final nonExistentDir = path.join(tempDir.path, 'does_not_exist');

      final result = await _runCheckCycles(nonExistentDir);

      expect(result.exitCode, 2);
      expect(result.stderr, contains('Directory not found'));
    });

    test('shows help message when --help flag is used', () async {
      final result = await Process.run(
        'dart',
        ['run', 'barrel_file_lints:check_cycles', '--help'],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, 0);
      expect(result.stdout, contains('Barrel File Cycle Detector'));
      expect(result.stdout, contains('Usage:'));
      expect(result.stdout, contains('--lib-dir'));
      expect(result.stdout, contains('verbose'));
    });

    test('verbose mode shows detailed output', () async {
      _createFeature(libDir, 'auth', exports: []);
      _createFeature(libDir, 'profile', exports: []);

      final result = await _runCheckCycles(libDir, verbose: true);

      expect(result.exitCode, 0);
      expect(result.stdout, contains('Analyzing barrel files in:'));
      expect(result.stdout, contains('Found'));
      expect(result.stdout, contains('barrel files'));
    });

    test('allows one-way dependencies without cycles', () async {
      // a → b → c (no cycle)
      _createFeature(libDir, 'a', exports: ["export 'package:test/feature_b/b.dart';"]);
      _createFeature(libDir, 'b', exports: ["export 'package:test/feature_c/c.dart';"]);
      _createFeature(libDir, 'c', exports: []);

      final result = await _runCheckCycles(libDir);

      expect(result.exitCode, 0);
      expect(result.stdout, contains('No circular dependencies found'));
    });

    test('handles self-exports gracefully', () async {
      // Feature exports itself (should not crash)
      _createFeature(libDir, 'auth', exports: ["export 'package:test/feature_auth/auth.dart';"]);

      final result = await _runCheckCycles(libDir);

      // Self-export is filtered out, so no cycle
      expect(result.exitCode, 0);
    });
  });
}

/// Helper to create a feature directory with barrel file
void _createFeature(
  String libDir,
  String featureName, {
  required List<String> exports,
  bool useFeaturesStyle = false,
}) {
  final featureDir = useFeaturesStyle
      ? Directory(path.join(libDir, 'features', featureName))
      : Directory(path.join(libDir, 'feature_$featureName'));

  featureDir.createSync(recursive: true);

  final barrelFile = File(path.join(featureDir.path, '$featureName.dart'));
  barrelFile.writeAsStringSync(exports.join('\n'));
}

/// Helper to run the check_cycles CLI tool
Future<ProcessResult> _runCheckCycles(String libDir, {bool verbose = false}) async {
  final args = [
    'run',
    'barrel_file_lints:check_cycles',
    '--lib-dir=$libDir',
    if (verbose) '--verbose',
  ];

  return Process.run(
    'dart',
    args,
    workingDirectory: Directory.current.path,
  );
}
