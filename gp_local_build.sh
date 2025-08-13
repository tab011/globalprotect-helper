#!/usr/bin/env bash
set -euo pipefail
PORTAL="${1:-myvpn.uml.edu}"

say(){ printf '[*] %s\n' "$*"; }
need(){ command -v "$1" >/dev/null || { echo "Missing: $1" >&2; exit 1; }; }
need tar; need make; need systemctl; need awk; need sed; need grep

# 1) Build the two tars that already have same-named dirs beside them
mapfile -t TGZS < <(find . -maxdepth 1 -type f -name '*.tgz' -printf '%P\n' | sort)
MATCHED=(); for t in "${TGZS[@]}"; do b="${t%.tgz}"; [[ -d "$b" ]] && MATCHED+=("$t"); done
[[ ${#MATCHED[@]} -gt 0 ]] || { echo "[!] No matching tarballs here"; exit 1; }

for t in "${MATCHED[@]}"; do
  b="${t%.tgz}"
  say "Extract $t (safe if already extracted)…"; tar -xzf "$t"
  say "make in $b…"; make -C "$b"
  say "install from $b…"
  [[ -x "$b/install.sh" ]] || { echo "[!] $b/install.sh missing"; exit 1; }
  if [[ $EUID -ne 0 ]]; then sudo "$PWD/$b/install.sh"; else "$PWD/$b/install.sh"; fi
done

# 2) Ensure default-browser+portal in XML
GP_DIR="/opt/paloaltonetworks/globalprotect"; GP_XML="$GP_DIR/GlobalProtect.xml"
SUDO=; [[ $EUID -ne 0 ]] && SUDO=sudo
$SUDO mkdir -p "$GP_DIR"
if [[ ! -f "$GP_XML" ]]; then
  $SUDO tee "$GP_XML" >/dev/null <<EOF
<GlobalProtect>
  <Settings>
    <connect-method>on-demand</connect-method>
    <default-browser>yes</default-browser>
  </Settings>
  <PanSetup>
    <Portal>${PORTAL}</Portal>
  </PanSetup>
</GlobalProtect>
EOF
else
  grep -q "<default-browser>" "$GP_XML" || {
    tmp="$(mktemp)"
    awk '/<Settings>/{print;print "    <default-browser>yes</default-browser>";next}{print}' "$GP_XML" > "$tmp"
    grep -q "<default-browser>yes</default-browser>" "$tmp" || \
      sed -e '/<PanSetup>/i \  <Settings>\n    <default-browser>yes</default-browser>\n  </Settings>' -i "$tmp"
    $SUDO cp "$tmp" "$GP_XML"; rm -f "$tmp"
  }
  if grep -q '<Portal>' "$GP_XML"; then
    $SUDO sed -i "s#<Portal>.*</Portal>#<Portal>${PORTAL}</Portal>#g" "$GP_XML"
  else
    $SUDO sed -i "s#</PanSetup>#  <Portal>${PORTAL}</Portal>\n  </PanSetup>#g" "$GP_XML" || true
  fi
fi

# 3) Restart service
say "Restart gpd.service…"; $SUDO systemctl restart gpd.service || true

# 4) Relaunch UI for desktop user
TARGET_USER="${SUDO_USER:-$USER}"
if command -v loginctl >/dev/null && [[ -z "${SUDO_USER:-}" ]]; then
  TARGET_USER="$(loginctl list-users --no-legend 2>/dev/null | awk '{print $2}' | head -n1 || echo "$USER")"
fi
TARGET_UID="$(id -u "$TARGET_USER")"
ENVV=(sudo -u "$TARGET_USER" env "XDG_RUNTIME_DIR=/run/user/${TARGET_UID}" "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${TARGET_UID}/bus" DISPLAY=:0)
command -v pkill >/dev/null && $SUDO pkill -u "$TARGET_USER" -f 'globalprotect.*launch-ui|GlobalProtect' || true
"${ENVV[@]}" bash -lc 'command -v globalprotect >/dev/null 2>&1 && (globalprotect launch-ui >/dev/null 2>&1 & disown) || true'

say "Done. Try: globalprotect show --status"
