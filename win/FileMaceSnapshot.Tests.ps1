BeforeAll {
    Import-Module $PSCommandPath.Replace('.Tests.ps1','')
}

Describe 'Get-FileBasicInformation' {
    BeforeAll {
        $itemCount = 0

        New-Item 'TestDrive:\f202301' -ItemType 'File'
        $e = Get-Item 'TestDrive:\f202301'
        $e.LastWriteTimeUtc = '2023-01-01Z'
        $e.LastAccessTimeUtc = '2023-01-02Z'
        $e.CreationTimeUtc = '2023-01-03Z'
        ++$itemCount

        New-Item 'TestDrive:\fnow' -ItemType 'File'
        ++$itemCount

        #FIXME# Directory timestamps might not be re-assignable by PowerShell?
        New-Item 'TestDrive:\d202301' -ItemType 'Directory'
        $e = Get-Item 'TestDrive:\f202301'
        $e.LastWriteTimeUtc = '2023-01-01Z'
        $e.LastAccessTimeUtc = '2023-01-02Z'
        $e.CreationTimeUtc = '2023-01-03Z'
        ++$itemCount

        New-Item 'TestDrive:\dnow' -ItemType 'Directory'
        ++$itemCount

        $nowDayOfYear = [datetime]::Now.DayOfYear
    }
    It 'gets new file timestamps' {
        $fbi = Get-FileBasicInformation "$TestDrive\fnow"
        $fbi.CreationTime.DayOfYear | Should -Be $nowDayOfYear
        $fbi.LastAccessTime.DayOfYear | Should -Be $nowDayOfYear
        $fbi.LastWriteTime.DayOfYear | Should -Be $nowDayOfYear
    }
    It 'gets old file timestamps' {
        $fbi = Get-FileBasicInformation "$TestDrive\f202301"
        $fbi.CreationTime | Should -Be ([datetime]'2023-01-03Z')
        $fbi.LastAccessTime | Should -Be ([datetime]'2023-01-02Z')
        $fbi.LastWriteTime | Should -Be ([datetime]'2023-01-01Z')
    }
    It 'gets new directory timestamps' {
        $fbi = Get-FileBasicInformation "$TestDrive\dnow"
        $fbi.CreationTime.DayOfYear | Should -Be $nowDayOfYear
        $fbi.LastAccessTime.DayOfYear | Should -Be $nowDayOfYear
        $fbi.LastWriteTime.DayOfYear | Should -Be $nowDayOfYear
    }
    #It 'gets old directory timestamps' {
    #    $fbi = Get-FileBasicInformation "$TestDrive\d202301"
    #    $fbi.CreationTime | Should -Be ([datetime]'2023-01-03Z')
    #    $fbi.LastAccessTime | Should -Be ([datetime]'2023-01-02Z')
    #    $fbi.LastWriteTime | Should -Be ([datetime]'2023-01-01Z')
    #}
    It 'supports a mixed directory structure' {
        Get-ChildItem "$TestDrive\*" | Get-FileBasicInformation |
            Should -HaveCount $itemCount
    }
    It 'fails on nonexistent paths' {
        {Get-FileBasicInformation "$TestDrive\nonexistent" -ErrorAction Stop} |
            Should -Throw `
                -ErrorId 'FileNotFoundException,Get-FileBasicInformation' `
                -ExpectedMessage '*HRESULT: 0x80070002*'
    }
}
