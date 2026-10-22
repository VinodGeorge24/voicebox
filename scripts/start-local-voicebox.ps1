param(
    [string]$DataDirectory = (Join-Path $env:USERPROFILE '.local/share/voicebox'),
    [ValidateRange(1024, 65535)][int]$Port = 17493
)

$ErrorActionPreference = 'Stop'
$endpoint = "http://127.0.0.1:$Port"
$listeners = @(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
if ($listeners.Count -gt 0) {
    $identity = Invoke-RestMethod "$endpoint/openapi.json" -TimeoutSec 5
    if ($identity.info.title -ne 'voicebox API') { throw "Port $Port belongs to another application" }
    Invoke-RestMethod "$endpoint/health" -TimeoutSec 10
    return
}

$backendDirectory = Join-Path $DataDirectory 'backends/cuda'
$executable = Join-Path $backendDirectory 'voicebox-server-cuda.exe'
if (-not (Test-Path -LiteralPath $executable)) { throw "Local CUDA backend not found: $executable" }
$logDirectory = Join-Path $DataDirectory 'logs'
New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null
$previousModelsDirectory = $env:VOICEBOX_MODELS_DIR
$previousTelemetry = $env:HF_HUB_DISABLE_TELEMETRY
$previousImplicitToken = $env:HF_HUB_DISABLE_IMPLICIT_TOKEN
try {
    $env:VOICEBOX_MODELS_DIR = Join-Path $DataDirectory 'models-cache'
    $env:HF_HUB_DISABLE_TELEMETRY = '1'
    $env:HF_HUB_DISABLE_IMPLICIT_TOKEN = '1'
    $serverArguments = @('--host', '127.0.0.1', '--port', "$Port", '--data-dir', ('"' + $DataDirectory + '"'))
    $serverProcess = Start-Process -FilePath $executable -ArgumentList $serverArguments `
        -WorkingDirectory $backendDirectory -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput (Join-Path $logDirectory 'server.stdout.log') `
        -RedirectStandardError (Join-Path $logDirectory 'server.stderr.log')
    [pscustomobject]@{ ProcessId = $serverProcess.Id; Endpoint = $endpoint; DataDirectory = $DataDirectory }
} finally {
    $env:VOICEBOX_MODELS_DIR = $previousModelsDirectory
    $env:HF_HUB_DISABLE_TELEMETRY = $previousTelemetry
    $env:HF_HUB_DISABLE_IMPLICIT_TOKEN = $previousImplicitToken
}
