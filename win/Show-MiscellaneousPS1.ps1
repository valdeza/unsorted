# Miscellaneous commands stuck into this .ps1 for delicious syntax highlighting.

# When commands are added to this, most would probably not want to execute these arbitrary one-liners.
{ # Wrapped in ScriptBlock to prevent script execution
    # 'throw' statement to *really* prevent script execution
    throw 'Script execution prohibited.'



    # Linux `tail -f` equivalent
    Get-Content $varFilepath -Wait



    # List available methods for command outputs
    $varCommand | Get-Member
}
