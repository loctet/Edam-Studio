# EDAM Studio Documentation Build Script
# Generates HTML documentation from Markdown using Pandoc
# Requires: Pandoc (https://pandoc.org)

$ErrorActionPreference = "Stop"
$DocDir = $PSScriptRoot
$MdFile = Join-Path $DocDir "studio-documentation.md"
$CssFile = Join-Path $DocDir "doc-style.css"
$OutputFile = Join-Path $DocDir "studio-documentation.html"

Write-Host "EDAM Studio - Documentation Build" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Check Pandoc
try {
    $pandocVersion = pandoc --version 2>$null | Select-Object -First 1
    Write-Host "Using: $pandocVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Pandoc is not installed or not in PATH." -ForegroundColor Red
    Write-Host "Install from: https://pandoc.org/installing.html" -ForegroundColor Yellow
    exit 1
}

# Check source file
if (-not (Test-Path $MdFile)) {
    Write-Host "ERROR: Source file not found: $MdFile" -ForegroundColor Red
    exit 1
}

# Build Pandoc command
$pandocArgs = @(
    $MdFile,
    "-o", $OutputFile,
    "--standalone",
    "--toc",
    "--toc-depth=3",
    "--metadata", "title=EDAM Studio Documentation",
    "--metadata", "lang=en",
    "-f", "markdown",
    "-t", "html5",
    "--css=doc-style.css",
    "--number-sections"
)

Write-Host "`nGenerating HTML..." -ForegroundColor Yellow
& pandoc $pandocArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nSUCCESS: Documentation generated at:" -ForegroundColor Green
    Write-Host "  $OutputFile" -ForegroundColor White
    Write-Host "`nOpen in browser: file:///$($OutputFile -replace '\\', '/')" -ForegroundColor Gray
} else {
    Write-Host "`nERROR: Pandoc failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit 1
}
