<# 
=======================================================================================================================
FILE NAME    :    RE10_00_03_-_POWERSHELL_-_Generate-GitHub_And_Local_Links_-_Target-Root-Directory.ps1
FILE Type    :    Windows PowerShell Script
AUTHOR       :    Studio NoodlFjord
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
DESCRIPTION
    - This script generates GitHub raw URLs and local file paths for ALL files in a specified directory.
    - Users provide a directory path, and the script automatically constructs for each file:
        - A full local file path for the file's location on the Studio PC
            - Useful for quickly locating assets locally if needed.
        - A GitHub raw content URL
            - Useful for pulling assets from GitHub.
        - JSON-friendly versions of both paths
            - Useful for embedding in JSON configuration files.

PURPOSE SERVED
    - Ensures consistent use of links.
    - Most of my apps are designed to pull info from strictly defined locations in order to function.
    - Ensures a single source of truth is maintained.
    - Generates links for multiple files at once, saving time.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
LAUCH COMMAND
./RE10_00_03_-_POWERSHELL_-_Generate-GitHub_And_Local_Links_-_Target-Root-Directory.ps1
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
USAGE | LAUNCH & INITIAL USER INPUT
    - Run the script in PowerShell.
    - Enter a directory path in one of these formats:
        - - INPUT TYPE 01 | ABSOLUTE PATH WITHOUT QUOTES - - - 
            - Example Input: D:\RE10_--_Active-Live_--_Private-Master-Repo\RE10_01_-_CONFIG_-_Master-Active-Live-Link-Library
        - - INPUT TYPE 02 | ABSOLUTE PATH WITH QUOTES - - - 
            - Example Input: "D:\RE10_--_Active-Live_--_Private-Master-Repo\RE10_01_-_CONFIG_-_Master-Active-Live-Link-Library"
            - This is helpful if location dir is copied using Windows, (Shift + Right Click) Copy Path

    - The script will generate links for all files with these extensions:
        - .txt, .png, .pdf, .jpg, .json, .html, .css, .js

    - If you receive a permission error, use:
        Set-ExecutionPolicy RemoteSigned -Scope Process

- - - - - - - - - - - - - - - - - - - - 
USAGE | REPO SELECTION FEATURE
    - CLI prompts user to selecting desired Repo.
    - Two Repo Options Are Availible.
    - Both Repo options have an associated local and remote directory / link

    REPO OPTION 01 | MASTER PUBLIC FILES SERVING CDN
        - Accepted Prompts :  "Public" , "Public Repo" , "Pub" , "P" , "1" , "01" <--- Note These are NOT Case senstive
        LOCAL WINDOWS DIRECTORY
            Repo Name      :  RE20_--_Core_Repo_--_Public
            Description    :  The Local location, Files saved here and pushed to Github from here.
            Github Repo    :  D:\RE20_--_Core_Repo_--_Public\
            Permission     :  Login required onto Studio PC, Files manually pushed as needed using GitHub Desktop. 
        GITHUB PUBLIC REPO
            Repo Name      :  RE10_I_GitHub_I_Public_Repo
            Description    :  CDN Used for Noble Architecture Project for project specific app source code & hosting client files
            Github Repo    :  https://github.com/Adam-Noble-01/RE20_--_Core_Repo_--_Public
            Permission     :  Public Repo; NO KEYS REQUIRED for fetch requests served from this location 

    REPO OPTION 02 | MASTER PRIVATE APPLICATION SOURCE REPO
        - Accepted Prompts :  "Private" , "Private Repo" , "Priv" , "App" , "Personal" , "Dev" , "D" , "2" , "02"   <--- Note These are NOT Case senstive
        LOCAL WINDOWS DIRECTORY
            Repo Name      :  RE10_--_Active-Live_--_Private-Master-Repo
            Description    :  The Local location, Files saves core application files with access restricts to the public.
            Github Repo    :  D:\RE10_--_Active-Live_--_Private-Master-Repo\
            Permission     :  Login required onto Studio PC, Files manually pushed as needed using GitHub Desktop. 
        GITHUB PUBLIC REPO
            Repo Name      :  RE10_--_Active-Live_--_Private-Master-Repo
            Description    :  CDN Used for Noble Architecture Project for project specific app source code & hosting client files
            Github Repo    :  https://github.com/Adam-Noble-01/RE10_--_Active-Live_--_Private-Master-Repo
            Permission     :  Private Repo; AUTH KEY REQUIRED for fetch requests, personal apps will have token access for reading files.
            Token Notes    :  Key stored at the directory listed above as plaintext in a text file on Studio Windows PC.
            Read Acces Key :  C:\01_Script_Dependencies\00-keys\github_token_-_read-only-permission.txt

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
VERSION CONTROL LOG

