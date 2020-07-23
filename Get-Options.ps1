function Get-Options {
    [Alias('getopt', 'getopt_long')]
    [CmdletBinding(DefaultParameterSetName = 'getopt')]
    param (
        [Alias('argv')]
        [Parameter(Mandatory = $true, Position = 0)]
        [object[]]$Arguments,

        [Alias('optstring', 'shortopts')]
        [Parameter(Mandatory = $true, ParameterSetName = 'getopt', Position = 1)]
        [Parameter(Mandatory = $true, ParameterSetName = 'getopt_long', Position = 1)]
        [string]$OptionsString,

        [Alias('longopts')]
        [Parameter(Mandatory = $true, ParameterSetName = 'getopt_long', Position = 2)]
        [string[]]$LongOptions
    )

    $Options = New-Object -TypeName System.Collections.Hashtable
    $Remaining = New-Object -TypeName System.Collections.ArrayList

    # Ensure these are arrays
    $Arguments = $Arguments -as [array]
    $LongOptions = $LongOptions -as [array]

    for ($i = 0; $i -lt $Arguments.Length; $i++) {
        $arg = $Arguments[$i]

        if ($null -eq $arg) { continue }

        # Don't try to parse array arguments
        elseif ($arg -is [array]) { $Remaining += ,$arg }
        elseif ($arg -is [int]) { $Remaining += $arg }
        elseif ($arg -is [decimal]) { $Remaining += $arg }

        elseif ($arg.StartsWith('--')) {
            $name = $arg.Substring(2)

            $longOpt = $LongOptions | Where-Object {
                $PSItem -match '^(' + [regex]::Escape($name) + ')=?$'
            }

            if ($longOpt) {
                if ($longOpt.EndsWith('=')) {
                    if ($i -eq ($Arguments.Length - 1)) {
                        return ($Options, $Remaining, ('Option "' + $name + '" requires an argument.'))
                    }
                    else { $Options[$name] = $Arguments[++$i] }
                }
                else { $Options[$name] = $true }
            }
            else {
                return ($Options, $Remaining, ('Option "' + $name + '" not recognized.'))
            }
        }

        elseif ($arg.StartsWith('-') -and ($arg -ne '-')) {
            for ($j = 1; $j -lt $arg.Length; $j++) {
                $flag = $arg[$j] -as [string]

                if ($OptionsString -match ([regex]::Escape($flag) + ':?')) {
                    $shortOpt = $Matches[0]

                    if ($shortOpt.EndsWith(':')) {
                        if (($j -ne ($arg.Length - 1)) -or ($i -eq ($Arguments.Length - 1))) {
                            return ($Options, $Remaining, ('Option "' + $flag + '" requires an argument.'))
                        }
                        else { $Options[$flag] = $Arguments[++$i] }
                    }
                    else { $Options[$flag] = $true }
                }
                else {
                    return ($Options, $Remaining, ('Option "' + $flag + '" not recognized.'))
                }
            }
        }

        else { $Remaining += $arg }
    }

    return $Options, $Remaining
}
