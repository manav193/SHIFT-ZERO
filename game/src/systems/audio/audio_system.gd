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


func _ready() -> void:
    _generate_streams()
    _create_pool()
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


func _create_pool() -> void:
    for i in _POOL_SIZE:
        var p := AudioStreamPlayer.new()
        add_child(p)
        _players.append(p)


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
