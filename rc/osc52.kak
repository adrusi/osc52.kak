declare-option -hidden str osc52_paste_buffer ""
declare-option -hidden str osc52_register '"'
declare-option -docstring "Maximum time interval the terminal is allowed to send osc52 paste chunks after receiving the first chunk." \
    int osc52_paste_timeout 5

define-command \
    -docstring "Copy selections to the current register and the system clipboard. Requires a parameter indicating the current register." \
    -params 1 \
    osc52-copy \
%{
    set-option window osc52_register %sh{
        if [ "$1" = "$(printf '\0')" ]; then
            printf '"'
        else
            printf '%s' "$1"
        fi
    }
    set-register %opt{osc52_register} %val{selections}
    nop %sh{
        concatenated_selections=$(eval printf '%s' "$kak_quoted_selections")
        encoded="$(printf %s "$concatenated_selections" | base64 | tr -d '\n')"
        printf "\033]52;c;%s\a" "$encoded" >/dev/tty
    }
}

define-command -hidden install-osc-capture-mappings %(
    map window prompt '<a-\>' '}<ret>'
    map window prompt %sh{printf '\a'} '}<ret>'
    map window normal '<a-]>' ': osc-capture %{'
)

define-command -hidden uninstall-osc-capture-mappings %(
    unmap window prompt '<a-\>' '}<ret>'
    unmap window prompt %sh{printf '\a'} '}<ret>'
    unmap window normal '<a-]>' ': osc-capture %{'
)

define-command -hidden -params 1 osc52-paste-recv %{
    set-option window osc52_paste_buffer %sh{ printf '%s' "$kak_opt_osc52_paste_buffer$1" }
    set-register %opt{osc52_register} %arg{1}
    execute-keys """%opt{osc52_register}p"
    set-register %opt{osc52_register} %opt{osc52_paste_buffer}
}

define-command -hidden -params 1 osc-capture %{
    nop %sh{ {
        (
            sleep "$kak_opt_osc52_paste_timeout"
            printf 'eval -client %%{%s} %%{%s}\n' "$kak_client" uninstall-osc-capture-mappings |
                kak -p "$kak_session"
        ) &

        osc52() {
            quoted_decoded=$(printf '%s\n' "$1" | base64 -d | sed "s/'/''''/g")
            printf "eval -client '%s' 'osc52-paste-recv ''%s'''\n" "$kak_client" "$quoted_decoded" |
                kak -p "$kak_session"
        }

        oscmsg=$1
        case "$oscmsg" in
        '52;'*) osc52 "${oscmsg#52;*;}" ;;
        esac
    } >/dev/null 2>&1 </dev/null & }
}

define-command \
    -docstring "Paste the system clipboard at each cursor. Also sets the current register to the contents of the system clipboard." \
    -params 1 \
    osc52-paste \
%(
    install-osc-capture-mappings
    set-option window osc52_register %sh{
        if [ "$1" = "$(printf '\0')" ]; then
            printf '"'
        else
            printf '%s' "$1"
        fi
    }
    set-option window osc52_paste_buffer ""
    nop %sh{ {
        printf "\033]52;c;?\a" >/dev/tty
    } >/dev/null 2>&1 </dev/null & }
)
