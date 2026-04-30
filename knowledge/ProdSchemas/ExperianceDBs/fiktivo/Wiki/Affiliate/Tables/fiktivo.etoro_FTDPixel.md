# fiktivo.etoro_FTDPixel

> Records First Time Deposit (FTD) conversion pixel events fired when customers make their first deposit, capturing affiliate attribution, deposit details, and browser/cookie state for affiliate commission tracking.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Table |
| **Key Identifier** | FTD_ID (BIGINT IDENTITY) |
| **Partition** | No |
| **Indexes** | 0 (heap - no clustered index) |

---

## 1. Business Meaning

etoro_FTDPixel records conversion tracking pixel events fired when a customer makes their first deposit (FTD) on the eToro platform. FTD is a critical milestone in the affiliate conversion funnel - it represents the point where a referred user becomes a paying customer, often triggering CPA (Cost Per Acquisition) commissions for the affiliate.

This table exists to capture the precise moment and context of a first deposit event as seen by the affiliate tracking pixel system. It records the deposit amount, payment method, the affiliate who referred the customer, and whether the AffiliateWizard tracking cookie was present. Without this table, the platform would lose the pixel-level evidence that an FTD occurred, which is essential for reconciling affiliate commissions with actual conversions.

Data enters this table when the FTD tracking pixel fires on the deposit confirmation page. The `QueryString` column captures the raw pixel parameters (e.g., `method=CreditCard&amount=50&affiliateid=3&transid=61A6EE&cid=130294`). Historical data ranges from 2007-2008 with 5,185 records, indicating this is a legacy tracking mechanism from the early affiliate system. No views or stored procedures in the fiktivo schema reference this table.

---

## 2. Business Logic

### 2.1 Affiliate Cookie Attribution

**What**: The system checks for the AffiliateWizard (AffWiz) tracking cookie at pixel fire time to determine the original affiliate attribution.

**Columns/Parameters Involved**: `FTD_ReadCookie`, `FTD_AffWizCookie`, `AffWizCookieContent`, `FTD_AffiliateID`

**Rules**:
- `FTD_ReadCookie` indicates whether the browser allowed cookie reading at pixel fire time
- `FTD_AffWizCookie` indicates whether the AffWiz affiliate tracking cookie was found
- When `FTD_AffWizCookie=true`, `AffWizCookieContent` contains the original click data: AffiliateID, ClickBannerID, SubAffiliateID, and ClickDateTime
- The `FTD_AffiliateID` in the pixel may differ from the AffWizCookieContent AffiliateID when attribution has been reassigned
- CID vs OrigCID: `FTD_CID` is the current customer ID; `FTD_OrigCID` is the original customer ID (may differ after account merges)

---

## 3. Data Overview

