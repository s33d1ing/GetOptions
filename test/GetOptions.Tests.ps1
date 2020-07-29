$ModuleManifestName = 'GetOptions.psd1'
$ModuleManifestPath = "$PSScriptRoot\..\$ModuleManifestName"

Import-Module -FullyQualifiedName $ModuleManifestPath -Force

Describe 'Module Manifest Tests' {
    It 'Passes Test-ModuleManifest' {
        Test-ModuleManifest -Path $ModuleManifestPath | Should -Not -BeNullOrEmpty
        $? | Should -Be $true
    }
}

Describe 'Argument Parsing Tests' {
    It 'Comment Based Help examples' {
        $p, $r, $m = Get-Options -Arguments '-xzvf', 'Archive.zip', '--Force' -OptionsString 'f:vxz' -LongOptions 'File=', 'Force'
        $p.x | Should -Be $true
        $p.z | Should -Be $true
        $p.v | Should -Be $true
        $p.f | Should -Be 'Archive.zip'
        $p.Force | Should -Be $true

        $p, $r, $m = Get-Options -Arguments '-xzvf', 'Archive.zip', 'C:\Temp\Extracted' -OptionsString 'f:vxz' -LongOptions 'File=', 'Force'
        $p.x | Should -Be $true
        $p.z | Should -Be $true
        $p.v | Should -Be $true
        $p.f | Should -Be 'Archive.zip'
        $r | Should -Contain 'C:\Temp\Extracted'

        $p, $r, $m = Get-Options -Arguments '-xzv', '--File=Archive.zip', '--Force'  -OptionsString 'f:vxz' -LongOptions 'File=', 'Force'
        $p.x | Should -Be $true
        $p.z | Should -Be $true
        $p.v | Should -Be $true
        $p.File | Should -Be 'Archive.zip'
        $p.Force | Should -Be $true
    }

    It 'Test for required arguments' {
        $p, $r, $m = Get-Options -Arguments '-xzvfArchive.zip', '--Force'  -OptionsString 'f:vxz' -LongOptions 'File=', 'Force'
        $p.x | Should -Be $true
        $p.z | Should -Be $true
        $p.v | Should -Be $true
        $p.f | Should -Be 'Archive.zip'
        $p.Force | Should -Be $true

        $p, $r, $m = Get-Options -Arguments '-xzv', '-fArchive.zip', '--Force'  -OptionsString 'f:vxz' -LongOptions 'File=', 'Force'
        $p.x | Should -Be $true
        $p.z | Should -Be $true
        $p.v | Should -Be $true
        $p.f | Should -Be 'Archive.zip'
        $p.Force | Should -Be $true

        $p, $r, $m = Get-Options -Arguments '-xzvf', '--Force'  -OptionsString 'f:vxz' -LongOptions 'File=', 'Force'
        $m | Should -Be 'Option "f" requires an argument.'

        $p, $r, $m = Get-Options -Arguments '-fxzv', '--Force'  -OptionsString 'f:vxz' -LongOptions 'File=', 'Force'
        $m | Should -Be 'Option "f" requires an argument.'
    }

    It 'Test for optional arguments' {
        $p, $r, $m = Get-Options -Arguments '-f', 'Hello', '--Bar' -OptionsString 'f:b::' -LongOptions 'Foo=', 'Bar=='
        $p.f | Should -Be 'Hello'
        $p.Bar | Should -Be $true

        $p, $r, $m = Get-Options -Arguments '--Foo', 'Hello', '-b' -OptionsString 'f:b::' -LongOptions 'Foo=', 'Bar=='
        $p.Foo | Should -Be 'Hello'
        $p.b | Should -Be $true

        $p, $r, $m = Get-Options -Arguments '-f', 'Hello', '--Bar', 'World' -OptionsString 'f:b::' -LongOptions 'Foo=', 'Bar=='
        $p.f | Should -Be 'Hello'
        $p.Bar | Should -Be 'World'

        $p, $r, $m = Get-Options -Arguments '--Foo', 'Hello', '-b', 'World' -OptionsString 'f:b::' -LongOptions 'Foo=', 'Bar=='
        $p.Foo | Should -Be 'Hello'
        $p.b | Should -Be 'World'
    }

    It 'Test for non string arguments' {
        $p, $r, $m = Get-Options -Arguments (-1, @(1), @(2, 3), @{ 'Foo' = 'Bar' }) -OptionsString 'h'
        $r[0] | Should -Be -1
        $r[1][0] | Should -Be 1
        $r[2][0] | Should -Be 2
        $r[2][1] | Should -Be 3
        $r.Foo | Should -Be 'Bar'
    }

    It 'Test for abbreviated names' {
        $p, $r, $m = Get-Options -Arguments '--F', 'Hello', '--B', 'World' -LongOptions 'Foo=', 'Bar='
        $p.Foo | Should -Be 'Hello'
        $p.Bar | Should -Be 'World'

        $p, $r, $m = Get-Options -Arguments '--Foo', 'Hello', '--FooBar' -LongOptions 'Foo=', 'FooBar'
        $p.Foo | Should -Be 'Hello'
        $p.FooBar | Should -Be $true

        $p, $r, $m = Get-Options -Arguments '--F', 'Hello' -LongOptions 'Foo=', 'FooBar'
        $m | Should -Be 'Option "F" is not a unique prefix.'
    }

    It 'Test for case sensitivity' {
        $p, $r, $m = Get-Options -Arguments '-F', 'Bar', '-f', '-v', '-V' -OptionsString 'F:fvV'
        $p.F | Should -Be 'Bar'
        $p.f | Should -Be $true
        $p.v | Should -Be $true
        $p.V | Should -Be $true

        $p, $r, $m = Get-Options -Arguments '--foo', 'Bar', '--version' -LongOptions 'Foo=', 'Version'
        $p.Foo | Should -Be 'Bar'
        $p.Version | Should -Be $true
    }

    It 'Test for repeating flags' {
        $p, $r, $m = Get-Options -Arguments '-d', '-vvv' -OptionsString 'dv'
        $p.d | Should -Be $true
        $p.v | Should -Be 3

        $p, $r, $m = Get-Options -Arguments '-dvvV' -OptionsString 'dvV'
        $p.d | Should -Be $true
        $p.v | Should -Be 2
        $p.V | Should -Be $true
    }

    It 'Test for different prefixes' {
        $p, $r, $m = Get-Options -Arguments '-a', '/b', '+c' -OptionsString 'abc'
        $p.a | Should -Be $true
        $p.b | Should -Be $true
        $p.c | Should -Be $true

        $p, $r, $m = Get-Options -Arguments '--D', '//E', '-/F', '/-F' -LongOptions 'D', 'E', 'F'
        $p.D | Should -Be $true
        $p.E | Should -Be $true
        $r | Should -Contain '-/F'
        $r | Should -Contain '/-F'
    }

    It 'Test for missing arguments' {
        $p, $r, $m = Get-Options -Arguments '--Foo', '--Bar' -OptionsString 'f:b' -LongOptions 'Foo=', 'Bar'
        $m | Should -Be 'Option "Foo" requires an argument.'

        $p, $r, $m = Get-Options -Arguments '-f', '-b' -OptionsString 'f:b' -LongOptions 'Foo=', 'Bar'
        $m | Should -Be 'Option "f" requires an argument.'

        $p, $r, $m = Get-Options -Arguments '--Foo', '--Bar' -OptionsString 'fb:' -LongOptions 'Foo', 'Bar='
        $m | Should -Be 'Option "Bar" requires an argument.'

        $p, $r, $m = Get-Options -Arguments '-f', '-b' -OptionsString 'fb:' -LongOptions 'Foo', 'Bar='
        $m | Should -Be 'Option "b" requires an argument.'
    }

    It 'Test for repeated options' {
        $p, $r, $m = Get-Options -Arguments '--Foo', '--Bar', '--Foo' -OptionsString 'fb' -LongOptions 'Foo', 'Bar'
        $m | Should -Be 'Option "Foo" is already specified.'

        $p, $r, $m = Get-Options -Arguments '-f', '-b', '-f' -OptionsString 'fb' -LongOptions 'Foo', 'Bar'
        $m | Should -Be 'Option "f" is already specified.'
    }

    It 'Test for unrecognized options' {
        $p, $r, $m = Get-Options -Arguments '--Foo', '--Bar', '--Test' -OptionsString 'fb' -LongOptions 'Foo', 'Bar'
        $m | Should -Be 'Option "Test" not recognized.'

        $p, $r, $m = Get-Options -Arguments '-f', '-b', '-t' -OptionsString 'fb' -LongOptions 'Foo', 'Bar'
        $m | Should -Be 'Option "t" not recognized.'
    }
}
