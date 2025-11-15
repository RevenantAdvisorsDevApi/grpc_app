# check_dependencies.ps1
# PowerShell pre-build script for Market Data gRPC C++ project

Write-Host "🔍 Checking required tools and dependencies..." -ForegroundColor Cyan

# --- Step 1: Check basic tools ---
function Check-Tool($name, $cmd) {
    Write-Host "Checking $name..."
    $exists = Get-Command $cmd -ErrorAction SilentlyContinue
    if (-not $exists) {
        Write-Host "❌ $name not found. Please install it and re-run." -ForegroundColor Red
        exit 1
    } else {
        Write-Host "✅ $name found: $($exists.Source)" -ForegroundColor Green
    }
}

Check-Tool "CMake" "cmake"
Check-Tool "Git" "git"

# Check for Visual Studio compiler (cl.exe)
$cl = Get-Command "cl.exe" -ErrorAction SilentlyContinue
if (-not $cl) {
    Write-Host "❌ Visual Studio C++ compiler not found. Please open the Developer Command Prompt or ensure VS Build Tools are installed." -ForegroundColor Red
    exit 1
} else {
    Write-Host "✅ MSVC compiler found." -ForegroundColor Green
}

# --- Step 2: vcpkg setup ---
$VCPKG_ROOT = "$env:USERPROFILE\vcpkg"

if (-Not (Test-Path $VCPKG_ROOT)) {
    Write-Host "⚙️ vcpkg not found. Installing to $VCPKG_ROOT ..." -ForegroundColor Yellow
    git clone https://github.com/microsoft/vcpkg.git $VCPKG_ROOT
    & "$VCPKG_ROOT\bootstrap-vcpkg.bat"
} else {
    Write-Host "✅ vcpkg found at $VCPKG_ROOT" -ForegroundColor Green
}

# --- Step 3: Check required packages ---
$packages = @("protobuf:x64-windows", "grpc:x64-windows", "curl:x64-windows")

foreach ($pkg in $packages) {
    $pkgName = $pkg.Split(":")[0]
    Write-Host "Checking if $pkgName is installed..."
    $pkgInstalled = & "$VCPKG_ROOT\vcpkg.exe" list | Select-String $pkgName

    if (-not $pkgInstalled) {
        Write-Host "⚙️ Installing $pkgName via vcpkg..." -ForegroundColor Yellow
        & "$VCPKG_ROOT\vcpkg.exe" install $pkg
    } else {
        Write-Host "✅ $pkgName already installed." -ForegroundColor Green
    }
}

Write-Host "🎉 All dependencies verified. Ready to build!" -ForegroundColor Cyan
exit 0