TYPE     -  Major Release 
VERSION  -  1.0.0
DATE     -  26-Mar-2025
    - First Release
    - Based on RE10_00_02_-_POWERSHELL_-_Generate-GitHub_And_Local_Links.ps1
    - Modified to process all files in a directory instead of a single file
    - Added filtering by file extension (.txt, .png, .pdf, .jpg, .json, .html, .css, .js)
    - Improved output formatting for multiple files

=======================================================================================================================
#>

# ----------------------------------------------------------------
# CONFIGURE REPOSITORY PATH PREFIXES
# ----------------------------------------------------------------

# Define repository local path prefixes and GitHub raw URL prefixes
$privateLocalPathPrefix = "D:\RE10_--_Active-Live_--_Private-Master-Repo\"
$privateGithubRawPrefix = "https://raw.githubusercontent.com/Adam-Noble-01/RE10_--_Active-Live_--_Private-Master-Repo/main/"

$publicLocalPathPrefix = "D:\RE20_--_Core_Repo_--_Public\"
$publicGithubRawPrefix = "https://raw.githubusercontent.com/Adam-Noble-01/RE20_--_Core_Repo_--_Public/main/"

# Initialise variables
[string]$localPathPrefix = ""
[string]$githubRawPrefix = ""
[string]$githubRawSuffix = ""

# ----------------------------------------------------------------
# DEFINE ALLOWED FILE EXTENSIONS
# ----------------------------------------------------------------

$allowedExtensions = @(".txt", ".png", ".pdf", ".jpg", ".json", ".html", ".css", ".js")

# ----------------------------------------------------------------
# DEFINE TOKEN FOR PRIVATE REPO
# ----------------------------------------------------------------

$tokenPath = "C:\01_Script_Dependencies\00-keys\github_token_-_read-only-permission.txt"
if (Test-Path $tokenPath) {
    $githubToken = (Get-Content -Path $tokenPath -ErrorAction Stop).Trim()
} else {
    Write-Host "⚠️  GitHub token file not found at $tokenPath. Exiting." -ForegroundColor Red
    exit
}

# ----------------------------------------------------------------
# DEFINE UNICODE EMOJIS
# ----------------------------------------------------------------

$folderEmoji = [System.Text.Encoding]::UTF8.GetString([byte[]](0xF0,0x9F,0x93,0x82))  # 📂
$globeEmoji = [System.Text.Encoding]::UTF8.GetString([byte[]](0xF0,0x9F,0x8C,0x90))  # 🌐
$checkEmoji = [System.Text.Encoding]::UTF8.GetString([byte[]](0xE2,0x9C,0x85))       # ✅
$fileEmoji = [System.Text.Encoding]::UTF8.GetString([byte[]](0xF0,0x9F,0x93,0x84))   # 📄

# ----------------------------------------------------------------
# DISPLAY WELCOME MESSAGE & REPOSITORY SELECTION
# ----------------------------------------------------------------

Clear-Host
Write-Host "=======================================================================================" -ForegroundColor Cyan
Write-Host "  Studio NoodlFjord | Directory GitHub Path Generator Utility" -ForegroundColor Green
Write-Host "=======================================================================================" -ForegroundColor Cyan
Write-Host "  Select Repository Option:" -ForegroundColor Yellow
Write-Host "    - Public Repo Options: [Public, Public Repo, Pub, P, 1, 01]" -ForegroundColor Yellow
Write-Host "    - Private Repo Options: [Private, Private Repo, Priv, App, Personal, Dev, D, 2, 02]" -ForegroundColor Yellow
Write-Host "=======================================================================================" -ForegroundColor Cyan


