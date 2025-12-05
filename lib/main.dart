/// Analysis Server plugin entry point for barrel file lints.
///
/// This file must exist with a top-level `plugin` variable per the
/// Analysis Server plugin specification. The server generates code that
/// imports this file and references the `plugin` variable to initialize
/// the plugin.
library;

import 'package:barrel_file_lints/barrel_file_lints.dart';

/// Top-level plugin variable that the Analysis Server looks for.
final plugin = BarrelFileLintPlugin();
