#* Import Get-Options function
. "$PSScriptRoot\..\Get-Options.ps1"

#* Comment based help examples
Get-Options -Arguments ('-xzvf', 'Archive.zip', '--Force') -OptionsString 'f:vxz' -LongOptions ('File=', 'Force')
Get-Options -Arguments ('-xzvf', 'Archive.zip', 'C:\Temp\Extracted') -OptionsString 'f:vxz' -LongOptions ('File=', 'Force')
Get-Options -Arguments ('-xzv', '--File=Archive.zip', '--Force') -OptionsString 'f:vxz' -LongOptions ('File=', 'Force')

#* Test for optional arguments
Get-Options -Arguments ('-f', 'Hello', '--Bar') -OptionsString 'f:b::' -LongOptions ('Foo=', 'Bar==')
Get-Options -Arguments ('--Foo', 'Hello', '-b') -OptionsString 'f:b::' -LongOptions ('Foo=', 'Bar==')
Get-Options -Arguments ('-f', 'Hello', '--Bar', 'World') -OptionsString 'f:b::' -LongOptions ('Foo=', 'Bar==')
Get-Options -Arguments ('--Foo', 'Hello', '-b', 'World') -OptionsString 'f:b::' -LongOptions ('Foo=', 'Bar==')

#* Test for non string arguments
Get-Options -Arguments (-1, @(1), @(2, 3), @{ 'Foo' = 'Bar' }) -OptionsString 'f:b::' -LongOptions ('Foo=', 'Bar==')

#* Test for repeating flags
Get-Options -Arguments ('-d', '-vvv') -OptionsString 'dv' -LongOptions ('Debug', 'Verbose')
Get-Options -Arguments ('-d', '-vvV') -OptionsString 'dvV' -LongOptions ('Debug', 'Verbose')

#* Test for abbreviated names
Get-Options -Arguments ('--F', 'Hello', '--B', 'World') -OptionsString 'f:b::' -LongOptions ('Foo=', 'Bar==')
Get-Options -Arguments ('--Foo', 'Hello', '--FooBar') -OptionsString 'f:b::' -LongOptions ('Foo=', 'FooBar==')

#* Test for case sensitivity
Get-Options -Arguments ('-F', 'Bar', '-f', '-v', '-V') -OptionsString 'F:fvV' -LongOptions ('Foo=', 'Version')
Get-Options -Arguments ('--foo', 'Bar', '--version') -OptionsString 'F:fvV' -LongOptions ('Foo=', 'Version')

#* Test for different prefixes
Get-Options -Arguments ('-a', '/b', '+c', '--D', '//E') -OptionsString 'abc' -LongOptions ('D', 'E')
