# Day 5: Editing Files

## Objectives
- Learn how to use basic text editors in Linux: `nano` and `vim`.
- Practice creating and editing text files.

## Introduction to Text Editors

Text editors are essential tools for creating and modifying files in Linux. Two popular command-line text editors are `nano` and `vim`. Each has its own features and use cases.

### Nano

`nano` is a simple, user-friendly text editor that's ideal for beginners. It provides on-screen prompts for basic commands, making it easy to learn and use.

#### Basic Commands in Nano

- **Open a file**: `nano filename`
- **Save changes**: Press `CTRL + O`, then press `Enter`.
- **Exit**: Press `CTRL + X`.
- **Cut a line**: Press `CTRL + K`.
- **Paste a line**: Press `CTRL + U`.
- **Search for text**: Press `CTRL + W`, then enter the search term.

### Vim

`vim` is a powerful, highly configurable text editor with a steeper learning curve. It's favored by many advanced users for its efficiency and extensive feature set.

#### Basic Commands in Vim

Vim operates in different modes. The two primary modes are:

1. **Normal Mode**: For navigation and command execution.
2. **Insert Mode**: For editing text.

To start editing, you need to switch from Normal Mode to Insert Mode.

- **Open a file**: `vim filename`
- **Enter Insert Mode**: Press `i`.
- **Exit Insert Mode**: Press `ESC`.
- **Save changes and exit**: Type `:wq` in Normal Mode, then press `Enter`.
- **Exit without saving**: Type `:q!` in Normal Mode, then press `Enter`.
- **Undo last change**: Press `u` in Normal Mode.
- **Search for text**: Type `/search_term`, then press `Enter`.

## Task

1. Open your terminal and practice using both editors:

   ### Using Nano:
    - Create a new file by typing `nano myfile.txt`.
    - Enter some text into the file.
    - Save your changes (`CTRL + O`) and exit (`CTRL + X`).

   ### Using Vim:
    - Open the same file by typing `vim myfile.txt`.
    - Switch to Insert Mode by pressing `i` and add more text.
    - Exit Insert Mode by pressing `ESC`.
    - Save your changes and exit by typing `:wq`.

2. Document any challenges you encounter and how you overcame them.

## Additional Resources
- [Nano Text Editor Guide](https://www.nano-editor.org/docs.php)
- [Vim Basics Cheat Sheet](https://www.fprintf.net/vimCheatSheet.html)

