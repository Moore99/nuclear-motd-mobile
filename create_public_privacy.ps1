# Create public /privacy route for Google Play Store
$SERVER = "root@149.248.60.234"

Write-Host "=== Creating Public Privacy Policy Route ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Creating server-side fix..." -ForegroundColor Yellow

ssh $SERVER @'
cd /root/nuclear-motd

# Create a simple public privacy route at /privacy
cat > /tmp/privacy_route.py << 'PYTHON'

# Add this to main.py or create as separate public route

from fastapi import APIRouter
from fastapi.responses import RedirectResponse

@app.get("/privacy")
def privacy_redirect():
    """Public privacy policy redirect for app stores"""
    return RedirectResponse(url="/privacy-policy", status_code=301)

PYTHON

# Add the route to main.py
echo ""
echo "Adding /privacy route to main.py..."

# Check if privacy-policy route is already included
if grep -q "privacy_policy" app/main.py; then
    echo "✓ Privacy policy router already imported"
else
    echo "Adding privacy policy import..."
    # Add import if not present
    sed -i '/from app.api import/a from app.api import privacy_policy' app/main.py
    # Add router if not present  
    sed -i '/app.include_router/a app.include_router(privacy_policy.router)' app/main.py
fi

# Add simple redirect at /privacy
python3 << 'ADDROUTE'
with open('/root/nuclear-motd/app/main.py', 'r') as f:
    content = f.read()

# Check if /privacy route exists
if '/privacy"' not in content or 'def privacy_redirect' not in content:
    # Find a good place to add it (after other routes)
    # Add before the if __name__ == "__main__" line
    
    redirect_code = '''
# Public privacy policy route for app stores (Google Play, etc.)
@app.get("/privacy")
def privacy_redirect():
    """Redirect /privacy to /privacy-policy for app store compliance"""
    from fastapi.responses import RedirectResponse
    return RedirectResponse(url="/privacy-policy", status_code=301)

'''
    
    # Insert before the final if __name__ block
    if 'if __name__ == "__main__":' in content:
        content = content.replace('if __name__ == "__main__":', redirect_code + 'if __name__ == "__main__":')
    else:
        # Just append at the end
        content += '\n' + redirect_code
    
    with open('/root/nuclear-motd/app/main.py', 'w') as f:
        f.write(content)
    
    print("✓ Added /privacy redirect route")
else:
    print("✓ /privacy route already exists")

ADDROUTE

echo ""
echo "Restarting service..."
systemctl restart nuclear-motd

echo ""
echo "Waiting for service to start..."
sleep 3

echo ""
echo "Testing routes..."
echo ""
echo "1. Testing /privacy-policy (main route):"
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:8000/privacy-policy

echo ""
echo "2. Testing /privacy (redirect for app stores):"
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:8000/privacy

echo ""
echo "3. Testing public accessibility (no auth required):"
curl -s http://localhost:8000/privacy-policy | grep -o "<title>.*</title>" | head -1

'@

Write-Host ""
Write-Host "=== Server Fix Complete ===" -ForegroundColor Green
Write-Host ""

Write-Host "Testing from external URL..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://nuclear-motd.com/privacy" -UseBasicParsing -ErrorAction Stop
    Write-Host "✓ https://nuclear-motd.com/privacy is accessible (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    $status = $_.Exception.Response.StatusCode.value__
    if ($status -eq 301 -or $status -eq 302) {
        Write-Host "✓ Redirects to privacy policy (Status: $status)" -ForegroundColor Green
    } else {
        Write-Host "✗ Not accessible (Status: $status)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Next Steps ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Verify the route works:" -ForegroundColor Yellow
Write-Host "   Open: https://nuclear-motd.com/privacy" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Use this URL in Play Store:" -ForegroundColor Yellow
Write-Host "   https://nuclear-motd.com/privacy" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. The page should:" -ForegroundColor Yellow
Write-Host "   ✓ Load without requiring login" -ForegroundColor Gray
Write-Host "   ✓ Show complete privacy policy" -ForegroundColor Gray
Write-Host "   ✓ Be accessible to Google's validators" -ForegroundColor Gray
Write-Host ""
