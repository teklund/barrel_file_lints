# Example Usage

## 1. Add to your project

```yaml
# pubspec.yaml
dev_dependencies:
  barrel_file_lints: ^1.0.0
```

## 2. Configure analysis_options.yaml

```yaml
plugins:
  barrel_file_lints:
    diagnostics:
      avoid_internal_feature_imports: true
      avoid_core_importing_features: true
      avoid_self_barrel_import: true
      avoid_cross_feature_barrel_exports: true
      avoid_barrel_cycle: true
```

## 3. Example violations

### Bad: Internal feature import

```dart
// lib/feature_home/ui/home_page.dart

// ❌ This will trigger avoid_internal_feature_imports
import 'package:myapp/feature_auth/data/auth_service.dart';

class HomePage extends StatelessWidget {
  // ...
}
```

### Good: Barrel file import

```dart
// lib/feature_home/ui/home_page.dart

// ✅ Import via barrel file
import 'package:myapp/feature_auth/auth.dart';

class HomePage extends StatelessWidget {
  // ...
}
```

### Bad: Core importing feature

```dart
// lib/core/network/api_client.dart

// ❌ This will trigger avoid_core_importing_features
import 'package:myapp/feature_auth/auth.dart';

class ApiClient {
  // ...
}
```

### Bad: Importing own barrel

```dart
// lib/feature_auth/data/auth_service.dart

// ❌ This will trigger avoid_self_barrel_import
import 'package:myapp/feature_auth/auth.dart';

class AuthService {
  // ...
}
```

### Bad: Cross-feature barrel export

```dart
// lib/feature_auth/auth.dart (barrel file)

export 'data/auth_service.dart';

// ❌ This will trigger avoid_cross_feature_barrel_exports
export '../feature_profile/data/user.dart';
```

### Bad: Barrel cycle

```dart
// lib/feature_auth/auth.dart
// ❌ This will trigger avoid_barrel_cycle
export '../feature_profile/profile.dart';

// lib/feature_profile/profile.dart
// ❌ Creates a cycle back to auth
export '../feature_auth/auth.dart';
```

## 4. Run analysis

```bash
dart analyze
# or
flutter analyze
```
