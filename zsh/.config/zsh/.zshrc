# install zinit
source $ZDOTDIR/zinit.zsh

# load remote plugins
zinit wait lucid light-mode for \
    wintermi/zsh-brew \
    zap-zsh/supercharge \
    wintermi/zsh-fnm \
    hlissner/zsh-autopair \
    atinit"zicompinit; zicdreplay -q" \
        zdharma-continuum/fast-syntax-highlighting \
    atload"_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions \
    blockf atpull'zinit creinstall -q .' \
        zsh-users/zsh-completions

# load local snippets
zinit snippet $ZDOTDIR/exports.zsh
zinit snippet $ZDOTDIR/aliases.zsh

# load prompt theme
zinit ice as"command" from"gh-r" \
    atclone"./starship init zsh > init.zsh; ./starship completions zsh > _starship" \
    atpull"%atclone" src"init.zsh"
zinit light starship/starship

# load binaries
zinit as"command" wait lucid light-mode from"gh-r" for \
    pick"bat-*/bat" atclone'cd $(ls -d */|head -n 1); cp autocomplete/bat.zsh _bat' atpull"%atclone" @sharkdp/bat \
    pick"lsd-*/lsd" lsd-rs/lsd \
    atclone"./zoxide init zsh > init.zsh" atpull"%atclone" src"init.zsh" \
        ajeetdsouza/zoxide \
    atclone"./fzf --zsh > init.zsh" atpull="%atclone" src"init.zsh" \
        junegunn/fzf
