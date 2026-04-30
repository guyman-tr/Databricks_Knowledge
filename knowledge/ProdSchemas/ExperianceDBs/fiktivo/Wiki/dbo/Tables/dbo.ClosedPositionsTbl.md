# dbo.ClosedPositionsTbl

> Stores aggregated closed trading position records used by the affiliate commission processing pipeline to calculate and distribute affiliate payouts.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | ClosedPositionsID (int, PK CLUSTERED) |
| **Partition** | No (soft-partitioned via computed PartitionCol = CID % 10) |
| **Indexes** | 7 active |

---

## 1. Business Meaning

dbo.ClosedPositionsTbl holds closed trading position records that feed into the affiliate commission processing pipeline. Each row represents a single closed position from the eToro trading platform, capturing the financial outcome (commission, net profit, lots traded) alongside the marketing attribution chain (affiliate, sub-affiliate, banner, download source, country) that originated the customer.

Without this table, the affiliate system would have no source data for calculating commissions on closed positions. It is the bridge between the core trading platform's position lifecycle and the affiliate commission engine - positions are written here after closing, then processed by the QuesService workers to generate commission records in the various `_Commissions` tables.

Data flows into this table from the core trading platform when positions close. The `FinishedUpdating` flag is set to 1 once all position data is complete. QuesService workers then read unprocessed positions (via the `dbo.ClosedPositions` view) filtered by `PartitionCol` for 10-way parallelism, calculate commissions, and set `FinishedProcessing` to 1. The `dbo.SSRS_AffWiz_ClosedPositions` procedure monitors the processing backlog for operational reporting.

---

## 2. Business Logic

### 2.1 Two-Phase Processing Pipeline

**What**: Positions go through a two-step processing pipeline tracked by boolean flags.

**Columns/Parameters Involved**: `FinishedUpdating`, `FinishedProcessing`

**Rules**:
- `FinishedUpdating = 0, FinishedProcessing = 0`: Position data is still being populated from the trading platform - not ready for processing
- `FinishedUpdating = 1, FinishedProcessing = 0`: Position data is complete but commissions have not yet been calculated - this is the "ready for processing" state (96% of rows in the table are in this state, indicating test/demo data)
- `FinishedUpdating = 1, FinishedProcessing = 1`: Commission processing complete - terminal state
- `FinishedUpdating = 0, FinishedProcessing = 1`: Invalid state (should never occur - cannot process before data is complete)

**Diagram**:
```
[Not Ready]              [Ready for Processing]           [Fully Processed]
FinishedUpdating=0  -->  FinishedUpdating=1           --> FinishedUpdating=1
FinishedProcessing=0     FinishedProcessing=0              FinishedProcessing=1
                         (filtered indexes target this)
```

### 2.2 Soft Partitioning for Parallel Processing

**What**: The table uses CID-based modular arithmetic to distribute rows across 10 processing workers.

**Columns/Parameters Involved**: `CID`, `PartitionCol`

**Rules**:
- `PartitionCol` is computed as `CID % 10`, producing values 0-9
- The `dbo.ClosedPositions` view routes rows to QuesService-0 through QuesService-9 based on `PartitionCol` matching the app_name()
- Each QuesService instance processes only its partition, enabling lock-free parallel commission calculation
- Non-QuesService connections (not from `lon-affwiz-srv*`) see all rows

**Diagram**:
```
ClosedPositionsTbl (all rows)
    |
    v
dbo.ClosedPositions (view - partition filter)
    |
    +-- QuesService-0 sees PartitionCol=0
    +-- QuesService-1 sees PartitionCol=1
    +-- ...
    +-- QuesService-9 sees PartitionCol=9
    +-- Other apps see ALL rows
```

### 2.3 Marketing Attribution Chain

**What**: Each closed position carries the full marketing attribution chain from customer acquisition.

**Columns/Parameters Involved**: `SerialID`, `SubSerialID`, `BannerID`, `DownloadID`, `OriginalProviderID`, `ProviderID`, `RealProviderID`, `FunnelID`, `LabelID`, `CountryIDByIP`

