<#
.SYNOPSIS
Writes text to stderr when running in a regular console window,
to the host''s error stream otherwise.

.DESCRIPTION
Writing to true stderr allows you to write a well-behaved CLI
as a PS script that can be invoked from a batch file, for instance.

Note that PS by default sends ALL its streams to *stdout* when invoked from 
cmd.exe.

This function acts similarly to Write-Host in that it simply calls
.ToString() on its input; to get the default output format, invoke
it via a pipeline and precede with Out-String.

.NOTES
Copypasta'd from https://stackoverflow.com/a/15669365 ; by mklement0 on Stack Overflow
#> 
function Write-StdErr {
  param ([PSObject] $InputObject)
  $outFunc = if ($Host.Name -eq 'ConsoleHost') { 
    [Console]::Error.WriteLine
  } else {
    $host.ui.WriteErrorLine
  }
  if ($InputObject) {
    [void] $outFunc.Invoke($InputObject.ToString())
  } else {
    [string[]] $lines = @()
    $Input | % { $lines += $_.ToString() }
    [void] $outFunc.Invoke($lines -join "`r`n")
  }
}

function Select-FFprobeAudioInfo([string] $InputObject)
{
    <#
    .SYNOPSIS
    Parses the given FFprobe output and extracts sampling and bitrate information.

    .DESCRIPTION
    Internal function.
    Parses the given FFprobe output and extracts sampling and bitrate information.
    - Only handles output for files containing only a single audio stream
    - On failure:
        - Calls Write-Error
        - It is suggested to display $InputObject

    .OUTPUTS
    System.Management.Automation.PSObject

        Select-FFprobeAudioInfo returns a PSObject with the following properties:
        - [bool] Success    : Whether extraction succeeded. If true, the other properties will be set.
        - [int]  SampleRate : (in Hz)
        - [int]  Bitrate    : (in kbps)
    #>

    $INVALID_VALUE = -1
    $ret = New-Object 'PSObject' -Property (@{
        'Success' = $false
        'SampleRate' = $INVALID_VALUE
        'Bitrate' = $INVALID_VALUE
    })

    $slsres = ($InputObject | Select-String -Pattern 'Stream #\d:\d.*: Audio:').Matches
    if ($slsres.Count -le 0)
    { # oi what're you trying to pull is this even an audio file
        Write-Error `
            -Message 'Audio stream not found.' `
            -Category ObjectNotFound `
            -CategoryReason 'Provided FFprobe output indicates file contains no audio streams.' `
            -CategoryTargetType $InputObject.GetType() `
            -TargetObject $InputObject
        return $ret
    }
    elseif ($slsres.Count -gt 1)
    {
        Write-Error `
            -Message "Detected multiple ($($slsres.Count)) audio streams; expected 1." `
            -Category LimitsExceeded `
            -CategoryActivity 'Provided FFprobe output indicates file contains multiple audio streams.' `
            -CategoryReason 'This function currently only works on files containing only a single audio stream.' `
            -CategoryTargetType $InputObject.GetType() `
            -RecommendedAction 'Consider manually processing file to select audio stream to use.' `
            -TargetObject $InputObject
        return $ret
    }
    #else ($slsres.Count -eq 1)

    $slsres = ($InputObject | Select-String -Pattern 'Stream #\d:\d.*?: Audio:.*? (?<samplingrate>\d+) Hz,.*? (?<bitrate>\d+) kb/s' -List).Matches
    if ($slsres.Count -gt 0)
    {
        $slsres = $slsres[0].Groups
        $ret.SampleRate = $slsres['samplingrate'].Value
        $ret.Bitrate = $slsres['bitrate'].Value
        $ret.Success = $true

        return $ret
    }
    #else: Parse failed, try alternative

    #.ogg output?
    $slsres = ($InputObject | Select-String -Pattern 'Input #0, (.*?)(, .*?):' -List).Matches
    if ($slsres.Count -gt 0 -and $slsres[0].Groups[1].Value.Equals('ogg'))
    {
        $slsres = ($InputObject | Select-String -Pattern 'bitrate: (\d+) kb\/s' -List).Matches
        if ($slsres.Count -eq 1)
            { $ret.Bitrate = $slsres[0].Groups[1].Value }

        $slsres = ($InputObject | Select-String -Pattern 'Stream #0:0.*?:.*? (\d+) Hz' -List).Matches
        if ($slsres.Count -eq 1)
            { $ret.SampleRate = $slsres[0].Groups[1].Value }

        $ret.Success = ($ret.Bitrate -ne $INVALID_VALUE -and $ret.SampleRate -ne $INVALID_VALUE)
        Write-Debug $ret
        if ($ret.Success)
            { return $ret }
    }
    #else: `*-,-*`*-, >>> PANIC <<< ,-*`*-,-*`
    return $ret
}

