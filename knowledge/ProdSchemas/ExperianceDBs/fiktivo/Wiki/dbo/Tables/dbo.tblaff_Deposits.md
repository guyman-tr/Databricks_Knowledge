# dbo.tblaff_Deposits

> Records customer deposit transactions for affiliate commission attribution, tracking deposit amounts, first-deposit flags, and the full marketing attribution chain.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | id (int IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (PK + OrigCID) |

---

## 1. Business Meaning

dbo.tblaff_Deposits stores customer deposit events linked to affiliate marketing attribution. Each row represents a single deposit made by a customer who was referred by an affiliate, capturing the deposit amount, whether it is a first-time deposit (FTD), the deposit type, and the complete marketing attribution chain (affiliate, sub-affiliate, banner, download parameter, provider, country).

First-time deposits (FTDs) are a critical affiliate commission trigger - many affiliate programs pay CPA (Cost Per Acquisition) commissions specifically on a customer's first deposit. This table enables the affiliate system to identify and track FTDs separately from subsequent deposits.

Data flows from the core trading platform's deposit processing system. When a customer makes a deposit, the system records it here with the affiliate attribution carried over from the customer's registration. The DailySummaryReport view aggregates FTD counts from this table for daily affiliate performance dashboards. The table contains ~789K records spanning 2007-2012, indicating this is historical/legacy deposit tracking data.

---

## 2. Business Logic

### 2.1 First-Time Deposit (FTD) Identification

**What**: Distinguishes a customer's first deposit (critical for CPA commissions) from subsequent deposits.

**Columns/Parameters Involved**: `isFirstDeposit`, `cid`, `amount`

**Rules**:
- `isFirstDeposit = 1`: This is the customer's first deposit - triggers CPA commission calculations
- `isFirstDeposit = 0`: Subsequent deposit - may trigger different commission types (e.g., revenue share)
- 12% of deposits (97K of 789K) are first deposits
- The DailySummaryReport view counts only `isFirstDeposit = 1` rows for the "FTDs" metric

### 2.2 Deposit Type Classification

**What**: Categorizes deposits by payment method or deposit channel.

**Columns/Parameters Involved**: `type`

**Rules**:
- Type 1: Most common (53%, 415K rows) - likely credit card or primary deposit method
- Type 2: Second most common (44%, 350K rows) - likely wire transfer or secondary method
- Type 3: 2.2% (17K rows) - alternative payment method
- Types 4-7: Rare (< 1% combined) - specialized deposit channels
- Values are integer enum-like but no explicit lookup table exists in SSDT

### 2.3 Marketing Attribution Chain

**What**: Every deposit carries the full referral chain from customer acquisition.

**Columns/Parameters Involved**: `affiliateID`, `subAffiliateID`, `banner`, `dl_param`, `ProviderID`, `OriginalProviderID`, `RealProviderID`, `CountryID`, `FunnelID`, `LabelID`

**Rules**:
- `affiliateID` links to the referring affiliate (tblaff_Affiliates.AffiliateID)
- `subAffiliateID` captures the tracking tag/URL from the affiliate link
- `OrigCID` preserves the original customer ID before any account consolidation
- Provider triple (`ProviderID`, `OriginalProviderID`, `RealProviderID`) tracks broker relationships through any migration

---

## 3. Data Overview

| id | date | cid | amount | isFirstDeposit | type | affiliateID | subAffiliateID | Meaning |
|---|---|---|---|---|---|---|---|---|
| 794558 | 2012-06-03 | 2172553 | 50 | 1 | 1 | 3 | (empty) | First-time deposit of $50 via primary method. Affiliate #3 (direct/house). Country 146. Player level 1 (new). |
| 794557 | 2012-06-03 | 2115136 | 100 | 0 | 1 | 35513 | (empty) | Subsequent $100 deposit. Affiliate #35513 with banner 1915. Returning customer (PlayerLevel 5). |
| 794556 | 2012-06-03 | 2146952 | 60.86 | 0 | 1 | 29962 | (empty) | Subsequent deposit via banner 3613 with download param tracking. Funnel 5, Country 102 (Italy). |
| 794555 | 2012-06-03 | 1863184 | 100 | 0 | 1 | 11 | Mail | Email marketing attributed deposit. Sub-affiliate "Mail" indicates email campaign source. |
| 794554 | 2012-06-03 | 2135202 | 206.12 | 0 | 1 | 19541 | http://www.google.com.au/url... | Google Australia organic search referral. Affiliate #19541 credited for this $206 subsequent deposit. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | id | int IDENTITY | NO | - | CODE-BACKED | Auto-incrementing primary key for each deposit record. NOT FOR REPLICATION ensures identity values are preserved during replication. |
| 2 | date | datetime | NO | - | CODE-BACKED | Timestamp when the deposit was made. Used by DailySummaryReport to aggregate daily FTD counts (cast to date via FLOOR). Range: 2007-09-06 to 2012-06-03. |
| 3 | cid | bigint | NO | - | VERIFIED | Customer ID who made the deposit. Maps to the eToro customer account. Different from OrigCID when customer accounts have been consolidated. |
| 4 | OrigCID | bigint | YES | - | CODE-BACKED | Original customer ID before any account migration or consolidation. Preserves the initial attribution even after CID changes. Indexed for lookups during late-binding attribution. |
| 5 | affiliateID | bigint | YES | - | VERIFIED | The affiliate who referred this customer. Maps to tblaff_Affiliates.AffiliateID. Used in DailySummaryReport for FTD grouping by affiliate. |
| 6 | subAffiliateID | nvarchar(1024) | YES | - | VERIFIED | Sub-affiliate tracking parameter. Contains referral URLs (Google search), campaign names ("Mail"), partner codes, or empty string for untracked. Same concept as ClosedPositionsTbl.SubSerialID. |
| 7 | amount | float | NO | - | CODE-BACKED | Deposit amount in the customer's account currency. Typical values: $50-$206 in sample. Float precision may cause rounding artifacts (e.g., 60.86000061035156). |
| 8 | isFirstDeposit | int | YES | - | VERIFIED | First-time deposit flag: 1 = customer's first deposit (FTD, triggers CPA commission), 0 = subsequent deposit. 12% of records are FTDs. DailySummaryReport filters on isFirstDeposit=1 for FTD metrics. Stored as int (not bit) for legacy reasons. |
| 9 | type | int | NO | - | CODE-BACKED | Deposit type/payment method classification. Values: 1 (53%), 2 (44%), 3 (2.2%), 4-7 (< 1%). No explicit lookup table found in SSDT - likely corresponds to payment methods (credit card, wire transfer, etc.). |
| 10 | banner | bigint | YES | - | NAME-INFERRED | Banner ID that drove the customer registration. References tblaff_Banners. 0 = no banner attribution. Non-zero = specific marketing creative. |
| 11 | dl_param | bigint | YES | - | NAME-INFERRED | Download parameter tracking ID. 0 = no download tracked. Non-zero values reference download tracking entries. |
| 12 | ProviderID | bigint | NO | 1 | NAME-INFERRED | Current provider/broker ID for this customer. Default 1 = primary provider. |
| 13 | OriginalProviderID | bigint | NO | 1 | NAME-INFERRED | Original provider ID at time of customer registration. Default 1. Preserved through provider migrations. |
| 14 | CountryID | bigint | NO | 0 | NAME-INFERRED | Country ID, likely by IP geolocation. Default 0 = unknown. References a country dictionary. |
| 15 | DID | bigint | YES | - | NAME-INFERRED | Device/download ID. NULL in most records - added later in the system's lifecycle. |
| 16 | FID | bigint | YES | - | NAME-INFERRED | File/flow ID. NULL in most records - added later in the system's lifecycle. |
| 17 | RealProviderID | bigint | NO | 1 | NAME-INFERRED | Actual provider ID resolving any white-labeling. Default 1. |
| 18 | FunnelID | int | YES | - | NAME-INFERRED | Marketing funnel identifier. Values 0-5 observed. Tracks which acquisition funnel the customer entered through. |
| 19 | LabelID | int | YES | - | NAME-INFERRED | Brand/label ID for multi-brand operations. Values 1 (primary) and 11 (alternate brand) observed. |
| 20 | PlayerLevelID | int | YES | - | NAME-INFERRED | Customer tier/level at time of deposit. Values 1 (new) and 5 (high) observed. Maps to a player level classification system. |
| 21 | ClubID | int | YES | - | NAME-INFERRED | Club/loyalty program ID. NULL in all sample data - likely a later addition not retroactively populated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| affiliateID | dbo.tblaff_Affiliates | Implicit | The referring affiliate for commission attribution |
| banner | dbo.tblaff_Banners | Implicit | Marketing banner creative that drove registration |
| CountryID | Dictionary.Country (via synonym) | Implicit | Customer's country by IP geolocation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.DailySummaryReport | FROM (FTD subquery) | View | Counts first-time deposits (isFirstDeposit=1) grouped by date and affiliateID for daily performance dashboards |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.DailySummaryReport | View | Reads FTD records (isFirstDeposit=1) for daily affiliate summary metrics |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_tblaff_Deposits_ | CLUSTERED PK | id ASC | - | - | Active (fill 90%, PAGE compression) |
| IDX_tblaff_Deposits_OrigCID | NC | OrigCID ASC | - | - | Active (PAGE compression) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_tblaff_Deposits_ProviderID | DEFAULT | 1 - Primary provider as default |
| DF_tblaff_Deposits_OriginalProviderID | DEFAULT | 1 - Primary provider as default |
| DF_tblaff_Deposits_CountryID | DEFAULT | 0 - Unknown country |
| DF_tblaff_Deposits_RealProviderID | DEFAULT | 1 - Primary provider as default |

---

## 8. Sample Queries

### 8.1 Count first-time deposits by affiliate
```sql
SELECT affiliateID, COUNT(*) AS FTDCount, SUM(amount) AS TotalFTDAmount
FROM dbo.tblaff_Deposits WITH (NOLOCK)
WHERE isFirstDeposit = 1
GROUP BY affiliateID
ORDER BY FTDCount DESC
```

### 8.2 Deposit volume by type
```sql
SELECT [type], COUNT(*) AS DepositCount, SUM(amount) AS TotalAmount,
       AVG(amount) AS AvgAmount
FROM dbo.tblaff_Deposits WITH (NOLOCK)
GROUP BY [type]
ORDER BY DepositCount DESC
```

### 8.3 Daily FTD trend with affiliate attribution
```sql
SELECT CAST([date] AS DATE) AS DepositDate, affiliateID,
       COUNT(*) AS FTDs, SUM(amount) AS FTDVolume
FROM dbo.tblaff_Deposits WITH (NOLOCK)
WHERE isFirstDeposit = 1
GROUP BY CAST([date] AS DATE), affiliateID
ORDER BY DepositDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 5.7/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 9 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_Deposits | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_Deposits.sql*
