param (
    [Parameter(Mandatory=$true)]
    [string]$Message
)

Write-Host "Starting Deployment Process..."

# 1. Save Source Code
Write-Host "Saving source code to GitHub..."
git add .
git commit -m "$Message"
git push origin main

# 2. Build Web App
Write-Host "Building Flutter Web (Release)..."
flutter build web --release --base-href "/learmayor-crm/"

# 3. Deploy to GitHub Pages
Write-Host "Deploying to live website..."
flutter pub global run peanut
git push origin gh-pages --force

Write-Host "Deployment Complete! Your site will be updated in ~60 seconds."
Write-Host "Link: https://jafar1090.github.io/learmayor-crm/"
