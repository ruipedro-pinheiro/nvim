#!/usr/bin/env sh
# install.sh — Neovim + ISOLATED toolchain, no root. The toolchain (node, rg, fd,
# tree-sitter, unzip, norminette) lives in a DEDICATED directory exposed ONLY to
# nvim through its wrapper. The shell PATH is NOT modified -> other programs keep
# their system versions (zero pollution). Idempotent.
# Handles a non-fresh machine (preinstalled dev env + existing configs).
#
#   git clone https://github.com/ruipedro-pinheiro/nvim.git ~/.config/nvim
#   ~/.config/nvim/install.sh
#   WITH_FONT=0 ./install.sh
set -u

NVIM_TAG="nightly"
SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
BIN_DIR="$HOME/.local/bin"                  # contains ONLY the nvim wrapper (exposed to the shell)
OPT_DIR="$HOME/.local/opt"
TC="$OPT_DIR/nvim-toolchain"                # isolated toolchain root
TOOL="$TC/bin"                             # toolchain binaries — OUTSIDE global PATH
REPO="https://github.com/ruipedro-pinheiro/nvim.git"
REPO_SSH="git@github.com:ruipedro-pinheiro/nvim.git"
ARCH="linux-x86_64"
WITH_FONT="${WITH_FONT:-1}"
MIN_FREE_MB="2048"
RG_VER="15.1.0"; FD_VER="10.4.2"; TS_VER="0.25.10"; NODE_VER="v24.18.0"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$BIN_DIR" "$OPT_DIR"

