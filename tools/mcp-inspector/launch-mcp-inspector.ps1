param(
  [ValidateSet("direct", "ingress", "egress", "agentNetworkEgress")]
  [string]$Endpoint = "direct"
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$endpointsPath = Join-Path $scriptDir "endpoints.json"
$endpoints = Get-Content -Raw -Path $endpointsPath | ConvertFrom-Json
$selected = $endpoints.$Endpoint

Write-Host ""
Write-Host "MCP Inspector endpoint:" -ForegroundColor Cyan
Write-Host "  Name:      $($selected.name)"
Write-Host "  Transport: $($selected.transport)"
Write-Host "  URL:       $($selected.url)" -ForegroundColor Green
Write-Host ""
Write-Host "In the MCP Inspector UI:"
Write-Host "  1. Select Streamable HTTP"
Write-Host "  2. Paste the URL above"
Write-Host "  3. Add client_id/client_secret headers only if the gateway policy requires them"
Write-Host ""

npx @modelcontextprotocol/inspector
