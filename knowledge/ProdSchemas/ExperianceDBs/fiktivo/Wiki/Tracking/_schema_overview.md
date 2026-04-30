# Tracking Schema Overview

> Conversion tracking pixel retrieval procedures - returns tracking code snippets that fire to affiliate external tracking platforms when customers register or make their first deposit.

## Purpose

The Tracking schema provides the database-side API for the affiliate conversion pixel system. When a conversion event occurs (customer registration, approved FTD), the tracking service calls these procedures to retrieve the appropriate pixel code snippets and affiliate context, then fires those pixels to the affiliate's external tracking platform (e.g., HasOffers, CAKE, Impact).

## Architecture

```
Conversion Event (Registration or FTD Approval)
    |
    v
Tracking Service (AKS)
    |
    +-- Registration? --> EXEC GetClientRegistrationPixels(@AffiliateID)
    |                       -> Returns: pixel codes + marketing channel
    |
    +-- FTD Approved? --> EXEC GetApprovedFTDPixels(@CID)
    |                       -> Returns: affiliate context + pixel codes
    |
    +-- Cache Init?   --> EXEC GetAffiliatesPixels
    |                       -> Returns: ALL pixel configurations
    v
Fire Pixels to Affiliate Tracking Platforms
    -> Client-side: render JavaScript/HTML in customer's browser
    -> (Server-side postbacks handled by IsPost=1, not returned by these SPs)
```

## Object Summary

| Object | Type | Role |
|--------|------|------|
| GetAffiliatesPixels | SP | Bulk load: returns ALL pixel configurations for cache initialization |
| GetApprovedFTDPixels | SP | Event-driven: resolves CID -> affiliate, returns Approved FTD pixels (PixelTypeID=6) |
| GetClientRegistrationPixels | SP | Event-driven: returns Registration pixels (PixelTypeID=1) + marketing channel |

## Pixel Types (from Glossary)

| PixelTypeID | Name | Trigger Event |
|------------|------|--------------|
| 1 | Registration Pixel | Customer completes registration |
| 6 | Approved FTD Pixel | Customer's first deposit is approved |
| 8 | Eligible FTD Pixel | Customer's first deposit meets eligibility criteria |

## Key Design Patterns

- **Affiliate-specific + global pixels**: All event procedures return BOTH the affiliate's own pixels AND global pixels (AffiliateID IS NULL) that fire for every affiliate
- **Client-side only (IsPost=0)**: These procedures return only client-side pixels; server-side postbacks (IsPost=1) are handled separately
- **Dual result sets**: FTD and Registration procedures return affiliate context (AffiliateID, campaign, channel) alongside pixel codes for URL parameter substitution
- **NOLOCK on all reads**: Pixel configurations are reference data with eventual consistency acceptable

## Conversion Funnel

```
Customer clicks affiliate tracking link
    |
    v (registration)
GetClientRegistrationPixels fires Registration Pixel (PixelTypeID=1)
    |
    v (first deposit approved)
GetApprovedFTDPixels fires Approved FTD Pixel (PixelTypeID=6)
    |
    v (first deposit eligible)
Commission pipeline fires Eligible FTD Pixel (PixelTypeID=8) [separate system]
```

## JIRA References

- **PART-576**: Refactor deposit pixel to AKS
- **PART-867**: GetClientRegistrationPixels creation (Dec 2022, Moshe Ozar)
- **PART-2448**: CPA New Compensation Design (Dec 2023)
- **PART-3638**: Added AdditionalData from Registration view (Oct 2024)
