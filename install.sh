#!/usr/bin/env bash
# cpurr installer: copies the plugin into the local Noctalia plugin directory
# and fetches the Waycat pose font from its upstream repository.
set -euo pipefail

PLUGIN_ID="deoxizn/cpurr"
PLUGIN_NAME="${PLUGIN_ID##*/}"
FONT_URL="https://raw.githubusercontent.com/CarloCattano/waycat/main/fonts/Waycat.ttf"

usage() {
  cat <<'EOF'
Usage: install.sh [--uninstall]

Installs cpurr as a local Noctalia plugin under
  ~/.local/share/noctalia/plugins/cpurr/

Options:
  --uninstall   Disable and remove the plugin again
EOF
}

data_dir="${XDG_DATA_HOME:-$HOME/.local/share}"
plugin_dir="$data_dir/noctalia/plugins/$PLUGIN_NAME"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source_dir="$script_dir/$PLUGIN_NAME"

noctalia_running() {
  command -v noctalia >/dev/null 2>&1 && pgrep -x noctalia >/dev/null 2>&1
}

if [[ "${1:-}" == "--uninstall" ]]; then
  if [[ $# -gt 1 ]]; then
    usage
    exit 1
  fi
  if noctalia_running; then
    noctalia msg plugins disable "$PLUGIN_ID" || true
  fi
  rm -rf -- "$plugin_dir"
  echo "Removed $plugin_dir"
  echo "Note: if the cpurr widget is still placed on a bar, remove it there too."
  exit 0
fi

if [[ $# -gt 0 ]]; then
  usage
  exit 1
fi

if [[ ! -f "$source_dir/cpurr.luau" ]]; then
  echo "error: cpurr plugin files not found next to install.sh" >&2
  exit 1
fi

mkdir -p "$plugin_dir/fonts" "$plugin_dir/translations"
install -m 644 "$source_dir/plugin.toml" "$plugin_dir/plugin.toml"
install -m 644 "$source_dir/cpurr.luau" "$plugin_dir/cpurr.luau"
install -m 644 "$source_dir/translations/en.json" "$plugin_dir/translations/en.json"

if [[ -s "$source_dir/fonts/Waycat.ttf" ]]; then
  install -m 644 "$source_dir/fonts/Waycat.ttf" "$plugin_dir/fonts/Waycat.ttf"
elif [[ -s "$plugin_dir/fonts/Waycat.ttf" ]]; then
  echo "Font already present, keeping it."
else
  echo "Fetching Waycat.ttf from CarloCattano/waycat ..."
  curl -fsSL --retry 2 -o "$plugin_dir/fonts/Waycat.ttf" "$FONT_URL"
fi

echo
echo "Installed to $plugin_dir"
echo
echo "Next steps:"
echo "  1. Enable the plugin:  noctalia msg plugins enable $PLUGIN_ID"
echo "  2. Add the 'cpurr' widget to a bar (right-click the bar, or Settings -> Bar)."
