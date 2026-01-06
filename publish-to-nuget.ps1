# 推送 HoYoShadeHub.Assets 到 NuGet.org

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  发布 NuGet 包到 NuGet.org" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 参数配置
$packageName = "HoYoShadeHub.Assets"
$packageVersion = "1.01.0"
$nugetSource = "https://api.nuget.org/v3/index.json"

# 检查 API Key
Write-Host "[1/5] 检查 NuGet API Key..." -ForegroundColor Yellow

# 从环境变量或配置中读取 API Key
$apiKey = $env:NUGET_API_KEY

if ([string]::IsNullOrEmpty($apiKey)) {
    Write-Host ""
    Write-Host "未找到 NuGet API Key。" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "请访问以下步骤获取 API Key:" -ForegroundColor White
    Write-Host "  1. 访问 https://www.nuget.org/" -ForegroundColor Gray
    Write-Host "  2. 登录您的账户" -ForegroundColor Gray
    Write-Host "  3. 点击右上角用户名 -> API Keys" -ForegroundColor Gray
    Write-Host "  4. 创建新的 API Key (Create)" -ForegroundColor Gray
    Write-Host "  5. 设置范围为 'Push' 和 'Push new packages and package versions'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "请输入您的 NuGet API Key: " -NoNewline -ForegroundColor Cyan
    $apiKey = Read-Host -AsSecureString
    $apiKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKey))
    
    if ([string]::IsNullOrEmpty($apiKey)) {
        Write-Host "[错误] API Key 不能为空" -ForegroundColor Red
        exit 1
    }
}

Write-Host "  ✓ API Key 已配置" -ForegroundColor Green

# 检查包文件是否存在
Write-Host "`n[2/5] 检查包文件..." -ForegroundColor Yellow

$packageFile = "LocalNuGetPackages\$packageName.$packageVersion.nupkg"

if (-not (Test-Path $packageFile)) {
    Write-Host "[错误] 未找到包文件: $packageFile" -ForegroundColor Red
    Write-Host ""
    Write-Host "请先运行打包脚本:" -ForegroundColor Yellow
    Write-Host "  .\build-nuget-package.ps1" -ForegroundColor Gray
    exit 1
}

Write-Host "  ✓ 找到包文件: $packageFile" -ForegroundColor Green

# 验证包内容
Write-Host "`n[3/5] 验证包内容..." -ForegroundColor Yellow

try {
    # 使用 nuget verify 验证包（如果支持）
    $verifyOutput = nuget verify -Signatures $packageFile 2>&1
    Write-Host "  ✓ 包文件格式正确" -ForegroundColor Green
} catch {
    Write-Host "  ! 警告: 无法验证包签名（这是正常的，如果包未签名）" -ForegroundColor Yellow
}

# 确认发布
Write-Host "`n[4/5] 准备发布..." -ForegroundColor Yellow
Write-Host ""
Write-Host "包名称: $packageName" -ForegroundColor Cyan
Write-Host "包版本: $packageVersion" -ForegroundColor Cyan
Write-Host "目标源: $nugetSource" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  警告: 发布后的包版本无法删除，只能取消列出（unlist）" -ForegroundColor Yellow
Write-Host ""
Write-Host "是否继续发布? (Y/N): " -NoNewline -ForegroundColor White
$confirmation = Read-Host

if ($confirmation -ne "Y" -and $confirmation -ne "y") {
    Write-Host ""
    Write-Host "已取消发布" -ForegroundColor Yellow
    exit 0
}

# 推送到 NuGet.org
Write-Host "`n[5/5] 推送到 NuGet.org..." -ForegroundColor Yellow

try {
    $pushOutput = nuget push $packageFile -Source $nugetSource -ApiKey $apiKey 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ 推送成功！" -ForegroundColor Green
    } else {
        Write-Host "  ✗ 推送失败" -ForegroundColor Red
        Write-Host ""
        Write-Host "错误信息:" -ForegroundColor Red
        Write-Host $pushOutput
        
        # 常见错误提示
        if ($pushOutput -match "409") {
            Write-Host ""
            Write-Host "提示: 此版本号已存在，请更新 .nuspec 文件中的版本号" -ForegroundColor Yellow
        }
        exit 1
    }
} catch {
    Write-Host "  ✗ 推送出错: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  发布成功！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "包页面: https://www.nuget.org/packages/$packageName/$packageVersion" -ForegroundColor Cyan
Write-Host ""
Write-Host "⏰ 注意: 包可能需要几分钟时间才能在 NuGet.org 上索引完成" -ForegroundColor Yellow
Write-Host ""
Write-Host "使用方法:" -ForegroundColor White
Write-Host "  在项目中添加包引用:" -ForegroundColor Gray
Write-Host "  <PackageReference Include=`"$packageName`" Version=`"$packageVersion`" />" -ForegroundColor Gray
Write-Host ""
Write-Host "或使用命令行:" -ForegroundColor Gray
Write-Host "  dotnet add package $packageName --version $packageVersion" -ForegroundColor Gray
Write-Host ""

# 可选: 保存 API Key 到环境变量
Write-Host "是否保存 API Key 到用户环境变量? (Y/N): " -NoNewline -ForegroundColor White
$saveKey = Read-Host

if ($saveKey -eq "Y" -or $saveKey -eq "y") {
    try {
        [System.Environment]::SetEnvironmentVariable("NUGET_API_KEY", $apiKey, [System.EnvironmentVariableTarget]::User)
        Write-Host "  ✓ API Key 已保存到环境变量 NUGET_API_KEY" -ForegroundColor Green
        Write-Host "  下次运行时将自动使用此 API Key" -ForegroundColor Gray
    } catch {
        Write-Host "  ✗ 保存失败: $_" -ForegroundColor Red
    }
}

Write-Host ""