# ----------------------------------------------------------------
# PROMPT FOR REPOSITORY SELECTION
# ----------------------------------------------------------------

$repoSelection = Read-Host "Enter repository option"
$repoSelectionTrimmed = $repoSelection.Trim().ToLower()

switch ($repoSelectionTrimmed) {
    "public" { 
        $localPathPrefix = $publicLocalPathPrefix
        $githubRawPrefix = $publicGithubRawPrefix
        $githubRawSuffix = "" 
    }
    "public repo" { 
        $localPathPrefix = $publicLocalPathPrefix
        $githubRawPrefix = $publicGithubRawPrefix
        $githubRawSuffix = "" 
    }
    "pub" { 
        $localPathPrefix = $publicLocalPathPrefix
        $githubRawPrefix = $publicGithubRawPrefix
        $githubRawSuffix = ""
    }
    "p" { $localPathPrefix = $publicLocalPathPrefix; $githubRawPrefix = $publicGithubRawPrefix; $githubRawSuffix = "" }
    "1" { $localPathPrefix = $publicLocalPathPrefix; $githubRawPrefix = $publicGithubRawPrefix; $githubRawSuffix = "" }
    "01" { $localPathPrefix = $publicLocalPathPrefix; $githubRawPrefix = $publicGithubRawPrefix; $githubRawSuffix = "" }

    # Private Repo with Token
    "private" { 
        $localPathPrefix = $privateLocalPathPrefix
        $githubRawPrefix = $privateGithubRawPrefix
        $githubRawSuffix = "?token=$githubToken"
    }
    "private repo" { $localPathPrefix = $privateLocalPathPrefix; $githubRawPrefix = $privateGithubRawPrefix; $githubRawSuffix = "?token=$githubToken" }
    "priv" { $localPathPrefix = $privateLocalPathPrefix; $githubRawPrefix = $privateGithubRawPrefix; $githubRawSuffix = "?token=$githubToken" }
    "app" { $localPathPrefix = $privateLocalPathPrefix; $githubRawPrefix = $privateGithubRawPrefix; $githubRawSuffix = "?token=$githubToken" }
    "personal" { $localPathPrefix = $privateLocalPathPrefix; $githubRawPrefix = $privateGithubRawPrefix; $githubRawSuffix = "?token=$githubToken" }
    "dev" { $localPathPrefix = $privateLocalPathPrefix; $githubRawPrefix = $privateGithubRawPrefix; $githubRawSuffix = "?token=$githubToken" }
    "d" { $localPathPrefix = $privateLocalPathPrefix; $githubRawPrefix = $privateGithubRawPrefix; $githubRawSuffix = "?token=$githubToken" }
    "2" { $localPathPrefix = $privateLocalPathPrefix; $githubRawPrefix = $privateGithubRawPrefix; $githubRawSuffix = "?token=$githubToken" }
    "02" { $localPathPrefix = $privateLocalPathPrefix; $githubRawPrefix = $privateGithubRawPrefix; $githubRawSuffix = "?token=$githubToken" }

    default {
        Write-Host "⚠️  Invalid repository selection. Exiting script." -ForegroundColor Red
        exit
    }
}

Write-Host "`n$checkEmoji  Repository selected. Local Path Prefix set to:" -ForegroundColor Green
Write-Host "    $localPathPrefix"
Write-Host "$checkEmoji  GitHub Raw URL Prefix set to:" -ForegroundColor Green
Write-Host "    $githubRawPrefix"
Write-Host "=======================================================================================" -ForegroundColor Cyan

# ----------------------------------------------------------------
# PRINT INSTRUCTIONS FOR DIRECTORY INPUT
# ----------------------------------------------------------------

Write-Host "`nEnter a directory path to scan for files:" -ForegroundColor Yellow
Write-Host "  - Example: D:\RE10_--_Active-Live_--_Private-Master-Repo\RE10_01_-_CONFIG_-_Master-Active-Live-Link-Library" -ForegroundColor Yellow
Write-Host "  - Will scan for files with extensions: .txt, .png, .pdf, .jpg, .json, .html, .css, .js" -ForegroundColor Yellow
Write-Host "=======================================================================================" -ForegroundColor Cyan

