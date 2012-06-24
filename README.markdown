## vim-blockcomment

### Description

This is a VIM plugin used to un-/comment blocks of code.
Currently there are three possibilities for alignment:

1. Block: Left-aligned multiline-comments.
2. RBlock: Left+right aligned borders around commented code.
3. Normal: Comment each line independently.

For each of these modes there is a mapping to toggle/comment/uncomment.


### Features

* Keybindings for both **range** and **motion** modes
* Works for large variety of filetypes using `&cms`
* Individual configuration per filetype possible
* Can detect syntax-regions (for example php/html/javascript)
* Uses [vim-repeat](https://github.com/tpope/vim-repeat/)


### Installation

You can install this plugin using [vim-pathogen](https://github.com/tpope/vim-pathogen/):

    cd ~/.vim/bundle
    git clone git://github.com/thomas-glaessle/vim-blockcomment.git

Alternatively, you can simply drop the `blockcomment.vim` file into your `~/.vim/plugin` directory.


### Key mappings

The default key bindings are:

1. `\\o`/`\\a`/`\\u` for Block toggle/comment/uncomment
2. `\0o`/`\0a`/`\0u` for RBlock toggle/comment/uncomment
3. `\"o`/`\"a`/`\"u` for Normal toggle/comment/uncomment

In normal mode, this will trigger a motion-command.
In visual mode the selected range will be used.

For each of these keybindings, there is also an uppercase variant which always invokes the corresponding command with a range.


### Missing features

The plugin is still under development.
It is therefore thoroughly tested.  Use at your own risk.

The following features are not implemented yet:

* Backup and restore comment termination sequences when required