| FTD_ID | FTD_CID | FTD_AffiliateID | FTD_DepositAmount | FTD_Method | Meaning |
|---|---|---|---|---|---|
| 5190 | 130294 | 3 | 50 | CreditCard | A real FTD event: customer 130294 deposited $50 via credit card, attributed to affiliate 3 (house affiliate). Cookie was readable but no AffWiz cookie present - attribution came from direct pixel parameters. |
| 5189 | 73340 | 705 | 50 | CreditCard | An FTD with AffWiz cookie present: the cookie shows original click was from affiliate 6100 with sub-affiliate 'yap6666', but the pixel affiliate is 705 - demonstrating attribution reassignment between click and deposit. |
| 5192 | 0 | 3 | 0 | (empty) | A pixel fire with CID=0 and no deposit amount - likely a test fire or pixel loaded without proper parameters. Shows the system records even malformed pixel events. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FTD_ID | bigint (IDENTITY) | NO | Auto-increment | CODE-BACKED | Unique identifier for each FTD pixel event. Auto-generated sequence. |
| 2 | FTD_Date | datetime | NO | GETDATE() | CODE-BACKED | Timestamp when the FTD pixel fired. Defaults to current time. Records the exact moment the deposit confirmation page loaded the tracking pixel. |
| 3 | FTD_CID | bigint | YES | - | CODE-BACKED | Current Customer ID at the time of the first deposit. May differ from FTD_OrigCID after account merges. Value of 0 indicates the pixel fired without a valid customer context. |
| 4 | FTD_OrigCID | bigint | YES | - | CODE-BACKED | Original Customer ID - the customer ID at the time of initial registration. Preserved through account merges for attribution continuity. When equal to FTD_CID, no merge has occurred. |
| 5 | FTD_AffiliateID | bigint | YES | - | CODE-BACKED | Affiliate ID attributed with this FTD conversion. Passed as a pixel parameter. May differ from the AffWiz cookie affiliate if attribution was reassigned between click and deposit. |
| 6 | FTD_TransactionId | varchar(50) | YES | - | CODE-BACKED | Unique transaction identifier for the deposit (e.g., '61A6EE'). Links to the payment processing system for reconciliation. |
| 7 | FTD_DepositAmount | float | YES | - | CODE-BACKED | Deposit amount in the customer's currency. Value of 0 indicates test/invalid pixel fires. Typical values in sample data: 50. |
| 8 | FTD_Method | varchar(50) | YES | - | CODE-BACKED | Payment method used for the deposit (e.g., 'CreditCard'). Empty string when the pixel fired without proper parameters. |
| 9 | FTD_Browser | varchar(200) | YES | - | CODE-BACKED | Browser identification string at pixel fire time (e.g., 'IE 7.0', 'Netscape 4.0'). Used for debugging and analytics. |
| 10 | FTD_ReadCookie | bit | YES | - | CODE-BACKED | Whether the tracking pixel was able to read cookies from the browser. true = cookies accessible, false = cookies blocked. Essential for determining if affiliate attribution via cookie is reliable. |
| 11 | FTD_AffWizCookie | bit | YES | - | CODE-BACKED | Whether the AffiliateWizard tracking cookie was present at pixel fire time. true = cookie found (check AffWizCookieContent for original click data), false = no AffWiz cookie (attribution relies on pixel URL parameters only). |
| 12 | AffWizCookieContent | varchar(100) | YES | - | CODE-BACKED | Raw content of the AffWiz tracking cookie. Contains: AffiliateID, ClickBannerID, SubAffiliateID, and ClickDateTime from the original affiliate click. Format: 'AffiliateID=6100&ClickBannerID=0&SubAffiliateID=yap6666&ClickDateTime=7/4/2008 5:10:44 AM'. |
| 13 | QueryString | varchar(300) | YES | - | CODE-BACKED | Full query string from the pixel URL, capturing all parameters passed at fire time. Format: 'method=CreditCard&amount=50&affiliateid=3&transid=61A6EE&cid=130294&origcid=30221'. Primary source for deposit details and attribution. |
| 14 | IP | nvarchar(16) | YES | - | NAME-INFERRED | IP address of the customer at the time of deposit. Used for fraud detection and geographic attribution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FTD_AffiliateID | dbo.tblaff_Affiliates | Implicit | References the affiliate credited with the FTD conversion |
| FTD_CID | External customer table | Implicit | References the customer who made the first deposit |

### 5.2 Referenced By (other objects point to this)

No objects in the fiktivo schema reference this table.

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

This table has no indexes (heap table). The lack of a clustered index suggests it is primarily an append-only logging table with infrequent reads.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_etoro_FTDPixel_FTD_Date | DEFAULT | GETDATE() for FTD_Date - auto-timestamps pixel fire events |

---

## 8. Sample Queries

### 8.1 Recent FTD events with deposit details
```sql
SELECT TOP 10 FTD_ID, FTD_Date, FTD_CID, FTD_AffiliateID, FTD_DepositAmount, FTD_Method
FROM fiktivo.etoro_FTDPixel WITH (NOLOCK)
WHERE FTD_DepositAmount > 0
ORDER BY FTD_Date DESC
```

### 8.2 FTD count and total deposits by affiliate
```sql
SELECT FTD_AffiliateID, COUNT(*) AS FTDCount, SUM(FTD_DepositAmount) AS TotalDeposits
FROM fiktivo.etoro_FTDPixel WITH (NOLOCK)
WHERE FTD_CID > 0
GROUP BY FTD_AffiliateID
ORDER BY COUNT(*) DESC
```

### 8.3 Events with AffWiz cookie attribution mismatch
```sql
SELECT FTD_ID, FTD_AffiliateID, AffWizCookieContent, QueryString
FROM fiktivo.etoro_FTDPixel WITH (NOLOCK)
WHERE FTD_AffWizCookie = 1
  AND AffWizCookieContent NOT LIKE '%AffiliateID=' + CAST(FTD_AffiliateID AS VARCHAR) + '&%'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 9.3/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.etoro_FTDPixel | Type: Table | Source: fiktivo/fiktivo/Tables/fiktivo.etoro_FTDPixel.sql*
