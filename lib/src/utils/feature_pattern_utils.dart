/// Utilities for parsing and matching feature patterns.
library;

/// Represents a parsed feature path with extracted metadata.
///
/// Contains information about the feature directory structure and naming style,
/// including the full directory path, the feature name, and the architectural
/// style (underscore or slash convention).
class FeatureMatch {
  /// Creates a feature match.
  FeatureMatch({
    required this.featureDir,
    required this.featureName,
    required this.style,
  });

  /// The full feature directory path (e.g., 'feature_auth' or 'features/auth').
  final String featureDir;

  /// The extracted feature name without prefix (e.g., 'auth').
  final String featureName;

  /// The architectural style: 'underscore' for `feature_xxx`, 'slash' for `features/xxx`.
  final String style;
}

/// Represents the architectural layer of a file or barrel.
///
/// Based on Clean Architecture principles with dependency direction: UI → Data → Domain.
enum ArchLayer {
  /// Data layer - repositories, data sources, infrastructure implementations.
  data,

  /// Domain layer - entities, use cases, business logic (innermost/core).
  domain,

  /// UI/Presentation layer - widgets, screens, state management (outermost).
  ui,

  /// Unknown or mixed layer - cannot be determined from path.
  unknown,
}

/// Represents a barrel file type.
///
/// Barrels can be monolithic (export all layers) or split by architectural layer.
enum BarrelType {
  /// Monolithic barrel (e.g., `auth.dart`) - exports all layers.
  monolithic,

  /// Split data barrel (e.g., `auth_data.dart` or `auth_infrastructure.dart`).
  splitData,

  /// Split domain barrel (e.g., `auth_domain.dart`).
  splitDomain,

  /// Split UI barrel (e.g., `auth_ui.dart` or `auth_presentation.dart`).
  splitUi,

  /// Not a barrel file - internal implementation file.
  notBarrel,
}

