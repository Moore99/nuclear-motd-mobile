# Check current privacy policy accessibility
$URL = "https://nuclear-motd.com/privacy"

Write-Host "=== Checking Privacy Policy Accessibility ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Testing URL: $URL" -ForegroundColor Yellow
Write-Host ""

try {
    $response = Invoke-WebRequest -Uri $URL -Method Get -UseBasicParsing -ErrorAction Stop
    
    Write-Host "Status Code: $($response.StatusCode)" -ForegroundColor Gray
    
    if ($response.StatusCode -eq 200) {
        Write-Host "✓ Page is accessible" -ForegroundColor Green
        
        # Check if it requires authentication
        if ($response.Content -match "login|sign in|authenticate" -or $response.Content -match "401|403") {
            Write-Host "✗ Page appears to require authentication" -ForegroundColor Red
            Write-Host ""
            Write-Host "PROBLEM: Privacy policy must be publicly accessible" -ForegroundColor Yellow
            Write-Host "Google Play will REJECT the app if login is required" -ForegroundColor Red
        } else {
            Write-Host "✓ Page appears to be public (no login required)" -ForegroundColor Green
        }
        
        # Check content length
        $contentLength = $response.Content.Length
        Write-Host "Content length: $contentLength characters" -ForegroundColor Gray
        
        if ($contentLength -lt 500) {
            Write-Host "⚠ Warning: Content seems very short for a privacy policy" -ForegroundColor Yellow
        }
    }
    
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "✗ Status Code: $statusCode" -ForegroundColor Red
    Write-Host ""
    
    if ($statusCode -eq 401 -or $statusCode -eq 403) {
        Write-Host "PROBLEM: Page requires authentication" -ForegroundColor Red
        Write-Host "Google Play requires PUBLIC access (no login)" -ForegroundColor Yellow
    } elseif ($statusCode -eq 404) {
        Write-Host "PROBLEM: Privacy policy page doesn't exist" -ForegroundColor Red
    } else {
        Write-Host "PROBLEM: Unable to access page" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "SOLUTION: Create a public privacy policy page" -ForegroundColor Yellow
    Write-Host "See: create_public_privacy_policy.txt" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "=== Check Complete ===" -ForegroundColor Cyan
