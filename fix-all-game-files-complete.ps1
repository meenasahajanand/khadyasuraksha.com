# PowerShell Script to Fix All Game Files - Complete Structure
# Based on Five_Nights_at_Freddy_s_2.html structure
# Fixes: Remove duplicate ads, add icon URLs, add carousel, ensure proper structure

$gameFiles = Get-ChildItem -Path "game" -Filter "*.html" -File

# Read index.html to get icon URLs mapping
$iconMap = @{}
$indexContent = Get-Content "index.html" -Raw -Encoding UTF8
$iconMatches = [regex]::Matches($indexContent, 'href="game/([^"]+\.html)">[\s\S]*?data-src="https://img\.civilitythegame\.com/Icon/([^"]+)"[\s\S]*?alt="([^"]+)"')
foreach ($match in $iconMatches) {
    $fileName = $match.Groups[1].Value
    $iconUrl = "https://img.civilitythegame.com/Icon/" + $match.Groups[2].Value
    $gameName = $match.Groups[3].Value
    $iconMap[$fileName] = @{
        'url' = $iconUrl
        'name' = $gameName
    }
}

# Also check games.html, hotgame.html, newdategame.html
$otherPages = @("games.html", "hotgame.html", "newdategame.html", "index-2.html")
foreach ($page in $otherPages) {
    if (Test-Path $page) {
        $pageContent = Get-Content $page -Raw -Encoding UTF8
        $pageMatches = [regex]::Matches($pageContent, 'href="game/([^"]+\.html)"[^>]*>[\s\S]*?data-src="https://img\.civilitythegame\.com/Icon/([^"]+)"[\s\S]*?alt="([^"]+)"')
        foreach ($match in $pageMatches) {
            $fileName = $match.Groups[1].Value
            if (-not $iconMap.ContainsKey($fileName)) {
                $iconUrl = "https://img.civilitythegame.com/Icon/" + $match.Groups[2].Value
                $gameName = $match.Groups[3].Value
                $iconMap[$fileName] = @{
                    'url' = $iconUrl
                    'name' = $gameName
                }
            }
        }
    }
}

$count = 0
$fixed = 0
$errors = 0

