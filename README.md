# vscode-settings
**install extensions command**

```xargs -L1 code --install-extension < extensions.txt```

**uninstall all extensions**

``code --list-extensions | xargs -L1 code --uninstall-extension``

# Homebrew Brewfile
**install all listed packages using**

``brew bundle``- in the dir where the Brewfile is located

**generate a new Brewfile using**

``brew bundle dump``