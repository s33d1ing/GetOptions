# Get Options

Parses command line arguments.  

This module helps scripts to parse the command line arguments in $args.  

It supports the same conventions as the Unix getopt() function differentiating between arguments starting with "-" and "--".  
Long options similar to those supported by GNU software may be used as well via an optional third argument.  

The function returns an array containing the Options as a hashtable and the remaining arguments as a string array.  

    Arguments:
        Array of values for undeclared parameters that are passed to a function, script, or script block.

        An option's value can be provided as the proceeding argument or as a long option with an equal sign (i.e. --Option=Value).
        A single flag will evaluate to $true, repeating flags (i.e. -vvv) will evaluate to the number of occurrences (i.e. 3).

        Flags are case sensitive and long options are case insensitive.
        Note, PowerShell cannot handle like parameters of different cases.

    OptionsString:
        String containing the legitimate option characters.

        Options which require an argument should be followed by a colon (":").
        Options which accept an optional argument should be followed by two colons ("::").

    LongOptions:
        Array of strings containing the names of the long options.

        Options which require an argument should be followed by an equal sign ("=").
        Options which accept an optional argument should be followed by two equal signs ("==").

Source: https://github.com/lukesampson/scoop/blob/master/lib/getopt.ps1  
Origin: http://hg.python.org/cpython/file/2.7/Lib/getopt.py  
