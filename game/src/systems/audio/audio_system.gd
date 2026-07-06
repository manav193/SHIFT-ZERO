## AudioSystem
##
## Autoload that turns gameplay events into short SFX. Streams are procedurally
## generated at boot (no asset files shipped) -- sine bursts for flip / land /
## modifier / start, decaying sweep for death.
##
## Design: pooled AudioStreamPlayers to allow overlapping cues without
## popping. Adding real .ogg cues later = swap `_streams["<cue>"]`.
extends Node

const Events := preload("res://src/core/events.gd")

const _POOL_SIZE := 8

var _players: Array[AudioStreamPlayer] = []
var _next_idx: int = 0
var _streams: Dictionary = {}   # cue_id (String) -> AudioStreamWAV
var _ambient_a: AudioStreamPlayer
var _ambient_b: AudioStreamPlayer
var _ambient_use_a: bool = true


func _ready() -> void:
    _generate_streams()
    _create_pool()
    _create_ambient_players()
    EventBus.subscribe(Events.PLAYER_GRAVITY_FLIPPED, _on_flip)
    EventBus.subscribe(Events.PLAYER_LANDED, _on_landed)
    EventBus.subscribe(Events.RUN_STARTED, _on_run_started)
    EventBus.subscribe(Events.RUN_FINISHED, _on_run_finished)
    EventBus.subscribe(Events.MODIFIER_ACTIVATED, _on_modifier_activated)
    EventBus.subscribe(Events.MODIFIER_EXPIRED, _on_modifier_expired)
    EventBus.subscribe(Events.COIN_COLLECTED, _on_coin_collected)
    EventBus.subscribe(Events.POWERUP_ACTIVATED, _on_powerup_activated)
    EventBus.subscribe(Events.RUN_LEVEL_CHANGED, _on_run_level_changed)
    EventBus.subscribe(Events.WORLD_THEME_CHANGED, _on_world_theme_changed)
    EventBus.subscribe(Events.BOSS_WARNING, _on_boss_warning)
    EventBus.subscribe(Events.BOSS_STARTED, _on_boss_started)
    EventBus.subscribe(Events.BOSS_DEFEATED, _on_boss_defeated)
    print("Audio", "audio system ready (%d cues, pool=%d)" % [_streams.size(), _POOL_SIZE])


func play(cue: String, volume_db: float = 0.0) -> void:
    if not _streams.has(cue):
        return
    var p: AudioStreamPlayer = _players[_next_idx]
    _next_idx = (_next_idx + 1) % _players.size()
    p.stream = _streams[cue]
    p.volume_db = volume_db
    p.play()


func _on_flip(_p: Dictionary) -> void:
    play("flip", -6.0)


func _on_landed(_p: Dictionary) -> void:
    play("land", -10.0)


func _on_run_started(_p: Dictionary) -> void:
    play("start", -3.0)


func _on_run_finished(_p: Dictionary) -> void:
    play("death", 0.0)


func _on_modifier_activated(_p: Dictionary) -> void:
    play("mod_on", -4.0)


func _on_modifier_expired(_p: Dictionary) -> void:
    play("mod_off", -6.0)


func _on_coin_collected(_p: Dictionary) -> void:
    play("coin", -8.0)


func _on_powerup_activated(_p: Dictionary) -> void:
    play("powerup", -4.0)


func _on_run_level_changed(_p: Dictionary) -> void:
    play("level", -7.0)


func _on_world_theme_changed(payload: Dictionary) -> void:
    if not bool(payload.get("instant", false)):
        play("theme", -9.0)
    var theme: Dictionary = payload.get("theme", {})
    _crossfade_ambient(str(theme.get("id", "neon_city")))


func _on_boss_warning(_payload: Dictionary) -> void:
    play("boss_warn", -5.0)


func _on_boss_started(_payload: Dictionary) -> void:
    play("boss_start", -5.0)


func _on_boss_defeated(_payload: Dictionary) -> void:
    play("boss_win", -4.0)


func _create_pool() -> void:
    for i in _POOL_SIZE:
        var p := AudioStreamPlayer.new()
        add_child(p)
        _players.append(p)


