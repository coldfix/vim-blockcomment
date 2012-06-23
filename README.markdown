## vim-blockcomment

### Description

This is a VIM plugin used to un-/comment blocks of code.
Currently there are three possibilities for alignment:

1. Block: Left-aligned multiline-comments.
2. RBlock: Left+right aligned borders around commented code.
3. Normal: Comment each line independently.

For each of these modes there is a mapping to toggle/comment/uncomment.


### Features

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

1. `\\\`/`\\a`/`\\u` for Block toggle/comment/uncomment
2. `\00`/`\0a`/`\0u` for RBlock toggle/comment/uncomment
3. `\""`/`\"a`/`\"u` for Normal toggle/comment/uncomment


### Missing features

The plugin is still under development.
It is therefore thoroughly tested.  Use at your own risk.

The following features are not implemented yet:

* Provide bindings to be used with a motion command
* Backup and restore comment termination sequences when required

