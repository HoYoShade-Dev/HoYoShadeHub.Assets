# HoYoShadeHub.Assets NuGet 包打包脚本

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  HoYoShadeHub.Assets NuGet 打包工具" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查 nuget.exe
$nugetPath = Get-Command nuget -ErrorAction SilentlyContinue
if (-not $nugetPath) {
    Write-Host "[错误] 未找到 nuget.exe" -ForegroundColor Red
    Write-Host "请安装 NuGet:" -ForegroundColor Yellow
    Write-Host "  winget install Microsoft.NuGet" -ForegroundColor Gray
    Write-Host "或者:" -ForegroundColor Yellow
    Write-Host "  使用 dotnet pack (如果项目有 .csproj)" -ForegroundColor Gray
    exit 1
}

Write-Host "[1/5] 验证包结构..." -ForegroundColor Yellow

# 检查必要文件
$requiredFiles = @(
    "HoYoShadeHub.Assets.nuspec",
    "build\HoYoShadeHub.Assets.targets",
    "build\Assets\logo.png"
)

$missing = @()
foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        $missing += $file
    }
}

if ($missing.Count -gt 0) {
    Write-Host "[错误] 缺少必要文件:" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}

Write-Host "  ? 包结构验证通过" -ForegroundColor Green

# 列出包内容
Write-Host "`n[2/5] 包内容:" -ForegroundColor Yellow
Get-ChildItem "build\Assets" -Recurse -File | ForEach-Object {
    $relativePath = $_.FullName.Replace("$PWD\build\", "")
    $size = if ($_.Length -gt 1MB) { 
        "$([math]::Round($_.Length/1MB,2)) MB" 
    } else { 
        "$([math]::Round($_.Length/1KB,2)) KB" 
    }
    Write-Host "  $relativePath - $size" -ForegroundColor Cyan
}

# 打包
Write-Host "`n[3/5] 打包 NuGet 包..." -ForegroundColor Yellow

try {
    $output = nuget pack HoYoShadeHub.Assets.nuspec 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ? 打包成功" -ForegroundColor Green
    } else {
        Write-Host "  ? 打包失败" -ForegroundColor Red
        Write-Host $output
        exit 1
    }
} catch {
    Write-Host "  ? 打包出错: $_" -ForegroundColor Red
    exit 1
}

# 移动包文件
Write-Host "`n[4/5] 整理包文件..." -ForegroundColor Yellow

$packageFile = Get-Item "*.nupkg" -ErrorAction SilentlyContinue
if ($packageFile) {
    # 创建本地 NuGet 源目录
    $localSource = "LocalNuGetPackages"
    New-Item $localSource -ItemType Directory -Force | Out-Null
    
    # 移动包文件
    Move-Item $packageFile.FullName $localSource -Force
    Write-Host "  ? 包文件已移动到: $localSource\$($packageFile.Name)" -ForegroundColor Green
    
    $finalPath = Join-Path $localSource $packageFile.Name
} else {
    Write-Host "  ? 未找到生成的包文件" -ForegroundColor Red
    exit 1
}

# 配置本地 NuGet 源
Write-Host "`n[5/5] 配置本地 NuGet 源..." -ForegroundColor Yellow

$sourceName = "HoYoShadeHub-Local"
$sourceExists = nuget sources list | Select-String $sourceName

if ($sourceExists) {
    Write-Host "  本地 NuGet 源已存在: $sourceName" -ForegroundColor Gray
} else {
    $sourceUrl = Resolve-Path $localSource
    nuget sources add -Name $sourceName -Source $sourceUrl.Path
    Write-Host "  ? 已添加本地 NuGet 源: $sourceName" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  打包完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "包文件: $finalPath" -ForegroundColor Cyan
Write-Host "包版本: 1.0.0" -ForegroundColor Cyan
Write-Host ""
Write-Host "下一步:" -ForegroundColor Yellow
Write-Host "  1. 更新项目引用:" -ForegroundColor White
Write-Host "     将 <PackageReference Include=`"Starward.Assets`" Version=`"0.5.9`" />" -ForegroundColor Gray
Write-Host "     改为 <PackageReference Include=`"HoYoShadeHub.Assets`" Version=`"1.0.0`" />" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. 清理 NuGet 缓存:" -ForegroundColor White
Write-Host "     dotnet nuget locals all --clear" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. 重新编译:" -ForegroundColor White
Write-Host "     .\publish_test.ps1" -ForegroundColor Gray
Write-Host ""
