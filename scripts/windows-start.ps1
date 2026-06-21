# managed-by: winwm-dotfiles
param(
  [Parameter(Mandatory = $true)]
  [string]$RepoRootWsl
)

$ErrorActionPreference = "Stop"

function ConvertTo-BashSingleQuoted {
  param([Parameter(Mandatory = $true)][string]$Value)
  return "'" + $Value.Replace("'", "'\''") + "'"
}

$quotedRepo = ConvertTo-BashSingleQuoted $RepoRootWsl
$command = "cd $quotedRepo && ./bin/winwm start"

& wsl.exe bash -lc $command
exit $LASTEXITCODE
