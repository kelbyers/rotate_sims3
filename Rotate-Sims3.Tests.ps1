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

    # It 'should accept a sims 3 backup save directory' {
    #     $TestDir = New-Item -Path 'TestDrive:\' -Name 'TestDir.sims3.backup' -ItemType Directory
    #     { Get-Root $TestDir } | Should -Not -Throw
    # }
}



Describe 'Test-Locked' {
    BeforeEach {
        # clear the test drive, sometimes these get left behind
        Remove-Item -Force -Recurse 'TestDrive:\*'
        # set up a temporary directory
        $TestDir = New-Item -Path 'TestDrive:\' -Name 'TestDir' -ItemType Directory
        # create a few files in the directory
        $TestFile1 = New-Item -Path $TestDir -Name 'TestFile1.txt' -ItemType File
        $TestFile2 = New-Item -Path $TestDir -Name 'TestFile2.txt' -ItemType File
        $TestFile3 = New-Item -Path $TestDir -Name 'TestFile3.txt' -ItemType File
        $OtherFile = New-Item -Path 'TestDrive:\' -Name 'OtherFile.txt' -ItemType File
    }

    It 'checks all the files in a directory to see if any of them are locked' {
        $Files = (Get-ChildItem $TestDir.FullName -Recurse)

        foreach ($File in $Files) {
            Write-Debug "Testing $($File.FullName)"
            $locked = [IO.File]::OpenWrite($File.FullName)

            Test-Locked $TestDir.FullName | Should -BeTrue
            $locked.close()
        }
    }

    It 'does not check files in other directories' {
        # lock the other file
        $locked = [IO.File]::OpenWrite($OtherFile.FullName)

        Test-Locked $TestDir.FullName | Should -BeFalse

        $locked.close()
    }
}

Describe 'Wait-Unlocked' {
    BeforeEach {
        Mock Test-Locked {
            $script:checks++ ;
            $locked = ($script:checks -lt $script:expectedChecks)
            return  $locked
        }
        Mock Start-Sleep {
            Write-Debug "Mock sleep"
        }
    }
    It 'waits until all files in a directory are unlocked' {
        $script:expectedChecks = 3
        $script:checks = 0

        Wait-Unlocked 'TestDrive:\'
        Should -Invoke Test-Locked -Exactly $expectedChecks
        Should -Invoke Start-Sleep -Exactly ($expectedChecks - 1)
    }

    It 'should not wait when all files are unlocked' {
        $script:expectedChecks = 1
        $script:checks = 0

        Wait-Unlocked 'TestDrive:\'
        Should -Invoke Test-Locked -Exactly $expectedChecks
        Should -Invoke Start-Sleep -Exactly 0
    }

    It 'should progressively wait longer between checks' {
        $script:expectedChecks = 3
        $script:checks = 0

        Wait-Unlocked 'TestDrive:\'
        Should -Invoke Test-Locked -Exactly $expectedChecks
        $sleepTime = 1
        for ($i = 1; $i -lt $expectedChecks; $i++) {
            $sleepTime *= $i
            Should -Invoke Start-Sleep -Exactly 1 -ParameterFilter { $Seconds -eq $sleepTime }
        }
    }

    It 'should not wait longer than the max sleep time' {
        $script:expectedChecks = 10
        $script:checks = 0
        $script:MaxSleep = 5

        Wait-Unlocked 'TestDrive:\'

        # the number of times under the max sleep time
        $underMax = 0
        $sleepTime = 1
        for ($i = 1; ($sleepTime * $i) -lt $script:MaxSleep; $i++) {
            $underMax++
            $sleepTime *= $i
            Should -Invoke Start-Sleep -Exactly 1 -ParameterFilter { $Seconds -eq $sleepTime }
        }

        # the number of times over the max sleep time
        $overMax = $expectedChecks - $underMax - 1

        Should -Invoke Start-Sleep -Exactly $overMax -ParameterFilter { $Seconds -eq $MaxSleep}
    }

    It 'should throw if the directory is locked for more than the max check time' {
        $script:expectedChecks = 10
        $script:checks = 0
        $script:MaxSleep = 5
        $script:MaxCheckTime = 10

        { Wait-Unlocked 'TestDrive:\' } | Should -Throw
    }

    It 'has a default max sleep time of 30 seconds' {
        $script:MaxSleep | Should -Be 30
    }

    It 'has a default max check time of 400 seconds' {
        $script:MaxCheckTime | Should -Be 400
    }
}
