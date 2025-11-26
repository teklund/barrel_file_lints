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
  final pattern =
      RegExp('${feature.featureDir}/${feature.featureName}\\.dart');
  return pattern.hasMatch(path);
}

/// Check if URI is relative (starts with ./ or ../)
bool isRelativeUri(String uri) =>
    uri.startsWith('./') || uri.startsWith('../');

/// Check if a relative URI escapes the feature folder using ../
bool escapesFeatureFolder(String uri) =>
    // Any ../ in the path means we're going up and out of the feature
    uri.contains('../');
