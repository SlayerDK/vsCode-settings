# vsCode-settings

## install extensions command
```xargs -L1 code --install-extension < extensions.txt```

## uninstall all extensions
``code --list-extensions | xargs -L1 code --uninstall-extension``