import 'package:flutter/foundation.dart';

/// Funnel events from the PRD. Each is sent with `day_number`.
enum AnalyticsEvent {
  onboardingCompleted('onboarding_completed'),
  reminderEnabled('reminder_enabled'),
  pieceStarted('piece_started'),
  pieceCompleted('piece_completed'),
  nightCompleted('night_completed'),
  streakBroken('streak_broken'),
  paywallShown('paywall_shown'),
  trialStarted('trial_started'),
  purchaseCompleted('purchase_completed'),
  // Stage 1 community: favourites and share cards.
  favoriteAdded('favorite_added'),
  favoriteRemoved('favorite_removed'),
  shareCardOpened('share_card_opened'),
  shareCardShared('share_card_shared');

  const AnalyticsEvent(this.name);
  final String name;
}

/// Analytics sink. The PostHog/Firebase choice is still open (PRD), so v0
/// ships a debug logger; swap in a real implementation behind this class.
abstract class Analytics {
  const Analytics();

  static const Analytics noop = _NoopAnalytics();

  void track(AnalyticsEvent event, {int? dayNumber, Map<String, Object?> props = const {}});
}

class _NoopAnalytics extends Analytics {
  const _NoopAnalytics();
  @override
  void track(AnalyticsEvent event, {int? dayNumber, Map<String, Object?> props = const {}}) {}
}

class DebugAnalytics extends Analytics {
  const DebugAnalytics();
  @override
  void track(AnalyticsEvent event, {int? dayNumber, Map<String, Object?> props = const {}}) {
    debugPrint('[analytics] ${event.name} day_number=$dayNumber ${props.isEmpty ? '' : props}');
  }
}
