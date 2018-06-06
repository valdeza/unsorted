# To use, run . .\New-TimeLog.ps1

function New-TimeLog
{
    <#
    .SYNOPSIS
    Writes a series of timestamped entries to a file.

    .DESCRIPTION
    The New-TimeLog function writes timestamped entries to a file. 
    The date and log entry format is customisable for absolutely no good reason (to pass the time at the time of writing).

    .PARAMETER DateFormat
    Displays the date and time in the Microsoft .NET Framework format indicated by the format specifier. 
    For more information, run `Get-Help Get-Date -Parameter 'Format'` / 
    For a list of available format specifiers, see the DateTimeFormatInfo Class in MSDN at http://msdn.microsoft.com/library/system.globalization.datetimeformatinfo.aspx

    .PARAMETER FilePath
    Specifies the path to the output file.

    .PARAMETER LogEntryFormat
    Composes log entries according to the specified format string. 
    Must contain the following format characters (without quotes) '%1' and '%2', which will be substituted as follows: 
    '%1' - Timestamp, formatted according to parameter 'DateFormat' / 
    '%2' - Log entry // 
    Format characters do not have to be in numerical order.

    .EXAMPLE
    PS C:\>New-TimeLog 'tmp.log'
    
    Writes a timelog to file 'tmp.log'. 

    Sample log entry: 
    2014-09-21 21:51:10.1040 - Sample text

    .EXAMPLE
    PS C:\>New-TimeLog -FilePath 'C:\path\tmp.log' -DateFormat 'MMM %d (ddd), %y; hh:%f%tzz' -LogEntryFormat "<%1>`n`t%2`n</%1>"

    Writes a timelog to the specified absolute file path, with some sort of customised format.

    Sample log entry, written Sat Feb 17 14:29:11 2018 -0500:
    <Feb 17 (Sat), 18; 02:20P-05>
    	Why would you do this
    </Feb 17 (Sat), 18; 02:20P-05>

    .INPUTS
    None
        You cannot pipe input to New-TimeLog.

    .OUTPUTS
    None
        New-TimeLog writes to file. It does not return any objects.

    .NOTES
    is windows update done interrupting my work nope it's still running guess I'll keep writing documentation for an extremely simple script
    actually maybe this would be useful as a future documentation example
    #>
    [CmdletBinding()]
    param(
        [parameter(
            HelpMessage='Enter file path to save log as.',
            Mandatory=$true)]
        [ValidateScript({
            if (!(Test-Path -Path $_ -IsValid))
                { throw 'Invalid path.' }
            if (Test-Path -Path $_ -PathType Container)
                { throw 'Directory found, expected file.' }
            else # if file or non-existent
                { $true }
        })]
        [string] $FilePath,

        [PSDefaultValue(Help = 'yyyy-MM-dd HH:mm:ss.ffff')]
        [string] $DateFormat = 'yyyy-MM-dd HH:mm:ss.ffff',

        [PSDefaultValue(Help = '%1 - %2')]
        [string] $LogEntryFormat = '%1 - %2'
    )
    Write-Host 'Enter blank line to quit.'
    while ($true)
    {
        $tmpstr = Read-Host -Prompt ':'
        if ($tmpstr -eq '') 
            { break }
        #else: Write to file and output date to screen
        $now = Get-Date -Format $DateFormat
        Write-Host "`t@ $now"
        
        $entry = $LogEntryFormat -replace '%1',"$now" -replace '%2',"$tmpstr"
        $entry | Out-File -FilePath $FilePath -Encoding oem -Append
        Write-Verbose "`n$entry"
    }
}

Get-Command New-TimeLog -Syntax
if ($?)
    { Write-Output 'Excessive Get-Help documentation available.' }
