# Explorer Session Snapshot

_Why buy an uninterruptable power supply when you can backup and restore everything_

Most everyday applications have some forme of protection against crashes and unexpected power loss. Not Windows File Explorer! You see, I may or may not have an awful habit of keeping _toomanythings_ open at all times, ripe for it all to be taken away either by Mother Nature's crusade against electricity to my home or the Microsoft Corporation's crusade "to schedule a restart during a time you usually don't use your device" [(right now the middle of your Twitch stream looks good)](https://youtu.be/eP31lluUDWU)<!-- tbf, partially the reason we got to this point is probably to avoid the Windows XP fiasco all over again. (Supposedly) Microsoft has been getting better about this in more recent win10 versions, giving people a bit more leeway in scheduling updates for themselves. While I do not approve of this forced restarting for updates, we are partially to blame if we've been told about the update up to a week beforehand. But if Windows never notified us about downloading the thing, yeah Microsoft bashing's fair game. Besides, if you're up to it, you can dig around Windows's guts to make Windows Update a wee bit more tolerable (even if you're on win10 Home). Google around for it. -->. I was going to just use this AutoIt script and call it a day.. until I found AutoIt is yet another thing my win10 complains about. So I did the sensible thing: learn PowerShell harder.

## Getting Started
_(Ignore [_explorer-session-snapshot.au3_](explorer-session-snapshot.au3)! I kept it here for legacy win7 stuffs.)_

1. Download the [_ExplorerSessionSnapshot.psm1_](ExplorerSessionSnapshot.psm1) module.
1. Import the module:
   ```PowerShell
   Import-Module "$DownloadLocation\ExplorerSessionSnapshot.psm1"
   ```

   > If an error appears, see [the note on execution policy](#miscellaneous-powershell-execution-policy).

   _(`Import-Module` only temporarily includes a module in your current session. You can always remove the _ExplorerSessionSnapshot_ module by entering `Remove-Module ExplorerSessionSnapshot` or opening a new PowerShell host.)_
1. ??? (explore it, fork it, automate it, ...)
   ```PowerShell
   Get-Help Save-FileExplorerSession
   Get-Help Restore-FileExplorerSession
   Get-Help Clear-FileExplorerSession
   ```

_Note: I recommend the purchase of an uninterruptable power supply for work and/or hosted services <!-- (if you're hosting a server on Windows for some reason) --> that should not be interrupted. Not allowing your computer to properly shut down or hibernate has a chance of corrupting your files. Don't be like me: I'mcheap. :I_ <!-- Or.. I guess you *could* be like me. But just know what you're getting yourself into. -->

### Miscellaneous: PowerShell Execution Policy
If upon attempting to import the module a security error appears stating "running scripts is disabled on this system", you will need to modify your PowerShell execution policy to permit it. To do so temporarily, run the following command:
```
Set-ExecutionPolicy Unrestricted Process
```
This command allows you to run any PowerShell script until you restart PowerShell. For most scripts downloaded from the Internet (such as this one), you will instead be prompted for confirmation before continuing.

For more information about PowerShell Execution Policy (including permanent settings), please see [http://go.microsoft.com/fwlink/?LinkID=135170](http://go.microsoft.com/fwlink/?LinkID=135170) (PowerShell Reference: About Execution Policies).

## TODO
- Cleanup: Ensure posh module looks all neat and proper for `Install-Module`
- PowerShell unit tests: Implement Pester?
- Automation: Write up a how2 on running the posh module via Windows scheduled tasks
- Exposure: Upload to PowerShell Gallery