log()  { printf '\033[1;32m::\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$1"; }
dl()   { curl -fL --retry 3 -o "$2" "$1"; }
have() { p=$(command -v "$1" 2>/dev/null) || return 1; case "$p" in /*) [ -x "$p" ];; *) return 1;; esac; }
runs() { command -v "$1" >/dev/null 2>&1 && "$1" --version >/dev/null 2>&1; }
node_ok() { runs node || return 1; m=$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0); [ "$m" -ge 18 ] 2>/dev/null && runs npm; }
ts_ok()   { runs tree-sitter || return 1; case "$(tree-sitter --version 2>/dev/null | awk '{print $2}')" in 0.25.*) return 0;; *) return 1;; esac; }

require_free_space() {
  required_kb=$((MIN_FREE_MB * 1024))
  for path in "$HOME" "$TMP"; do
    available_kb=$(df -Pk "$path" 2>/dev/null | awk 'NR == 2 { print $4 }')
    if [ -z "$available_kb" ] || [ "$available_kb" -lt "$required_kb" ]; then
      printf 'At least %s MiB of free space is required in %s.\n' "$MIN_FREE_MB" "$path" >&2
      exit 1
    fi
  done
}

cleanup_old_install() {
  log "Nettoyage des anciennes installations nvim"
  rm -rf "$OPT_DIR/nvim" "$TC" \
    "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim"
  for old in "$OPT_DIR/nvim-nightly" "$OPT_DIR"/nvim-nightly.bak-*; do
    [ ! -e "$old" ] || rm -rf "$old"
  done
  for old_bin in nvim nvim-nightly node npm npx rg fd tree-sitter norminette unzip; do
    rm -f "$BIN_DIR/$old_bin"
  done
  mkdir -p "$TOOL"
  export PATH="$TOOL:$PATH"
}

is_own_config() {
  remote=$(git -C "$CFG" remote get-url origin 2>/dev/null) || return 1
  case "$remote" in
    "$REPO"|"${REPO%.git}"|"$REPO_SSH") return 0 ;;
    *) return 1 ;;
  esac
}

prune_config_backups() {
  keep=""
  for backup in "$HOME/.config"/nvim.bak.*; do
    [ -e "$backup" ] || continue
    [ -z "$keep" ] || rm -rf "$keep"
    keep="$backup"
  done
}

# ── 0. System prerequisites (not installable without root: verify + warn) ─────
require_free_space
miss=""; for c in git curl tar gzip; do have "$c" || miss="$miss $c"; done
have cc || have gcc || miss="$miss cc/gcc"; have python3 || miss="$miss python3"
[ -z "$miss" ] || warn "Prérequis système manquants (hors script, requièrent root) :$miss"

# ── 1. Neovim (OPT_DIR) + wrapper exposing the toolchain TO NVIM ONLY ─────────
log "Neovim ($NVIM_TAG)"
if dl "https://github.com/neovim/neovim/releases/download/$NVIM_TAG/nvim-$ARCH.tar.gz" "$TMP/nvim.tgz" && tar -xzf "$TMP/nvim.tgz" -C "$TMP" 2>/dev/null; then
  cleanup_old_install
  mv "$TMP/nvim-$ARCH" "$OPT_DIR/nvim"
  printf '#!/usr/bin/env sh\nunset VIMRUNTIME\nexport VIMRUNTIME="%s/nvim/share/nvim/runtime"\nexport PATH="%s:$PATH"\nexec "%s/nvim/bin/nvim" "$@"\n' "$OPT_DIR" "$TOOL" "$OPT_DIR" > "$BIN_DIR/nvim"
  chmod +x "$BIN_DIR/nvim"
  "$BIN_DIR/nvim" --version >/dev/null 2>&1 || warn "nvim posé mais ne démarre pas (glibc ?)"
  "$SCRIPT_DIR/check-nvim-nightly.sh" || exit 1
else warn "Téléchargement Neovim KO (tag $NVIM_TAG / réseau) — STOP"; exit 1; fi

# ── 2. node (only if system node is missing/broken/<18; placed in TOOLCHAIN) ──
if node_ok; then log "node système OK ($(node --version 2>/dev/null)) -> nvim le réutilise, rien posé"; else
  log "node $NODE_VER (isolé dans la toolchain ; ton node système reste intact)"
  if dl "https://nodejs.org/dist/$NODE_VER/node-$NODE_VER-linux-x64.tar.gz" "$TMP/node.tgz" && tar -xzf "$TMP/node.tgz" -C "$TMP" 2>/dev/null; then
    rm -rf "$TC/node"; mv "$TMP/node-$NODE_VER-linux-x64" "$TC/node"
    for b in node npm npx; do ln -sf "$TC/node/bin/$b" "$TOOL/$b"; done
  else warn "node download KO"; fi
fi

# ── 3. ripgrep / 4. fd / 5. unzip / 6. tree-sitter (all in TOOLCHAIN) ─────────
if ! runs rg; then log "ripgrep $RG_VER"
  dl "https://github.com/BurntSushi/ripgrep/releases/download/$RG_VER/ripgrep-$RG_VER-x86_64-unknown-linux-musl.tar.gz" "$TMP/rg.tgz" \
    && tar -xzf "$TMP/rg.tgz" -C "$TMP" 2>/dev/null && cp "$TMP/ripgrep-$RG_VER-x86_64-unknown-linux-musl/rg" "$TOOL/" || warn "rg KO"; fi
if ! { runs fd && fd --version 2>/dev/null | grep -q '^fd '; }; then log "fd $FD_VER"
  dl "https://github.com/sharkdp/fd/releases/download/v$FD_VER/fd-v$FD_VER-x86_64-unknown-linux-musl.tar.gz" "$TMP/fd.tgz" \
    && tar -xzf "$TMP/fd.tgz" -C "$TMP" 2>/dev/null && cp "$TMP/fd-v$FD_VER-x86_64-unknown-linux-musl/fd" "$TOOL/" || warn "fd KO"; fi
if ! have unzip; then
  if have python3; then log "unzip (shim python3, isolé)"
    printf '#!/usr/bin/env python3\nimport sys,zipfile\na=sys.argv[1:];d=".";s=None;i=0\nwhile i<len(a):\n if a[i]=="-d":i+=1;d=a[i]\n elif a[i].startswith("-"):pass\n elif s is None:s=a[i]\n i+=1\nzipfile.ZipFile(s).extractall(d)\n' > "$TOOL/unzip"; chmod +x "$TOOL/unzip"
  else warn "ni unzip ni python3 : codelldb/js-debug ne s'extrairont pas"; fi
fi
if ! ts_ok; then log "tree-sitter CLI $TS_VER (isolé)"
  dl "https://github.com/tree-sitter/tree-sitter/releases/download/v$TS_VER/tree-sitter-linux-x64.gz" "$TMP/ts.gz" \
    && gunzip -f "$TMP/ts.gz" && cp "$TMP/ts" "$TOOL/tree-sitter" && chmod +x "$TOOL/tree-sitter" || warn "tree-sitter KO"; fi

# ── 7. norminette (dedicated venv in toolchain; pip --user fallback) ──────────
if ! runs norminette; then
  log "norminette (venv isolé)"
  if python3 -m venv "$TC/venv" 2>/dev/null && "$TC/venv/bin/pip" install --quiet norminette 2>/dev/null; then
    ln -sf "$TC/venv/bin/norminette" "$TOOL/norminette"
  else
    python3 -m pip install --user --quiet norminette 2>/dev/null || python3 -m pip install --user --break-system-packages --quiet norminette 2>/dev/null \
      && warn "norminette via pip --user (pas isolé — venv indispo)" || warn "norminette KO"
  fi
fi

# ── 8. Nerd Font (icons; terminal selection is manual) ────────────────────────
if [ "$WITH_FONT" = "1" ] && have fc-cache && ! fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd"; then
  log "JetBrainsMono Nerd Font"; mkdir -p "$HOME/.local/share/fonts"
  dl "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" "$TMP/font.zip" \
    && ( cd "$HOME/.local/share/fonts" && { unzip -oq "$TMP/font.zip" 2>/dev/null || "$TOOL/unzip" "$TMP/font.zip"; } ) && fc-cache -f >/dev/null 2>&1 \
    && warn "Font posée — règle ton terminal sur 'JetBrainsMono Nerd Font' (manuel)" || warn "font KO (non bloquant)"
fi

# ── 9. ~/.local/bin in PATH (to FIND nvim wrapper) — NOT the toolchain ─────────
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) for rc in "$HOME/.profile" "$HOME/.zshrc" "$HOME/.bashrc"; do
       [ -f "$rc" ] && ! grep -qF ">>> nvim wrapper >>>" "$rc" 2>/dev/null \
         && printf '\n# >>> nvim wrapper >>>\nexport PATH="%s:$PATH"\n# <<< nvim wrapper <<<\n' "$BIN_DIR" >> "$rc"
     done; warn "$BIN_DIR ajouté à tes rc (pour trouver 'nvim') — la toolchain reste isolée" ;;
esac

# ── 10. nvim config (missing / own / foreign->backup) ─────────────────────────
CFG="$HOME/.config/nvim"
if [ ! -e "$CFG" ]; then log "Clone config"; git clone "$REPO" "$CFG" || warn "clone KO"
elif is_own_config; then
  if [ -f "$CFG/.git" ]; then
    log "Config fournie par le submodule dotfiles -> conservée"
  else
    log "Config déjà la tienne -> pull"; git -C "$CFG" pull --ff-only 2>/dev/null || warn "pull KO (modifs locales ?)"
  fi
else BK="$CFG.bak.$(date +%Y%m%d-%H%M%S)"; warn "Config étrangère -> backup $BK"; mv "$CFG" "$BK"; git clone "$REPO" "$CFG" || warn "clone KO"; fi
prune_config_backups

# ── 11. Bootstrap (nvim, through its wrapper, sees the toolchain) ──────────────
log "Bootstrap (Lazy sync + Mason) — quelques minutes"
"$BIN_DIR/nvim" --headless "+Lazy! sync" +qa >"$TMP/lazy.log" 2>&1 || warn "bootstrap : $(tail -2 "$TMP/lazy.log" | tr '\n' ' ')"

# ── 12. Isolation proof: SHELL vs NVIM ────────────────────────────────────────
hash -r 2>/dev/null || true
log "Isolation — ce que voit ton SHELL (doit rester ton système, pas ma toolchain) :"
PSHELL=$(printf '%s' "$PATH" | sed "s#$TOOL:##")   # PATH WITHOUT the toolchain = shell view
for x in node rg tree-sitter; do printf '   shell  %-12s %s\n' "$x" "$(PATH="$PSHELL" command -v "$x" 2>/dev/null || echo '(rien — non pollué)')"; done
for x in node rg tree-sitter nvim; do printf '   nvim   %-12s %s\n' "$x" "$(command -v "$x" 2>/dev/null)"; done
log "Fini. Lance : nvim"
