# Miscellaneous commands stuck into this .ps1 for delicious syntax highlighting.

# When commands are added to this, most would probably not want to execute these arbitrary one-liners.
{ # Wrapped in ScriptBlock to prevent script execution
    # 'throw' statement to *really* prevent script execution
    throw 'Script execution prohibited.'



    # Linux `tail -f` equivalent
    Get-Content $varFilepath -Wait



    # List available methods for command outputs
    $varCommand | Get-Member



    # Poor man's password generator (insecure!)
    # Length of random string
    $varStrlen = 16
    # Any extra characters to be a part of the charset
    $varCharsetCustom = [char[]]''

    $varCharsetCharLower   = [char[]]([char]'a'..[char]'z')
    $varCharsetCharUpper   = [char[]]([char]'A'..[char]'Z')
    $varCharsetNum         = [char[]]([char]'0'..[char]'9')
    $varCharsetPunctuation = [char[]]'~!@#$%^&*()`-=_+[]\{}|;:''",.<>/?'
    $varCharset = $varCharsetCharUpper + $varCharsetCharLower + $varCharsetNum + $varCharsetPunctuation + $varCharsetCustom # Adjust to use desired charsets

    # Keep running the line below to generate strings
    $varStr = ''; for ($i = 0; $i -lt $varStrlen; ++$i) { $varStr += Get-Random $varCharset }; $varStr
}
