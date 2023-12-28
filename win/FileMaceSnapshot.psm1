$cscopts = '/define:NO_USING'
if ([Environment]::Is64BitProcess) {
    # C# defines cannot be assigned a value, unlike C,
    # so we pass whether we're 64-bit
    # rather than passing the width of a pointer
    # (which can be defined on the C# side, anyway)
    $cscopts += ' /define:LP64'
}
Add-Type `
    -CompilerParameters ([System.CodeDom.Compiler.CompilerParameters]@{
        CompilerOptions = $cscopts }) `
    -Language CSharp `
    -MemberDefinition (Get-Content -Path "$PSScriptRoot\FileMaceSnapshotPlatformExtension.cs" -Raw) `
    -Name 'FileMaceSnapshotPlatformExtension' `
    -Namespace 'FileMaceSnapshotPlatformExtension' `
    -Using 'Microsoft.Win32.SafeHandles'
$Accelerators = [PowerShell].Assembly.GetType("System.Management.Automation.TypeAccelerators")
$Accelerators::Add('FMSPEX','FileMaceSnapshotPlatformExtension.FileMaceSnapshotPlatformExtension')

function Get-FileBasicInformation {
<#
.SYNOPSIS
Gets MACE timestamp information at the specified location.

.DESCRIPTION
Gets MACE timestamp information at the specified location.
MACE stands for:
M: Modified
A: Accessed
C: Created
E: Entry modified (NTFS master file table (MFT))

Useful for Windows forensic analysis.

.PARAMETER Path
Specifies the path to an item where `Get-FileBasicInformation` gets MACE timestamp information.
The paths can be paths to either files or directories.

.INPUTS
System.String[]
You can pipe paths to `Get-FileBasicInformation`.

.OUTPUTS
FileMaceSnapshotPlatformExtension.FileMaceSnapshotPlatformExtension+FileBasicInformation
`Get-FileBasicInformation` returns a struct with the following members:
- [DateTime] LastWriteTime  # M
- [DateTime] LastAccessTime # A
- [DateTime] CreationTime   # C
- [DateTime] ChangeTime     # E
- [uint]     FileAttributes

.NOTES
`Get-FileBasicInformation` is a PowerShell wrapper for method
[FMSPEX]::QueryInformationFileBasic(), which is a .NET P/Invoke method for
NTSYSCALLAPI NtQueryInformationFile(FILE_INFORMATION_CLASS.FileBasicInformation)
#>
    [OutputType([FileMaceSnapshotPlatformExtension.FileMaceSnapshotPlatformExtension+FileBasicInformation])]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string[]] $Path
    )

    PROCESS {
        foreach ($p in $Path) {
            try {
                [FMSPEX]::QueryInformationFileBasic($p) | Write-Output
            } catch {
                # Add the offending path if it's missing from the ErrorRecord
                if (!$_.TargetObject) {
                    Write-Error `
                        -Exception $_.Exception `
                        -Category $_.CategoryInfo.Category `
                        -ErrorId $_.FullyQualifiedErrorId `
                        -TargetObject $p
                }
            }
        }
    }
}

Export-ModuleMember -Function 'Get-FileBasicInformation'
