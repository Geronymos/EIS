# EIS 🍦

> [E]ditor [I]n [S]hell 🍦 - Vim-like text editor written in shell script. 

## About

EIS is a minimal text editor which is written in shell script utilizing other programs. Its main feature is the ability to use any shell command to modify selected text. No more IDEs which miserable try to clone the functionality of core-utils! 

You may ask `"Why a NEW editor? Why shell script? Isn't that unperformant and needs unnecessary dependencies?"` and you would be right asking those questions but this project is primarily for learning shell-scripting and regular expressions and maybe it will mature and become the next big thing. 

## Features 🏁

- [X] Syntax highlighting 🌈
- [X] status line
- [X] edit and save 📝
- [X] select text
- [X] modify text with shell commands
- [ ] language server protocol implementation
- [ ] complete git integration

## Usage 

```sh
./eis.sh [File]
```

### Key map ⌨
*For more information start by learning vim (with vimtutor)*
- normal, insert, visual, command: `esc,i,v,:`
- movement: `h,j,k,l` / `arrow keys/enter` 

## Inspiration ✨

- [Vim](https://www.vim.org/) / [neovim](https://neovim.io/) - *text editor*
- [powerlevel9k](https://github.com/Powerlevel9k/powerlevel9k) / [powerlevel10k](https://github.com/romkatv/powerlevel10k) - *prompt*
- [Dylan Araps](https://github.com/dylanaraps) - *bash-evangelist (see ["pure bash bible"](https://github.com/dylanaraps/pure-bash-bible))*

## Authors

- **Gero Beckmann** - *Initial work* - [Geronymos](https://github.com/Geronymos)

## License

This project is licensed under the GPT-3 License - see the `LICENSE` file for details
