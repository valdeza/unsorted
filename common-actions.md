## Git: Setting your identity
Because forgetting to do this can lead to leaking your PC username and/or associated email:
```
> $ git config --global user.name "$username"
> $ git config --global user.email $email
```

To do this for only the current repository, add the following to `.git/config`:
```
[user]
  name = "$username"
  email = $email
```

## Steam: Manually moving game program data between libraries
_because while Steam has the capability to do this, it doesn't work a lot of the time (for me)!_
1. Ensure there is no ongoing download for the game to be moved
1. Fully exit Steam
1. Keeping the same directory structure,  copy game-related program data to destination library  
   e.g.:  
   ${source}\steamapps\common\${game}\ -> ${destination}\steamapps\common\${game}\  
   ${source}\steamapps\${username}\${game}\ -> ${destination}\steamapps\${username}\${game}\
1. In the 'steamapps' directory, determine which appmanifest belongs to the game to be moved.  
   This PowerShell command can be run to quickly view which appmanifest belongs to which game:
   ```powershell
   Get-ChildItem "appmanifest_*" | ForEach-Object { $_ | Select-String '"name"'; Write-Host "" }
   ```
1. Move the appropriate appmanifest to the destination steam library, noting the number at the end of the filename.
1. In the 'workshop' subdirectory, move the appropriate appworkshop.acf file and copy the same-numbered directory under 'content' to the destination.
1. Start Steam to allow it to verify game cache.
1. Now your game most likely works and future updates will be downloaded to the new library.
