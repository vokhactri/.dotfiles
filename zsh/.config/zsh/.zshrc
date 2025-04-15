# install zinit
source $ZDOTDIR/zinit

# load remote plugins
zinit wait lucid light-mode id-as depth"1" for \
    wintermi/zsh-brew \
    hlissner/zsh-autopair \
    Aloxaf/fzf-tab \
    atinit"zicompinit; zicdreplay -q" \
        zdharma-continuum/fast-syntax-highlighting \
    atload"_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions

# load prompt theme
zinit ice as"command" from"gh-r" id-as \
    atclone"./starship init zsh > init.zsh; ./starship completions zsh > _starship" \
    atpull"%atclone" src"init.zsh"
zinit light starship/starship

# load binaries
zinit as"command" wait lucid light-mode from"gh-r" id-as for \
    extract"!" lsd-rs/lsd \
    extract"!" zyedidia/micro \
    extract"!" cp"autocomplete/bat.zsh -> _bat" @sharkdp/bat \
    extract"!" pick"usr/bin/fastfetch" \
        fastfetch-cli/fastfetch \
    atclone"./zoxide init zsh > init.zsh" atpull"%atclone" src"init.zsh" \
        ajeetdsouza/zoxide \
    atclone"./fzf --zsh > init.zsh" atpull="%atclone" src"init.zsh" \
        junegunn/fzf \
    atclone"./fnm env --use-on-cd --shell zsh > init.zsh; ./fnm completions --shell zsh > _fnm" atpull"%atclone" src"init.zsh" Schniz/fnm

# load local scripts
zinit is-snippet id-as for \
    $ZDOTDIR/snippets/exports \
    $ZDOTDIR/snippets/aliases \
    $ZDOTDIR/snippets/options \
    $ZDOTDIR/snippets/bin
