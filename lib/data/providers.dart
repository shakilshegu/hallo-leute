import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';
import 'home_data.dart';

/// The app database. Overridden in `main()` (and in tests).
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

/// The current learner profile, or `null` before onboarding.
final profileProvider = FutureProvider<Profile?>(
  (ref) => ref.watch(databaseProvider).getProfile(),
);

/// Live data for the Home dashboard.
final homeDataProvider = StreamProvider.autoDispose<HomeData>(
  (ref) => ref.watch(databaseProvider).watchHomeData(),
);
