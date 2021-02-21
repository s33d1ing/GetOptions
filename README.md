# Get Options

Parses command line arguments.  

This module helps scripts to parse the command line arguments in $args.  

Get-Options supports the same conventions as getopt but allows options starting with "-", "/", or "+".  
Get-LongOptions works the same as Get-Options but also accepts long options starting with "--" or "//".  

Get-LongOptionsOnly works the same as Get-LongOptions but allows long options starting with "-", "/", or "+".  
If an option does not match a long option, but matches a short option, it is parsed as a short option.  

The function returns an array containing the Options as a hashtable and the remaining arguments as a array.  
If an error is encountered, a third array object containing the error message is returned.  

    Arguments:
        Array of values for undeclared parameters that are passed to a function, script, or script block.

        An short option's value can be provided as the proceeding argument (i.e. -f Bar) or immediately following the flag (i.e. -fBar).
        A single flag (i.e. -v) will evaluate to $true, repeating flags (i.e. -vvv) will evaluate to the number of occurrences (i.e. 3).

        An long option's value can be provided as the proceeding argument (i.e. --Foo Bar) or after an equals sign (i.e. --Foo=Bar).

        Note, flags are case sensitive but PowerShell cannot handle like parameters of different cases.

    OptionsString:
        String containing the legitimate option characters.

        Options which require an argument should be followed by a colon (":").
        Options which accept an optional argument should be followed by two colons ("::").

    LongOptions:
        Array of strings containing the names of the long options.

        Options which require an argument should be followed by an equal sign ("=").
        Options which accept an optional argument should be followed by two equal signs ("==").

Source: <https://github.com/lukesampson/scoop/blob/master/lib/getopt.ps1>  
Origin: <http://hg.python.org/cpython/file/2.7/Lib/getopt.py>  
