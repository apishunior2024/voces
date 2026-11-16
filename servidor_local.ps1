$ErrorActionPreference = 'Stop'
$root = [System.IO.Path]::GetFullPath($PSScriptRoot)
$port = 8765
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$port/")
try { $listener.Start() } catch {
 Write-Host "No se pudo abrir el puerto $port. Cierra otros servidores o programas que lo utilicen." -ForegroundColor Red
 Write-Host $_.Exception.Message
 Read-Host 'Pulsa Enter para salir'
 exit 1
}
$url = "http://127.0.0.1:$port/"
Write-Host ''
Write-Host 'THE WEEKLY FLYER - VOZ FACIL' -ForegroundColor Cyan
Write-Host "Abriendo $url" -ForegroundColor Green
Write-Host 'Mantener esta ventana abierta. Ctrl+C para cerrar.' -ForegroundColor Yellow
try { Start-Process $url } catch { Write-Host "Abre manualmente: $url" }
$mime = @{
 '.html' = 'text/html; charset=utf-8'; '.js' = 'text/javascript; charset=utf-8';
 '.css' = 'text/css; charset=utf-8'; '.json' = 'application/json';
 '.webmanifest' = 'application/manifest+json'; '.png' = 'image/png';
 '.svg' = 'image/svg+xml'; '.wasm'='application/wasm'; '.ico'='image/x-icon';
 '.txt'='text/plain; charset=utf-8'
}
try {
 while($listener.IsListening){
  $context=$listener.GetContext()
  try {
   $requestPath = [Uri]::UnescapeDataString($context.Request.Url.AbsolutePath)
   $requestPath=$requestPath.TrimStart('/')
   if([string]::IsNullOrWhiteSpace($requestPath)){$requestPath='index.html'}
   $target=[System.IO.Path]::GetFullPath([System.IO.Path]::Combine($root,$requestPath.Replace('/',[System.IO.Path]::DirectorySeparatorChar)))
   if((-not $target.StartsWith($root+[System.IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) -or (-not [System.IO.File]::Exists($target))){
    $context.Response.StatusCode=404
    $bytes=[System.Text.Encoding]::UTF8.GetBytes('Archivo no encontrado')
   } else {
    $ext=[System.IO.Path]::GetExtension($target).ToLowerInvariant()
    if($mime.ContainsKey($ext)){$context.Response.ContentType=$mime[$ext]}else{$context.Response.ContentType='application/octet-stream'}
    $bytes=[System.IO.File]::ReadAllBytes($target)
   }
   $context.Response.ContentLength64=$bytes.Length
   $context.Response.OutputStream.Write($bytes,0,$bytes.Length)
  } catch {
   Write-Host $_.Exception.Message -ForegroundColor Yellow
  } finally {
   try{$context.Response.OutputStream.Close()}catch{}
  }
 }
} finally { $listener.Stop(); $listener.Close() }
