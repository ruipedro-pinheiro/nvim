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
grep -qF 'for old_bin in nvim nvim-nightly node npm npx rg fd tree-sitter norminette unzip; do' "$INSTALL" || fail "anciens binaires directs de la toolchain non nettoyés"
if grep -E 'old_bin in .*\b(lazygit|lazycommit|zoxide|gdb)\b' "$INSTALL" >/dev/null; then
  fail "le cleanup nvim touche un binaire géré hors du repo nvim"
fi
grep -qF '"$HOME/.local/share/nvim"' "$INSTALL" || fail "anciennes données Neovim non nettoyées"
grep -qF '"$HOME/.local/state/nvim"' "$INSTALL" || fail "ancien état Neovim non nettoyé"
grep -qF '"$HOME/.cache/nvim"' "$INSTALL" || fail "ancien cache Neovim non nettoyé"
grep -qF 'git@github.com:ruipedro-pinheiro/nvim.git' "$INSTALL" || fail "remote SSH du submodule non reconnu"
grep -qF '[ -f "$CFG/.git" ]' "$INSTALL" || fail "checkout submodule non reconnu"
grep -qF 'Config fournie par le submodule dotfiles' "$INSTALL" || fail "branche submodule absente"
grep -qF 'prune_config_backups' "$INSTALL" || fail "anciens backups de config non limités"
grep -qF '"$HOME/.config"/nvim.bak.*' "$INSTALL" || fail "glob des backups nvim absent"
grep -qF '[ -z "$keep" ] || rm -rf "$keep"' "$INSTALL" || fail "anciens backups nvim non supprimés"
grep -qF 'keep="$backup"' "$INSTALL" || fail "backup nvim le plus récent non conservé"
grep -qF 'MIN_FREE_MB="2048"' "$INSTALL" || fail "réserve disque de 2 Gio absente"
grep -qF 'TS_VER="0.25.3"' "$INSTALL" || fail "tree-sitter doit rester compatible avec glibc 2.35"
grep -qF '"$TOOL/tree-sitter" --version' "$INSTALL" || fail "tree-sitter téléchargé non testé avant bootstrap"
grep -qF 'verify_toolchain' "$INSTALL" || fail "préflight global de la toolchain absent"
for tool in node npm rg fd tree-sitter; do
  grep -qF "verify_tool $tool" "$INSTALL" || fail "validation manquante pour $tool"
done
grep -qF 'require_free_space' "$INSTALL" || fail "préflight espace disque absent"
grep -qF 'for path in "$HOME" "$TMP"' "$INSTALL" || fail "espace temporaire non vérifié"

check_line=$(grep -nF 'check-nvim-nightly.sh' "$INSTALL" | sed -n '1s/:.*//p')
lazy_line=$(grep -nF '+Lazy! sync' "$INSTALL" | sed -n '1s/:.*//p')
prune_line=$(grep -nF 'prune_config_backups' "$INSTALL" | sed -n '2s/:.*//p')
verify_line=$(grep -nF 'verify_toolchain || exit 1' "$INSTALL" | sed -n '1s/:.*//p')
[ -n "$check_line" ] && [ -n "$lazy_line" ] || fail "lignes check/Lazy introuvables"
[ "$check_line" -lt "$lazy_line" ] || fail "vérification après Lazy sync"
[ -n "$prune_line" ] && [ "$prune_line" -lt "$lazy_line" ] || fail "backups nvim non purgés avant bootstrap"
[ -n "$verify_line" ] && [ "$verify_line" -lt "$lazy_line" ] || fail "toolchain non validée avant bootstrap"

printf 'ok - contrat install.sh\n'
