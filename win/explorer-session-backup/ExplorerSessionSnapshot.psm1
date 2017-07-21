function Save-FileExplorerSession
{
    <#
    .SYNOPSIS
    Saves the directory paths of all open File Explorer windows.

    .DESCRIPTION
    Saves the directory paths of all open File Explorer windows.
    Each path is saved in a line-delimited text file,
    optionally creating a backup copy of the previous session snapshot.

    .PARAMETER Path
    Specifies the path to the file to write to.

    .PARAMETER Backup
    If the specified 'Path' already exists, will create a backup copy of the file before overwriting it.
    The file will be renamed with the current date and time appended to its original name, like so:
        _yyyyMMddHHmmss.bak (e.g. June 15, 2008 9:15:07 PM -> _20080615211507.bak)

    *Takes precedence over -NoBackup switch, if also defined.*

    .PARAMETER NoBackup
    Overrides the prompt to overwrite a pre-existing file, if applicable.

    *This switch is ignored if -Backup switch is also defined.*

    .PARAMETER PassThru
    Prints each explorer directory path as they are written to file.
    By default, this function does not generate any output.

    .PARAMETER WhatIf
    Shows what would happen if the function runs. The function is not run.

    .PARAMETER Confirm
    Prompts you for whether to write a File Explorer path to file.
    This may be desirable if you wish to save only a portion of File Explorer windows.

    .INPUTS
    None. You cannot pipe objects to Save-FileExplorerSession.

    .OUTPUTS
    None, if -PassThru switch omitted.

    .OUTPUTS
    System.String[], if -PassThru switch supplied.
    Save-FileExplorerSession generates a System.String object for each File Explorer path written to file.

    .NOTES
    Known issue: Restarting explorer.exe causes Save-FileExplorerSession to fail retrieval of open windows
    Workaround: Restart PowerShell host under new Explorer process, using Restore-FileExplorerSession to restore the previous session (if needed).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            if (!(Test-Path -Path $_ -IsValid))
                { throw "Invalid path." }
            if (Test-Path -Path $_ -PathType Container)
                { throw "Directory found, expected file." }
            else # if file or non-existent
                { $true }
        })]
        [string] $Path,

        [switch] $Backup,
        [switch] $NoBackup,
        [switch] $PassThru
    )

    BEGIN
    {
        if (Test-Path -Path $Path) # Does file exist?
        {
            $isBoundParamPresent = @{
                "WhatIf" = $PSCmdlet.MyInvocation.BoundParameters[“WhatIf”].IsPresent -eq $true;
                "Verbose" = $PSCmdlet.MyInvocation.BoundParameters[“Verbose”].IsPresent -eq $true
            }

            if ($Backup)
            {
                if ($NoBackup)
                    { Write-Warning "Switches -Backup and -NoBackup both defined. -NoBackup switch ignored." }

                $newName = "$Path _$(Get-Date -Format "yyyyMMddHHmmss").bak"
                Move-Item -Path $Path -Destination $newName -Confirm:$false -ErrorAction Stop #-WhatIf:$WhatIf
                Write-Verbose "Pre-existing file renamed to `"$newName`"."
            }
            elseif ($NoBackup -or $PSCmdlet.ShouldContinue("Proceed to overwrite `"${Path}`"?", "$(if ($isBoundParamPresent["WhatIf"]) {"What if: "})File already exists"))
                { Clear-Content -Path $Path -ErrorAction Stop -Confirm:$false -Verbose:$isBoundParamPresent["Verbose"] } #-WhatIf:$WhatIf
            else # -NoBackup switch not defined and user responded 'no'.
            {
                $errorArgs = @{
                    Category           = [Management.Automation.ErrorCategory]::OperationStopped;
                    CategoryActivity   = "Operation cancelled by user.";
                    CategoryReason     = "Unable to proceed: cannot write to file.";
                    CategoryTargetType = "Path";
                    Message            = "Operation cancelled by user. Please either relocate file or specify a different file path.";
                    RecommendedAction  = "Relocate file or choose a different file path.";
                    TargetObject       = $Path
                }
                Write-Error @errorArgs -ErrorAction Stop
            }
        }
    }

    PROCESS
    {
        $unknownExplorerWindowErrorArgs = @{
            Category           = [Management.Automation.ErrorCategory]::ReadError;
            CategoryActivity   = "Unhandled explorer window encountered.";
            CategoryReason     = "Unhandled explorer window encountered.";
            CategoryTargetType = "InternetExplorer"; # https://msdn.microsoft.com/en-us/library/windows/desktop/aa752084(v=vs.85).aspx (Windows Dev Center: "InternetExplorer object")
            ErrorId            = "UnhandledExplorerWindowError";
            Message            = "Unhandled explorer window skipped. Please report this error to the developer.";
        }

        $nonAutoOpenWindowsPresent = $false
        # Thanks SO: https://stackoverflow.com/a/31349468 (Answer to "get report of all open explorer windows")
        (New-Object -ComObject "Shell.Application").Windows() |
            Where-Object { $_.Name -eq "File Explorer" } | # Exclude Internet Explorer windows, if present
            ForEach-Object {
                if ($_.LocationURL -like "*about:blank*") # Unknown window. Silently ignore.
                { # ...unless -Debug flag passed.
                    Write-Debug "Found 'about:blank': $_"
                    continue
                }

                $strout = ""
                if ($_.LocationURL)
                    { $strout = [Uri]::UnescapeDataString($_.LocationURL) -replace "file:///","" -replace "/","\" }
                elseif ($_.LocationName) # if LocationURL empty, LocationName not empty
                    { $strout = "// $($_.LocationName)" }
                else # unknown explorer window
                {
                    Write-Error @unknownExplorerWindowErrorArgs -TargetObject $_
                    continue
                }

                if ($PSCmdlet.ShouldProcess("Path: $Path, Value: $strout", "Add Content")) # Add Value detail to confirmation
                {
                    Add-Content -Path $Path -Value $strout -PassThru:$PassThru -Confirm:$false
                    if ($strout.StartsWith("// "))
                        { $nonAutoOpenWindowsPresent = $true }
                }
            }
        if ($nonAutoOpenWindowsPresent)
            { Write-Warning "Some windows will not be able to be automatically restored with Restore-FileExplorerSession. These line entries have been marked beginning with '// '" }
    }
}

function Restore-FileExplorerSession
{
    <#
    .SYNOPSIS
    Restores open File Explorer windows from the specified file of directory paths.

    .DESCRIPTION
    Restores open File Explorer windows from the specified file of directory paths, opening each path in a new window.
    Said file is expected to contain line-delimited paths, ideally created by the Save-FileExplorerSession function.

    .PARAMETER Path
    Specifies the path to the file to read from.

    .PARAMETER PassThru
    Prints each explorer directory path as they are read from file.
    By default, this function does not generate any output.

    .PARAMETER WhatIf
    Shows what would happen if the function runs. The function is not run.

    .PARAMETER Confirm
    Prompts you for whether to open a File Explorer window for each path in file.
    This may be desirable if you wish to open only a portion of File Explorer windows.

    .INPUTS
    None. You cannot pipe objects to Restore-FileExplorerSession.

    .OUTPUTS
    None, if -PassThru switch omitted.

    .OUTPUTS
    System.String[], if -PassThru switch supplied.
    Restore-FileExplorerSession generates a System.String object for each path that opens a File Explorer window.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            if (!(Test-Path -Path $_ -PathType Leaf))
                { throw "File not found." }
            else
                { $true }
        })]
        [string] $Path,

        [switch] $PassThru
    )

    $app = New-Object -ComObject "Shell.Application"
    Get-Content -Path $Path |
    ForEach-Object {
        if ($_.StartsWith("// "))
            { Write-Warning "Cannot auto-open: $($_.Substring(3))" }
        elseif (!(Test-Path -Path $_ -IsValid))
            { Write-Error -Message "Invalid path." -Category InvalidArgument -TargetObject $_ }
        elseif (!(Test-Path -Path $_))
            { Write-Error -Message "Path not found. Skipping." -Category ObjectNotFound -TargetObject $_ }
        elseif ($PSCmdlet.ShouldProcess("Path: $_", "Open Explorer"))
        {
            $app.Explore($_)

            if ($PassThru)
                { Write-Output $_ }
        }
    }
}

