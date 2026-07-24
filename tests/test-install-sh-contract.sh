#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
INSTALL="$ROOT/install.sh"

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

grep -qF 'unset VIMRUNTIME' "$INSTALL" || fail "wrapper ne neutralise pas VIMRUNTIME"
grep -qF 'export VIMRUNTIME="%s/nvim/share/nvim/runtime"' "$INSTALL" || fail "wrapper ne force pas le runtime embarqué"
grep -qF '"$SCRIPT_DIR/check-nvim-nightly.sh" || exit 1' "$INSTALL" || fail "vérification automatique absente"
grep -qF 'NVIM_TAG="nightly"' "$INSTALL" || fail "install.sh ne force pas la dernière nightly"
grep -qF 'BIN_DIR="$HOME/.local/bin"' "$INSTALL" || fail "BIN_DIR destructif non limité au HOME"
if grep -q 'NVIM_TAG=v0\|NVIM_TAG:-' "$INSTALL"; then
  fail "fallback ou version Neovim fixe encore présent"
fi
grep -qF 'cleanup_old_install' "$INSTALL" || fail "nettoyage des anciennes installations absent"
grep -qF '"$OPT_DIR/nvim-nightly"' "$INSTALL" || fail "ancien dossier nvim-nightly non nettoyé"
grep -qF '"$OPT_DIR"/nvim-nightly.bak-*' "$INSTALL" || fail "anciens backups nightly non nettoyés"
grep -qF '"$BIN_DIR/nvim-nightly"' "$INSTALL" || fail "ancien wrapper nightly non nettoyé"
grep -qF '"$HOME/.local/share/nvim"' "$INSTALL" || fail "anciennes données Neovim non nettoyées"
grep -qF '"$HOME/.local/state/nvim"' "$INSTALL" || fail "ancien état Neovim non nettoyé"
grep -qF '"$HOME/.cache/nvim"' "$INSTALL" || fail "ancien cache Neovim non nettoyé"

check_line=$(grep -nF 'check-nvim-nightly.sh' "$INSTALL" | sed -n '1s/:.*//p')
lazy_line=$(grep -nF '+Lazy! sync' "$INSTALL" | sed -n '1s/:.*//p')
[ -n "$check_line" ] && [ -n "$lazy_line" ] || fail "lignes check/Lazy introuvables"
[ "$check_line" -lt "$lazy_line" ] || fail "vérification après Lazy sync"

printf 'ok - contrat install.sh\n'
