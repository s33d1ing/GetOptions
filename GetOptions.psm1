function Get-Options {
    <#
        .SYNOPSIS
            Parses command line arguments.

        .DESCRIPTION
            This module helps scripts to parse the command line arguments in $args.

            It supports the same conventions as the getopt function but allows options starting with "-", "/", or "+".

            The function returns an array containing the Options as a hashtable and the remaining arguments as a string array.
            If an error is encountered, a third array object containing the error message is returned.

        .PARAMETER Arguments
            Array of values for undeclared parameters that are passed to a function, script, or script block.

            An short option's value can be provided as the proceeding argument (i.e. -f Bar) or immediately following the flag (i.e. -fBar).
            A single flag (i.e. -v) will evaluate to $true, repeating flags (i.e. -vvv) will evaluate to the number of occurrences (i.e. 3).

            Note, flags are case sensitive but PowerShell cannot handle like parameters of different cases.

        .PARAMETER OptionsString
            String containing the legitimate option characters.

            Options which require an argument should be followed by a colon (":").
            Options which accept an optional argument should be followed by two colons ("::").
    #>

    [Alias('getopt')]
    [CmdletBinding()]

    param (
        [Alias('argv')]
        [Parameter(Mandatory = $true, Position = 0)]
        [object[]]$Arguments,

        [Alias('optstring', 'shortopts')]
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$OptionsString
    )

    Convert-Arguments @PSBoundParameters
}

function Get-LongOptions {
    <#
        .SYNOPSIS
            Parses command line arguments.

        .DESCRIPTION
            This module helps scripts to parse the command line arguments in $args.

            It works the same as the Get-Options function, but also accepts long options starting with "--" or "//".

            The function returns an array containing the Options as a hashtable and the remaining arguments as a string array.
            If an error is encountered, a third array object containing the error message is returned.

        .PARAMETER Arguments
            Array of values for undeclared parameters that are passed to a function, script, or script block.

            An short option's value can be provided as the proceeding argument (i.e. -f Bar) or immediately following the flag (i.e. -fBar).
            A single flag (i.e. -v) will evaluate to $true, repeating flags (i.e. -vvv) will evaluate to the number of occurrences (i.e. 3).

            An long option's value can be provided as the proceeding argument (i.e. --Foo Bar) or after an equals sign (i.e. --Foo=Bar).

            Note, flags are case sensitive but PowerShell cannot handle like parameters of different cases.

        .PARAMETER OptionsString
            String containing the legitimate option characters.

            Options which require an argument should be followed by a colon (":").
            Options which accept an optional argument should be followed by two colons ("::").

        .PARAMETER LongOptions
            Array of strings containing the names of the long options.

            Options which require an argument should be followed by an equal sign ("=").
            Options which accept an optional argument should be followed by two equal signs ("==").
    #>

    [Alias('getopt_long')]
    [CmdletBinding()]

    param (
        [Alias('argv')]
        [Parameter(Mandatory = $true, Position = 0)]
        [object[]]$Arguments,

        [Alias('optstring', 'shortopts')]
        [Parameter(Position = 1)]
        [string]$OptionsString,

        [Alias('longopts')]
        [Parameter(Mandatory = $true, Position = 2)]
        [string[]]$LongOptions
    )

    Convert-Arguments @PSBoundParameters
}

function Get-LongOptionsOnly {
    <#
        .SYNOPSIS
            Parses command line arguments.

        .DESCRIPTION
            This module helps scripts to parse the command line arguments in $args.

            It works the same as the Get-LongOptions function, but allows long options to start with a "-", "/", or "+".
            If an option does not match a long option, but matches a short option, it is parsed as a short option.

            The function returns an array containing the Options as a hashtable and the remaining arguments as a string array.
            If an error is encountered, a third array object containing the error message is returned.

        .PARAMETER Arguments
            Array of values for undeclared parameters that are passed to a function, script, or script block.

            An short option's value can be provided as the proceeding argument (i.e. -f Bar) or immediately following the flag (i.e. -fBar).
            A single flag (i.e. -v) will evaluate to $true, repeating flags (i.e. -vvv) will evaluate to the number of occurrences (i.e. 3).

            An long option's value can be provided as the proceeding argument (i.e. --Foo Bar) or after an equals sign (i.e. --Foo=Bar).

            Note, flags are case sensitive but PowerShell cannot handle like parameters of different cases.

        .PARAMETER OptionsString
            String containing the legitimate option characters.

            Options which require an argument should be followed by a colon (":").
            Options which accept an optional argument should be followed by two colons ("::").

        .PARAMETER LongOptions
            Array of strings containing the names of the long options.

            Options which require an argument should be followed by an equal sign ("=").
            Options which accept an optional argument should be followed by two equal signs ("==").
    #>

    [Alias('getopt_long_only')]
    [CmdletBinding()]

    param (
        [Alias('argv')]
        [Parameter(Mandatory = $true, Position = 0)]
        [object[]]$Arguments,

        [Alias('optstring', 'shortopts')]
        [Parameter(Position = 1)]
        [string]$OptionsString,

        [Alias('longopts')]
        [Parameter(Mandatory = $true, Position = 2)]
        [string[]]$LongOptions
    )

    Convert-Arguments @PSBoundParameters -LongOptionsOnly
}


