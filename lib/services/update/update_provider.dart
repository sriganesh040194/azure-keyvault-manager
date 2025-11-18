/// Riverpod providers for update service
library;

import 'package:riverpod/riverpod.dart';
import 'package:azure_key_vault_manager/services/update/update_service.dart';
import 'package:azure_key_vault_manager/services/update/update_storage.dart';
import 'package:azure_key_vault_manager/services/update/update_models.dart';
import 'package:azure_key_vault_manager/shared/constants/app_constants.dart';

/// Provider for UpdateStorage instance
final updateStorageProvider = Provider<UpdateStorage>((ref) {
  return UpdateStorage();
});

/// Provider for UpdateService instance
final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService(
    githubOwner: AppConstants.githubOwner,
    githubRepo: AppConstants.githubRepo,
  );
});

/// Provider for checking updates
/// This is a FutureProvider that automatically checks for updates when accessed
final updateCheckProvider = FutureProvider<UpdateCheckResult>((ref) async {
  final updateService = ref.watch(updateServiceProvider);
  final updateStorage = ref.watch(updateStorageProvider);

  // Perform the update check
  final result = await updateService.checkForUpdates();

  // Save the last check time
  await updateStorage.setLastCheckTime(DateTime.now());

  // If update is available, check if user has skipped this version
  if (result.updateAvailable && result.updateInfo != null) {
    final hasSkipped = await updateStorage.hasSkippedVersion(
      result.updateInfo!.version,
    );

    // If user has skipped this version, return no update
    if (hasSkipped) {
      return UpdateCheckResult.noUpdate(result.currentVersion);
    }
  }

  return result;
});

/// Provider for manual update check (for Settings button)
/// This is a StateNotifierProvider that allows triggering manual checks
final manualUpdateCheckProvider =
    StateNotifierProvider<ManualUpdateCheckNotifier, AsyncValue<UpdateCheckResult?>>(
  (ref) => ManualUpdateCheckNotifier(ref),
);

/// Notifier for manual update checks
class ManualUpdateCheckNotifier extends StateNotifier<AsyncValue<UpdateCheckResult?>> {
  final Ref _ref;

  ManualUpdateCheckNotifier(this._ref) : super(const AsyncValue.data(null));

  /// Manually trigger an update check
  Future<void> checkForUpdates({bool ignoreSkipped = false}) async {
    state = const AsyncValue.loading();

    try {
      final updateService = _ref.read(updateServiceProvider);
      final updateStorage = _ref.read(updateStorageProvider);

      final result = await updateService.checkForUpdates();

      // If ignoring skipped versions, clear the skipped version first
      if (ignoreSkipped) {
        await updateStorage.clearSkippedVersion();
      }

      // Check if user has skipped this version (unless ignoring)
      if (!ignoreSkipped &&
          result.updateAvailable &&
          result.updateInfo != null) {
        final hasSkipped = await updateStorage.hasSkippedVersion(
          result.updateInfo!.version,
        );

        if (hasSkipped) {
          state = AsyncValue.data(
            UpdateCheckResult.noUpdate(result.currentVersion),
          );
          return;
        }
      }

      state = AsyncValue.data(result);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Reset the state
  void reset() {
    state = const AsyncValue.data(null);
  }
}