# ----------------------------------------------------------------
# PROMPT FOR DIRECTORY INPUT
# ----------------------------------------------------------------

$inputPath = Read-Host "Enter directory path"
Write-Host ""  # Break for readability

if ([string]::IsNullOrWhiteSpace($inputPath)) {
    Write-Host "`n⚠️  No input provided. Exiting script." -ForegroundColor Red
    exit
}

# Remove any enclosing quotes
$inputPath = $inputPath.Trim('"')

# Verify the directory exists
if (-not (Test-Path -Path $inputPath -PathType Container)) {
    Write-Host "`n⚠️  The provided path does not exist or is not a directory. Exiting script." -ForegroundColor Red
    exit
}

# Determine if the input is within one of the repositories
$isInPublicRepo = $inputPath.StartsWith($publicLocalPathPrefix)
$isInPrivateRepo = $inputPath.StartsWith($privateLocalPathPrefix)
$isInSelectedRepo = ($isInPublicRepo -and ($repoSelectionTrimmed -in @("public", "public repo", "pub", "p", "1", "01"))) -or 
                   ($isInPrivateRepo -and ($repoSelectionTrimmed -in @("private", "private repo", "priv", "app", "personal", "dev", "d", "2", "02")))

# Set base directory and handling method based on path location
if ($isInPublicRepo) {
    $baseDir = $publicLocalPathPrefix
    $isRelativePath = $true
} elseif ($isInPrivateRepo) {
    $baseDir = $privateLocalPathPrefix
    $isRelativePath = $true
} else {
    # Directory is outside of repositories - use selected repo for links
    $baseDir = ""
    $isRelativePath = $false
    
    Write-Host "`n⚠️  Note: The directory is outside the selected repository." -ForegroundColor Yellow
    Write-Host "    Links will still be generated using the selected repository as the base." -ForegroundColor Yellow
}

# ----------------------------------------------------------------
# FUNCTION TO GENERATE PATHS
# ----------------------------------------------------------------

function Generate-Paths {
    param (
        [string]$fullPath,
        [string]$fileName,
        [bool]$isRelativePath
    )

    if ($isRelativePath) {
        # For paths within repositories, use relative path
        $relativePath = $fullPath.Substring($baseDir.Length)
        
        return @{  
            "local_path"       = "$localPathPrefix$relativePath"  
            "raw_url"          = (($githubRawPrefix + $relativePath) -replace '\\', '/') + $githubRawSuffix
            "json_local_path"  = ($localPathPrefix + $relativePath) -replace '\\', '\\'
            "json_raw_url"     = ((($githubRawPrefix + $relativePath) -replace '\\', '/') + $githubRawSuffix) -replace '"', '\"'
        }
    } else {
        # For paths outside repositories, create links based on filename only
        return @{  
            "local_path"       = $fullPath
            "raw_url"          = (($githubRawPrefix + $fileName) -replace '\\', '/') + $githubRawSuffix
            "json_local_path"  = $fullPath -replace '\\', '\\'
            "json_raw_url"     = ((($githubRawPrefix + $fileName) -replace '\\', '/') + $githubRawSuffix) -replace '"', '\"'
        }
    }
}

# ----------------------------------------------------------------
# GET ALL FILES IN DIRECTORY WITH ALLOWED EXTENSIONS
# ----------------------------------------------------------------

$allFiles = Get-ChildItem -Path $inputPath -File -Recurse | Where-Object { $allowedExtensions -contains $_.Extension }

if ($allFiles.Count -eq 0) {
    Write-Host "`n⚠️  No files with the allowed extensions (.txt, .png, .pdf, .jpg, .json, .html, .css, .js) found in the specified directory. Exiting script." -ForegroundColor Red
    exit
}

# ----------------------------------------------------------------
# GENERATE PATHS FOR EACH FILE
# ----------------------------------------------------------------

$allResults = @()
$clipboardText = ""

foreach ($file in $allFiles) {
    # Generate paths for this file
    $result = Generate-Paths -fullPath $file.FullName -fileName $file.Name -isRelativePath $isRelativePath
    $allResults += $result
}

# ----------------------------------------------------------------
# FUNCTION TO GET FILE TYPE DESCRIPTION
# ----------------------------------------------------------------