function Convert-Arguments {
    param ([object[]]$Arguments, [string]$OptionsString, [string[]]$LongOptions, [switch]$LongOptionsOnly)


    $Options = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
    $Remaining = New-Object -TypeName System.Collections.Generic.List[System.Object]

    # Ensure these are arrays
    $Arguments = $Arguments -as [array]
    $LongOptions = $LongOptions -as [array]


    for ($i = 0; $i -lt $Arguments.Length; $i++) {
        $arg = $Arguments[$i]


        # Allow "-" as well as "--" to indicate a long option
        if ($LongOptionsOnly -and ($arg -match '^[-/\+][^-/]')) {
            $arg = '--' + $arg.Substring(1)

            # Check if the option does not match a long option, but does match a short option
            if (-not ($LongOptions -match ('^(' + [regex]::Escape($arg.Substring(2)) + '[\w-]*)={0,2}$'))) {
                if (($OptionsString -cmatch ([regex]::Escape($arg.SubString(2)) + ':{0,2}'))) {
                    $arg = '-' + $arg.Substring(2)
                }
            }
        }

        # If the options string contains "W;", then "-W Option" is treated as "--Option"
        if ($LongOptions -and ($OptionsString -match 'W;') -and ($arg -cmatch '^[-/\+]W(.+)?')) {
            if ($null -ne $Matches[1]) { $arg = '--' + $Matches[1] }
            elseif ($i -lt ($Arguments.Length - 1)) {
                if ($Arguments[$i + 1] -notmatch '^[-/\+].') {
                    $arg = '--' + $Arguments[++$i]
                }
            }
        }


        if ($null -eq $arg) { continue }

        # Ensure only strings are parsed as options or arguments
        elseif ($arg -isnot [string]) { $Remaining.Add($arg) }

        # The argument "--" forces an end of option processing regardless of the scanning mode
        elseif ($arg -match '^--$') { while ($Arguments[$i + 1]) { $Remaining.Add($Arguments[++$i]) } }


        elseif ($LongOptions -and ($arg -match '^(--|//)([\w-]+)([=:](.+))?')) {
            $name = $Matches[2] -as [string]


            # Capture the value if it was included with the option
            if ($null -ne $Matches[4]) { $value = $Matches[4] -as [string] }

            # Check if the argument matches an option's name exactly, or if it is an abbreviated name
            if (-not ($longOpt = $LongOptions | Where-Object { $PSItem -match ('^(' + $name + ')={0,2}$') })) {
                $longOpt = $LongOptions | Where-Object { $PSItem -match ('^(' + $name + '[\w-]*)={0,2}$') }
            }


            if ($longOpt.Count -eq 1) {
                # Capture the unabbreviated name
                $name = $Matches[1] -as [string]


                if ($Options.Contains($name)) {
                    $message = 'Option "' + $name + '" is already specified.'
                    return $Options, $Remaining, $message
                }


                if ($longOpt -match '=$') {
                    if ($null -ne $value) { $Options.Add($name, $value) }

                    # Check if on the last argument, or if the next argument is another flag or option
                    elseif (($i -eq ($Arguments.Length - 1)) -or ($Arguments[$i + 1] -match '^[-/\+].')) {
                        if ($longOpt -match '==$') { $Options.Add($name, $true) }
                        else {
                            $message = 'Option "' + $name + '" requires an argument.'
                            return $Options, $Remaining, $message
                        }
                    }
                    else { $Options.Add($name, $Arguments[++$i]) }
                }
                else { $Options.Add($name, $true) }
            }

            elseif ($longOpt.Count -gt 1) {
                $message = 'Option "' + $name + '" is not a unique prefix.'
                return $Options, $Remaining, $message
            }
            else {
                $message = 'Option "' + $name + '" not recognized.'
                return $Options, $Remaining, $message
            }
        }

        elseif ($OptionsString -and ($arg -match '^[-/\+].')) {
            for ($j = 1; $j -lt $arg.Length; $j++) {
                $flag = $arg[$j] -as [string]

                if ($OptionsString -cmatch ([regex]::Escape($flag) + ':{0,2}')) {
                    $shortOpt = $Matches[0] -as [string]


                    if ($Options.Contains($flag)) {
                        $message = 'Option "' + $flag + '" is already specified.'
                        return $Options, $Remaining, $message
                    }


                    if ($shortOpt -match ':$') {
                        if (($j -eq 1) -and ($j -ne ($arg.Length - 1))) {
                            # Capture anything following the flag
                            $Options.Add($flag, $arg.Substring($j + 1))

                            while ($j -lt $arg.Length) { $j++ }
                        }

                        # Check if there are more arguments, or if the next argument is another flag or option
                        elseif (($i -eq ($Arguments.Length - 1)) -or ($Arguments[$i + 1] -match '^[-/\+].')) {
                            if ($shortOpt -match '::$') { $Options.Add($flag, $true) }
                            else {
                                $message = 'Option "' + $flag + '" requires an argument.'
                                return $Options, $Remaining, $message
                            }
                        }
                        else { $Options.Add($flag, $Arguments[++$i]) }
                    }

                    # Check if the flag was repeated more than once
                    elseif ($arg -cmatch ([regex]::Escape($flag) + '{2,}')) {
                        $repeated = $Matches[0] -as [string]
                        $Options.Add($flag, $repeated.Length)

                        while ($arg[$j + 1] -ceq $flag) { $j++ }
                    }
                    else { $Options.Add($flag, $true) }
                }
                else {
                    $message = 'Option "' + $flag + '" not recognized.'
                    return $Options, $Remaining, $message
                }
            }
        }

        else { $Remaining.Add($arg) }


        # If the options string starts with "+" or the environment variable POSIXLY_CORRECT is set,
        # then stop processing options as soon as soon as a non-option argument is encountered

        if ((($OptionsString -match '^\+') -or $env:POSIXLY_CORRECT) -and $Remaining) {
            while ($Arguments[$i + 1]) { $Remaining.Add($Arguments[++$i]) }
        }
    }

    return $Options, $Remaining
}
