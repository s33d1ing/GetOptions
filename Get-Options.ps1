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

            An option's value can be provided as the proceeding argument or as a long option with an equal sign (i.e. --Option=Value).
            A single flag will evaluate to $true, repeating flags (i.e. -vvv) will evaluate to the number of occurrences (i.e. 3).

            Flags are case sensitive and long options are case insensitive.
            Note, PowerShell cannot handle like parameters of different cases.

        .PARAMETER OptionsString
            String containing the legitimate option characters.

            Options which require an argument should be followed by a colon (":").
            Options which accept an optional argument should be followed by two colons ("::").

        .PARAMETER LongOptions
            Array of strings containing the names of the long options.

            Options which require an argument should be followed by an equal sign ("=").
            Options which accept an optional argument should be followed by two equal signs ("==").

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

    # Replace "-", "/", or "+" prefixes with a single or double dash ("-")
    $Arguments = $Arguments -replace '^[-/+]{1}', '-' -replace '^[-/]{2}', '--'

    # Ensure these are arrays
    $Arguments = $Arguments -as [array]
    $LongOptions = $LongOptions -as [array]

    for ($i = 0; $i -lt $Arguments.Length; $i++) {
        $arg = $Arguments[$i]

        if ($null -eq $arg) { continue }

        # Ensure arrays are added to the list as an element
        elseif ($arg -is [array]) { $Remaining.Add((, $arg)) }

        # Ensure only strings are parsed as options or arguments
        elseif ($arg -isnot [string]) { $Remaining.Add($arg) }

        elseif ($LongOptions -and $arg.StartsWith('--')) {
            # Capture the option and value if included
            if (($index = $arg.IndexOf('=')) -ne -1) {
                $name = $arg.Substring(2, ($index - 2))
                $value = $arg.Substring($index + 1)
            }

            # Capture the option and reset value to null
            else { $name, $value = $arg.Substring(2) }

            # Check if the argument matches an option's name exactly, else check if the argument is an abbreviated name
            if (-not ($longOpt = $LongOptions | Where-Object { $PSItem -match ('^(' + [regex]::Escape($name) + ')={0,2}$') })) {
                $longOpt = $LongOptions | Where-Object { $PSItem -match ('^(' + [regex]::Escape($name) + '[\w-]*)={0,2}$') }
            }

            # Ensure there was only one match and capture the unabbreviated name
            if (($longOpt.Count -eq 1) -and ($name = $Matches[1] -as [string])) {

                if ($Options.Contains($name)) {
                    return ($Options, $Remaining, ('Option "' + $name + '" is already specified.'))
                }

                if ($longOpt.EndsWith('=')) {
                    if ($null -ne $value) { $Options.Add($name, $value) }

                    # Check if on the last argument, or if the next argument begins with dash ("-")
                    elseif (($i -eq ($Arguments.Length - 1)) -or ($Arguments[$i + 1] -match '^-')) {
                        if ($longOpt.EndsWith('==')) { $Options.Add($name, $true) }
                        else { return ($Options, $Remaining, ('Option "' + $name + '" requires an argument.')) }
                    }
                    else { $Options.Add($name, $Arguments[++$i]) }
                }
                else { $Options.Add($name, $true) }
            }
            elseif ($longOpt.Count -gt 1) {
                return ($Options, $Remaining, ('Option "' + $name + '" is not a unique prefix.'))
            }
            else {
                return ($Options, $Remaining, ('Option "' + $name + '" not recognized.'))
            }
        }

        elseif ($arg.StartsWith('-') -and ($arg -ne '-')) {
            for ($j = 1; $j -lt $arg.Length; $j++) {
                $flag = $arg[$j] -as [string]

                if ($Options.Contains($flag)) {
                    return ($Options, $Remaining, ('Option "' + $flag + '" is already specified.'))
                }

                if ($OptionsString -cmatch ([regex]::Escape($flag) + ':{0,2}')) {
                    $shortOpt = $Matches[0] -as [string]

                    if ($shortOpt.EndsWith(':')) {
                        # Check if there are more flags, if on the last argument, or if the next argument begins with dash ("-")
                        if (($j -ne ($arg.Length - 1)) -or ($i -eq ($Arguments.Length - 1)) -or ($Arguments[$i + 1] -match '^-')) {
                            if ($shortOpt.EndsWith('::')) { $Options.Add($flag, $true) }
                            else { return ($Options, $Remaining, ('Option "' + $flag + '" requires an argument.')) }
                        }
                        else { $Options.Add($flag, $Arguments[++$i]) }
                    }

                    # Check if the flag was repeated more than once
                    elseif ($arg -cmatch ([regex]::Escape($flag) + '{2,}')) {
                        $multiple = $Matches[0] -as [string]
                        $Options.Add($flag, $multiple.Length)

                        while ($arg[$j + 1] -eq $flag) { $j++ }
                    }
                    else { $Options.Add($flag, $true) }
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
