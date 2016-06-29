## Reusable artifacts for generic projects

### Setting up Subtree

    git subtree add -P Vendor/AWLShared git@github.com:vgorloff/AWLShared.git master --squash

### Pulling Subtree

    git subtree pull -P Vendor/AWLShared git@github.com:vgorloff/AWLShared.git master --squash
    
### Pushing Subtree

    git subtree pull --prefix Vendor/AWLShared git@github.com:vgorloff/AWLShared.git master
