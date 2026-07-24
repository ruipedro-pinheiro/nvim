#!/usr/bin/env sh
set -u

BIN_DIR="$HOME/.local/bin"
OPT_NVIM="$HOME/.local/opt/nvim"
WRAPPER="$BIN_DIR/nvim"
RUNTIME="$OPT_NVIM/share/nvim/runtime"

fail() { printf 'ERREUR: %s\n' "$1" >&2; exit 1; }

[ -x "$WRAPPER" ] || fail "wrapper absent: $WRAPPER"
[ -x "$OPT_NVIM/bin/nvim" ] || fail "binaire absent: $OPT_NVIM/bin/nvim"
[ -d "$RUNTIME" ] || fail "runtime absent: $RUNTIME"

grep -qF "$OPT_NVIM/bin/nvim" "$WRAPPER" 2>/dev/null || fail "wrapper inattendu"
grep -qF "$RUNTIME" "$WRAPPER" 2>/dev/null || fail "wrapper sans runtime embarqué"

version=$(
  unset VIMRUNTIME
  "$WRAPPER" --version 2>/dev/null | sed -n '1p'
) || fail "nvim ne démarre pas"
case "$version" in
  *-dev*|*nightly*) ;;
  *) fail "pas une build nightly/dev: $version" ;;
esac

probe=$(
  unset VIMRUNTIME
  "$WRAPPER" --clean --headless -u NONE -n \
    '+lua local f=vim.api.nvim_get_runtime_file("doc/help.txt", false)[1] or ""; print("runtime_file=" .. f); print("hl_op=" .. type(vim.hl and vim.hl.hl_op))' \
    '+qa' 2>/dev/null
) || fail "sonde nvim échouée"

runtime_file=$(printf '%s\n' "$probe" | sed -n 's/^runtime_file=//p' | sed -n '1p')
hl_op=$(printf '%s\n' "$probe" | sed -n 's/^hl_op=//p' | sed -n '1p')

[ -n "$runtime_file" ] || fail "runtime chargé inconnu"
case "$runtime_file" in
  "$RUNTIME"/*) ;;
  *) fail "runtime externe: $runtime_file" ;;
esac

[ "$hl_op" = "function" ] || fail "vim.hl.hl_op absent"

printf 'OK vérification nvim nightly\n'
