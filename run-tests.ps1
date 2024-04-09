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
        Start-Process npm -ArgumentList ('start') -PassThru | Out-Null
    } finally {
        Pop-Location
    }
}

function RunTests() {
    Write-Host "Starting TestCafe"

    $browserList = 'chrome'
    $fileOrGlob = './smoke-test.ts'

    $arguments = @(
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

    $process = Start-Process 'npx' -ArgumentList $arguments -NoNewWindow -Wait -ErrorAction Stop -PassThru
    $exitCode = $process.ExitCode

    Write-Host "TestCafe exit code: $exitCode"

    # npx testcafe --base-url http://localhost:4200 chrome .\smoke-test.ts | Out-Host
    # $exitCode = $LastExitCode

    return $exitCode

}

function Main() {
    InstallNpmPackages
    $backendProcess = LaunchBackend ./ServerSideAspNetCoreReportingApp/ServerSideAspNetCoreReportingApp
    try {
        LaunchFrontend ./angular-report-designer
        # We do not store $frontendProcess, because running 'npm start' creates a sequence of processes, ending with esbuild.exe
        # And I'm not sure if there is an easy way to track that process
        # Options to consider:
        # - what about powershell jobs?
        # - leverage knowledge on 'stream waiting' and use 'launcher tool'.

        return RunTests

    } finally {
        Stop-Process $backendProcess
    }

    
}

try {
    Exit [int](Main)
} catch {
    Write-Host -ForegroundColor Red $_.Exception
    $_.ScriptStackTrace -split [System.Environment]::NewLine | ForEach-Object { Write-Host -ForegroundColor Red "  $_" }
    Exit -1
}