// Pre-compiled regex patterns for performance optimization
// These are computed once at load time instead of on every function call
final _underscorePattern = RegExp(r'feature_([^/]+)');
final _slashPattern = RegExp(r'features/([^/]+)');
final _exportPattern = RegExp(
  r'''export\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// Extracts feature information from a file path or URI.
///
/// Supports both common feature directory patterns: `feature_xxx/` (underscore
/// style) and `features/xxx/` (clean architecture style). Returns `null` if no
/// feature pattern is found.
FeatureMatch? extractFeature(String path) {
  // Try underscore style first: feature_xxx
  final underscoreMatch = _underscorePattern.firstMatch(path);
  if (underscoreMatch != null) {
    final name = underscoreMatch.group(1)!;
    return FeatureMatch(
      featureDir: 'feature_$name',
      featureName: name,
      style: 'underscore',
    );
  }

  // Try clean architecture style: features/xxx
  final slashMatch = _slashPattern.firstMatch(path);
  if (slashMatch != null) {
    final name = slashMatch.group(1)!;
    return FeatureMatch(
      featureDir: 'features/$name',
      featureName: name,
      style: 'slash',
    );
  }

  return null;
}

/// Whether [path] contains any recognized feature pattern.
bool containsFeaturePattern(String path) =>
    path.contains('feature_') || path.contains('features/');

/// Whether [path] is a test file.
///
/// Recognizes standard Dart/Flutter test locations and naming conventions.
bool isTestFile(String path) =>
    path.contains('/test/') ||
    path.contains('/test_driver/') ||
    path.contains('/integration_test/') ||
    path.endsWith('_test.dart');

/// Whether [uri] points to internal feature implementation files.
///
/// Internal files are subdirectories within a feature (like `/data/`, `/ui/`,
/// `/domain/`) that should not be imported directly from other features. Use
/// barrel files instead.
bool isInternalImport(String uri) =>
    uri.contains('/data/') ||
    uri.contains('/ui/') ||
    uri.contains('/models/') ||
    uri.contains('/exceptions/') ||
    uri.contains('/extensions/') ||
    uri.contains('/domain/') ||
    uri.contains('/presentation/') ||
    uri.contains('/application/') ||
    uri.contains('/infrastructure/') ||
    uri.contains('/services/') ||
    uri.contains('/repositories/') ||
    uri.contains('/providers/') ||
    uri.contains('/bloc/') ||
    uri.contains('/cubit/') ||
    uri.contains('/notifiers/') ||
    uri.contains('/widgets/') ||
    uri.contains('/utils/') ||
    uri.contains('/config/') ||
    uri.contains('/helpers/');

/// Whether [path] is a monolithic barrel file for the given [feature].
///
/// Barrel files must be at the feature root and named after the feature,
/// such as `feature_auth/auth.dart`. This function does not check for split
/// barrels like `auth_data.dart` or `auth_domain.dart`.
bool isBarrelFile(String path, FeatureMatch feature) {
  // Extract the file name from the path
  final segments = path.split('/');
  final fileName = segments.isNotEmpty ? segments.last : '';

  // Check if filename matches feature name
  if (fileName != '${feature.featureName}.dart') return false;

  // Check if it's at the feature root (not in a subdirectory)
  // For underscore style: should be like .../feature_auth/auth.dart
  // For slash style: should be like .../features/auth/auth.dart
  final pattern = RegExp('${feature.featureDir}/${feature.featureName}\\.dart');
  return pattern.hasMatch(path);
}

/// Whether [uri] is a relative import (starts with `./` or `../`).
bool isRelativeUri(String uri) => uri.startsWith('./') || uri.startsWith('../');

/// Whether [uri] navigates up and out of the current directory.
///
/// Any `../` in the path means we're going up the directory tree.
bool escapesFeatureFolder(String uri) => uri.contains('../');

/// Returns the preferred barrel filename for a given layer.
///
/// This is the canonical naming used by quick fixes and suggestions. While
/// alternative patterns like `_infrastructure` and `_presentation` are
/// recognized via [isBarrelFileName] and [getBarrelType], this function
/// returns the preferred standard naming convention for consistency.
///
/// Examples:
/// ```dart
/// getBarrelFileName('auth', ArchLayer.data) // => 'auth_data.dart'
/// getBarrelFileName('auth', ArchLayer.domain) // => 'auth_domain.dart'
/// getBarrelFileName('auth', ArchLayer.ui) // => 'auth_ui.dart'
/// getBarrelFileName('auth', ArchLayer.unknown) // => 'auth.dart' (monolithic)
/// ```
String getBarrelFileName(String featureName, ArchLayer layer) {
  // Return the canonical/preferred naming convention for each layer
  // While we recognize alternatives (_infrastructure, _presentation),
  // we recommend these standard suffixes for consistency
  switch (layer) {
    case ArchLayer.data:
      return '${featureName}_data.dart';
    case ArchLayer.domain:
      return '${featureName}_domain.dart';
    case ArchLayer.ui:
      return '${featureName}_ui.dart';
    case ArchLayer.unknown:
      return '$featureName.dart'; // Default to monolithic barrel
  }
}

/// Whether [fileName] matches a barrel pattern for the given [featureName] and [layer].
///
/// Recognizes both standard patterns (`_data`, `_domain`, `_ui`) and
/// alternatives (`_infrastructure`, `_presentation`). When [layer] is `null`,
/// checks if the filename matches any barrel pattern. When [layer] is
/// specified, checks for that specific layer.
///
/// Examples:
///
/// ```dart
/// isBarrelFileName('auth.dart', 'auth') // => true (monolithic)
/// isBarrelFileName('auth_data.dart', 'auth', ArchLayer.data) // => true
/// isBarrelFileName('auth_infrastructure.dart', 'auth', ArchLayer.data) // => true
/// isBarrelFileName('auth_domain.dart', 'auth', ArchLayer.data) // => false
/// ```
bool isBarrelFileName(String fileName, String featureName, [ArchLayer? layer]) {
  // Check monolithic barrel
  if (fileName == '$featureName.dart') {
    return true;
  }

  // If no specific layer, check if it matches any split barrel pattern
  if (layer == null) {
    return fileName == '${featureName}_data.dart' ||
        fileName == '${featureName}_domain.dart' ||
        fileName == '${featureName}_ui.dart' ||
        fileName == '${featureName}_presentation.dart' ||
        fileName == '${featureName}_infrastructure.dart';
  }

  // Check if it matches the specific layer's barrel pattern
  switch (layer) {
    case ArchLayer.data:
      return fileName == '${featureName}_data.dart' ||
          fileName == '${featureName}_infrastructure.dart';
    case ArchLayer.domain:
      return fileName == '${featureName}_domain.dart';
    case ArchLayer.ui:
      return fileName == '${featureName}_ui.dart' ||
          fileName == '${featureName}_presentation.dart';
    case ArchLayer.unknown:
      return false;
  }
}

/// Determines the barrel type from a file path.
///
/// Returns [BarrelType.notBarrel] if the file is not a barrel or not at the
/// feature root. Recognizes both standard and alternative naming patterns for
/// split barrels.
BarrelType getBarrelType(String path, FeatureMatch feature) {
  final segments = path.split('/');
  final fileName = segments.isNotEmpty ? segments.last : '';

  // Check if it's at the feature root
  final atFeatureRootPattern = RegExp('${feature.featureDir}/[^/]+\\.dart');
  if (!atFeatureRootPattern.hasMatch(path)) return BarrelType.notBarrel;

  // Check for split barrel patterns
  if (fileName == '${feature.featureName}_data.dart' ||
      fileName == '${feature.featureName}_infrastructure.dart') {
    return BarrelType.splitData;
  }
  if (fileName == '${feature.featureName}_domain.dart') {
    return BarrelType.splitDomain;
  }
  if (fileName == '${feature.featureName}_ui.dart' ||
      fileName == '${feature.featureName}_presentation.dart') {
    return BarrelType.splitUi;
  }

  // Check for monolithic barrel
  if (fileName == '${feature.featureName}.dart') {
    return BarrelType.monolithic;
  }

  return BarrelType.notBarrel;
}

/// Determines the architectural layer from a file path.
///
/// Analyzes the directory structure to identify which layer a file belongs to
/// based on path segments like `/data/`, `/domain/`, or `/ui/`. Returns
/// [ArchLayer.unknown] if the layer cannot be determined.
ArchLayer getLayerFromPath(String path) {
  // Data layer indicators
  if (path.contains('/data/') ||
      path.contains('/repositories/') ||
      path.contains('/datasources/') ||
      path.contains('/infrastructure/')) {
    return ArchLayer.data;
  }

  // Domain layer indicators
  if (path.contains('/domain/') ||
      path.contains('/entities/') ||
      path.contains('/usecases/') ||
      path.contains('/use_cases/')) {
    return ArchLayer.domain;
  }

  // UI/Presentation layer indicators
  if (path.contains('/ui/') ||
      path.contains('/presentation/') ||
      path.contains('/screens/') ||
      path.contains('/pages/') ||
      path.contains('/widgets/') ||
      path.contains('/views/') ||
      path.contains('/bloc/') ||
      path.contains('/cubit/') ||
      path.contains('/notifiers/') ||
      path.contains('/providers/')) {
    return ArchLayer.ui;
  }

  return ArchLayer.unknown;
}

/// Analyzes which layers a barrel file exports by parsing its export statements.
///
/// Examines export directives to determine which architectural layers are
/// included. Returns a set of detected layers, which may be empty if no
/// recognizable layers are found.
Future<Set<ArchLayer>> analyzeBarrelExports(String barrelContent) async {
  final layers = <ArchLayer>{};

  for (final match in _exportPattern.allMatches(barrelContent)) {
    final exportPath = match.group(1);
    if (exportPath != null) {
      final layer = getLayerFromPath(exportPath);
      if (layer != ArchLayer.unknown) {
        layers.add(layer);
      }
    }
  }

  return layers;
}

/// Whether an import from [from] layer to [to] layer is allowed.
///
/// Based on Clean Architecture principles with dependency direction:
/// UI → Data → Domain. The UI layer (outermost) can import Domain and Data.
/// The Data layer (middle) can import Domain but not UI. The Domain layer
/// (innermost) cannot import Data or UI. Unknown layers have no restrictions.
bool isLayerImportAllowed(ArchLayer from, ArchLayer to) {
  switch (from) {
    case ArchLayer.domain:
      // Domain is innermost - CANNOT import Data or UI
      return to == ArchLayer.domain || to == ArchLayer.unknown;
    case ArchLayer.data:
      // Data can import Domain (implements domain interfaces)
      return to == ArchLayer.domain ||
          to == ArchLayer.data ||
          to == ArchLayer.unknown;
    case ArchLayer.ui:
      // UI can import anything (outermost layer)
      return true;
    case ArchLayer.unknown:
      // Unknown layers have no restrictions
      return true;
  }
}
