#Requires -Version 5.1
<#
.SYNOPSIS
  Создаёт .cursor/mcp.json (MCP 1c-platform): Java, JAR, --platform-path.

.DESCRIPTION
  Варианты:
  1) Запуск из клона репозитория (рядом scripts/ и dist/) — пишет в корень этого клона.
  2) -WorkspaceRoot "C:\проект\ERP" — пишет в открытый проект; источник — клон рядом со скриптом.
  3) -GitHubUrl "https://github.com/Owner/Repo" [-WorkspaceRoot ...] — клон в %LOCALAPPDATA%\1C_mcp_bsl\checkout,
     затем как (2); WorkspaceRoot по умолчанию — текущий каталог (Get-Location).
  -OverrideJarPath / -OverridePlatformPath — для тестов и нестандартных путей (без скачивания JAR / без поиска 1С в Program Files).
  После успеха копирует use-1c-platform-mcp.mdc и mcp.json.example в WorkspaceRoot\.cursor\
#>
param(
    [string] $WorkspaceRoot = "",
    [string] $SourceRepoRoot = "",
    [string] $GitHubUrl = "",
    [string] $OverrideJarPath = "",
    [string] $OverridePlatformPath = "",
    [switch] $DryRun
)

$ErrorActionPreference = "Stop"

function Parse-GitHubSpec {
    param([string] $Spec)
    $t = $Spec.Trim()
    if ($t -match '^https?://github\.com/([^/]+)/([^/#?]+)') {
        return @{ Owner = $matches[1]; Repo = $matches[2].TrimEnd(".git") }
    }
    if ($t -match '^([^/]+)/([^/]+)$') {
        return @{ Owner = $matches[1].Trim(); Repo = $matches[2].TrimEnd(".git") }
    }
    return $null
}

function Ensure-GitClone {
    param([string] $Owner, [string] $Repo)
    $base = Join-Path $env:LOCALAPPDATA "1C_mcp_bsl\checkout"
    $dest = Join-Path $base ("{0}_{1}" -f $Owner, $Repo)
    $gitUrl = "https://github.com/${Owner}/${Repo}.git"
    if (Test-Path (Join-Path $dest ".git")) {
        Write-Host "Обновление клона: $dest"
        if (-not $DryRun) {
            git -C $dest pull --ff-only 2>$null
            if ($LASTEXITCODE -ne 0) {
                git -C $dest fetch --depth 1 origin 2>$null
                git -C $dest merge FETCH_HEAD --ff-only 2>$null
            }
        }
    } else {
        Write-Host "Клонирование: $gitUrl -> $dest"
        if (-not $DryRun) {
            New-Item -ItemType Directory -Force -Path $base | Out-Null
            git clone --depth 1 $gitUrl $dest
        }
    }
    return $dest
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
    return ($candidates | Sort-Object { try { [version](Split-Path $_ -Leaf) } catch { $_ } } -Descending | Select-Object -First 1)
}

function Get-ReleaseJarUrl {
    param([string] $Owner, [string] $Repo)
    $uri = "https://api.github.com/repos/${Owner}/${Repo}/releases/latest"
    $rel = Invoke-RestMethod -Uri $uri -Headers @{ "User-Agent" = "1C_mcp_bsl-install-script" }
    $asset = $rel.assets | Where-Object { $_.name -eq "1C_mcp_bsl.jar" } | Select-Object -First 1
    if (-not $asset) { throw "В последнем релизе $Owner/$Repo нет вложения 1C_mcp_bsl.jar" }
    return $asset.browser_download_url
}

function Copy-CursorTemplateFiles {
    param([string] $FromRepo, [string] $ToWorkspace)
    $cursorSrc = Join-Path $FromRepo ".cursor"
    $cursorDst = Join-Path $ToWorkspace ".cursor"
    $rulesSrc = Join-Path $cursorSrc "rules"
    $rulesDst = Join-Path $cursorDst "rules"
    $ruleFile = "use-1c-platform-mcp.mdc"
    $srcRule = Join-Path $rulesSrc $ruleFile
    if (Test-Path -LiteralPath $srcRule) {
        if (-not $DryRun) {
            New-Item -ItemType Directory -Force -Path $rulesDst | Out-Null
            Copy-Item -LiteralPath $srcRule -Destination (Join-Path $rulesDst $ruleFile) -Force
        }
        Write-Host "Скопировано: $ruleFile -> $rulesDst"
    }
    $srcEx = Join-Path $cursorSrc "mcp.json.example"
    if (Test-Path -LiteralPath $srcEx) {
        if (-not $DryRun) {
            New-Item -ItemType Directory -Force -Path $cursorDst | Out-Null
            Copy-Item -LiteralPath $srcEx -Destination (Join-Path $cursorDst "mcp.json.example") -Force
        }
        Write-Host "Скопировано: mcp.json.example -> $cursorDst"
    }
}

# --- Разбор источника (клон с GitHub или репозиторий рядом со скриптом) ---
$jarOwner = "Adam-Rubinstein"
$jarRepo = "1C_mcp_bsl"

