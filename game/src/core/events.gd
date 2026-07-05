## Events
##
## Central registry of ALL EventBus channel names and analytics event names.
## Referencing string literals directly is a lint violation — use the constants here.
extends Node

# ---------- App / lifecycle ----------
const APP_BOOTED            := "app/booted"
const APP_PAUSED            := "app/paused"
const APP_RESUMED           := "app/resumed"

# ---------- Input ----------
const INPUT_TAP             := "input/tap"
const INPUT_HOLD_BEGIN      := "input/hold_begin"
const INPUT_HOLD_END        := "input/hold_end"

# ---------- Run lifecycle ----------
const RUN_STARTED           := "run/started"
const RUN_FINISHED          := "run/finished"
const RUN_CONTINUE_GRANTED  := "run/continue_granted"
const RUN_PAUSED            := "run/paused"
const RUN_RESUMED           := "run/resumed"
const RUN_LEVEL_CHANGED     := "run/level_changed"

# ---------- Modifier ----------
const MODIFIER_ACTIVATED    := "modifier/activated"
const MODIFIER_EXPIRED      := "modifier/expired"

# ---------- Player ----------
const PLAYER_GRAVITY_FLIPPED := "player/gravity_flipped"
const PLAYER_LANDED          := "player/landed"

# ---------- Score ----------
const SCORE_UPDATED         := "score/updated"
const BEST_SCORE_CHANGED    := "score/best_changed"
const COIN_COLLECTED        := "score/coin_collected"
const PLAYER_LEVEL_UP       := "score/player_level_up"

# ---------- Save / entitlements ----------
const SAVE_PERSISTED        := "save/persisted"
const ENTITLEMENTS_CHANGED  := "entitlements/changed"

# ---------- Collectibles / powerups ----------
const POWERUP_COLLECTED     := "powerup/collected"
const POWERUP_ACTIVATED     := "powerup/activated"
const POWERUP_EXPIRED       := "powerup/expired"
const SHIELD_USED           := "powerup/shield_used"

# ---------- Settings / a11y ----------
const SETTINGS_CHANGED      := "settings/changed"
const A11Y_PALETTE_CHANGED  := "a11y/palette_changed"
const A11Y_VFX_LEVEL_CHANGED := "a11y/vfx_level_changed"
const A11Y_HAPTICS_CHANGED  := "a11y/haptics_changed"

# ---------- Remote config ----------
const REMOTE_CONFIG_ACTIVATED := "remote_config/activated"


# ---------- Analytics event names ----------
# Keep these stable — dashboards depend on them.
class AnalyticsEvents:
    const APP_START           := "app_start"
    const RUN_STARTED         := "run_started"
    const RUN_ENDED           := "run_ended"
    const MODIFIER_ACTIVATED  := "modifier_activated"
    const PLAYER_DIED         := "player_died"
    const AD_REQUESTED        := "ad_requested"
    const AD_SHOWN            := "ad_shown"
    const AD_REWARD_GRANTED   := "ad_reward_granted"
    const IAP_IMPRESSION      := "iap_impression"
    const IAP_PURCHASE_START  := "iap_purchase_start"
    const IAP_PURCHASE_SUCCESS := "iap_purchase_success"
    const IAP_PURCHASE_ERROR  := "iap_purchase_error"
    const COSMETIC_EQUIPPED   := "cosmetic_equipped"
    const SETTINGS_CHANGED    := "settings_changed"
    const DAILY_STARTED       := "daily_started"
    const DAILY_COMPLETED     := "daily_completed"
