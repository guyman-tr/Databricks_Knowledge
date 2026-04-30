# Dictionary.PlayerLevel

> Lookup table defining customer loyalty tiers based on trading activity (lot count) and deposit amount, determining cashout processing speed and VIP benefits.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PlayerLevelID (int, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.PlayerLevel defines the customer loyalty tier system. Customers are classified into tiers based on their cumulative trading activity (lot count) and total deposit amount. Higher tiers receive faster cashout processing and VIP benefits. This classification is central to the affiliate reporting system because customer quality (player level) directly impacts affiliate value metrics.

This table is the most heavily referenced Dictionary table in the fiktivo database. Over 14 transactional tables (deposits, bonuses, chargebacks, registrations, sales, copy traders, closed positions, etc.) and 30+ stored procedures reference PlayerLevelID. Every affiliate report aggregates or filters by player level to segment customer quality.

PlayerLevel is static reference data with dual threshold criteria. A customer must meet BOTH the lot count range AND the deposit range to qualify for a tier. The Sort column provides display ordering independent of the non-sequential PlayerLevelID values.

---

## 2. Business Logic

### 2.1 Customer Loyalty Tiers

**What**: Five tiers with dual qualification criteria (trading volume AND deposit amount) that determine service levels.

**Columns/Parameters Involved**: `PlayerLevelID`, `Name`, `CashoutPendingHours`, `FromSumLotCount`, `ToSumLotCount`, `FromSumDeposit`, `ToSumDeposit`, `Sort`

**Rules**:
- Bronze (ID=1): Entry tier - 1 to 3,000 lots, $0-$999 deposits, 120-hour cashout
- Silver (ID=5): Mid tier - 3,001 to 20,000 lots, $1,000-$4,999 deposits, 120-hour cashout
- Gold (ID=3): High tier - 20,001 to 100,000 lots, $5,000-$19,999 deposits, 72-hour cashout (faster processing)
- V.I.P (ID=2): Top tier - 100,001+ lots, $20,000+ deposits, 24-hour cashout (priority processing)
- Test (ID=4): QA/development tier - 0 lots, $0 deposits, 120-hour cashout, Sort=0 (hidden from production)
- Higher tiers receive progressively faster cashout processing (VIP=24hrs vs Bronze=120hrs)
- Non-sequential IDs (1,5,3,2,4) suggest tiers were added at different times; Sort column provides proper display order

**Diagram**:
```
Customer Tier Ladder:
  [Test (4)]    -- Sort 0 -- QA only, hidden
  [Bronze (1)]  -- Sort 1 -- 1-3K lots, $0-$999,     120hr cashout
  [Silver (5)]  -- Sort 2 -- 3K-20K lots, $1K-$5K,   120hr cashout
  [Gold (3)]    -- Sort 3 -- 20K-100K lots, $5K-$20K, 72hr cashout
  [V.I.P (2)]   -- Sort 4 -- 100K+ lots, $20K+,      24hr cashout
```

---

## 3. Data Overview

| PlayerLevelID | Name | CashoutPendingHours | LotRange | DepositRange | Meaning |
|---|---|---|---|---|---|
| 1 | Bronze | 120 | 1-3,000 | $0-$999 | Entry-level tier for new or low-activity customers. Standard 5-day cashout processing. Most customers start here |
| 5 | Silver | 120 | 3,001-20,000 | $1K-$5K | Mid-tier for moderately active customers. Same cashout speed as Bronze but tracked separately for reporting |
| 3 | Gold | 72 | 20,001-100,000 | $5K-$20K | High-value customers receiving priority 3-day cashout processing. Significant trading activity and deposits |
| 2 | V.I.P | 24 | 100,001+ | $20K+ | Top-tier customers with priority 1-day cashout processing. Highest value to affiliates and the platform |
| 4 | Test | 120 | 0 | $0 | QA/development tier used for test accounts. Sort=0 ensures it is hidden from production displays |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PlayerLevelID | int | NO | - | VERIFIED | Primary key identifying the customer loyalty tier. Values: 1=Bronze, 2=V.I.P, 3=Gold, 4=Test, 5=Silver. Non-sequential IDs - use Sort for display order. See [Player Level](../../_glossary.md#player-level) for full definitions. Most heavily referenced Dictionary column in the database. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable tier name. Used in all affiliate reporting displays and admin UIs. |
| 3 | CashoutPendingHours | int | YES | - | VERIFIED | Maximum hours allowed for cashout processing at this tier. Lower values = faster service. 24=VIP priority, 72=Gold, 120=Standard. Nullable but all current rows have values. |
| 4 | FromSumLotCount | int | NO | - | VERIFIED | Lower bound (inclusive) of cumulative lot count range for tier qualification. Combined with deposit range for dual-criteria qualification. |
| 5 | ToSumLotCount | int | NO | - | VERIFIED | Upper bound (inclusive) of cumulative lot count range for tier qualification. Value of 0 for Test tier means no trading required. |
| 6 | FromSumDeposit | int | NO | - | VERIFIED | Lower bound (inclusive) of cumulative deposit amount range (in USD) for tier qualification. Combined with lot count range. |
| 7 | ToSumDeposit | int | NO | - | VERIFIED | Upper bound (inclusive) of cumulative deposit amount range (in USD). V.I.P tier uses a high value to represent "unlimited". |
| 8 | Sort | int | NO | - | VERIFIED | Display order for presenting tiers in UIs and reports. 0=Test (hidden), 1=Bronze, 2=Silver, 3=Gold, 4=V.I.P. Independent of PlayerLevelID to allow non-sequential IDs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_Deposits | PlayerLevelID | Implicit FK | Customer deposit records tagged with player level |
| dbo.tblaff_Registrations | PlayerLevelID | Implicit FK | Customer registration records tagged with player level |
| dbo.tblaff_Sales | PlayerLevelID | Implicit FK | Sales records tagged with player level |
| dbo.tblaff_Bonuses | PlayerLevelID | Implicit FK | Bonus records tagged with player level |
| dbo.tblaff_CPA | PlayerLevelID | Implicit FK | CPA records tagged with player level |
| dbo.tblaff_Chargebacks | PlayerLevelID | Implicit FK | Chargeback records tagged with player level |
| dbo.tblaff_CopyTraders | PlayerLevelID | Implicit FK | Copy trader records tagged with player level |
| dbo.tblaff_Leads | PlayerLevelID | Implicit FK | Lead records tagged with player level |
| dbo.tblaff_FirstPositions | PlayerLevelID | Implicit FK | First position records tagged with player level |
| dbo.ClosedPositionsTbl | PlayerLevelID | Implicit FK | Closed positions tagged with player level |
| AffiliateCommission.RegistrationMetaData | PlayerLevelID | Implicit FK | Registration metadata includes player level |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Deposits | Table | PlayerLevelID column |
| dbo.tblaff_Registrations | Table | PlayerLevelID column |
| dbo.tblaff_Sales | Table | PlayerLevelID column |
| dbo.tblaff_Bonuses | Table | PlayerLevelID column |
| dbo.tblaff_CPA | Table | PlayerLevelID column |
| dbo.tblaff_Chargebacks | Table | PlayerLevelID column |
| dbo.ClosedPositionsTbl | Table | PlayerLevelID column |
| AffWizReports.GetDepositAggregatedData | Stored Procedure | READER - aggregates by player level |
| AffWizReports.GetRegistrationsData | Stored Procedure | READER - filters by player level |
| AffiliateCommission.InsertRegistrationMetaData | Stored Procedure | WRITER - stores player level with registration |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary.PlayerLevel | CLUSTERED PK | PlayerLevelID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all player levels in display order
```sql
SELECT PlayerLevelID, Name, CashoutPendingHours, FromSumLotCount, ToSumLotCount, FromSumDeposit, ToSumDeposit, Sort
FROM Dictionary.PlayerLevel WITH (NOLOCK)
ORDER BY Sort
```

### 8.2 Count deposits by player level
```sql
SELECT pl.Name, pl.Sort, COUNT(*) AS DepositCount
FROM dbo.tblaff_Deposits d WITH (NOLOCK)
JOIN Dictionary.PlayerLevel pl WITH (NOLOCK) ON d.PlayerLevelID = pl.PlayerLevelID
WHERE pl.PlayerLevelID != 4
GROUP BY pl.Name, pl.Sort
ORDER BY pl.Sort
```

### 8.3 Show tier qualification ranges
```sql
SELECT Name,
    CONCAT(FromSumLotCount, ' - ', ToSumLotCount) AS LotRange,
    CONCAT('$', FromSumDeposit, ' - $', ToSumDeposit) AS DepositRange,
    CONCAT(CashoutPendingHours, ' hours') AS CashoutTime
FROM Dictionary.PlayerLevel WITH (NOLOCK)
WHERE PlayerLevelID != 4
ORDER BY Sort
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 8 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 10 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PlayerLevel | Type: Table | Source: fiktivo/Dictionary/Tables/Dictionary.PlayerLevel.sql*
