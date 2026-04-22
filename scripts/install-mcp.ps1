#Requires -Version 5.1
<#
.SYNOPSIS
  Собирает .cursor/mcp.json для MCP 1c-platform: Java, JAR, --platform-path (автообнаружение).

.DESCRIPTION
  Запускайте из корня репозитория или с любого каталога: скрипт сам находит корень по расположению scripts/.
  JAR: dist/1C_mcp_bsl.jar при наличии, иначе загрузка из GitHub Releases (latest) в %LOCALAPPDATA%\1C_mcp_bsl\
#>
param(
    [string] $RepoRoot = "",
    [switch] $DryRun
)

$ErrorActionPreference = "Stop"

if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

$cursorDir = Join-Path $RepoRoot ".cursor"
$examplePath = Join-Path $cursorDir "mcp.json.example"
$outPath = Join-Path $cursorDir "mcp.json"

if (-not (Test-Path $examplePath)) {
    Write-Error "Не найден $examplePath — запускайте скрипт из клона репозитория 1C_mcp_bsl."
}

function Find-JavaCommand {
    if ($env:JAVA_HOME) {
        $jh = Join-Path $env:JAVA_HOME "bin\java.exe"
        if (Test-Path $jh) { return (Resolve-Path $jh).Path }
    }
    $cmd = Get-Command "java.exe" -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $cmd = Get-Command "java" -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

function Find-1CPlatformPath {
    $bases = @(
        (Join-Path $env:ProgramFiles "1cv8"),
        (Join-Path ${env:ProgramFiles(x86)} "1cv8")
    )
    $candidates = [System.Collections.Generic.List[string]]::new()
    foreach ($base in $bases) {
        if (-not (Test-Path $base)) { continue }
        foreach ($d1 in Get-ChildItem -LiteralPath $base -Directory -ErrorAction SilentlyContinue) {
            $bin1 = Join-Path $d1.FullName "bin"
            if (Test-Path -LiteralPath $bin1) { $candidates.Add($d1.FullName) }
            foreach ($d2 in Get-ChildItem -LiteralPath $d1.FullName -Directory -ErrorAction SilentlyContinue) {
                $bin2 = Join-Path $d2.FullName "bin"
                if (Test-Path -LiteralPath $bin2) { $candidates.Add($d2.FullName) }
            }
        }
    }
    if ($candidates.Count -eq 0) { return $null }
    # Имя последнего сегмента вида 8.3.xx — сортируем как строки версий
    return ($candidates | Sort-Object { try { [version](Split-Path $_ -Leaf) } catch { $_ } } -Descending | Select-Object -First 1)
}

function Get-ReleaseJarUrl {
    $uri = "https://api.github.com/repos/Adam-Rubinstein/1C_mcp_bsl/releases/latest"
    $rel = Invoke-RestMethod -Uri $uri -Headers @{ "User-Agent" = "1C_mcp_bsl-install-script" }
    $asset = $rel.assets | Where-Object { $_.name -eq "1C_mcp_bsl.jar" } | Select-Object -First 1
    if (-not $asset) { throw "В последнем релизе нет вложения 1C_mcp_bsl.jar" }
    return $asset.browser_download_url
}

$javaCmd = Find-JavaCommand
if (-not $javaCmd) {
    Write-Error "Не найден java. Установите JDK 17+ и добавьте в PATH или задайте JAVA_HOME."
}

$jarInRepo = Join-Path $RepoRoot "dist\1C_mcp_bsl.jar"
$jarPath = $null
if (Test-Path -LiteralPath $jarInRepo) {
    $jarPath = (Resolve-Path $jarInRepo).Path
} else {
    $cacheDir = Join-Path $env:LOCALAPPDATA "1C_mcp_bsl"
    New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
    $jarPath = Join-Path $cacheDir "1C_mcp_bsl.jar"
    if (-not $DryRun) {
        $url = Get-ReleaseJarUrl
        Write-Host "Скачивание JAR в $jarPath ..."
        Invoke-WebRequest -Uri $url -OutFile $jarPath -UseBasicParsing
    }
}

$platformPath = Find-1CPlatformPath
if (-not $platformPath) {
    Write-Error "Не найдена установка 1С:Предприятие 8.3 (ожидались каталоги с bin под Program Files\1cv8). Установите платформу или передайте путь вручную (см. documentation/INSTALL.md)."
}

$obj = [ordered]@{
    mcpServers = [ordered]@{
        "1c-platform" = [ordered]@{
            type    = "stdio"
            command = $javaCmd
            args    = @(
                "-Dfile.encoding=UTF-8",
                "-jar",
                $jarPath,
                "--platform-path",
                $platformPath
            )
        }
    }
}

$json = $obj | ConvertTo-Json -Depth 10
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

Write-Host "Java:          $javaCmd"
Write-Host "JAR:           $jarPath"
Write-Host "platform-path: $platformPath"
Write-Host "Выход:         $outPath"

if ($DryRun) {
    Write-Host "[DryRun] файл не записан."
    exit 0
}

New-Item -ItemType Directory -Force -Path $cursorDir | Out-Null
[System.IO.File]::WriteAllText($outPath, $json, $utf8NoBom)
Write-Host "Готово. В Cursor: Reload Window, проверьте MCP 1c-platform."