if ($GitHubUrl) {
    $spec = Parse-GitHubSpec $GitHubUrl
    if (-not $spec) { Write-Error "Не разобрать URL GitHub: $GitHubUrl (ожидалось https://github.com/Владелец/Репо или Владелец/Репо)" }
    $jarOwner = $spec.Owner
    $jarRepo = $spec.Repo
    if (-not $DryRun) {
        $SourceRepoRoot = Ensure-GitClone -Owner $spec.Owner -Repo $spec.Repo
        $SourceRepoRoot = (Resolve-Path $SourceRepoRoot).Path
    } else {
        $SourceRepoRoot = Join-Path $env:LOCALAPPDATA ("1C_mcp_bsl\checkout\{0}_{1}" -f $spec.Owner, $spec.Repo)
    }
} elseif ($SourceRepoRoot) {
    $SourceRepoRoot = (Resolve-Path -LiteralPath $SourceRepoRoot).Path
} else {
    $nextToScript = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $exNext = Join-Path $nextToScript ".cursor\mcp.json.example"
    if (Test-Path -LiteralPath $exNext) {
        $SourceRepoRoot = $nextToScript
    } else {
        Write-Error "Скрипт не из клона 1C_mcp_bsl (нет .cursor/mcp.json.example рядом). Укажите -GitHubUrl, например: -GitHubUrl 'https://github.com/Adam-Rubinstein/1C_mcp_bsl'"
    }
}

if (-not $WorkspaceRoot) {
    if ($GitHubUrl) {
        $WorkspaceRoot = (Get-Location).Path
    } else {
        $WorkspaceRoot = $SourceRepoRoot
    }
} else {
    $WorkspaceRoot = (Resolve-Path -LiteralPath $WorkspaceRoot).Path
}

if (Test-Path -LiteralPath $SourceRepoRoot) {
    $SourceRepoRoot = (Resolve-Path -LiteralPath $SourceRepoRoot).Path
}
$examplePath = Join-Path $SourceRepoRoot ".cursor\mcp.json.example"
if (-not (Test-Path -LiteralPath $examplePath)) {
    Write-Error "Не найден $examplePath. Укажите -GitHubUrl с корректным репозиторием или клонируйте проект вручную."
}

$cursorDir = Join-Path $WorkspaceRoot ".cursor"
$outPath = Join-Path $cursorDir "mcp.json"

$javaCmd = Find-JavaCommand
if (-not $javaCmd) {
    Write-Error "Не найден java. Установите JDK 17+ и PATH или JAVA_HOME."
}

$jarPath = $null
if ($OverrideJarPath) {
    if (-not (Test-Path -LiteralPath $OverrideJarPath)) { Write-Error "Не найден JAR по OverrideJarPath: $OverrideJarPath" }
    $jarPath = (Resolve-Path -LiteralPath $OverrideJarPath).Path
} else {
    $jarInRepo = Join-Path $SourceRepoRoot "dist\1C_mcp_bsl.jar"
    if (Test-Path -LiteralPath $jarInRepo) {
        $jarPath = (Resolve-Path $jarInRepo).Path
    } else {
        $cacheDir = Join-Path $env:LOCALAPPDATA "1C_mcp_bsl"
        New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
        $jarPath = Join-Path $cacheDir "1C_mcp_bsl.jar"
        if ($DryRun) {
            Write-Host "[DryRun] JAR не скачивается; условный путь: $jarPath"
        } else {
            $url = Get-ReleaseJarUrl -Owner $jarOwner -Repo $jarRepo
            Write-Host "Скачивание JAR в $jarPath ..."
            Invoke-WebRequest -Uri $url -OutFile $jarPath -UseBasicParsing
        }
    }
}

$platformPath = $null
if ($OverridePlatformPath) {
    if (-not (Test-Path -LiteralPath $OverridePlatformPath)) { Write-Error "Не найден каталог платформы: $OverridePlatformPath" }
    $platformPath = (Resolve-Path -LiteralPath $OverridePlatformPath).Path
} else {
    $platformPath = Find-1CPlatformPath
}
if (-not $platformPath) {
    Write-Error "Не найдена установка 1С:Предприятие 8.3 (каталоги с bin под Program Files\1cv8). Укажите -OverridePlatformPath или см. documentation/INSTALL.md."
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

Write-Host "Источник шаблонов: $SourceRepoRoot"
Write-Host "Рабочий проект:    $WorkspaceRoot"
Write-Host "Java:              $javaCmd"
Write-Host "JAR:               $jarPath"
Write-Host "platform-path:     $platformPath"
Write-Host "mcp.json ->        $outPath"

if ($DryRun) {
    Write-Host "[DryRun] файлы не записаны."
    exit 0
}

New-Item -ItemType Directory -Force -Path $cursorDir | Out-Null
[System.IO.File]::WriteAllText($outPath, $json, $utf8NoBom)
Copy-CursorTemplateFiles -FromRepo $SourceRepoRoot -ToWorkspace $WorkspaceRoot
Write-Host "Готово. В Cursor: Reload Window, проверьте MCP 1c-platform."