function Clear-FileExplorerSession
{
    <#
    .SYNOPSIS
    Closes all open File Explorer windows.

    .DESCRIPTION
    Closes all open File Explorer windows.

    .PARAMETER PassThru
    Prints each explorer directory path closed.
    By default, this function does not generate any output.
    *File Explorer windows opened to a "special folder" (e.g. "This PC", "Power Options") will instead print the window title.*

    .PARAMETER WhatIf
    Shows what would happen if the function runs. The function is not run.

    .PARAMETER Confirm
    Prompts you for each individual File Explorer window on whether to close it.
    This may be desirable if you wish to close only a portion of File Explorer windows.

    .PARAMETER Force
    Forces the function to run without asking for user confirmation.

    .INPUTS
    None. You cannot pipe objects to Clear-FileExplorerSession.

    .OUTPUTS
    None, if -PassThru switch omitted.

    .OUTPUTS
    System.String[], if -PassThru switch supplied.
    Clear-FileExplorerSession generates a System.String object representing each File Explorer window.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [switch] $PassThru,
        [switch] $Force
    )

    $isBoundParamPresentWhatIf = $PSCmdlet.MyInvocation.BoundParameters[“WhatIf”].IsPresent -eq $true;
    if ($Force -or $PSCmdlet.ShouldContinue("Proceed to close explorer windows?", "$(if ($isBoundParamPresentWhatIf) {"What if: "})Confirm"))
    {
        $unknownExplorerWindowErrorArgs = @{
            Category           = [Management.Automation.ErrorCategory]::ReadError;
            CategoryActivity   = "Unhandled explorer window encountered.";
            CategoryReason     = "Unhandled explorer window encountered.";
            CategoryTargetType = "InternetExplorer"; # https://msdn.microsoft.com/en-us/library/windows/desktop/aa752084(v=vs.85).aspx (Windows Dev Center: "InternetExplorer object")
            ErrorId            = "UnhandledExplorerWindowError";
            Message            = "Unhandled explorer window skipped. Please report this error to the developer.";
        }

        # Make copy of windows since ForEach-Object apparently refreshes pipeline input (if a command).
        # InternetExplorer.Quit() modifies the ShellWindows collection.
        $explorerWindows = (New-Object -ComObject "Shell.Application").Windows() |
            Where-Object { $_.Name -eq "File Explorer" } # Exclude Internet Explorer windows, if present
        $explorerWindows | ForEach-Object { Write-Debug $explorerWindows.Count #dbg
                if ($_.LocationURL -like "*about:blank*") # Unknown window. Silently ignore.
                { # ...unless -Debug flag passed.
                    Write-Debug "Found 'about:blank': $_"
                    continue
                }

                $strout = ""
                if ($_.LocationURL)
                    { $strout = [Uri]::UnescapeDataString($_.LocationURL) -replace "file:///","" -replace "/","\" }
                elseif ($_.LocationName) # if LocationURL empty, LocationName not empty
                    { $strout = "// $($_.LocationName)" }
                else # unknown explorer window
                {
                    Write-Error @unknownExplorerWindowErrorArgs -TargetObject $_
                    continue
                }

                if ($PSCmdlet.ShouldProcess("Window: $strout", "Close Explorer Window"))
                {
                    $_.Quit()

                    if ($PassThru)
                        { Write-Output $strout }
                }
            }
    }
}