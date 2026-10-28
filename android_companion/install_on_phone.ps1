param(
    [string]$ApkPath = ""
)

$ErrorActionPreference = "Stop"

$adb = Get-Command adb -ErrorAction SilentlyContinue
if (-not $adb) {
    throw "ADB не найден. Установите Android Platform Tools и повторите запуск."
}

$devices = @(
    & $adb.Source devices |
        Select-Object -Skip 1 |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -match "\sdevice$" }
)

if ($devices.Count -ne 1) {
    throw "Нужен ровно один подключённый Android со статусом device. Сейчас найдено: $($devices.Count)."
}

if (-not $ApkPath) {
    $ApkPath = Join-Path $PSScriptRoot "app\build\outputs\apk\debug\app-debug.apk"
}
$resolvedApk = Resolve-Path -LiteralPath $ApkPath -ErrorAction SilentlyContinue
if (-not $resolvedApk) {
    throw "APK не найден: $ApkPath. Сначала скачайте артефакт GitHub Actions или соберите :app:assembleDebug."
}

Write-Host "Устанавливаю OMA Digital Home на единственный подключённый телефон..."
& $adb.Source install -r $resolvedApk.Path
if ($LASTEXITCODE -ne 0) {
    throw "Установка не выполнена. Если Android сообщает о несовместимой подписи, вручную удалите только демоверсию by.oma.digitalhome.demo и повторите команду."
}

& $adb.Source shell am force-stop by.oma.digitalhome.demo
& $adb.Source shell monkey -p by.oma.digitalhome.demo -c android.intent.category.LAUNCHER 1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "APK установлен, но приложение не удалось запустить автоматически. Откройте «ОМА · Цифровой дом» на телефоне."
}

Write-Host "Готово: приложение установлено и запущено на одном Android."
