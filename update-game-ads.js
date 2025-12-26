// Script to update all game pages with AdSense ads
// This is a Node.js script that can be run to update all game HTML files

const fs = require('fs');
const path = require('path');
const glob = require('glob');

// Pattern to find ad_box in game pages
const adBoxPattern = /<div class="ad_box">[\s\S]*?<\/div>/g;

// New ad box HTML with responsive AdSense
const newAdBox = `                    <div class="ad_box">
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
                    </div>`;

// AdSense script to add in head
const adSenseScript = `    <!-- Google AdSense -->
    <script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-7354377815781712"
     crossorigin="anonymous"></script>`;

// First display ad HTML
const firstDisplayAd = `    <!-- First Display Ad - After Header -->
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

`;

// Function to update a single game file
function updateGameFile(filePath) {
    try {
        let content = fs.readFileSync(filePath, 'utf8');
        let updated = false;

        // Add AdSense script in head if not present
        if (!content.includes('pagead2.googlesyndication.com/pagead/js/adsbygoogle.js')) {
            const headPattern = /(<link rel="shortcut icon"[^>]*>)/;
            if (headPattern.test(content)) {
                content = content.replace(headPattern, `$1\n${adSenseScript}`);
                updated = true;
            }
        }

        // Add first display ad after header if not present
        if (!content.includes('data-ad-slot="1150075265"')) {
            const mainContainerPattern = /(<div class="main container">)/;
            if (mainContainerPattern.test(content)) {
                content = content.replace(mainContainerPattern, `${firstDisplayAd}$1`);
                updated = true;
            }
        }

        // Update ad_box with new AdSense ad
        const oldAdBoxPattern = /<div class="ad_box">[\s\S]*?<\/div>\s*<\/div>/;
        if (oldAdBoxPattern.test(content) && !content.includes('data-ad-slot="2463156936"')) {
            content = content.replace(oldAdBoxPattern, newAdBox);
            updated = true;
        }

        if (updated) {
            fs.writeFileSync(filePath, content, 'utf8');
            console.log(`Updated: ${filePath}`);
            return true;
        }
        return false;
    } catch (error) {
        console.error(`Error updating ${filePath}:`, error.message);
        return false;
    }
}

// Main function
function main() {
    const gameDir = path.join(__dirname, 'game');
    const files = glob.sync('game/*.html');
    
    console.log(`Found ${files.length} game files`);
    let updatedCount = 0;

    files.forEach(file => {
        if (updateGameFile(file)) {
            updatedCount++;
        }
    });

    console.log(`\nUpdated ${updatedCount} files successfully.`);
}

// Run if executed directly
if (require.main === module) {
    main();
}

module.exports = { updateGameFile };

