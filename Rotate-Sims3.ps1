Param( [string]$savePath, [switch]$once, [switch]$timeStampAll )

$base = (get-item $savePath)
if ($base -Is [System.IO.FileInfo]) {
  $base = $base.Directory
}
$ext = $base.extension

$root = $base.Name.replace("$($base.Extension)", '').replace('-save`$','')
while ($root -match '.*[^0-9](?= - [0-9\-]+)' -or $root -match '^.*\D(?=\d+$)') {
  $root = $matches[0]
}

Write-Output "Rotating for $($root)"
Write-Output "base = $($base)"
Get-ChildItem $base.parent.FullName -Directory

$candidates = Get-ChildItem $base.parent.FullName -Directory |
  Where-Object {
    $_.Name -match "`^($(${root})$(${ext})(.backup)?|$($root)[0-9]+$($ext))`$"
  } | Sort-Object CreationTime

Write-Output "candidates:"
$candidates

while ($true) {
  if ($candidates.Length -gt 0) {
    if ($timeStampAll) {
      $toTimeStamp = $candidates
      $noTimeStamp = @()
    } else {
      $toTimeStamp = $candidates[0..($candidates.length - 2)]
      $noTimeStamp = @($candidates[-1])
    }
    Foreach ($candidate in $toTimeStamp)
    {
      $ds = $candidate.CreationTime.toString('yyyyMMdd-HHmmss')
      Write-Output "$($candidate.Name) : $($ds)"
      Rename-Item $candidate.FullName -NewName "$($root) - $($ds)$($ext)"
    }
    Foreach ($candidate in $noTimeStamp) {
      $newest = $candidate
      $new_name = $root + $ext
      if ($newest.Name -ne $new_name) {
        $ds = $newest.CreationTime.toString('yyyyMMdd-HHmmss')
        Write-Output "$($newest.Name) : $($ds) : (no timestamp added)"
        Rename-Item $newest.FullName -NewName "$($root)$($ext)"
      } else {
        Write-Output "$($new_name) already rotated"
      }
    }
  }
  if ($once) {
    Write-Output "Started with -once, done"
    break
  } else {
    Write-Output "Loop complete, waiting..."
    Start-Sleep -s 57
  }
}
Start-Sleep -s 5
