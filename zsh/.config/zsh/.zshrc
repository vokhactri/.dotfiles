# install zinit
source $ZDOTDIR/zinit.zsh

zinit light zdharma-continuum/zinit-annex-bin-gem-node
zinit light zdharma-continuum/zinit-annex-binary-symlink

zinit wait lucid light-mode id-as depth'1' for \
    wintermi/zsh-brew \
    hlissner/zsh-autopair \
    Aloxaf/fzf-tab \
    atinit'zicompinit; zicdreplay -q' \
        zdharma-continuum/fast-syntax-highlighting \
    atload'_zsh_autosuggest_start' \
        zsh-users/zsh-autosuggestions

zinit id-as from'gh-r' lbin'!' null for \
    lsd-rs/lsd \
    micro-editor/micro \
    @sharkdp/bat

zinit for \
    id-as \
    from'gh-r' \
    sbin'!**/bin/fastfetch -> fastfetch' \
    @fastfetch-cli/fastfetch

zinit for \
    id-as \
    atload'eval "$(zoxide init zsh)"' \
    from'gh-r' \
    lbin'!' \
    @ajeetdsouza/zoxide

zinit for \
    id-as \
    as'completion' \
    atclone'./fnm completions --shell zsh > _fnm.zsh' \
    atload'eval "$(fnm env --use-on-cd --shell zsh)"' \
    atpull'%atclone' \
    blockf \
    from'gh-r' \
    nocompile \
    sbin'fnm' \
    @Schniz/fnm

zinit for \
    id-as \
    as'completion' \
    atclone'./starship completions zsh > _starship' \
    atpull'%atclone' \
    atload'eval "$(starship init zsh)"' \
    from'gh-r' \
    sbin'**/starship -> starship' \
    @starship/starship

zinit for \
    id-as \
    from'gh-r'  \
    lbin'!fzf'  \
    atclone'fzf --zsh > fzf.zsh' \
    atpull'%atclone' \
    src'fzf.zsh' \
    @junegunn/fzf

for script in $ZDOTDIR/config/*.zsh; do
    source "$script"
done