foreach ($file in $gameFiles) {
    $count++
    $filePath = $file.FullName
    $fileName = $file.Name
    Write-Host "[$count/$($gameFiles.Count)] Processing: $fileName" -ForegroundColor Cyan
    
    try {
        $content = Get-Content $filePath -Raw -Encoding UTF8
        $originalContent = $content
        $changed = $false
        
        # 1. Remove duplicate horizontal ads (keep only first one after navigation)
        $horizontalAdPattern = '(?s)(<!-- First Display Ad - Horizontal \(468x50\) -->.*?</div>\s*</div>\s*</div>)'
        $matches = [regex]::Matches($content, $horizontalAdPattern)
        if ($matches.Count -gt 1) {
            # Keep first, remove others
            for ($i = 1; $i -lt $matches.Count; $i++) {
                $content = $content -replace [regex]::Escape($matches[$i].Value), ''
                $changed = $true
            }
            Write-Host "  Removed $($matches.Count - 1) duplicate horizontal ad(s)" -ForegroundColor Yellow
        }
        
        # 2. Extract game name from navigation
        $gameName = ""
        if ($content -match '<span>([^<]+)</span></p>') {
            $gameName = $matches[1]
        } else {
            $gameName = $fileName -replace '\.html$', '' -replace '_', ' '
        }
        
        # 3. Find and update icon URL
        $iconUrl = ""
        if ($iconMap.ContainsKey($fileName)) {
            $iconUrl = $iconMap[$fileName]['url']
        } else {
            # Try to find in Recommended Games section of the file itself
            if ($content -match "data-src=`"https://img\.civilitythegame\.com/Icon/([^`"]+)`".*alt=`"$([regex]::Escape($gameName))`"") {
                $iconHash = $matches[1]
                $iconUrl = "https://img.civilitythegame.com/Icon/$iconHash"
            }
        }
        
        if ($iconUrl -and $content -match '<img class="lazyLoad" src=""') {
            $content = $content -replace '<img class="lazyLoad" src=""', "<img class=`"lazyLoad`" src=`"$iconUrl`""
            $changed = $true
            Write-Host "  Updated icon URL" -ForegroundColor Green
        }
        
        # 4. Check if carousel section exists, if not add it
        if (-not ($content -match 'seeding_box')) {
            # Find carousel images from Recommended Games or other sections
            $carouselImages = @()
            $imgMatches = [regex]::Matches($content, 'data-src="https://img\.civilitythegame\.com/Img/([^"]+\.jpg)"')
            foreach ($match in $imgMatches) {
                $imgName = $match.Groups[1].Value
                if ($imgName -notmatch 'lazyload\.png' -and $imgName -notmatch 'Icon/') {
                    # Check if image name matches game name pattern
                    $gameNamePattern = $gameName -replace '[^a-zA-Z0-9]', '_'
                    if ($imgName -match $gameNamePattern -or $imgName -match [regex]::Escape($fileName -replace '\.html$', '')) {
                        $carouselImages += $imgName
                    }
                }
            }
            
            # If no specific images found, use first 3 Img folder images
            if ($carouselImages.Count -eq 0) {
                $allImgMatches = [regex]::Matches($content, 'data-src="https://img\.civilitythegame\.com/Img/([^"]+\.jpg)"')
                foreach ($match in $allImgMatches) {
                    $imgName = $match.Groups[1].Value
                    if ($imgName -notmatch 'lazyload\.png' -and $imgName -notmatch 'Icon/') {
                        $carouselImages += $imgName
                        if ($carouselImages.Count -ge 3) { break }
                    }
                }
            }
            
            # Add carousel section before Description
            if ($carouselImages.Count -gt 0) {
                $carouselSlides = ""
                foreach ($img in $carouselImages) {
                    $carouselSlides += "                                <div class=`"swiper-slide`">`n<img  class=`"lazyload`" src=`"https://img.civilitythegame.com/Img/lazyload.png`" data-src=`"https://img.civilitythegame.com/Img/$img`" alt=`"`">`n</div>`n"
                }
                
                $carouselSection = @"
            <!-- Carousel -->
            <div class="public_box">
                <div class="seeding_box">
                    <div class="seeding">
                        <div class="swiper">
                            <div class="swiper-wrapper">
$carouselSlides                            </div>
                        </div>
                    </div>
                </div>
            </div>

"@
                
                # Insert before Description section
                if ($content -match '(?s)(<div class="public_box">\s*<div class="box_three">\s*<h3>Description</h3>)') {
                    $content = $content -replace '(?s)(<div class="public_box">\s*<div class="box_three">\s*<h3>Description</h3>)', "$carouselSection`$1"
                    $changed = $true
                    Write-Host "  Added carousel section with $($carouselImages.Count) images" -ForegroundColor Green
                }
            }
        }
        
        # 5. Ensure only one vertical ad in ad_box (remove any extra)
        $adBoxPattern = '(?s)(<div class="ad_box">.*?</div>\s*</div>\s*</div>)'
        $adBoxMatches = [regex]::Matches($content, $adBoxPattern)
        if ($adBoxMatches.Count -gt 1) {
            # Keep first, remove others
            for ($i = 1; $i -lt $adBoxMatches.Count; $i++) {
                $content = $content -replace [regex]::Escape($adBoxMatches[$i].Value), ''
                $changed = $true
            }
            Write-Host "  Removed $($adBoxMatches.Count - 1) duplicate ad_box(s)" -ForegroundColor Yellow
        }
        
        # 6. Ensure proper spacing between sections
        if ($content -match '</div>\s*</div>\s*<div class="public_box">') {
            $content = $content -replace '</div>\s*</div>\s*<div class="public_box">', "`n            </div>`n            <div class=`"public_box`">"
            $changed = $true
        }
        
        # Save if changed
        if ($changed) {
            $content | Set-Content $filePath -Encoding UTF8 -NoNewline
            Write-Host "  Fixed!" -ForegroundColor Green
            $fixed++
        } else {
            Write-Host "  No changes needed" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        $errors++
    }
    
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Total files: $count" -ForegroundColor White
Write-Host "  Fixed: $fixed" -ForegroundColor Green
Write-Host "  Errors: $errors" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Cyan