**Rules**:
- `SerialID` is the affiliate ID that referred this customer (maps to tblaff_Affiliates.AffiliateID)
- `SubSerialID` is the sub-affiliate tracking parameter - contains marketing URLs, campaign tags, or partner identifiers (e.g., Google search referral URLs, "SITcomp6-AVAFX", "EN-Profile", "Mail")
- `OriginalCustomerID` / `OriginalProviderID` preserve the original attribution before any customer migration
- The `UpdateSubAffiliateID` procedure can retroactively update `SerialID` and `SubSerialID` for late-binding attribution (e.g., mobile registrations where affiliate is unknown at registration time)

---

## 3. Data Overview

| ClosedPositionsID | Occurred | CID | Commission | NetProfit | Lots | SerialID | SubSerialID | FinishedProcessing | Meaning |
|---|---|---|---|---|---|---|---|---|---|
| 8473665 | 2013-01-20 | 212515 | 120 | -40 | 4 | 2 | www.google.co.il/search?q=etoro... | true | Fully processed position: customer found eToro via Israeli Google search, lost money but generated $120 commission. Affiliate #2 credited. |
| 8473667 | 2013-01-20 | 792672 | 755 | 214.93 | 10 | 15722 | NULL | true | Rare profitable position ($215 profit) with high commission ($755). No sub-affiliate tracking - direct affiliate referral. PlayerLevel 3. |
| 8473668 | 2013-01-20 | 944583 | 280 | -44 | 20 | 16009 | SITcomp6-AVAFX | false | Unprocessed position with banner attribution (BannerID 2043) and competitor-comparison sub-affiliate tag. Commission not yet distributed. |
| 8473673 | 2013-01-20 | 1545933 | 700 | -109.5 | 50 | 81 | EN-Profile | false | High-volume position (50 lots, $700 commission). Sub-affiliate "EN-Profile" suggests English-language social profile referral. Uses bonus ($70). |
| 8473674 | 2013-01-20 | 1961082 | 435 | -39.27 | 8 | 11 | Mail | false | Email marketing attribution ("Mail" sub-affiliate). Large bonus usage ($3,927) relative to commission - possible VIP customer with bonus incentives. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ClosedPositionsID | int | NO | - | VERIFIED | Primary key identifying a unique closed trading position. Values are non-sequential (start at ~8.4M), suggesting these originate from the core trading platform's position ID space. |
| 2 | Occurred | datetime | NO | - | CODE-BACKED | Timestamp when the trading position was closed on the platform. Used as a clustering key for time-range queries. Range in data: 2013-01-20 to 2023-02-15. |
| 3 | CID | int | NO | - | VERIFIED | Customer ID - the eToro customer who owns this closed position. High cardinality (maps to Customer.Customer). Also used to compute PartitionCol (CID % 10) for parallel processing distribution. Indexed for lookups. |
| 4 | Commission | money | NO | - | CODE-BACKED | Total commission amount (in USD) generated by this closed position. This is the gross commission before tier-based distribution to affiliates. Typical values range from $120 to $755 in sample data. |
| 5 | NetProfit | money | NO | - | CODE-BACKED | Net profit or loss for the customer on this position. Negative values (most common) indicate customer losses. Used in affiliate reporting (SSRS_AffWiz_ClosedPositions). |
| 6 | Lots | decimal(34,6) | NO | - | NAME-INFERRED | Number of lots (trading volume units) in this closed position. Higher lot counts generally correlate with higher commissions. Values range from 4 to 50 in sample data. |
| 7 | BonusUsed | money | NO | - | CODE-BACKED | Amount of bonus funds consumed by this position. Negative values indicate bonus consumption (e.g., -154 means $154 of bonus was used). Zero means no bonus applied. Large values (e.g., -3927) suggest VIP or high-bonus customers. |
| 8 | OriginalCustomerID | int | YES | - | CODE-BACKED | The original customer ID before any account migration or merge. When a customer account is consolidated, this preserves the original attribution. Different from CID when customer migration has occurred. |
| 9 | OriginalProviderID | int | YES | - | CODE-BACKED | The original provider/broker ID assigned at customer registration. Value 1 = primary provider, 0 = organic/direct. Preserved to maintain original attribution even if provider changes. |
| 10 | SerialID | int | YES | - | VERIFIED | Affiliate ID that referred this customer (maps to tblaff_Affiliates.AffiliateID). Called "SerialID" for legacy reasons. Can be updated retroactively by UpdateSubAffiliateID for late-binding mobile attribution. |
| 11 | SubSerialID | varchar(1024) | YES | - | VERIFIED | Sub-affiliate tracking parameter containing the marketing attribution source. Contains referral URLs (Google search URLs), campaign identifiers ("SITcomp6-AVAFX"), channel tags ("Mail", "EN-Profile"), or NULL for direct referrals. Updated by UpdateSubAffiliateID for late-binding. |
| 12 | BannerID | int | YES | - | CODE-BACKED | Marketing banner ID that drove the customer registration. 0 = no banner (organic/direct). Non-zero values reference tblaff_Banners for creative tracking. |
| 13 | DownloadID | int | YES | - | CODE-BACKED | Download tracking ID for the customer's app/software download. 0 = no tracked download. Can be updated retroactively by UpdateSubAffiliateID when mobile download data becomes available. |
| 14 | CountryIDByIP | int | YES | - | NAME-INFERRED | Country ID determined by IP geolocation at time of the position. References a country dictionary. Used for country-based commission rate calculations and regional reporting. |
| 15 | ProviderID | int | YES | - | NAME-INFERRED | Current provider/broker ID for this customer. May differ from OriginalProviderID if the customer was migrated between providers. Value 1 is the dominant provider in sample data. |
| 16 | RealProviderID | int | YES | - | NAME-INFERRED | Actual/real provider ID, resolving any provider aliasing or white-labeling. In sample data, always matches ProviderID (value 1), suggesting no provider aliasing in this dataset. |
| 17 | FunnelID | int | YES | - | NAME-INFERRED | Marketing funnel identifier tracking which acquisition funnel the customer entered through. NULL for older records, numeric values (0-5) for tracked funnels. |
| 18 | LabelID | int | YES | - | NAME-INFERRED | Brand/label identifier for multi-brand operations. Value 1 is dominant (primary brand). Other values (e.g., 11) indicate white-label or regional brand variants. |
| 19 | DownloadCounter | int | YES | - | NAME-INFERRED | Counter tracking how many downloads the customer has performed. NULL for older records, 0 for customers with no additional downloads beyond initial. |
| 20 | PlayerLevelID | int | YES | - | NAME-INFERRED | Customer tier/level classification. Values 1, 3, 5 observed - likely maps to a player level dictionary. Higher levels may indicate more active or valuable customers. |
| 21 | FinishedUpdating | bit | NO | 0 | VERIFIED | Processing pipeline flag: 1 = position data is complete from the source trading platform and ready for commission calculation. 0 = data still being populated. Must be 1 before FinishedProcessing can be set. Filtered indexes target rows where FinishedUpdating=1 AND FinishedProcessing=0 for efficient processing queue queries. |
| 22 | FinishedProcessing | bit | NO | 0 | VERIFIED | Processing pipeline flag: 1 = commission calculation and distribution complete. 0 = not yet processed. SSRS_AffWiz_ClosedPositions monitors the backlog of FinishedUpdating=1/FinishedProcessing=0 rows. The DeferredMessages table is cross-referenced to avoid reprocessing positions that already have pending messages. |
| 23 | PartitionCol | AS (CID % 10) | - | computed | VERIFIED | Computed column: CID modulo 10. Distributes rows into 10 buckets (0-9) for parallel processing by QuesService instances. The dbo.ClosedPositions view uses this to route each QuesService worker to its assigned partition. Indexed for partition-filtered lookups. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SerialID | dbo.tblaff_Affiliates | Implicit | Maps to AffiliateID - the referring affiliate for commission attribution |
| BannerID | dbo.tblaff_Banners | Implicit | References the marketing banner creative that drove registration |
| CountryIDByIP | Dictionary.Country (via synonym) | Implicit | Country determined by IP geolocation |
| CID | Customer.Customer (external DB) | Implicit | The trading customer who owns this position |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.ClosedPositions | FROM | View (base table) | View wraps this table with app-name-based partition filtering for parallel QuesService processing |
| dbo.SSRS_AffWiz_ClosedPositions | FROM | Procedure (READER) | Operational reporting - monitors unprocessed position backlog by partition |
| dbo.UpdateSubAffiliateID | UPDATE | Procedure (MODIFIER) | Retroactively updates SerialID and SubSerialID for late-binding affiliate attribution |
| dbo.DBA_ReplCheck_Update | - | Procedure (READER) | Replication health monitoring references closed positions |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.ClosedPositions | View | Base table - all columns exposed through partition-filtered view |
| dbo.SSRS_AffWiz_ClosedPositions | Stored Procedure | READER - aggregates unprocessed positions by partition for backlog monitoring |
| dbo.UpdateSubAffiliateID | Stored Procedure | MODIFIER - updates SerialID/SubSerialID via the ClosedPositions view |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ClosedPositions_201711 | CLUSTERED PK | ClosedPositionsID ASC | - | - | Active |
| IDX_ClosedPositionsTbl_PartitionCol | NC | PartitionCol ASC | - | - | Active (PAGE compression) |
| IDX_ClosedPositions_Filtered_201711 | NC | ClosedPositionsID ASC | - | FinishedUpdating=1 AND FinishedProcessing=0 | Active (fill 90%) |
| IX_FinishedUpdatingAndProcessing_201711 | NC | FinishedUpdating, FinishedProcessing | - | - | Active (fill 90%) |
| IX_Incl_FinishedUpdatingAndProcessing | NC | FinishedUpdating, FinishedProcessing | ClosedPositionsID | FinishedUpdating=1 AND FinishedProcessing=0 | Active (fill 90%) |
| IX_Incl_FinishedUpdatingAndProcessing_RAN | NC | FinishedUpdating, FinishedProcessing, PartitionCol | All data columns | FinishedUpdating=1 AND FinishedProcessing=0 | Active (covering index for processing) |
| NonClusteredIndex-CID_201711 | NC | CID ASC | - | - | Active (fill 90%) |
| NonClusteredIndex-Occured-CID_201711 | NC UNIQUE | Occurred ASC, CID ASC | - | - | Active (fill 90%) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_ClosedPositionsTbl_FinishedUpdating | DEFAULT | 0 - new positions start as "not yet updated" |
| DF_ClosedPositionsTbl_FinishedProcessing | DEFAULT | 0 - new positions start as "not yet processed" |

