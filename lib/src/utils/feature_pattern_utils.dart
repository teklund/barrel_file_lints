/// Utilities for parsing and matching feature patterns
library;

/// Represents a parsed feature path.
///
/// Contains the feature directory name, feature name, and architectural style.
class FeatureMatch {
  /// Creates a feature match with the given directory, name, and style.
  FeatureMatch({
    required this.featureDir,
    required this.featureName,
    required this.style,
  });

  /// The full feature directory name (e.g., 'feature_auth' or 'features/auth')
  final String featureDir;

  /// The short feature name (e.g., 'auth')
  final String featureName;

  /// The pattern style: 'underscore' for feature_xxx, 'slash' for features/xxx
  final String style;
}

/// Represents the architectural layer of a file or barrel
enum ArchLayer {
  /// Data layer (repositories, data sources)
  data,

  /// Domain layer (entities, use cases)
  domain,

  /// UI/Presentation layer (widgets, screens, blocs)
  ui,

  /// Unknown or mixed layer
  unknown,
}

/// Represents a barrel file type
enum BarrelType {
  /// Monolithic barrel (xxx.dart) - exports all layers
  monolithic,

  /// Split data barrel (xxx_data.dart)
  splitData,

  /// Split domain barrel (xxx_domain.dart)
  splitDomain,

  /// Split UI barrel (xxx_ui.dart)
  splitUi,

  /// Not a barrel file
  notBarrel,
}

/// Extract feature information from a path or URI
/// Supports both patterns:
/// - feature_xxx/ (underscore style)
/// - features/xxx/ (clean architecture style)
FeatureMatch? extractFeature(String path) {
  // Try underscore style first: feature_xxx
  final underscoreMatch = RegExp(r'feature_([^/]+)').firstMatch(path);
  if (underscoreMatch != null) {
    final name = underscoreMatch.group(1)!;
    return FeatureMatch(
      featureDir: 'feature_$name',
      featureName: name,
      style: 'underscore',
    );
  }

  // Try clean architecture style: features/xxx
  final slashMatch = RegExp(r'features/([^/]+)').firstMatch(path);
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

/// Check if a path/URI contains any feature pattern
bool containsFeaturePattern(String path) =>
    path.contains('feature_') || path.contains('features/');

/// Check if file is a test file
bool isTestFile(String path) =>
    path.contains('/test/') ||
    path.contains('/test_driver/') ||
    path.contains('/integration_test/') ||
    path.endsWith('_test.dart');

/// Check if import points to internal files (data/ or ui/ subdirectories)
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

/// Check if the current file is a barrel file
/// Barrel files are at the feature root and named after the feature
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

/// Check if URI is relative (starts with ./ or ../)
bool isRelativeUri(String uri) => uri.startsWith('./') || uri.startsWith('../');

/// Check if a relative URI escapes the feature folder using ../
bool escapesFeatureFolder(String uri) =>
    // Any ../ in the path means we're going up and out of the feature
    uri.contains('../');

/// Determine the barrel type from a file path
/// Returns the type of barrel file, or [BarrelType.notBarrel] if not a barrel
BarrelType getBarrelType(String path, FeatureMatch feature) {
  final segments = path.split('/');
  final fileName = segments.isNotEmpty ? segments.last : '';

  // Check if it's at the feature root
  final atFeatureRoot = RegExp(
    '${feature.featureDir}/[^/]+\\.dart',
  ).hasMatch(path);
  if (!atFeatureRoot) return BarrelType.notBarrel;

  // Check for split barrel patterns
  if (fileName == '${feature.featureName}_data.dart') {
    return BarrelType.splitData;
  }
  if (fileName == '${feature.featureName}_domain.dart') {
    return BarrelType.splitDomain;
  }
  if (fileName == '${feature.featureName}_ui.dart') {
    return BarrelType.splitUi;
  }

  // Check for monolithic barrel
  if (fileName == '${feature.featureName}.dart') {
    return BarrelType.monolithic;
  }

  return BarrelType.notBarrel;
}

/// Determine the architectural layer from a file path
/// Analyzes the directory structure to identify which layer a file belongs to
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

/// Analyze what layers a barrel file exports by examining its exports
/// This requires parsing the file to see what directories are exported
/// Returns a set of layers that the barrel exports
Future<Set<ArchLayer>> analyzeBarrelExports(String barrelContent) async {
  final layers = <ArchLayer>{};
  final exportPattern = RegExp(
    r'export\s+['
    "'"
    r'"]([^'
    "'"
    r'"]+)['
    "'"
    r'"]',
  );

  for (final match in exportPattern.allMatches(barrelContent)) {
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

/// Check if a layer is allowed to import from another layer
/// Based on clean architecture principles (dependency direction: UI→Data→Domain):
/// - UI can import Domain and Data (presentation layer uses everything)
/// - Data can import Domain (infrastructure implements domain interfaces)
/// - Domain cannot import Data or UI (core business logic is innermost layer)
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
