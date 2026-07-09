param(
  [Parameter(Mandatory = $true)]
  [string]$Watchman
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Invoke-Watchman {
  param([string[]]$Arguments)

  $output = & $Watchman @Arguments 2>&1
  if ($LASTEXITCODE -ne 0) {
    throw "watchman exited with code $LASTEXITCODE`n$($output -join "`n")"
  }
  return $output -join "`n"
}

$id = [guid]::NewGuid().ToString("N")
$tmpDir = Join-Path ([IO.Path]::GetTempPath()) "wm.$id"
$root = Join-Path $tmpDir "root"
$pipe = "\\.\pipe\watchman-smoke-$id"
$stateFile = Join-Path $tmpDir "state"
$pidFile = Join-Path $tmpDir "pid"
$logFile = Join-Path $tmpDir "watchman.log"
$configFile = Join-Path $tmpDir "config.json"
$server = $null
$previousConfig = $env:WATCHMAN_CONFIG_FILE

New-Item -ItemType Directory -Path $root -Force | Out-Null
Set-Content -Path $configFile -Value "{}" -NoNewline
$env:WATCHMAN_CONFIG_FILE = $configFile

$stateArgs = @(
  "--named-pipe-path=$pipe"
  "--statefile=$stateFile"
  "--pidfile=$pidFile"
  "--logfile=$logFile"
)

try {
  Invoke-Watchman -Arguments @("--version") | Out-Null

  $serverArgs = @("--foreground") + $stateArgs
  $serverInfo = [Diagnostics.ProcessStartInfo]::new()
  $serverInfo.FileName = (Resolve-Path -LiteralPath $Watchman).Path
  $serverInfo.UseShellExecute = $false
  foreach ($serverArg in $serverArgs) {
    [void]$serverInfo.ArgumentList.Add($serverArg)
  }
  $server = [Diagnostics.Process]::Start($serverInfo)

  $watchResponse = $null
  for ($attempt = 0; $attempt -lt 100; $attempt++) {
    if ($server.HasExited) {
      throw "watchman server exited before accepting named-pipe connections"
    }

    try {
      $response = Invoke-Watchman -Arguments ($stateArgs + @(
        "--no-spawn"
        "--no-pretty"
        "watch"
        $root
      ))
      $watchResponse = $response | ConvertFrom-Json
      break
    } catch {
      Start-Sleep -Milliseconds 100
    }
  }

  if (
    $null -eq $watchResponse -or
    $null -eq $watchResponse.PSObject.Properties["watcher"]
  ) {
    throw "watchman did not start its Windows filesystem watcher"
  }

  Invoke-Watchman -Arguments ($stateArgs + @(
    "--no-spawn"
    "--no-pretty"
    "shutdown-server"
  )) | Out-Null

  if (-not $server.WaitForExit(10000)) {
    throw "watchman server did not stop after shutdown-server"
  }

  Write-Output "watchman started its filesystem watcher with $($watchResponse | ConvertTo-Json -Compress)"
} catch {
  if (Test-Path $logFile) {
    Get-Content $logFile | Write-Host
  }
  throw
} finally {
  if ($null -ne $server) {
    try {
      if (-not $server.HasExited) {
        Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
        [void]$server.WaitForExit(5000)
      }
    } catch {
      # Preserve the original smoke-test failure during best-effort cleanup.
    }
    $server.Dispose()
  }

  if ($null -eq $previousConfig) {
    Remove-Item Env:WATCHMAN_CONFIG_FILE -ErrorAction SilentlyContinue
  } else {
    $env:WATCHMAN_CONFIG_FILE = $previousConfig
  }

  Remove-Item -Path $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
}
