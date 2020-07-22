# Get Options

Parser for command-line options, arguments, and sub-commands.  

It supports the same conventions as the Unix getopt() function, including the special meanings of arguments of the form "-" and "--".  
Long options similar to those supported by GNU software may be used as well via an optional third argument.  

    argv:
        Array of arguments.

    shortopts:
        String of single-letter options.
        Options that take a parameter should be follow by ":".

    longopts:
        Array of strings that are long-form options.
        Options that take a parameter should end with "=".

    returns:
        @(opts hash, remaining_args array, error string)

Source: https://github.com/lukesampson/scoop/blob/master/lib/getopt.ps1  
Origin: http://hg.python.org/cpython/file/2.7/Lib/getopt.py  
