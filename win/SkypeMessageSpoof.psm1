function Get-ClipboardAsDataObject
{
    <#
    .SYNOPSIS
    Wrapper function for `[System.Windows.Forms.Clipboard]::GetDataObject()`.

    .DESCRIPTION
    Wrapper function for `[System.Windows.Forms.Clipboard]::GetDataObject()`,
    exposing clipboard data not provided by the built-in 'Get-Clipboard' command.

    .INPUTS
    None. You cannot pipe objects to Get-ClipboardAsDataObject.

    .OUTPUTS
    System.Windows.Forms.DataObject
    #>
    Write-Output $([System.Windows.Forms.Clipboard]::GetDataObject())
}

function Expand-SkypeMessageDataObject
{
    <#
    .SYNOPSIS
    Extracts and displays metadata information on the provided Skype message (as a DataObject).

    .DESCRIPTION
    Extracts and displays metadata information on the provided Skype message (as a DataObject).

    .PARAMETER InputObject
    Specifies the Skype message (as a DataObject) to read.

    .EXAMPLE
    Get-ClipboardAsDataObject | Expand-SkypeMessageDataObject

    .INPUTS
    System.Windows.Forms.DataObject

        A DataObject representing clipboard content for a Skype message
        may be piped to Expand-SkypeMessageDataObject.

    .OUTPUTS
    System.String[2]

        [0] Plain text
        [1] SkypeMessageFragment MemoryStream as text
    #>
    param(
        [parameter(Mandatory, ValueFromPipeline)]
        [System.Windows.Forms.DataObject] $InputObject
    )
    $formats = $InputObject.GetFormats($false)
    if ($formats -notcontains 'SkypeMessageFragment')
        { Write-Warning 'The given InputObject does not appear to be a Skype message: SkypeMessageFragment stream not found.' }

    Write-Output $InputObject.GetText()
    Write-Output ([char[]]$InputObject.GetData('SkypeMessageFragment', $false).ToArray() -join '')
}

function Set-ClipboardSkypeMessage
{
    <#
    .SYNOPSIS
    *Note your current Windows clipboard will be overwritten.

    Sets the Windows clipboard to a spoofed Skype message for pasting into Skype.

    .DESCRIPTION
    Sets the Windows clipboard to a spoofed Skype message for pasting into Skype.
    Optionally uses a pre-existing clipboard Skype message (as DataObject) as a template.

    Recreate history!

    .NOTES
    Skype uses a 'SkypeMessageFragment' stream that is normally not visible when pasting.
    Pasting instead uses the standard 'Text', 'UnicodeText', or 'OEMText' streams.
    #>#or rewrite history
    param(
        [parameter(ParameterSetName='UsingTemplate', ValueFromPipeline, Mandatory)]
        [System.Windows.Forms.DataObject] $InputObject,

        #Optional: Omit to only get quote line
        [string] $MessageString,
        [datetime] $Time = [datetime]::Now,
        [parameter(ParameterSetName='UsingTemplate')]
        [parameter(ParameterSetName='ManualInput', Mandatory)]
        [string] $AuthorName,
        [string] $AuthorUsername,
        [parameter(ParameterSetName='UsingTemplate')]
        [parameter(ParameterSetName='ManualInput', Mandatory)]
        [string] $ConversationId,
        [parameter(ParameterSetName='UsingTemplate')]
        [parameter(ParameterSetName='ManualInput', Mandatory)]
        [string] $MessageGuid
    )
    $billgatesEpoch = [datetime]::new(1969, 12, 31, 20, 0, 0)
    $data = New-Object 'System.Windows.Forms.DataObject'

    # Extract InputObject data if provided InputObject,
    # only replacing non-bound params
    if ($PSBoundParameters.ContainsKey('InputObject'))
    {
        $formats = $InputObject.GetFormats($false)
        if ($formats -notcontains 'SkypeMessageFragment')
            { Write-Warning 'The given InputObject does not appear to be a Skype message: SkypeMessageFragment stream not found.' }

        $outMsgstr = $InputObject.GetText('UnicodeText')
        #TODO Also handle UnicodeText, Locale, Text, OEMText?

        # Try parsing SkypeMessageFragment
        [System.Text.RegularExpressions.Match] $rxmatch = [regex]::Match(
            #input
            ([char[]]$InputObject.GetData('SkypeMessageFragment', $false).ToArray() -join ''),
            #pattern
            '^<quote author="(?<username>.*?)" authorname="(?<name>.*?)" conversation="(?<convoid>.*?)" guid="(?<msgguid>.*?)" timestamp="(?<timestamp>\d+)"><legacyquote>\[(?<fmttime>.*?)\] \k<name>: <\/legacyquote>(?<msgstr>.*?)<legacyquote>\s{2,}(&lt;){3} <\/legacyquote><\/quote>'
        )
        if (!$rxmatch.Success)
        {
            $errargs = @{
                Category = 'ParserError'
                CategoryActivity = 'Encountered non-matching SkypeMessageFragment syntax.'
                CategoryReason = 'Failed to parse SkypeMessageFragment data stream.'
                Message = 'Failed to parse SkypeMessageFragment data stream.'
            }
            Write-Error @errargs -ErrorAction Stop
        }
        #else: SkypeMessageFragment parsed and tokenised

        # Copy tokens if no overriding param
        if (!$PSBoundParameters.ContainsKey('AuthorUsername'))
            { $AuthorUsername = $rxmatch.Groups['username'].Value }
        if (!$PSBoundParameters.ContainsKey('AuthorName'))
            { $AuthorName     = $rxmatch.Groups['name'].Value }
        if (!$PSBoundParameters.ContainsKey('ConversationId'))
            { $ConversationId = $rxmatch.Groups['convoid'].Value }
        if (!$PSBoundParameters.ContainsKey('MessageGuid'))
            { $MessageGuid    = $rxmatch.Groups['msgguid'].Value }
        if (!$PSBoundParameters.ContainsKey('Time'))
            { $Time = [datetime]$rxmatch.Groups['fmttime'].Value }
        if (!$PSBoundParameters.ContainsKey('MessageString'))
            { $MessageString  = $rxmatch.Groups['msgstr'].Value }
    }#end-if: InputObject processing
    $data.SetText($MessageString)

    # Generate timestamp
    $strTimestamp = "$([int]$Time.Subtract($billgatesEpoch).TotalSeconds)"
    $strFmtTimestamp = $Time.ToString('M/d/yyyy h:mm:ss tt')

    $strSkypeMessageFragment = '<quote author="{0}" authorname="{1}" conversation="{2}" guid="{3}" timestamp="{4}"><legacyquote>[{5}] {1}: </legacyquote>{6}<legacyquote>

&lt;&lt;&lt; </legacyquote></quote>' -f `
    "$AuthorUsername", "$AuthorName", "$ConversationId", "$MessageGuid", "$strTimestamp", "$strFmtTimestamp", "$MessageString"
    $data.SetData(
        'SkypeMessageFragment',
        [System.IO.MemoryStream]::new([byte[]][char[]]$strSkypeMessageFragment)
    )
    [System.Windows.Forms.Clipboard]::SetDataObject($data)
}