function Invoke-FFmpegConvertToKindleMp3
{
    <#
    .SYNOPSIS
    Converts provided audio files to Amazon Kindle-friendly .mp3 files.

    .DESCRIPTION
    Note: This function is requires ffprobe.exe and ffmpeg.exe .

    Converts provided audio files to Amazon Kindle-friendly .mp3 files.
    Using ffprobe.exe, input files will be matched to the closest constant bitrate to specify in ffmpeg.exe .

    .PARAMETER AudioFiles
    Specifies the audio files to convert.
    To enable progress reporting, specify this parameter explicitly rather than via pipeline.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.IO.FileInfo[]]$AudioFiles,

        [ValidateScript({
            if(!($_ | Test-Path) ){
                throw "Path does not exist." 
            }
            if(!($_ | Test-Path -PathType Leaf) ){
                throw "Invalid path: file expected."
            }
            return $true
        })]
        [System.IO.FileInfo]$FFprobeBinPath,

        [ValidateScript({
            if(!($_ | Test-Path) ){
                throw "Path does not exist." 
            }
            if(!($_ | Test-Path -PathType Leaf) ){
                throw "Invalid path: file expected."
            }
            return $true
        })]
        [System.IO.FileInfo]$FFmpegBinPath
    )

    BEGIN
    {
        if ($PSBoundParameters['Debug'])
            { $DebugPreference = 'Continue' }

        if (!$PSBoundParameters.ContainsKey('FFprobeBinPath'))
        {
            try
                { $FFprobeBinPath = (Get-Command 'ffprobe' -CommandType Application -TotalCount 1 -ErrorAction Stop).Path }
            catch [System.Management.Automation.CommandNotFoundException]
                { Write-Error -Exception $_.Exception -Message "'ffprobe.exe' not found. Update `$env:Path or specify parameter 'FFprobeBinPath'." -ErrorAction Stop }
        }

        if (!$PSBoundParameters.ContainsKey('FFmpegBinPath'))
        {
            try
                { $FFmpegBinPath = (Get-Command 'ffmpeg' -CommandType Application -TotalCount 1 -ErrorAction Stop).Path }
            catch [System.Management.Automation.CommandNotFoundException]
                { Write-Error -Exception $_.Exception -Message "'ffmpeg.exe' not found. Update `$env:Path or specify parameter 'FFmpegBinPath'." -ErrorAction Stop }
        }

        $PROGID_MAIN = 477214246
        $PROGID_PROC = 1416983588
        $cProcessed = -1
        $cFailed = 0
        $nBytesDone = 0
        $nBytesTotal = 0
        $bReportTotalProgress = $AudioFiles.Count -gt 0
        if ($bReportTotalProgress)
        {
            $nBytesTotal = ($AudioFiles | Measure-Object -Property 'Length' -Sum).Sum
            Write-Debug "$nBytesTotal bytes to process"
        }
    }

    PROCESS
    {
        foreach ($fin in $AudioFiles)
        {
            ++$cProcessed
            $nBytesDone += $fin.Length

            $foutname = [System.IO.Path]::ChangeExtension($fin.FullName, 'mp3')
            # Do not reprocess existing output files
            if (Test-Path -LiteralPath $foutname)
            {
                Write-Error `
                    -Message 'Skipping file: destination .mp3 already exists.' `
                    -Category ResourceExists `
                    -CategoryTargetType 'Path' `
                    -TargetObject "$fin" `
                    -RecommendedAction 'Delete destination file to attempt file conversion.'
                ++$cFailed
                continue
            }

            $progressArgs = @{
                'Activity' = 'Batch converting files to Kindle .mp3...'
                'CurrentOperation' = "$fin"
                'Id' = $PROGID_MAIN
                'Status' = "$cProcessed files processed"
            }
            if ($bReportTotalProgress)
            {
                $progressArgs['Status'] = "$cProcessed / $($AudioFiles.Count) files processed"
                $progressArgs['PercentComplete'] = (if ($cProcessed -eq 0) {0} else {100.0 * ($nBytesDone - $fin.Length) / $nBytesTotal})
            }
            if ($cFailed -gt 0)
                { $progressArgs['Status'] += ", $cFailed failed" }
            Write-Progress @progressArgs
            Write-Verbose "ffprobe: $fin"
            $progressArgs_File = @{
                'Activity' = 'ffprobe: Analysing file...'
                'Id' = $PROGID_PROC
                'ParentId' = $PROGID_MAIN
            }
            Write-Progress @progressArgs_File

            $psi = New-Object 'System.Diagnostics.ProcessStartInfo'
            $psi.FileName = "$FFprobeBinPath"
            $psi.Arguments = """$($fin.FullName)"""
            Write-Debug $fin.FullName
            $psi.UseShellExecute = $false # Required for redirecting IOstreams
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true
            $p = New-Object 'System.Diagnostics.Process'
            $p.StartInfo = $psi
            $p.Start() | Out-Null
            $p.WaitForExit()
            $stderr = $p.StandardError.ReadToEnd()

            if ($p.ExitCode -ne 0)
            {
                Write-Debug ("ffprobe.exe returned with non-zero exit code: {0}" -f $p.ExitCode)
                Write-Error `
                    -Message 'ffprobe.exe reported an error while processing file.' `
                    -Category FromStdErr `
                    -CategoryActivity 'ffprobe.exe reported an error while processing file.' `
                    -CategoryTargetName "$fin" `
                    -CategoryTargetType $stderr.GetType() `
                    -TargetObject $stderr
                Write-StdErr "$stderr"
                ++$cFailed
                continue
            }
            #else: ffprobe.exe returned 0 (OK)
            Write-Debug "$stderr"

            $psoAudioInfo = Select-FFprobeAudioInfo $stderr
            if (!$psoAudioInfo.Success)
            {
                Write-Error `
                    -Message "Cannot process: failed to parse audio information for file '$fin'." `
                    -CategoryTargetType $stderr.GetType() `
                    -TargetObject $stderr
                Write-StdErr "$stderr"
                ++$cFailed
                continue
            }
            else
            {
                Write-Debug "Parsed audio info: $($psoAudioInfo | Select-Object * -ExcludeProperty 'Success')"

                # Arbitrarily decide what constant bitrate to use
                $br = -1
                if ($psoAudioInfo.Bitrate -lt 105)
                    { $nbr = 96 }
                elseif ($psoAudioInfo.Bitrate -lt 140) #144 unavailable
                    { $nbr = 128 }
                elseif ($psoAudioInfo.Bitrate -lt 185) #192 unavailable
                    { $nbr = 160 }
                elseif ($psoAudioInfo.Bitrate -lt 275)
                    { $nbr = 256 }
                else
                    { $nbr = 320 }

                Write-Verbose "Source bitrate: $($psoAudioInfo.Bitrate) -> Target bitrate: $nbr"
                $psoAudioInfo.Bitrate = $nbr
            }

            $nSecDuration = -1
            $slsmatch = ($stderr | Select-String -Pattern 'Duration: ?(?<h>\d+):(?<m>\d+):(?<s>\d+\.\d+)' -List).Matches
            if ($slsmatch.Count -eq 0)
            {
                Write-Error `
                    -Message 'Failed to parse duration. Progress reporting will be unavailable for this file.' `
                    -Category ObjectNotFound `
                    -CategoryTargetType $stderr.GetType() `
                    -TargetObject $stderr
            }
            else
            {
                $slsmatch = $slsmatch[0].Groups
                $nSecDuration = 3600 * $slsmatch['h'].Value + 60 * $slsmatch['m'].Value + $slsmatch['s'].Value
                Write-Debug ("Parsed duration: {0}h{1}m{2}s == {3}s" -f $slsmatch['h'].Value, $slsmatch['m'].Value, $slsmatch['s'].Value, $nSecDuration)
            }

            $progressArgs_File['Activity'] = 'ffmpeg: Converting file...'
            Write-Progress @progressArgs_File
            Write-Verbose "ffmpeg: $fin"

            $psi = New-Object 'System.Diagnostics.ProcessStartInfo'
            $psi.FileName = "$FFmpegBinPath"
            $psi.Arguments = "-i ""$($fin.FullName)"" -ar $($psoAudioInfo.SampleRate) -b:a $($psoAudioInfo.Bitrate)k ""$foutname"""
            Write-Debug "exec: ffmpeg.exe $($psi.Arguments)"
            $psi.UseShellExecute = $false # Required for redirecting IOstreams
            $psi.RedirectStandardOutput = $false
            $psi.RedirectStandardError = $true
            $p = New-Object 'System.Diagnostics.Process'
            $p.StartInfo = $psi
            $p.Start() | Out-Null
            while (!$p.HasExited)
            {
                $strstat = $p.StandardError.ReadLine()
                if ($strstat -eq $null)
                    { break } # End of stream reached
                Write-Debug $strstat

                $slsstat = ($strstat | Select-String -Pattern 'size=\s*(?<size>\d+)kB time=(?<th>\d+):(?<tm>\d+):(?<ts>\d+\.\d+) bitrate=\s*(?<bitrate>[\d\.]+)kbits/s speed=(?<speed>[\d\.]+)x' -List).Matches
                if ($slsstat.Count -eq 0)
                    { continue } # Target pattern mismatch

                $slsstat = $slsstat[0].Groups
                if ($nSecDuration -eq -1)
                    { $progressArgs_File['Status'] = ("time={0}h{1}m{2}s" -f $slsstat['th'].Value, $slsstat['tm'].Value, $slsstat['ts'].Value) }
                else
                {
                    $nSecProcessed = 3600 * $slsstat['th'].Value + 60 * $slsstat['tm'].Value + $slsstat['ts'].Value
                    $progressArgs_File['PercentComplete'] = 100 * $nSecProcessed / $nSecDuration
                    if ($nSecDuration -ge 3600)
                    {
                        $h = [Math]::Floor($nSecDuration / 3600)
                        $m = [Math]::Floor(($nSecDuration - $h * 3600) / 60)
                        $s = ($nSecDuration - $h * 3600 - $m * 60)
                        $progressArgs_File['Status'] = ("time={0}h{1}m{2}s/{3}h{4}m{5:f2}s" -f `
                            $slsstat['th'].Value, $slsstat['tm'].Value, $slsstat['ts'].Value, `
                            $h, $m, $s
                        )
                    }
                    elseif ($nSecDuration -ge 60)
                    {
                        $m = [Math]::Floor($nSecDuration / 60)
                        $s = ($nSecDuration - $m * 60)
                        $progressArgs_File['Status'] = ("time={0}m{1}s/{2}m{3:f2}s" -f `
                            $slsstat['tm'].Value, $slsstat['ts'].Value, `
                            $m, $s
                        )
                    }
                    else
                        { $progressArgs_File['Status'] = "time=${nSecDuration}s/${nSecProcessed}" }

                    if ($bReportTotalProgress)
                    {
                        $progressArgs['PercentComplete'] = 100.0 * ($nBytesDone - $fin.Length * (1.0 - $nSecProcessed / $nSecDuration)) / $nBytesTotal
                        Write-Progress @progressArgs
                    }
                }
                $progressArgs_File['Status'] += (" size={0}kB bitrate={1}kbps speed={2}x" -f `
                    $slsstat['size'].Value, $slsstat['bitrate'].Value, $slsstat['speed'])
                Write-Progress @progressArgs_File
            }
            Write-Progress @progressArgs_File -Completed

            if ($p.ExitCode -ne 0)
            {
                Write-Debug ("ffmpeg.exe returned with non-zero exit code: {0}" -f $p.ExitCode)
                Write-Error `
                    -Message 'ffmpeg.exe reported an error while processing file.' `
                    -Category FromStdErr `
                    -CategoryActivity 'ffprobe.exe reported an error while processing file.' `
                    -CategoryTargetName "$fin"
                ++$cFailed
            }
            $p.Close()
        }#end-foreach file pipeline
    }#/PROCESS
}

Export-ModuleMember -Function 'Invoke-FFmpegConvertToKindleMp3'
