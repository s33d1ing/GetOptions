function Get-Options {
    <#
        .SYNOPSIS
            Parses command line arguments.

        .DESCRIPTION
            This module helps scripts to parse the command line arguments in $args.

            It supports the same conventions as the Unix getopt() function differentiating between arguments starting with "-" and "--".
            Long options similar to those supported by GNU software may be used as well via an optional third argument.

            The function returns an array containing the Options as a hashtable and the remaining arguments as a string array.

        .PARAMETER Arguments
            Array of values for undeclared parameters that are passed to a function, script, or script block.

        .PARAMETER OptionsString
            String containing the legitimate option characters.

            Options which require an argument should be followed by a colon (":").

        .PARAMETER LongOptions
            Array of strings containing the names of the long options.

            Options which require an argument should be followed by an equal sign ("=").

        .EXAMPLE
            Get-Options -Arguments ('-xzvf', 'Archive.zip', '--Force') -OptionsString 'f:vxz' -LongOptions ('File=', 'Force')

            Given: --Force = [bool]$Force; -f, --File = [string]$File; -v = [bool]$Verbose; -x = [bool]$Extract; -z = [bool]$Zip
            Returns: @{ Extract = $true; Zip = $true; Verbose = $true; File = 'Archive.zip'; Force = $true }

        .EXAMPLE
            Get-Options -Arguments ('-xzvf', 'Archive.zip', 'C:\Temp\Extracted') -OptionsString 'f:vxz' -LongOptions ('File=', 'Force')

            Given: --Force = [bool]$Force; -f, --File = [string]$File; -v = [bool]$Verbose; -x = [bool]$Extract; -z = [bool]$Zip
            Returns: @( @{ Extract = $true; Zip = $true; Verbose = $true; File = 'Archive.zip' }, 'C:\Temp\Extracted' )

        .EXAMPLE
            Get-Options -Arguments ('-xzv', '--File=Archive.zip', '--Force') -OptionsString 'f:vxz' -LongOptions ('File=', 'Force')

            Given: --Force = [bool]$Force; -f, --File = [string]$File; -v = [bool]$Verbose; -x = [bool]$Extract; -z = [bool]$Zip
            Returns: @{ Extract = $true; Zip = $true; Verbose = $true; File = 'Archive.zip'; Force = $true }

        .LINK
            https://github.com/lukesampson/scoop/blob/master/lib/getopt.ps1
            http://hg.python.org/cpython/file/2.7/Lib/getopt.py
    #>

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

    $Options = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
    $Remaining = New-Object -TypeName System.Collections.Generic.List[System.Object]

    # Ensure these are arrays
    $Arguments = $Arguments -as [array]
    $LongOptions = $LongOptions -as [array]

    for ($i = 0; $i -lt $Arguments.Length; $i++) {
        $arg = $Arguments[$i]

        if ($null -eq $arg) { continue }

        # Ensure arrays are added to the list as an element
        elseif ($arg -is [array]) { $Remaining.Add((, $arg)) }

        elseif ($arg -is [decimal]) { $Remaining.Add($arg) }
        elseif ($arg -is [double]) { $Remaining.Add($arg) }
        elseif ($arg -is [int]) { $Remaining.Add($arg) }

        elseif ($arg.StartsWith('--')) {
            # Capture the option and value if included
            if (($index = $arg.IndexOf('=')) -ne -1) {
                $name = $arg.Substring(2, ($index - 2))
                $value = $arg.Substring($index + 1)
            }

            # Capture the option and reset value to null
            else { $name, $value = $arg.Substring(2) }

            $longOpt = $LongOptions | Where-Object {
                $PSItem -match '^(' + [regex]::Escape($name) + ')=?$'
            }

            if ($longOpt) {
                if ($longOpt.EndsWith('=')) {
                    if ($null -ne $value) { $Options[$name] = $value }

                    # Check if on the last argument, or if the next argument begins with dash ("-")
                    elseif (($i -eq ($Arguments.Length - 1)) -or ($Arguments[$i + 1] -match '^-')) {
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
                        # Check if there are more flags, if on the last argument, or if the next argument begins with dash ("-")
                        if (($j -ne ($arg.Length - 1)) -or ($i -eq ($Arguments.Length - 1)) -or ($Arguments[$i + 1] -match '^-')) {
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

        else { $Remaining.Add($arg) }
    }

    return $Options, $Remaining
}
