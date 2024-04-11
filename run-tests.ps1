#Requires -Version 7

# [CmdletBinding(PositionalBinding = $false)]
# param(
# )

Set-StrictMode -Version latest
$ErrorActionPreference = 'Stop'

function CheckLastExitCode() {
    if ($LastExitCode -ne 0) {
        Write-Error -ErrorAction Stop "Last exit code: $LastExitCode"
    }
}

function InstallNpmPackages() {
    if(-Not(Test-Path .\node_modules\*)) {
        npm ci | Out-Host
        CheckLastExitCode
    }
}

function LaunchBackend([Parameter(Mandatory)][string]$path) {
    Push-Location $path
    try {
        return Start-Process dotnet -ArgumentList ('run') -PassThru
    } finally {
        Pop-Location
    }
}

function LaunchFrontend([Parameter(Mandatory)][string]$path) {
    Push-Location $path
    try {
        InstallNpmPackages
        return Start-Process cmd -ArgumentList ('/c', 'npm', 'start') -PassThru
    } finally {
        Pop-Location
    }
}

function RunTests() {
    Write-Host "Starting TestCafe"

    $browserList = 'chrome'
    $fileOrGlob = './smoke-test.ts'

    $arguments = @(
        '/c'
        'npx.cmd'
        'testcafe'
        $browserList
        $fileOrGlob
        '--base-url http://localhost:4200'
    )

    # if($fixture) {
    #     $arguments += "--fixture `"$fixture`""
    # }
    # if($test) {
    #     $arguments += "--test `"$test`""
    # }
    # if($concurrency) {
    #     $arguments += "--concurrency $concurrency"
    # }
    # if($debugOnFail) {
    #     $arguments += "--debug-on-fail"
    # }
    # if($live) {
    #     $arguments += "--live"
    # }

    $process = Start-Process 'cmd' -ArgumentList $arguments -NoNewWindow -Wait -ErrorAction Stop -PassThru
    $exitCode = $process.ExitCode

    Write-Host "TestCafe exit code: $exitCode"
    return $exitCode
}

function Main() {
    InstallNpmPackages
    $backendProcess = LaunchBackend ./ServerSideAspNetCoreReportingApp/ServerSideAspNetCoreReportingApp
    try {
        $frontendProcess = LaunchFrontend ./angular-report-designer
        return RunTests

    } finally {
        taskkill.exe /F /T /PID $frontendProcess.Id | Out-Host # TODO: current implementation is Windows-only
        Stop-Process $backendProcess | Out-Host
    }
}

try {
    Exit [int](Main)
} catch {
    Write-Host -ForegroundColor Red $_.Exception
    $_.ScriptStackTrace -split [System.Environment]::NewLine | ForEach-Object { Write-Host -ForegroundColor Red "  $_" }
    Exit -1
}
