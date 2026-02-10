# Debug content submission issue
$SERVER = "root@149.248.60.234"

Write-Host "=== Debugging Content Submission ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Check recent content submissions in database:" -ForegroundColor Yellow
ssh $SERVER @'
cd /root/nuclear-motd
python3 << 'PYTHON'
import sys
sys.path.insert(0, "/root/nuclear-motd")
from app.database import SessionLocal
from app.models.message import Message
from app.models.user import User

db = SessionLocal()

# Find recent user contributions
recent_submissions = db.query(Message).filter(
    Message.message_type == "user_contribution"
).order_by(Message.created_at.desc()).limit(5).all()

print(f"\nFound {len(recent_submissions)} user contributions:")
for msg in recent_submissions:
    user = db.query(User).filter(User.id == msg.created_by).first()
    print(f"\n  ID: {msg.id}")
    print(f"  Title: {msg.title}")
    print(f"  Created by: {user.email if user else 'Unknown'}")
    print(f"  Created at: {msg.created_at}")
    print(f"  Active: {msg.is_active}")
    print(f"  Type: {msg.message_type}")

# Also check all inactive messages
inactive = db.query(Message).filter(Message.is_active == False).order_by(Message.created_at.desc()).limit(5).all()
print(f"\n\nAll inactive messages (last 5):")
for msg in inactive:
    user = db.query(User).filter(User.id == msg.created_by).first()
    print(f"\n  ID: {msg.id}")
    print(f"  Title: {msg.title}")
    print(f"  Created by: {user.email if user else 'Unknown'}")
    print(f"  Type: {msg.message_type}")
    print(f"  Active: {msg.is_active}")

db.close()
PYTHON
'@

Write-Host ""
Write-Host "2. Check admin review endpoint:" -ForegroundColor Yellow
ssh $SERVER "cd /root/nuclear-motd && grep -r 'unified.*review' app/api/ | head -5"

Write-Host ""
Write-Host "3. Check recent API logs for content submission:" -ForegroundColor Yellow
ssh $SERVER "journalctl -u nuclear-motd --since '1 hour ago' | grep -i 'content.*submit' | tail -10"

Write-Host ""
Write-Host "Done!" -ForegroundColor Cyan
