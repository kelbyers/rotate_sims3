
# Test-Locked checks all the files in a directory to see if any of them are locked
function Test-Locked {
    Param( [string]$path )

    try {
        Get-ChildItem $path -Recurse | ForEach-Object {
            Write-Debug "Testing $($_.FullName)"
            [IO.File]::OpenWrite($_.FullName).close();
        }
    }
    catch {
        return $true
    }

    return $false
}

## Test-ProperlyAged is a function that checks if all files in a directory are
#  at least the minimum age
function Test-ProperlyAged {
    Param( [string]$path )

    # get the current time
    $now = Get-Date
    # get the youngest last write time allowed
    $youngestAllowed = $now.AddSeconds(-$script:MinimumAge)
    # get all the files in the directory
    $Files = Get-ChildItem $path -Recurse

    foreach ($File in $Files) {
        # DateTime.CompareTo returns:
        #  -1 if $youngestAllowed is newer,
        #   0 if they are the same, and
        #   1 if $youngestAllowed is older
        # Our logic says that $youngestAllowed should be NEWER,
        # otherwise return false and stop
        if ($youngestAllowed.CompareTo($File.LastWriteTime) -lt 0) {
            return $false
        }
    }

    # all files are at least the minimum age
    return $true
}

## Default values
# These can be overridden

# $script:MaxSleep controls the maximum amount of time to sleep between checks
# for a directory to be unlocked
$script:MaxSleep = 30

# $script:MaxCheckTime controls the maximum amount of time to wait for a
# directory to unlock
$script:MaxCheckTime = 400 # seconds

# $script:MinimumAge controls the minimum age of files in a directory
$script:MinimumAge = 30

# Wait-Unlocked waits until all files in a directory are unlocked
function Wait-Unlocked {
    Param( [string]$path )

    $checks = 0 # number of times Test-Locked has been called
    $sleep = 1  # seconds to sleep between checks
    $totalSleep = 0 # the total time spent sleeping

    while (Test-Locked $path) {
        # if we have spent more time sleeping than the max check time, throw
        if ($totalSleep -gt $script:MaxCheckTime) {
            throw 'Directory is locked for more than the max check time'
        }

        # the amount of time to sleep for the next check
        # do not sleep longer than the max sleep time
        if ($sleep -lt $script:MaxSleep) {
            $sleep = ((($sleep * ++$checks), $script:MaxSleep) | Measure-Object -Minimum).Minimum
        }

        Write-Host "$($path) is locked, sleeping for $sleep seconds..."
        $totalSleep += $sleep
        Start-Sleep -s $sleep
    }
}

# Wait-ProperlyAged waits until all files in a directory are at least the
# minimum age
function Wait-ProperlyAged {
    Param( [string]$path )

    while (!(Test-ProperlyAged $path)) {
        Start-Sleep -s 5
    }
    return
}

function Get-Root {
    # takes a parameter that is a FileSystemInfo object
    Param( [System.IO.FileSystemInfo]$base )

    # check if this is a sims3 save directory
    switch ($base.Extension) {
        '.sims3' { break }
        '.sims3.backup' { break }
        default {
            throw 'Not a sims3 save directory'
        }
    }

    return ''
}

function Rotate-Sims3 {
    Param( [string]$savePath, [switch]$once, [switch]$timeStampAll )

    $base = (get-item $savePath)
    if ($base -Is [System.IO.FileInfo]) {
        $base = $base.Directory
    }
    $ext = $base.extension

    $root = $base.Name.replace("$($base.Extension)", '').replace('-save`$', '')
    if ($root -match '.*[^0-9](?= - [0-9\-]+)' -or $root -match '^.*\D(?=\d+$)') {
        $root = $matches[0]
    }

    while ($true) {
        Write-Output "Rotating for $($root)"
        Write-Output "base = $($base)"
        Get-ChildItem $base.parent.FullName -Directory

        $candidates = Get-ChildItem $base.parent.FullName -Directory |
        Where-Object {
            $_.Name -match "`^($(${root})$(${ext})(.backup)?|$($root)[0-9]+$($ext)(.backup)?)`$"
        } | Sort-Object CreationTime

        Write-Output "candidates:"
        $candidates
        if ($candidates.Length -gt 0) {
            if ($timeStampAll) {
                $toTimeStamp = $candidates
                $noTimeStamp = @()
            }
            else {
                $toTimeStamp = $candidates[0..($candidates.length - 2)]
                $noTimeStamp = @($candidates[-1])
            }
            Foreach ($candidate in $toTimeStamp) {
                $ds = $candidate.CreationTime.toString('yyyyMMdd-HHmmss')
                Write-Output "$($candidate.Name) : $($ds)"
                Wait-Unlocked $candidate
                Wait-ProperlyAged $candidate
                Rename-Item $candidate.FullName -NewName "$($root) - $($ds)$($ext)"
            }
            Foreach ($candidate in $noTimeStamp) {
                $newest = $candidate
                $new_name = $root + $ext
                if ($newest.Name -ne $new_name) {
                    $ds = $newest.CreationTime.toString('yyyyMMdd-HHmmss')
                    Write-Output "$($newest.Name) : $($ds) : (no timestamp added)"
                    Wait-Unlocked $newest
                    Wait-ProperlyAged $newest
                    Rename-Item $newest.FullName -NewName "$($root)$($ext)"
                }
                else {
                    Write-Output "$($new_name) already rotated"
                }
            }
        }
        if ($once) {
            Write-Output "Started with -once, done"
            break
        }
        else {
            Write-Output "Loop complete, waiting..."
            Start-Sleep -s 57
        }
    }
    Start-Sleep -s 5
}

# run Rotate-Sims3 if invoked from the command line
if ($MyInvocation.InvocationName -ne '.') {
    write-host "Running Rotate-Sims3 with args: $args"
    Rotate-Sims3 @args
}
