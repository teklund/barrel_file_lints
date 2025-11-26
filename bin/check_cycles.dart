#!/usr/bin/env dart

/// CLI tool to detect transitive circular dependencies between barrel files
///
/// Usage:
///   dart run barrel_file_lints:check_cycles [--lib-dir=lib]
///
/// This tool performs a full analysis of all barrel files in your project
/// and detects any circular dependencies, including transitive cycles like:
///   feature_a → feature_b → feature_c → feature_a
///
/// Exit codes:
///   0 - No cycles found
///   1 - Cycles detected
///   2 - Error during analysis
library;

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'lib-dir',
      abbr: 'l',
      defaultsTo: 'lib',
      help: 'Path to the lib directory to analyze',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      defaultsTo: false,
      help: 'Show verbose output',
    )
    ..addFlag('help', abbr: 'h', help: 'Show this help message');

  final results = parser.parse(arguments);

  if (results['help'] as bool) {
    print('Barrel File Cycle Detector\n');
    print('Detects circular dependencies between barrel files.\n');
    print('Usage: dart run barrel_file_lints:check_cycles [options]\n');
    print(parser.usage);
    exit(0);
  }

  final libDir = results['lib-dir'] as String;
  final verbose = results['verbose'] as bool;

  if (verbose) {
    print('Analyzing barrel files in: $libDir');
  }

  final detector = CycleDetector(libDir, verbose: verbose);
  final cycles = await detector.detectCycles();

  if (cycles.isEmpty) {
    print('✅ No circular dependencies found!');
    exit(0);
  }

  print(
    '❌ Found ${cycles.length} circular ${cycles.length == 1 ? 'dependency' : 'dependencies'}:\n',
  );

  for (var i = 0; i < cycles.length; i++) {
    final cycle = cycles[i];
    print('Cycle ${i + 1}:');
    for (var j = 0; j < cycle.length; j++) {
      print('  ${cycle[j]}');
      if (j < cycle.length - 1) {
        print('    ↓ exports');
      } else {
        print('    ↓ exports back to ${cycle[0]}');
      }
    }
    print('');
  }

  exit(1);
}

class CycleDetector {
  CycleDetector(this.libDir, {this.verbose = false});

  final String libDir;
  final bool verbose;

  // Map of barrel file path to list of barrel files it exports
  final Map<String, List<String>> _dependencyGraph = {};

  // Cache of barrel file paths by feature
  final Map<String, String> _barrelFilesByFeature = {};

  Future<List<List<String>>> detectCycles() async {
    // Step 1: Find all barrel files
    await _findBarrelFiles();

    if (verbose) {
      print('Found ${_barrelFilesByFeature.length} barrel files');
    }

    // Step 2: Build dependency graph
    await _buildDependencyGraph();

    if (verbose) {
      print('Built dependency graph with ${_dependencyGraph.length} nodes');
      for (final entry in _dependencyGraph.entries) {
        if (entry.value.isNotEmpty) {
          print(
            '  ${path.relative(entry.key, from: libDir)} → ${entry.value.map((v) => path.relative(v, from: libDir)).join(', ')}',
          );
        }
      }
    }

    // Step 3: Detect cycles using DFS
    final cycles = <List<String>>[];
    final visited = <String>{};

    for (final node in _dependencyGraph.keys) {
      if (!visited.contains(node)) {
        final cycle = _findCycleFromNode(node, visited);
        if (cycle != null) {
          cycles.add(cycle);
        }
      }
    }

    return cycles;
  }

  /// Find all barrel files in the lib directory
  Future<void> _findBarrelFiles() async {
    final libDirectory = Directory(libDir);
    if (!await libDirectory.exists()) {
      stderr.writeln('Error: Directory not found: $libDir');
      exit(2);
    }

    await for (final entity in libDirectory.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final relativePath = path.relative(entity.path, from: libDir);

        // Check if it matches barrel file pattern
        // feature_xxx/xxx.dart or features/xxx/xxx.dart
        final underscoreMatch = RegExp(
          r'feature_([^/]+)/\1\.dart$',
        ).firstMatch(relativePath);
        final slashMatch = RegExp(
          r'features/([^/]+)/\1\.dart$',
        ).firstMatch(relativePath);

        if (underscoreMatch != null) {
          final featureName = underscoreMatch.group(1)!;
          _barrelFilesByFeature['feature_$featureName'] = entity.path;
        } else if (slashMatch != null) {
          final featureName = slashMatch.group(1)!;
          _barrelFilesByFeature['features/$featureName'] = entity.path;
        }
      }
    }
  }

  /// Build the dependency graph by analyzing export directives
  Future<void> _buildDependencyGraph() async {
    for (final barrelPath in _barrelFilesByFeature.values) {
      final file = File(barrelPath);
      final content = await file.readAsString();

      final dependencies = <String>[];

      // Find all export directives
      final exportPattern = RegExp(
        r'''export\s+['"]([^'"]+)['"]''',
        multiLine: true,
      );

      for (final match in exportPattern.allMatches(content)) {
        final exportUri = match.group(1)!;

        // Check if this export points to another barrel
        final targetBarrel = _resolveToBarrelFile(barrelPath, exportUri);
        if (targetBarrel != null && targetBarrel != barrelPath) {
          dependencies.add(targetBarrel);
        }
      }

      _dependencyGraph[barrelPath] = dependencies;
    }
  }

  /// Resolve an export URI to a barrel file path (if it is one)
  String? _resolveToBarrelFile(String currentFile, String exportUri) {
    // Handle package: URIs
    if (exportUri.startsWith('package:')) {
      // Extract relative path after package name
      final match = RegExp(r'package:[^/]+/(.+)').firstMatch(exportUri);
      if (match == null) return null;

      final relativePath = match.group(1)!;

      // Check if it matches a known barrel
      for (final entry in _barrelFilesByFeature.entries) {
        final featureDir = entry.key;
        final barrelPath = entry.value;
        final relativeBarrel = path.relative(barrelPath, from: libDir);

        if (relativePath == relativeBarrel ||
            relativePath.startsWith('$featureDir/') &&
                relativePath.endsWith('/${featureDir.split('/').last}.dart')) {
          return barrelPath;
        }
      }
    } else if (exportUri.startsWith('../') || exportUri.startsWith('./')) {
      // Handle relative imports
      final currentDir = path.dirname(currentFile);
      final resolvedPath = path.normalize(path.join(currentDir, exportUri));

      // Check if resolved path is a barrel file
      if (_barrelFilesByFeature.values.contains(resolvedPath)) {
        return resolvedPath;
      }
    }

    return null;
  }

  /// Find a cycle starting from the given node using DFS
  List<String>? _findCycleFromNode(String start, Set<String> globalVisited) {
    final stack = <String>[];
    final recursionStack = <String>{};

    bool dfs(String node) {
      globalVisited.add(node);
      stack.add(node);
      recursionStack.add(node);

      for (final neighbor in _dependencyGraph[node] ?? <String>[]) {
        if (!globalVisited.contains(neighbor)) {
          if (dfs(neighbor)) {
            return true;
          }
        } else if (recursionStack.contains(neighbor)) {
          // Found a cycle! Extract it from the stack
          final cycleStart = stack.indexOf(neighbor);
          final cycle = stack.sublist(cycleStart);
          cycle.add(neighbor); // Complete the cycle

          // Convert paths to relative for display
          return true;
        }
      }

      stack.removeLast();
      recursionStack.remove(node);
      return false;
    }

    if (dfs(start)) {
      // Convert absolute paths to relative for display
      return stack.map((p) => path.relative(p, from: libDir)).toList();
    }

    return null;
  }
}