function Get-FileTypeDescription {
    param (
        [string]$extension
    )
    
    switch ($extension.ToLower()) {
        ".txt"  { return "TEXT FILE" }
        ".png"  { return "PNG FILE" }
        ".pdf"  { return "PDF FILE" }
        ".jpg"  { return "JPG FILE" }
        ".json" { return "JSON FILE" }
        ".html" { return "HTML FILE" }
        ".css"  { return "CSS FILE" }
        ".js"   { return "JAVASCRIPT FILE" }
        default { return "FILE" }
    }
}

# ----------------------------------------------------------------
# DISPLAY RESULTS AND BUILD CLIPBOARD TEXT
# ----------------------------------------------------------------

Write-Host "`n=====================================================================================" -ForegroundColor Red
Write-Host "  Found $($allFiles.Count) files with the allowed extensions" -ForegroundColor Green
Write-Host "=====================================================================================" -ForegroundColor Red

$fileCounter = 1
foreach ($file in $allFiles) {
    # Get file type description
    $fileTypeDesc = Get-FileTypeDescription -extension $file.Extension
    $fileNameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    
    # Build separator line
    $separatorLine = "-----------------------------------------------------------"
    
    # Calculate relative path if applicable
    if ($isRelativePath) {
        $relativePath = $file.FullName.Substring($baseDir.Length)
        $rawUrl = (($githubRawPrefix + $relativePath) -replace '\\', '/') + $githubRawSuffix
    } else {
        $rawUrl = (($githubRawPrefix + $file.Name) -replace '\\', '/') + $githubRawSuffix
    }
    $jsonLocalPath = ($file.FullName) -replace '\\', '\\'
    $jsonRawUrl = $rawUrl -replace '"', '\"'
    
    # Add to clipboard text with improved formatting
    $clipboardText += "$separatorLine`n"
    $clipboardText += "$fileTypeDesc :  $fileNameWithoutExt`n"
    $clipboardText += "$separatorLine`n`n"
    $clipboardText += "FILE NAME`n"
    $clipboardText += "$($file.Name)`n`n"
    $clipboardText += "LOCAL PATH`n"
    $clipboardText += "$($file.FullName)`n`n"
    $clipboardText += "LOCAL PATH - - (JSON VERSION)`n"
    $clipboardText += "$jsonLocalPath`n`n"
    $clipboardText += "GITHUB RAW URL`n"
    $clipboardText += "$rawUrl`n`n"
    $clipboardText += "$separatorLine`n`n"
    
    # Display file information with improved formatting
    Write-Host "`n$separatorLine" -ForegroundColor Yellow
    Write-Host "$fileTypeDesc :  $fileNameWithoutExt" -ForegroundColor Cyan
    Write-Host "$separatorLine" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "FILE NAME" -ForegroundColor DarkCyan
    Write-Host "$($file.Name)" -ForegroundColor White
    Write-Host ""
    Write-Host "LOCAL PATH" -ForegroundColor Green
    Write-Host "$($file.FullName)" -ForegroundColor White
    Write-Host ""
    Write-Host "LOCAL PATH - - (JSON VERSION)" -ForegroundColor Magenta
    Write-Host "$jsonLocalPath" -ForegroundColor White
    Write-Host ""
    Write-Host "GITHUB RAW URL" -ForegroundColor Blue
    Write-Host "$rawUrl" -ForegroundColor White
    Write-Host ""
    Write-Host "$separatorLine" -ForegroundColor Yellow
    
    $fileCounter++
}

Write-Host "`n=====================================================================================" -ForegroundColor Red

# ----------------------------------------------------------------
# COPY RESULTS TO CLIPBOARD
# ----------------------------------------------------------------

try {
    $clipboardText | Set-Clipboard
    Write-Host "`n$checkEmoji  All links copied to clipboard with improved formatting." -ForegroundColor Green
} catch {
    Write-Host "`n⚠️  Unable to copy to clipboard. Please copy manually." -ForegroundColor Red
}

Write-Host "`nFile extensions scanned: .txt, .png, .pdf, .jpg, .json, .html, .css, .js" -ForegroundColor Yellow
Write-Host "`n=====================================================================================" -ForegroundColor Red

