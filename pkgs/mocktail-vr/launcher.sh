#!@bash@
set -euo pipefail
export MOCKTAIL_CONFIG_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}/mocktail-vr"
export MOCKTAIL_CONFIG_FILE="$MOCKTAIL_CONFIG_ROOT/config.yaml"
export MOCKTAIL_DATA_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/mocktail-vr"
export MOCKTAIL_CACHE_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/mocktail-vr"
export MOCKTAIL_STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/mocktail-vr"
export MOCKTAIL_AUTH_ROOT="$MOCKTAIL_DATA_ROOT/auth"
export MOCKTAIL_USE_REAL_SOBER_PATHS=0
export MOCKTAIL_WIN_TITLE="Mocktail VR"
export MOCKTAIL_VR_RUNTIME=wivrn
export XR_RUNTIME_JSON=/run/current-system/sw/share/openxr/1/openxr_wivrn.json

if [[ "${1:-}" == --help || "${1:-}" == -h ]]; then
  exec @out@/lib/mocktail/mocktail --vr "$@"
fi
mkdir -p "$MOCKTAIL_CONFIG_ROOT" "$MOCKTAIL_DATA_ROOT" \
  "$MOCKTAIL_CACHE_ROOT" "$MOCKTAIL_STATE_ROOT" "$MOCKTAIL_AUTH_ROOT"
exec >> "$MOCKTAIL_STATE_ROOT/launcher.log" 2>&1
if [[ ! -S "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/wivrn/comp_ipc" ]]; then
  exec @out@/lib/mocktail/mocktail_failure_dialog --message \
    "Connect your headset to WiVRn, then open Mocktail VR again."
fi
exec @out@/lib/mocktail/mocktail --vr "$@"
