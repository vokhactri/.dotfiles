# install zinit
source $ZDOTDIR/zinit.zsh

# load remote plugins
zinit wait lucid light-mode for \
    wintermi/zsh-brew \
    hlissner/zsh-autopair \
    Aloxaf/fzf-tab \
    atinit"zicompinit; zicdreplay -q" \
        zdharma-continuum/fast-syntax-highlighting \
    atload"_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions \
    blockf atpull'zinit creinstall -q .' \
        zsh-users/zsh-completions

# load prompt theme
zinit ice as"command" from"gh-r" \
    atclone"./starship init zsh > init.zsh; ./starship completions zsh > _starship" \
    atpull"%atclone" src"init.zsh"
zinit light starship/starship

# load binaries
zinit as"command" wait lucid light-mode from"gh-r" for \
    extract"!" lsd-rs/lsd \
    extract"!" zyedidia/micro \
    extract"!" cp"autocomplete/bat.zsh -> _bat" @sharkdp/bat \
    extract"!" atclone="cp usr/bin/fastfetch .; rm -rf usr" atpull"%atclone" \
        fastfetch-cli/fastfetch \
    atclone"./zoxide init zsh > init.zsh" atpull"%atclone" src"init.zsh" \
        ajeetdsouza/zoxide \
    atclone"./fzf --zsh > init.zsh" atpull="%atclone" src"init.zsh" \
        junegunn/fzf \
    atclone"./fnm env --use-on-cd > init.zsh" atpull"%atclone" src"init.zsh" Schniz/fnm

# load local scripts
source $ZDOTDIR/exports.zsh
source $ZDOTDIR/aliases.zsh
source $ZDOTDIR/options.zsh
source $ZDOTDIR/bin.zsh
