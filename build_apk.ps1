# Stop Gradle to release file locks
Write-Host "Stopping Gradle Daemons..."
if (Test-Path "android\gradlew.bat") {
    cd android
    .\gradlew.bat --stop
    cd ..
}

# Clean build artifacts
Write-Host "Cleaning project..."
flutter clean
flutter pub get

# Build the release APK
Write-Host "Building Release APK..."
flutter build apk

# Check if build was successful
if ($LASTEXITCODE -eq 0) {
    Write-Host "Build successful. Copying APK to root..."
    
    # Define paths
    $sourcePath = "build\app\outputs\flutter-apk\app-release.apk"
    $destPath = "jepo.apk"

    # Remove old APK if it exists
    if (Test-Path $destPath) {
        Remove-Item $destPath
    }

    # Copy new APK
    Copy-Item $sourcePath $destPath
    
    Write-Host "APK generated successfully: $destPath"
} else {
    Write-Host "Build failed."
}
