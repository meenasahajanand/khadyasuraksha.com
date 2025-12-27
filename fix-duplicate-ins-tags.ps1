# PowerShell Script to Fix Duplicate </ins> Tags

$gameFiles = Get-ChildItem -Path "game" -Filter "*.html" -File

$count = 0
$fixed = 0

foreach ($file in $gameFiles) {
    $count++
    $filePath = $file.FullName
    $fileName = $file.Name
    
    try {
        $content = Get-Content $filePath -Raw -Encoding UTF8
        
        if ($content -match '</ins></ins>') {
            $content = $content -replace '</ins></ins>', '</ins>'
            $content | Set-Content $filePath -Encoding UTF8 -NoNewline
            Write-Host "[$count] $fileName - Fixed duplicate </ins> tag" -ForegroundColor Yellow
            $fixed++
        }
    } catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nFixed: $fixed files" -ForegroundColor Green

