Param( [string]$savePath, [switch]$once )

$base = (get-item $savePath)
if ($base -Is [System.IO.FileInfo]) {
  $base = $base.Directory
}
$ext = $base.extension

$root = $base.Name.replace("$($base.Extension)", '').replace('-save`$','')
if ($root -match '.*(?= - [0-9\-]*)') {
      $root = $matches[0]
}

echo "Rotating for $($root)"
echo "base = $($base)"
Get-ChildItem $base.parent.FullName -Directory

$candidates = Get-ChildItem $base.parent.FullName -Directory |
  Where {
    $_.Name -match "`^($(${root})$(${ext})(.backup)?|$($root)[0-9]+$($ext))`$"
  } | sort CreationTime

echo "candidates:"
$candidates

while ($true) {
  Foreach ($candidate in $candidates[0..($candidates.length - 2)])
  {
    $ds = $candidate.CreationTime.toString('yyyyMMdd-HHmmss')
    echo "$($candidate.Name) : $($ds)"
    Rename-Item $candidate.FullName -NewName "$($root) - $($ds)$($ext)"
  }
  if ($candidates.Length -gt 0) {
    $newest = $candidates[-1]
    $new_name = $root + $ext
    if ($newest.Name -ne $new_name) {
      $ds = $newest.CreationTime.toString('yyyyMMdd-HHmmss')
      echo "$($newest.Name) : $($ds)"
      Rename-Item $newest.FullName -NewName "$($root)$($ext)"
    } else {
      echo "$($new_name) already rotated"
    }
  }
  if ($once) {
    echo "Started with -once, done"
    break
  } else {
    echo "Loop complete, waiting..."
    Start-Sleep -s 57
  }
}
# Start-Sleep -s 5
