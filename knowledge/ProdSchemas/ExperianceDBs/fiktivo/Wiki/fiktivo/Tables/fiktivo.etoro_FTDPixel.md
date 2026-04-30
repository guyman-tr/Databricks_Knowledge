# fiktivo.etoro_FTDPixel

> Legacy log of First Time Deposit (FTD) conversion pixel firings, recording when the platform notified affiliate tracking systems that a referred customer made their first deposit.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Table |
| **Key Identifier** | FTD_ID (BIGINT IDENTITY, no declared PK) |
| **Partition** | No |
| **Indexes** | 0 (heap - no clustered index) |

---

## 1. Business Meaning

This table logs every First Time Deposit (FTD) conversion pixel event fired by the affiliate platform. When a customer referred by an affiliate makes their very first deposit, the platform fires a tracking pixel back to the affiliate's system to confirm the conversion. Each row captures the deposit details (amount, method, transaction ID), the customer and affiliate identifiers, and browser/cookie state at the time of firing.

FTD is a critical conversion milestone in affiliate marketing - it proves the affiliate successfully drove a paying customer, not just a registration. This table provides the audit trail for FTD pixel delivery, enabling dispute resolution if an affiliate claims a pixel was not received. See [Pixel Types](../../_glossary.md#pixel-types): ID 6 = Approved FTD Pixel, ID 8 = Eligible FTD Pixel.

The table contains 5,185 rows from 2008 - this is historical/legacy data from the early affiliate platform. The QueryString column reveals the raw tracking parameters passed during pixel firing (method, amount, affiliateid, transid, cid, origcid). No views or stored procedures currently reference this table, indicating the FTD pixel mechanism has been modernized in the current event-driven architecture (see [Event State](../../_glossary.md#event-state) states 49: "send FTDE Pixel").

---

## 2. Business Logic

### 2.1 FTD Conversion Attribution

**What**: Records the moment a first-time deposit is confirmed and the affiliate tracking pixel is fired.

**Columns/Parameters Involved**: `FTD_CID`, `FTD_OrigCID`, `FTD_AffiliateID`, `FTD_DepositAmount`, `FTD_TransactionId`

**Rules**:
- FTD_CID is the current customer ID; FTD_OrigCID is the original CID at registration time. They differ when a customer account was migrated or merged (e.g., CID=73340 but OrigCID=122260)
- When FTD_CID=0 and FTD_OrigCID=0, the pixel fired but the customer could not be resolved (test or error condition)
- FTD_AffiliateID may differ from the AffiliateID in the AffWizCookieContent - the cookie captures the original click attribution, while FTD_AffiliateID is the final attributed affiliate after any re-attribution rules

### 2.2 Cookie-Based Tracking Validation

**What**: Validates whether the affiliate tracking cookie was present and readable at deposit time.

**Columns/Parameters Involved**: `FTD_ReadCookie`, `FTD_AffWizCookie`, `AffWizCookieContent`

**Rules**:
- FTD_ReadCookie = 1: Browser cookies were accessible (critical for tracking)
- FTD_AffWizCookie = 1: The AffWiz-specific tracking cookie was found, meaning the visitor was previously tracked through an affiliate click
- AffWizCookieContent contains the full cookie: `AffiliateID={id}&ClickBannerID={id}&SubAffiliateID={subId}&ClickDateTime={datetime}`
- When FTD_AffWizCookie = 0, the deposit occurred without an affiliate cookie (direct/organic deposit to an affiliate-attributed customer)

**Diagram**:
```
Customer clicks affiliate banner
       |
       v
AffWiz cookie set: AffiliateID=6100, SubAffiliateID=yap6666, ClickDateTime=...
       |
       v
Customer registers and deposits $50 via CreditCard
       |
       v
[etoro_FTDPixel row created]
  FTD_AffiliateID = 705 (final attribution)
  AffWizCookieContent = "AffiliateID=6100&..." (original click cookie)
  QueryString = "method=CreditCard&amount=50&..."
       |
       v
Pixel fires to affiliate tracking system
```

---

## 3. Data Overview

| FTD_ID | FTD_CID | FTD_AffiliateID | FTD_DepositAmount | FTD_Method | Meaning |
|--------|---------|-----------------|-------------------|------------|---------|
| 5190 | 130294 | 3 | 50 | CreditCard | Standard FTD: customer 130294 deposited $50 via credit card, attributed to affiliate 3. Cookie readable, no AffWiz cookie (direct attribution). |
| 5189 | 73340 | 705 | 50 | CreditCard | Cookie mismatch case: FTD attributed to affiliate 705, but AffWiz cookie shows original click was from affiliate 6100 with SubAffiliateID=yap6666. Demonstrates re-attribution. |
| 5192 | 0 | 3 | 0 | (empty) | Unresolved pixel firing: CID=0 and amount=0 suggest a test or error condition. Browser="Netscape 4.0" indicates very early web era. |
| 5188 | 136679 | 3 | 50 | CreditCard | Normal FTD where OrigCID (30221) differs from CID (136679), indicating the customer was migrated between accounts. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FTD_ID | BIGINT IDENTITY | NO | auto-increment | CODE-BACKED | Unique identifier for each FTD pixel firing event. Auto-incremented. |
| 2 | FTD_Date | DATETIME | NO | getdate() | CODE-BACKED | Timestamp when the FTD pixel was fired. All sample data from 2008 era (July-October 2008). |
| 3 | FTD_CID | BIGINT | YES | - | CODE-BACKED | Current customer ID at time of deposit. Confirmed by QueryString pattern: `cid=130294`. Value 0 means customer could not be resolved. |
| 4 | FTD_OrigCID | BIGINT | YES | - | CODE-BACKED | Original customer ID at registration. Confirmed by QueryString: `origcid=122260`. Differs from FTD_CID when customer was migrated/merged between accounts. |
| 5 | FTD_AffiliateID | BIGINT | YES | - | CODE-BACKED | Affiliate credited for this FTD conversion. Confirmed by QueryString: `affiliateid=705`. May differ from the AffiliateID in AffWizCookieContent due to re-attribution rules. |
| 6 | FTD_TransactionId | VARCHAR(50) | YES | - | CODE-BACKED | Payment transaction reference code (hex format, e.g., '61A6EE'). Confirmed by QueryString: `transid=61A6EE`. Links to the deposit transaction in the payment system. |
| 7 | FTD_DepositAmount | FLOAT | YES | - | CODE-BACKED | First deposit amount in the customer's currency. Confirmed by QueryString: `amount=50`. Value 0 indicates a test or error pixel firing. |
| 8 | FTD_Method | VARCHAR(50) | YES | - | CODE-BACKED | Payment method used for the deposit (e.g., 'CreditCard'). Confirmed by QueryString: `method=CreditCard`. Empty string when method was not captured. |
| 9 | FTD_Browser | VARCHAR(200) | YES | - | CODE-BACKED | Browser identification at time of pixel firing (e.g., 'IE 7.0', 'IE 6.0', 'Netscape 4.0'). Used for debugging pixel delivery issues. |
| 10 | FTD_ReadCookie | BIT | YES | - | CODE-BACKED | Whether the browser's cookies were readable at pixel firing time. 1=cookies accessible (tracking functional), 0=cookies blocked (tracking may be impaired). |
| 11 | FTD_AffWizCookie | BIT | YES | - | CODE-BACKED | Whether the AffWiz affiliate tracking cookie was found in the browser. 1=cookie present (visitor was previously tracked via affiliate click), 0=no cookie (direct/organic path to deposit). |
| 12 | AffWizCookieContent | VARCHAR(100) | YES | - | CODE-BACKED | Full content of the AffWiz tracking cookie when present. Format: `AffiliateID={id}&ClickBannerID={id}&SubAffiliateID={subId}&ClickDateTime={datetime}`. Empty when FTD_AffWizCookie=0. Reveals the original click attribution chain. |
| 13 | QueryString | VARCHAR(300) | YES | - | CODE-BACKED | Complete URL query string from the pixel firing request. Format: `method={method}&amount={amount}&affiliateid={id}&transid={txn}&cid={cid}&origcid={origcid}`. Primary audit trail for the pixel parameters. |
| 14 | IP | NVARCHAR(16) | YES | - | CODE-BACKED | Customer's IP address at time of deposit/pixel firing. Used for geo-attribution and fraud detection. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FTD_CID | (external) Customer system | Implicit | Current customer ID who made the first deposit. |
| FTD_OrigCID | (external) Customer system | Implicit | Original customer ID at registration time. |
| FTD_AffiliateID | dbo.tblaff_Affiliates | Implicit | Affiliate credited with the FTD conversion. |

### 5.2 Referenced By (other objects point to this)

No objects currently reference this table. The FTD pixel mechanism has been modernized into the event-driven commission pipeline (see Dictionary.EventState, state 49: "send FTDE Pixel").

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

This table is a **heap** (no clustered index). No nonclustered indexes defined.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_etoro_FTDPixel_FTD_Date | DEFAULT | getdate() for [FTD_Date] - auto-timestamps pixel firing events |

---

## 8. Sample Queries

### 8.1 FTD pixels by affiliate with deposit totals
```sql
SELECT FTD_AffiliateID,
       COUNT(*) AS PixelCount,
       SUM(FTD_DepositAmount) AS TotalDeposits
FROM fiktivo.etoro_FTDPixel WITH (NOLOCK)
WHERE FTD_DepositAmount > 0
GROUP BY FTD_AffiliateID
ORDER BY TotalDeposits DESC
```

### 8.2 Cases where cookie attribution differs from final attribution
```sql
SELECT FTD_ID, FTD_AffiliateID, AffWizCookieContent, QueryString
FROM fiktivo.etoro_FTDPixel WITH (NOLOCK)
WHERE FTD_AffWizCookie = 1
  AND AffWizCookieContent NOT LIKE '%AffiliateID=' + CAST(FTD_AffiliateID AS VARCHAR) + '&%'
```

### 8.3 Customer migration cases (CID differs from OrigCID)
```sql
SELECT FTD_ID, FTD_CID, FTD_OrigCID, FTD_AffiliateID, FTD_DepositAmount
FROM fiktivo.etoro_FTDPixel WITH (NOLOCK)
WHERE FTD_CID <> FTD_OrigCID
  AND FTD_CID > 0
ORDER BY FTD_Date DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.etoro_FTDPixel | Type: Table | Source: fiktivo/fiktivo/Tables/fiktivo.etoro_FTDPixel.sql*
