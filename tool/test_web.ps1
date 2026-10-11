param([string]$BrowserExecutable = 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe')
$ErrorActionPreference = 'Stop'
# Flutter 3.41.4's browser test host has a missing #play element and uses
# Windows separators to match HTTP URLs. Run the tools from source with a
# temporary fix, then restore the exact SDK bytes (no upgrade or cache edits).
$sageFlutterRoot = Split-Path (Split-Path (Get-Command flutter).Source -Parent) -Parent
$sageHostPath = Join-Path $sageFlutterRoot 'packages/flutter_tools/static/index.html'
$sagePlatformPath = Join-Path $sageFlutterRoot 'packages/flutter_tools/lib/src/test/flutter_web_platform.dart'
$sageHostBytes = [System.IO.File]::ReadAllBytes($sageHostPath)
$sagePlatformBytes = [System.IO.File]::ReadAllBytes($sagePlatformPath)
$sagePreviousChrome = $env:CHROME_EXECUTABLE
$sageTestExit = 1
try {
    $sageHost = [System.Text.Encoding]::UTF8.GetString($sageHostBytes)
    if (-not $sageHost.Contains('id="play"')) {
        $sageHost = $sageHost.Replace('<div id="dark"></div>', '<div id="dark"></div><button id="play" hidden></button>')
    }
    $sagePlatform = [System.Text.Encoding]::UTF8.GetString($sagePlatformBytes)
    $sagePlatform = $sagePlatform.Replace('final String fullPath = _fileSystem.path.fromUri(request.url);', 'final String fullPath = request.url.path;')
    $sagePlatform = $sagePlatform.Replace('final String path = _fileSystem.path.fromUri(request.url);', 'final String path = request.url.path;')
    [System.IO.File]::WriteAllText($sageHostPath, $sageHost)
    [System.IO.File]::WriteAllText($sagePlatformPath, $sagePlatform)
    $env:CHROME_EXECUTABLE = $BrowserExecutable
    $sageDart = Join-Path $sageFlutterRoot 'bin/cache/dart-sdk/bin/dart.exe'
    $sagePackages = Join-Path $sageFlutterRoot 'packages/flutter_tools/.dart_tool/package_config.json'
    $sageEntry = Join-Path $sageFlutterRoot 'packages/flutter_tools/bin/flutter_tools.dart'
    & $sageDart "--packages=$sagePackages" $sageEntry test --no-pub --platform chrome test/web --timeout 2m
    $sageTestExit = $LASTEXITCODE
} finally {
    [System.IO.File]::WriteAllBytes($sageHostPath, $sageHostBytes)
    [System.IO.File]::WriteAllBytes($sagePlatformPath, $sagePlatformBytes)
    $env:CHROME_EXECUTABLE = $sagePreviousChrome
}
exit $sageTestExit
