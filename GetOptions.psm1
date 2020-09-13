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

        .PARAMETER LongOptionsOnly
            Allow "-" as well as "--" to indicate a long option.

            If an option that starts with "-" (not "--") doesn't match a long option,
            but does match a short option, it is parsed as a short option instead.

        .EXAMPLE
            Get-Options -Arguments ('-xzvf', 'Archive.zip', '--Force') -OptionsString 'f:vxz' -LongOptions ('File=', 'Force')

            Given: --Force = [bool]$Force; -f, --File = [string]$File; -v = [bool]$Verbose; -x = [bool]$Extract; -z = [bool]$Zip
            Returns: @{ Extract = $true; Zip = $true; Verbose = $true; File = 'Archive.zip'; Force = $true }

        .EXAMPLE
            Get-Options -Arguments ('-xzvf', 'Archive.zip', 'C:\Temp\Extracted') -OptionsString 'f:vxz' -LongOptions ('File=', 'Force')

            Given: --Force = [bool]$Force; -f, --File = [string]$File; -v = [bool]$Verbose; -x = [bool]$Extract; -z = [bool]$Zip
            Returns: @( @{ Extract = $true; Zip = $true; Verbose = $true; File = 'Archive.zip' }, @( 'C:\Temp\Extracted' ) )

        .EXAMPLE
            Get-Options -Arguments ('-xzv', '--File=Archive.zip', '--Force') -OptionsString 'f:vxz' -LongOptions ('File=', 'Force')

            Given: --Force = [bool]$Force; -f, --File = [string]$File; -v = [bool]$Verbose; -x = [bool]$Extract; -z = [bool]$Zip
            Returns: @{ Extract = $true; Zip = $true; Verbose = $true; File = 'Archive.zip'; Force = $true }

        .LINK
            https://github.com/lukesampson/scoop/blob/master/lib/getopt.ps1
            http://hg.python.org/cpython/file/2.7/Lib/getopt.py
    #>

    [Alias('Get-LongOptions', 'Get-LongOptionsOnly', 'getopt', 'getopt_long', 'getopt_long_only')]
    [CmdletBinding(DefaultParameterSetName = 'getopt')]
    [OutputType([System.Object[]])]
    param (
        [Alias('argv')]
        [Parameter(Mandatory = $true, Position = 0)]
        [object[]]$Arguments,

        [Alias('optstring', 'shortopts')]
        [Parameter(Mandatory = $true, ParameterSetName = 'getopt', Position = 1)]
        [Parameter(Mandatory = $false, ParameterSetName = 'getopt_long', Position = 1)]
        [string]$OptionsString,

        [Alias('longopts')]
        [Parameter(Mandatory = $true, ParameterSetName = 'getopt_long', Position = 2)]
        [string[]]$LongOptions,

        [Parameter(DontShow = $true, ParameterSetName = 'getopt_long')]
        [switch]$LongOptionsOnly = $MyInvocation.Line -match 'Get-LongOptionsOnly|getopt_long_only'
    )

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
        elseif ($arg -match '^--$') { while ($Arguments[$i]) { $Remaining.Add($Arguments[++$i]) } }

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
                    return ($Options, $Remaining, ('Option "' + $name + '" is already specified.'))
                }

                if ($longOpt -match '=$') {
                    if ($null -ne $value) { $Options.Add($name, $value) }

                    # Check if on the last argument, or if the next argument is another flag or option
                    elseif (($i -eq ($Arguments.Length - 1)) -or ($Arguments[$i + 1] -match '^[-/\+].')) {
                        if ($longOpt -match '==$') { $Options.Add($name, $true) }
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

        elseif ($OptionsString -and ($arg -match '^[-/\+].')) {
            for ($j = 1; $j -lt $arg.Length; $j++) {
                $flag = $arg[$j] -as [string]

                if ($OptionsString -cmatch ([regex]::Escape($flag) + ':{0,2}')) {
                    $shortOpt = $Matches[0] -as [string]

                    if ($Options.Contains($flag)) {
                        return ($Options, $Remaining, ('Option "' + $flag + '" is already specified.'))
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
                            else { return ($Options, $Remaining, ('Option "' + $flag + '" requires an argument.')) }
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
                    return ($Options, $Remaining, ('Option "' + $flag + '" not recognized.'))
                }
            }
        }

        else { $Remaining.Add($arg) }

        # If the options string starts with "+" or the environment variable POSIXLY_CORRECT is set,
        # then stop processing options as soon as soon as a non-option argument is encountered
        if ((($OptionsString -match '^\+') -or $env:POSIXLY_CORRECT) -and $Remaining) {
            while ($Arguments[$i]) { $Remaining.Add($Arguments[++$i]) }
        }
    }

    return $Options, $Remaining
}
