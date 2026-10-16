# Compila LavaExpress para web en modo release y quita las fuentes que no se usan.
#
# El paquete lucide_icons_flutter trae variantes de grosor (Lucide100 ... Lucide600)
# que Flutter web descarga al iniciar aunque la app solo use la fuente "Lucide".
# Quitarlas del manifiesto ahorra cerca de 3 MB en la primera carga.
#
# El modo sin conexión lo da web/sw.js (registrado en index.html). La plantilla
# web/flutter_bootstrap.js no registra el service worker de Flutter, que en 3.47
# solo se desregistra a sí mismo (se deja en build\web para limpiar instalaciones viejas).
#
# Uso (desde la carpeta lavaexpress):   .\construir_web.ps1

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

flutter build web --release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$web = Join-Path $PSScriptRoot 'build\web'
$manifiesto = Join-Path $web 'assets\FontManifest.json'

$fuentes = Get-Content $manifiesto -Raw | ConvertFrom-Json
$usadas = @($fuentes | Where-Object { $_.family -notmatch '^packages/lucide_icons_flutter/Lucide\d+$' })
ConvertTo-Json -InputObject $usadas -Depth 5 -Compress | Set-Content $manifiesto -Encoding utf8NoBOM

$variantes = Join-Path $web 'assets\packages\lucide_icons_flutter\assets\build_font'
if (Test-Path $variantes) { Remove-Item $variantes -Recurse -Force }

if (-not (Test-Path (Join-Path $web 'sw.js'))) { throw 'Falta sw.js en build\web' }

Write-Host ("Listo: se quitaron {0} fuentes sin uso de build\web" -f ($fuentes.Count - $usadas.Count))
