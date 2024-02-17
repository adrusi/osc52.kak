# osc52.kak

Kakoune plugin that adds system clipboard integration via the standard OSC 52 terminal escape sequences.
Supports both copying to the system clipboard and pasting from the system clipboard, including correct handling of terminals that send large clipboard buffers in multiple chunks.

## Installation

### `plug.kak`

```kak
plug "adrusi/osc52.kak"
```

## Configuration

Recommended mappings:

```kak
map global user y ': osc52-copy %val{register}<ret>' -docstring 'copy to system clipboard'
map global user p ': osc52-paste %val{register}<ret>' -docstring 'paste from system clipboard'
```

Note that passing `%val{register}` to the osc52 commands is required.

If you are using kakoune over a slow connection, you may need to increase the paste timeout to give the terminal enough time to send long clipboard buffers over the wire:

```kak
set-option global osc52_paste_timeout 30
```

## Caveats

While OSC 52 is supported by the majority of terminal emulators, this plugin has only been tested with kitty.

In order to capture escape codes send by the terminal, this plugin sets some mappings in `prompt` mode.
Any existing mappings bound to `<a-]>` or `<a-\>` in prompt mode will be clobbered.

The plugin's handling of OSC52 paste does not try to keep track of multiple paste requests happening at the same time in the same client.
This may be an issue if it takes long enough for a paste operation to complete that the user is able to issue a subsequent request in the intervening time.
However, since most terminals require user confirmation before enacting a paste request, this edge case might not be possible to meet.
