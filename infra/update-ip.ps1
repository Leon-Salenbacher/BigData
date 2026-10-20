[CmdletBinding()]
param(
    [string]$PublicIp,
    [string]$OutputPath = (Join-Path $PSScriptRoot 'runtime.auto.tfvars.json')
)
$ErrorActionPreference = 'Stop'
if (-not $PSBoundParameters.ContainsKey('PublicIp')) {
    $PublicIp = [string](Invoke-RestMethod -Uri 'https://api4.ipify.org' -TimeoutSec 10)
}
$PublicIp = $PublicIp.Trim()
$parsedIp = $null
if ($PublicIp -notmatch '^(0|[1-9][0-9]{0,2})(\.(0|[1-9][0-9]{0,2})){3}$' -or
    -not [System.Net.IPAddress]::TryParse($PublicIp, [ref]$parsedIp) -or
    $parsedIp.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) {
    throw 'Keine gueltige oeffentliche IPv4 erhalten. Die Parameterdatei bleibt unveraendert.'
}
$json = @{ ssh_source_cidr = "$PublicIp/32" } | ConvertTo-Json
$encoding = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText([System.IO.Path]::GetFullPath($OutputPath), $json + [Environment]::NewLine, $encoding)
Write-Host "SSH-Quell-IP: $PublicIp/32. Vor dem Controllerstart Terraform plan und apply ausfuehren."
