BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
}


Describe 'Get-Root' {
    BeforeEach {
        # set up a temporary directory
    }
    
    It 'should not accept a directory' {
        $TestDir = New-Item -Path 'TestDrive:\' -Name 'TestDir' -ItemType Directory
        { Get-Root $TestDir } | Should -Throw
    }

    It 'should accept a sims 3 save directory' {
        $TestDir = New-Item -Path 'TestDrive:\' -Name 'TestDir.sims3' -ItemType Directory
        { Get-Root $TestDir } | Should -Not -Throw
    }

    It 'should accept a sims 3 backup save directory' { 
        $TestDir = New-Item -Path 'TestDrive:\' -Name 'TestDir.sims3.backup' -ItemType Directory
        { Get-Root $TestDir } | Should -Not -Throw
    }
}