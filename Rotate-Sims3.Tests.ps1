BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
}


Describe 'Get-Root' {    
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

Describe 'Is-Locked' {
    BeforeEach {
        # set up a temporary directory
        $TestDir = New-Item -Path 'TestDrive:\' -Name 'TestDir' -ItemType Directory
        # create a few files in the directory
        $TestFile = New-Item -Path $TestDir.FullName -Name 'TestFile.txt' -ItemType File
        $TestFile2 = New-Item -Path $TestDir.FullName -Name 'TestFile2.txt' -ItemType File
        $TestFile3 = New-Item -Path $TestDir.FullName -Name 'TestFile3.txt' -ItemType File
    }

}