---

## 8. Sample Queries

### 8.1 Find unprocessed positions ready for commission calculation
```sql
SELECT ClosedPositionsID, Occurred, CID, Commission, NetProfit, SerialID, SubSerialID
FROM dbo.ClosedPositionsTbl WITH (NOLOCK)
WHERE FinishedUpdating = 1 AND FinishedProcessing = 0
ORDER BY Occurred ASC
```

### 8.2 Commission summary by affiliate
```sql
SELECT SerialID AS AffiliateID, COUNT(*) AS PositionCount,
       SUM(Commission) AS TotalCommission, SUM(NetProfit) AS TotalNetProfit
FROM dbo.ClosedPositionsTbl WITH (NOLOCK)
WHERE SerialID IS NOT NULL AND SerialID > 0
GROUP BY SerialID
ORDER BY TotalCommission DESC
```

### 8.3 Processing backlog by partition
```sql
SELECT PartitionCol, COUNT(*) AS UnprocessedCount, MIN(Occurred) AS OldestPending
FROM dbo.ClosedPositionsTbl WITH (NOLOCK)
WHERE FinishedUpdating = 1 AND FinishedProcessing = 0
GROUP BY PartitionCol
ORDER BY PartitionCol
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 7.4/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 6 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.ClosedPositionsTbl | Type: Table | Source: fiktivo/dbo/Tables/dbo.ClosedPositionsTbl.sql*
