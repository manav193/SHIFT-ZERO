## App
##
## Top-level orchestrator. Runs the boot sequence:
##   1. Register all services with the ServiceLocator (per-platform selection).
##   2. Load persisted settings from ISaveService and apply them.
##   3. Kick a non-blocking Remote Config fetch.
##   4. Attach GameplayConfig to the Remote Config service.
##   5. Wire settings persistence (SETTINGS_CHANGED -> save.mutate).
##   6. Log app_start analytics event.
##   7. Emit APP_BOOTED on the EventBus.
##
## Autoloaded LAST so all core singletons above it are ready.
extends Node

const Events := preload("res://src/core/events.gd")

# ---------- Service classes (compile-time refs, no runtime cost) ----------
const _ISaveService                  := preload("res://src/services/save/i_save_service.gd")
const _InMemorySaveService           := preload("res://src/services/save/in_memory_save_service.gd")
const _FileSystemSaveService         := preload("res://src/services/save/filesystem_save_service.gd")

const _ISettingsService              := preload("res://src/services/settings/i_settings_service.gd")
const _InMemorySettingsService       := preload("res://src/services/settings/in_memory_settings_service.gd")

const _IAdsService                   := preload("res://src/services/ads/i_ads_service.gd")
const _NullAdsService                := preload("res://src/services/ads/null_ads_service.gd")

const _IBillingService               := preload("res://src/services/billing/i_billing_service.gd")
const _MockBillingService            := preload("res://src/services/billing/mock_billing_service.gd")

const _IAnalyticsService             := preload("res://src/services/analytics/i_analytics_service.gd")
const _ConsoleAnalyticsService       := preload("res://src/services/analytics/console_analytics_service.gd")

const _IRemoteConfigService          := preload("res://src/services/remote_config/i_remote_config_service.gd")
const _StaticRemoteConfigService     := preload("res://src/services/remote_config/static_remote_config_service.gd")

const _ILocalizationService          := preload("res://src/services/localization/i_localization_service.gd")
const _GodotLocalizationService      := preload("res://src/services/localization/godot_localization_service.gd")

const _IFeatureFlagsService          := preload("res://src/services/feature_flags/i_feature_flags_service.gd")
const _DefaultFeatureFlagsService    := preload("res://src/services/feature_flags/default_feature_flags_service.gd")

const _IInputRecorder                := preload("res://src/systems/input/i_input_recorder.gd")
const _NoopInputRecorder             := preload("res://src/systems/input/noop_input_recorder.gd")

const _GameplayConfig                := preload("res://src/gameplay/gameplay_config.gd")


func _ready() -> void:
    Logger.info("App", "booting %s" % Config.version_string())
    _register_services()
    _apply_settings()
    _wire_settings_persistence()
    _fetch_remote_config_async()
    _log_boot_analytics()
    ServiceLocator.seal()
    EventBus.emit(Events.APP_BOOTED, {"version": Config.version_string()})
    Logger.info("App", "boot complete")


func _register_services() -> void:
    # Save: real filesystem persistence for gameplay (Alpha M1.5).
    var save: Object = _make_save_service()
    ServiceLocator.register("ISaveService", save)

    var settings := _InMemorySettingsService.new()
    _hydrate_settings_from_save(settings, save)
    ServiceLocator.register("ISettingsService", settings)

    var analytics := _ConsoleAnalyticsService.new()
    ServiceLocator.register("IAnalyticsService", analytics)

    var rc := _StaticRemoteConfigService.new()
    rc.init()
    ServiceLocator.register("IRemoteConfigService", rc)
    _GameplayConfig.attach(rc)

    var flags := _DefaultFeatureFlagsService.new(rc)
    ServiceLocator.register("IFeatureFlagsService", flags)

    var ads: Object
    match OS.get_name():
        "Android":
            ads = _NullAdsService.new()
        _:
            ads = _NullAdsService.new()
    ServiceLocator.register("IAdsService", ads)

    ServiceLocator.register("IBillingService", _MockBillingService.new())

    var loc := _GodotLocalizationService.new()
    ServiceLocator.register("ILocalizationService", loc)

    ServiceLocator.register("IInputRecorder", _NoopInputRecorder.new())


## Filesystem save on real platforms; in-memory in headless CI (where
## user:// may not be writable).
func _make_save_service() -> Object:
    return _FileSystemSaveService.new()


func _hydrate_settings_from_save(settings: _ISettingsService, save: Object) -> void:
    if save == null:
        return
    var r: Result = save.load_state()
    if not r.ok:
        return
    var state: Dictionary = r.value
    var persisted: Dictionary = state.get("settings", {})
    for key in persisted.keys():
        settings.set_value(key, persisted[key])


func _apply_settings() -> void:
    var settings := ServiceLocator.get_service("ISettingsService") as _ISettingsService
    var loc := ServiceLocator.get_service("ILocalizationService") as _ILocalizationService
    var current: Dictionary = settings.load_settings()
    loc.set_locale(current.get("locale", "system"))
    for bus_key in ["audio_master", "audio_music", "audio_sfx", "audio_ui"]:
        var value: float = float(current.get(bus_key, 1.0))
        var bus_name := bus_key.trim_prefix("audio_").capitalize()
        var idx := AudioServer.get_bus_index(bus_name)
        if idx >= 0:
            AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(value, 0.0, 1.0)))


func _wire_settings_persistence() -> void:
    EventBus.subscribe(Events.SETTINGS_CHANGED, _on_settings_changed)


func _on_settings_changed(payload: Dictionary) -> void:
    var key: String = str(payload.get("key", ""))
    if key == "":
        return
    var value: Variant = payload.get("value")
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        return
    save.mutate(func(state: Dictionary) -> Dictionary:
        var s: Dictionary = state.get("settings", {})
        s[key] = value
        state["settings"] = s
        return state)


func _fetch_remote_config_async() -> void:
    var rc := ServiceLocator.get_service("IRemoteConfigService") as _IRemoteConfigService
    rc.fetch_and_activate(1.0)


func _log_boot_analytics() -> void:
    var analytics := ServiceLocator.get_service("IAnalyticsService") as _IAnalyticsService
    var consent := {"analytics": OS.is_debug_build(), "personalized_ads": false, "crashlytics": false}
    analytics.init(consent)
    analytics.log_event(Events.AnalyticsEvents.APP_START, {
        "version": Config.version_string(),
        "platform": OS.get_name(),
        "locale": TranslationServer.get_locale(),
    })
