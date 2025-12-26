# PowerShell Script to Update All Game Pages with AdSense Ads
# Run this script from the project root directory

$gameFiles = Get-ChildItem -Path "game" -Filter "*.html" -Recurse

$adSenseScript = @"
    <!-- Google AdSense -->
    <script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-7354377815781712"
     crossorigin="anonymous"></script>
"@

$firstDisplayAd = @"
    <!-- First Display Ad - After Header -->
    <div class="ads-container vertical" style="max-width: 300px; margin: 20px auto;">
        <div class="ad-label">Advertisement</div>
        <!-- 2display_2512 - 300x600 Desktop, 320x480 Mobile -->
        <ins class="adsbygoogle"
             style="display:block"
             data-ad-client="ca-pub-7354377815781712"
             data-ad-slot="1150075265"
             data-ad-format="auto"
             data-full-width-responsive="true"></ins>
        <script>
             (adsbygoogle = window.adsbygoogle || []).push({});
        </script>
    </div>

"@

$newAdBox = @"
                    <div class="ad_box">
                        <div class="ad">
                            <div style="width: 100%; max-width: 480px; margin: 0 auto;">
                                <!-- 1dispaly_2512 - Second Display Ad Horizontal 320x480 -->
                                <ins class="adsbygoogle"
                                     style="display:block; width: 100%; max-width: 480px; height: 320px;"
                                     data-ad-client="ca-pub-7354377815781712"
                                     data-ad-slot="2463156936"
                                     data-ad-format="auto"
                                     data-full-width-responsive="true"></ins>
                                <script>
                                     (adsbygoogle = window.adsbygoogle || []).push({});
                                </script>
                            </div>
                            <p>Advertisement</p>
                        </div>
                    </div>
"@

$interAds = @"

    <!-- Inter Ad Unit - 320x480 (1inter_2512) -->
    <div class="ads-container vertical" style="max-width: 320px; margin: 20px auto;">
        <div class="ad-label">Advertisement</div>
        <ins class="adsbygoogle"
             style="display:block; width: 320px; height: 480px;"
             data-ad-client="ca-pub-7354377815781712"
             data-ad-slot="1685902515"
             data-ad-format="auto"
             data-full-width-responsive="true"></ins>
        <script>
             (adsbygoogle = window.adsbygoogle || []).push({});
        </script>
    </div>

    <!-- Inter Ad Unit - 468x60 (2inter_2512) -->
    <div class="ads-container horizontal" style="max-width: 468px; margin: 20px auto;">
        <div class="ad-label">Advertisement</div>
        <ins class="adsbygoogle"
             style="display:block; width: 468px; height: 60px;"
             data-ad-client="ca-pub-7354377815781712"
             data-ad-slot="7523911922"
             data-ad-format="auto"
             data-full-width-responsive="true"></ins>
        <script>
             (adsbygoogle = window.adsbygoogle || []).push({});
        </script>
    </div>

    <!-- Inter Ad Unit - 480x320 (3inter) -->
    <div class="ads-container horizontal" style="max-width: 480px; margin: 20px auto;">
        <div class="ad-label">Advertisement</div>
        <ins class="adsbygoogle"
             style="display:block; width: 480px; height: 320px;"
             data-ad-client="ca-pub-7354377815781712"
             data-ad-slot="6278278869"
             data-ad-format="auto"
             data-full-width-responsive="true"></ins>
        <script>
             (adsbygoogle = window.adsbygoogle || []).push({});
        </script>
    </div>

"@

$updatedCount = 0

foreach ($file in $gameFiles) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $originalContent = $content
    $updated = $false

    # Add AdSense script in head if not present
    if ($content -notmatch "pagead2\.googlesyndication\.com/pagead/js/adsbygoogle\.js") {
        $content = $content -replace '(<link rel="shortcut icon"[^>]*>)', "`$1`n$adSenseScript"
        $updated = $true
    }

    # Add first display ad after header if not present
    if ($content -notmatch 'data-ad-slot="1150075265"') {
        $content = $content -replace '(<div class="main container">)', "$firstDisplayAd`$1"
        $updated = $true
    }

    # Update ad_box with new AdSense ad
    if ($content -match '<div class="ad_box">' -and $content -notmatch 'data-ad-slot="2463156936"') {
        $content = $content -replace '<div class="ad_box">[\s\S]*?</div>\s*</div>', $newAdBox
        $updated = $true
    }

    # Add inter ads before lazyload script if not present
    if ($content -notmatch 'data-ad-slot="1685902515"') {
        $content = $content -replace '(<script src="[^"]*lazyload\.js"></script>)', "$interAds`$1"
        $updated = $true
    }

    if ($updated) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
        Write-Host "Updated: $($file.Name)" -ForegroundColor Green
        $updatedCount++
    }
}

Write-Host "`nTotal files updated: $updatedCount" -ForegroundColor Cyan

