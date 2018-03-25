# Miscellaneous commands stuck into this .ps1 for delicious syntax highlighting.

# When commands are added to this, most would probably not want to execute these arbitrary one-liners.
{ # Wrapped in ScriptBlock to prevent script execution
    # 'throw' statement to *really* prevent script execution
    throw 'Script execution prohibited.'



    # Count lines in files (could be used for source code files out of curiosity)
    Get-ChildItem *.cpp,*.h -Recurse | Get-Content | Measure-Object -Line

    # Linux `tail -f` equivalent
    Get-Content $varFilepath -Wait

    # List available methods for command outputs
    $varCommand | Get-Member

    # Personal preferred timestamp (esp. for file naming)
    (Get-Date -Format 'yyyyMMddHHmmsszzz') -replace ':',''

    # Set PowerShell console title (for labelling my sessions)
    $Host.UI.RawUI.WindowTitle = $varstrNewTitle

    # Shuffle arbitrary array
    $varArray | Sort-Object {Get-Random}



    # Madman's 'disk cleanup'
    ##NOTES
    # - Before running, `cd` into directory full of files you don't particularly care about
    # - If deleting random things is 2spooky,
    #   just run the Get-ChildItem cmdlet by itself to confirm all files displayed are acceptable to delete.

    ##PARAMS
    $varBytesToFree = 429496730
    # Modify Get-ChildItem as necessary to change deletion candidates
    $funcLs = { Get-ChildItem -Recurse }

    ##SCRIPT
    $varNumDeletionTargets = $funcLs.InvokeReturnAsIs().Length
    while ($varBytesToFree -gt 0 -and $varNumDeletionTargets -gt 0 )
    {
        $varFile = $funcLs.InvokeReturnAsIs() | Get-Random
        #TODO Handle possible failed delete operation, do not update counters
        $varBytesToFree -= $varFile.Length
        --$varNumDeletionTargets
        $varFile | Remove-Item -Verbose
    }



    # Poor man's password generator (insecure!)
    ##PARAMS
    # Length of random string
    $varStrlen = 16
    # Any extra characters to be a part of the charset
    $varCharsetCustom = [char[]]''

    ##SETUP
    $varCharsetCharLower   = [char[]]([char]'a'..[char]'z')
    $varCharsetCharUpper   = [char[]]([char]'A'..[char]'Z')
    $varCharsetNum         = [char[]]([char]'0'..[char]'9')
    $varCharsetPunctuation = [char[]]'~!@#$%^&*()`-=_+[]\{}|;:''",.<>/?'
    $varCharset = $varCharsetCharUpper + $varCharsetCharLower + $varCharsetNum + $varCharsetPunctuation + $varCharsetCustom # Adjust to use desired charsets

    ##OUTPUT
    # Keep running the line below to generate strings
    $varStr = ''; for ($i = 0; $i -lt $varStrlen; ++$i) { $varStr += Get-Random $varCharset }; $varStr
}
