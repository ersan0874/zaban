/// Dynamic app icon after absence (Phase 13 soft requirement).
///
/// Most platforms do not support changing the icon at runtime without
/// platform-specific plugins (iOS: limited; Android: activity-alias).
/// Re-entry UX uses the diagnostic banner instead.
class DynamicAppIcon {
  static Future<void> setAbsenteeIcon({required bool absent}) async {
    // Stub — no-op until a supported plugin is added.
  }
}
