---
description: Build the active project, commit changes, push to origin, and release it to GitHub under the user's identity.
---
Before executing any steps, look up and read credentials from the universal sensitive storage at `C:\Users\akhla\.gemini\.agents\sensitive.md` if available.
If a credential is not defined in `sensitive.md`, check the resolved fallback profiles below.

1. **Parse Credentials & Actions**:
   Inspect the user's prompt or instruction to determine the selected credential and whether repository creation is requested:
   - **`akhlak` profile**:
     - Username: `{{AKHLAK_USERNAME}}`
     - Token/Password: `{{AKHLAK_TOKEN}}`
     - Email: `{{AKHLAK_EMAIL}}`
   - **`ifrit` profile** (Default if not specified):
     - Username: `{{IFRIT_USERNAME}}`
     - Token/Password: `{{IFRIT_TOKEN}}`
     - Email: `{{IFRIT_EMAIL}}`
   - **`create` command**:
     - If "create" is in the command, create a new GitHub repository for this project first.

2. **Configure Git & GitHub CLI Credentials**:
   Run the following commands using the resolved profile credentials:
   ```powershell
   git config user.name "<USERNAME>"
   git config user.email "<EMAIL>"
   $env:GITHUB_TOKEN="<TOKEN>"
   echo "<TOKEN>" | gh auth login --with-token
   ```

3. **Repository Creation (Optional)**:
   If "create" is requested:
   - Verify if Git is initialized. If not, run `git init` and commit initial files.
   - Create the repository via GitHub CLI:
     ```powershell
     $repoName = (Split-Path -Leaf $pwd)
     gh repo create $repoName --public --source=. --remote=origin --push
     ```
   - If the remote origin already exists or needs updating:
     ```powershell
     git remote set-url origin "https://<USERNAME>:<TOKEN>@github.com/<USERNAME>/$repoName.git"
     ```

4. **Dynamically Detect Project Type, Auto-Increment Version & Build**:
   - If `pubspec.yaml` exists, parse and increment the version code and build number before building:
     ```powershell
     # Determine release type (minor: 0.0.1, major: 0.1.0, big/jump: 1.0.0)
     $releaseType = "minor"
     if ($env:RELEASE_TYPE) {
         $releaseType = $env:RELEASE_TYPE.ToLower()
     } elseif ($args -contains "major" -or $args -contains "0.1.0") {
         $releaseType = "major"
      } elseif ($args -contains "big" -or $args -contains "jump" -or $args -contains "1.0.0" -or $args -contains "big-release") {
         $releaseType = "big"
     }

     $pubspec = Get-Content pubspec.yaml -Raw
     if ($pubspec -match 'name:\s*([^\r\n]+)') {
         $rawName = $Matches[1].Trim()
         $appName = $rawName.Substring(0,1).ToUpper() + $rawName.Substring(1)
         if ($rawName -eq "rgify") { $appName = "RedGify" }
     } else {
         $appName = "App"
     }

     if ($pubspec -match 'version:\s*([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+)') {
         $major = [int]$Matches[1]
         $minor = [int]$Matches[2]
         $patch = [int]$Matches[3]
         $build = [int]$Matches[4]
         $oldVer = "$major.$minor.$patch"

         if ($releaseType -eq "big") {
             $major += 1
             $minor = 0
             $patch = 0
         } elseif ($releaseType -eq "major") {
             $minor += 1
             $patch = 0
         } else {
             $patch += 1
         }
         $build += 1

         $newVer = "$major.$minor.$patch"
         $newFullVer = "$newVer+$build"

         # Update pubspec.yaml
         $pubspec = $pubspec -replace 'version:\s*[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+', "version: $newFullVer"
         Set-Content pubspec.yaml -Value $pubspec -NoNewline

         # Recursively find and replace old version references in all source files
         $dartFiles = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse
         foreach ($file in $dartFiles) {
             $fileContent = Get-Content $file.FullName -Raw
             if ($fileContent.Contains($oldVer)) {
                 $fileContent = $fileContent.Replace($oldVer, $newVer)
                 Set-Content $file.FullName -Value $fileContent -NoNewline
             }
         }
         Write-Host "Version bumped to $newVer ($releaseType) and build number to $build"
     }

     flutter build apk --split-per-abi
     ```
   - If `package.json` exists, run `npm run build` or appropriate build command.
   - If `gradlew` or Gradle project files exist, run `.\gradlew.bat assembleRelease` or `.\gradlew.bat assembleDebug`.

5. **Commit & Push to Main/Active Branch**:
   Stage changes and commit:
   ```powershell
   $branch = (git branch --show-current).Trim()
   if ([string]::IsNullOrEmpty($branch)) { $branch = "main" }
   git add .
   git commit -m "Auto-release update: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
   git push origin $branch
   ```

6. **Create a GitHub Release**:
   - Determine release tag and description, rename split ABI APKs, and attach to the release:
     ```powershell
     $pubspec = Get-Content pubspec.yaml -Raw
     if ($pubspec -match 'name:\s*([^\r\n]+)') {
         $rawName = $Matches[1].Trim()
         $appName = $rawName.Substring(0,1).ToUpper() + $rawName.Substring(1)
         if ($rawName -eq "rgify") { $appName = "RedGify" }
     } else {
         $appName = "App"
     }

     if ($pubspec -match 'version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+[0-9]+') {
         $newVer = $Matches[1]
     } else {
         $newVer = "1.0.0"
     }
     $tag = "${appName}_v${newVer}"

     $apkDir = "build/app/outputs/flutter-apk"
     $releaseApks = @()
     if (Test-Path $apkDir) {
         $apks = Get-ChildItem -Path $apkDir -Filter "app-*-release.apk"
         foreach ($apk in $apks) {
             $abi = $apk.Name -replace 'app-|-release\.apk', ''
             $newName = "${appName}_v${newVer}_${abi}-release.apk"
             $newPath = Join-Path $apkDir $newName
             Rename-Item -Path $apk.FullName -NewName $newName -Force
             $releaseApks += $newPath
         }
     }

     if ($releaseApks.Count -gt 0) {
         gh release create $tag $releaseApks --title $tag --notes "Release version $tag"
     } else {
         $hash = (git rev-parse HEAD).SubString(0, 7)
         gh release create "v$hash" --title "v$hash" --notes "Release version v$hash"
     }
     ```

7. **Output Status**:
   Report a concise summary of the successful deployment and release link to the user.
