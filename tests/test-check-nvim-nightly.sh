#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
CHECK="$ROOT/check-nvim-nightly.sh"

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
pass() { printf 'ok - %s\n' "$1"; }

make_home() {
  d=$(mktemp -d)
  mkdir -p "$d/.local/bin" "$d/.local/opt/nvim/bin" "$d/.local/opt/nvim/share/nvim/runtime"
  printf '%s\n' "$d"
}

write_wrapper() {
  h=$1
  cat > "$h/.local/bin/nvim" <<EOF
#!/usr/bin/env sh
export VIMRUNTIME="$h/.local/opt/nvim/share/nvim/runtime"
exec "$h/.local/opt/nvim/bin/nvim" "\$@"
EOF
  chmod +x "$h/.local/bin/nvim"
}

write_fake_nvim() {
  h=$1
  version=$2
  runtime=$3
  hl_type=$4
  cat > "$h/.local/opt/nvim/bin/nvim" <<EOF
#!/usr/bin/env sh
if [ "\${1:-}" = "--version" ]; then
  printf '%s\n' '$version'
  exit 0
fi
printf 'runtime_file=%s/doc/help.txt\\nhl_op=%s\\n' '$runtime' '$hl_type'
EOF
  chmod +x "$h/.local/opt/nvim/bin/nvim"
}

test_good_install_passes_with_inherited_vimruntime() {
  h=$(make_home); trap 'rm -rf "$h"' EXIT HUP INT TERM
  write_wrapper "$h"
  write_fake_nvim "$h" 'NVIM v0.13.0-dev-123+gabc' "$h/.local/opt/nvim/share/nvim/runtime" 'function'
  VIMRUNTIME=/tmp/old HOME="$h" "$CHECK" >/tmp/check-ok.out 2>/tmp/check-ok.err || fail "installation nightly valide rejetée"
  grep -q 'OK vérification nvim nightly' /tmp/check-ok.out || fail "message OK absent"
  rm -rf "$h"; trap - EXIT HUP INT TERM
  pass "installation valide acceptée"
}

test_system_runtime_fails() {
  h=$(make_home); trap 'rm -rf "$h"' EXIT HUP INT TERM
  write_wrapper "$h"
  write_fake_nvim "$h" 'NVIM v0.13.0-dev-123+gabc' '/usr/share/nvim/runtime' 'function'
  if HOME="$h" "$CHECK" >/tmp/check-bad-runtime.out 2>/tmp/check-bad-runtime.err; then
    fail "runtime externe accepté"
  fi
  grep -q 'runtime externe' /tmp/check-bad-runtime.err || fail "diagnostic runtime externe absent"
  rm -rf "$h"; trap - EXIT HUP INT TERM
  pass "runtime externe rejeté"
}

test_missing_hl_op_fails() {
  h=$(make_home); trap 'rm -rf "$h"' EXIT HUP INT TERM
  write_wrapper "$h"
  write_fake_nvim "$h" 'NVIM v0.13.0-dev-123+gabc' "$h/.local/opt/nvim/share/nvim/runtime" 'nil'
  if HOME="$h" "$CHECK" >/tmp/check-bad-api.out 2>/tmp/check-bad-api.err; then
    fail "API vim.hl.hl_op absente acceptée"
  fi
  grep -q 'vim.hl.hl_op absent' /tmp/check-bad-api.err || fail "diagnostic API absent"
  rm -rf "$h"; trap - EXIT HUP INT TERM
  pass "API manquante rejetée"
}

test_stable_build_fails() {
  h=$(make_home); trap 'rm -rf "$h"' EXIT HUP INT TERM
  write_wrapper "$h"
  write_fake_nvim "$h" 'NVIM v0.11.4' "$h/.local/opt/nvim/share/nvim/runtime" 'function'
  if HOME="$h" "$CHECK" >/tmp/check-stable.out 2>/tmp/check-stable.err; then
    fail "build stable acceptée"
  fi
  grep -q 'pas une build nightly/dev' /tmp/check-stable.err || fail "diagnostic build stable absent"
  rm -rf "$h"; trap - EXIT HUP INT TERM
  pass "build stable rejetée"
}

test_good_install_passes_with_inherited_vimruntime
test_system_runtime_fails
test_missing_hl_op_fails
test_stable_build_fails