func _create_ambient_players() -> void:
    _ambient_a = AudioStreamPlayer.new()
    _ambient_b = AudioStreamPlayer.new()
    add_child(_ambient_a)
    add_child(_ambient_b)
    _ambient_a.volume_db = -80.0
    _ambient_b.volume_db = -80.0


func _crossfade_ambient(theme_id: String) -> void:
    var next := _ambient_a if _ambient_use_a else _ambient_b
    var prev := _ambient_b if _ambient_use_a else _ambient_a
    _ambient_use_a = not _ambient_use_a
    next.stream = _ambient_for_theme(theme_id)
    if next.stream == null:
        return
    next.volume_db = -80.0
    next.play()
    var tween := create_tween()
    tween.tween_property(next, "volume_db", -26.0, 0.9)
    tween.parallel().tween_property(prev, "volume_db", -80.0, 0.9)
    tween.tween_callback(func() -> void:
        if prev.playing:
            prev.stop())


func _generate_streams() -> void:
    _streams["flip"] = _sine(880.0, 0.08)
    _streams["land"] = _sine(320.0, 0.10)
    _streams["start"] = _sine(660.0, 0.18)
    _streams["death"] = _sweep(220.0, 55.0, 0.55)
    _streams["mod_on"] = _sweep(440.0, 990.0, 0.22)
    _streams["mod_off"] = _sweep(720.0, 240.0, 0.20)
    _streams["coin"] = _sine(1320.0, 0.06)
    _streams["powerup"] = _sweep(520.0, 1180.0, 0.28)
    _streams["level"] = _sweep(360.0, 760.0, 0.18)
    _streams["theme"] = _sweep(260.0, 920.0, 0.32)
    _streams["boss_warn"] = _sweep(180.0, 90.0, 0.34)
    _streams["boss_start"] = _sweep(220.0, 620.0, 0.42)
    _streams["boss_win"] = _sweep(420.0, 1200.0, 0.5)


func _ambient_for_theme(theme_id: String) -> AudioStreamWAV:
    var stream: AudioStreamWAV
    match theme_id:
        "desert":
            stream = _sine(146.0, 1.1)
        "snow":
            stream = _sine(224.0, 1.1)
        "forest":
            stream = _sine(196.0, 1.1)
        "volcano":
            stream = _sine(92.0, 1.1)
        "space":
            stream = _sine(132.0, 1.1)
        "cyber_grid":
            stream = _sine(330.0, 1.1)
        "ancient_temple":
            stream = _sine(164.0, 1.1)
        _:
            stream = _sine(275.0, 1.1)
    stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
    stream.loop_end = int(stream.data.size() / 2)
    return stream


func _sine(freq: float, dur: float) -> AudioStreamWAV:
    var sr := 22050
    var n: int = int(sr * dur)
    var data := PackedByteArray()
    data.resize(n * 2)
    for i in n:
        var t: float = float(i) / sr
        var env: float = maxf(0.0, 1.0 - t / dur)
        var s: float = sin(TAU * freq * t) * env * 0.4
        var s16: int = clampi(int(s * 32767.0), -32768, 32767)
        data[i * 2] = s16 & 0xff
        data[i * 2 + 1] = (s16 >> 8) & 0xff
    return _wav_from_bytes(data, sr)


func _sweep(f_start: float, f_end: float, dur: float) -> AudioStreamWAV:
    var sr := 22050
    var n: int = int(sr * dur)
    var data := PackedByteArray()
    data.resize(n * 2)
    var phase: float = 0.0
    for i in n:
        var t: float = float(i) / sr
        var alpha: float = t / dur
        var f: float = lerp(f_start, f_end, alpha)
        phase += TAU * f / float(sr)
        var env: float = 1.0 - alpha
        var s: float = sin(phase) * env * 0.5
        var s16: int = clampi(int(s * 32767.0), -32768, 32767)
        data[i * 2] = s16 & 0xff
        data[i * 2 + 1] = (s16 >> 8) & 0xff
    return _wav_from_bytes(data, sr)


func _wav_from_bytes(data: PackedByteArray, sr: int) -> AudioStreamWAV:
    var w := AudioStreamWAV.new()
    w.data = data
    w.format = AudioStreamWAV.FORMAT_16_BITS
    w.mix_rate = sr
    w.stereo = false
    return w
