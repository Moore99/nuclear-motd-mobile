# Getting Sponsors for Nuclear MOTD Mobile App

## Overview

Your Nuclear MOTD app supports two monetization channels:
1. **Google AdMob** - Programmatic ads (banner, native)
2. **Direct Sponsors** - Your own sponsorship system

## 1. Google AdMob Setup

### Getting Started
1. Sign up at https://admob.google.com
2. Create an app for Android and iOS
3. Create ad units (Banner, Native)
4. Update `lib/core/config/app_config.dart` with your IDs

### Ad Placement Strategy (Unobtrusive)
- **Banner**: Bottom of home screen only
- **Native**: In message list after 5 items
- No interstitials or pop-ups (keeps UX clean)

### Expected Revenue
- CPM ranges from $0.50 - $3.00 for specialized B2B apps
- With 1,000 DAU: ~$50-150/month
- Scale with user growth

## 2. Direct Sponsors (Higher Revenue Potential)

### Tier Structure

| Tier | Monthly Cost | Benefits |
|------|--------------|----------|
| Bronze | $100-250 | Logo rotation, basic analytics |
| Silver | $250-500 | Priority placement, monthly report |
| Gold | $500-1,000 | Message sponsorship, premium placement |
| Platinum | $1,000-2,500 | Topic sponsorship, featured placement, dedicated support |

### Where to Find Sponsors

#### Nuclear Industry Companies
1. **Equipment Manufacturers**
   - Westinghouse
   - GE Hitachi Nuclear
   - Framatome
   - BWX Technologies

2. **Safety & Training Companies**
   - Nuclear Energy Institute (NEI)
   - INPO (Institute of Nuclear Power Operations)
   - Training solution providers

3. **Consulting Firms**
   - Accenture Nuclear Practice
   - Deloitte Energy & Resources
   - McKinsey Energy

4. **Software & Technology**
   - Nuclear plant software vendors
   - Maintenance management systems
   - Radiation monitoring equipment

5. **Industry Associations**
   - Nuclear Energy Institute
   - Canadian Nuclear Association
   - World Nuclear Association

### Outreach Template

```
Subject: Sponsorship Opportunity - Nuclear MOTD Mobile App

Dear [Company Name] Marketing Team,

I'm reaching out regarding a targeted advertising opportunity 
for the Nuclear MOTD mobile application - a daily content 
platform serving nuclear industry professionals.

Our Audience:
- [X] registered nuclear professionals
- Daily engagement with industry-specific content
- Decision-makers at nuclear facilities

Sponsorship Benefits:
- Direct access to your target market
- Impression and click analytics
- Tier-based visibility (Bronze through Platinum)
- Mobile app banner and in-content placement

Would you be interested in a brief call to discuss how we 
can help [Company Name] reach nuclear industry professionals?

Best regards,
[Your Name]
```

### Tracking & Reporting

Your backend already supports:
- Impression tracking: `GET /track/sponsor/impression/{id}`
- Click tracking: `GET /track/sponsor/click/{id}`
- Admin analytics dashboard

Provide monthly reports to sponsors:
- Total impressions
- Click-through rate (CTR)
- Audience demographics (company, country)
- Engagement metrics

## 3. Hybrid Approach (Recommended)

For best results:
1. Use AdMob for baseline revenue
2. Sell direct sponsorships to industry companies
3. Offer ad-free experience to premium sponsors' employees

### Premium Placement Rotation

In `sponsor_banner.dart`, sponsors rotate based on tier weight:
- Platinum sponsors: 4x more likely to appear
- Gold: 3x
- Silver: 2x
- Bronze: 1x

## 4. Legal Considerations

- Include "Sponsored" label (already in sponsor_banner.dart)
- Follow AdMob policies strictly
- Have sponsor agreements in writing
- Include advertising disclosure in Terms of Service

## 5. Implementation Checklist

### For AdMob:
- [ ] Create AdMob account
- [ ] Add Android app to AdMob
- [ ] Add iOS app to AdMob
- [ ] Create Banner ad unit
- [ ] Create Native ad unit
- [ ] Update app_config.dart with IDs
- [ ] Test with test IDs before production
- [ ] Submit app for review

### For Direct Sponsors:
- [ ] Create sponsor management admin UI (exists in /admin/sponsors)
- [ ] Prepare media kit/rate card
- [ ] Set up sponsor tracking analytics
- [ ] Create monthly report template
- [ ] Draft sponsor agreement contract
- [ ] Begin outreach to potential sponsors

## 6. Revenue Projections

### Conservative Estimate (Year 1)
| Source | Monthly Revenue |
|--------|-----------------|
| AdMob (1,000 DAU) | $75 |
| 2 Bronze sponsors | $400 |
| 1 Silver sponsor | $400 |
| **Total** | **$875/month** |

### Growth Estimate (Year 2)
| Source | Monthly Revenue |
|--------|-----------------|
| AdMob (5,000 DAU) | $400 |
| 3 Bronze sponsors | $600 |
| 2 Silver sponsors | $800 |
| 1 Gold sponsor | $800 |
| **Total** | **$2,600/month** |

## Questions?

The sponsor system is already integrated into your backend. Focus on:
1. Building user base (more users = more sponsor interest)
2. Outreach to nuclear industry marketing departments
3. Providing excellent analytics/reporting to sponsors
