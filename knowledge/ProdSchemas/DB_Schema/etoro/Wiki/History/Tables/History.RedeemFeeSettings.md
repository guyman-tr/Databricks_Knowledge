# History.RedeemFeeSettings

> Temporal history archive for Billing.RedeemFeeSettings, recording all past states of the redemption fee configuration (minimum/maximum/percentage fees per instrument, player level, and redeem type) with precise validity intervals.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite temporal key (SysEndTime, SysStartTime) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime ASC, SysStartTime ASC) |

---

## 1. Business Meaning

This table is the **temporal history table** for `Billing.RedeemFeeSettings`, capturing all past states of the Redeem feature fee configuration. Each row records a fee structure that was previously active: for a given combination of instrument, player tier, and redemption type, it records the fee percentage plus minimum and maximum fee caps that were in effect from `SysStartTime` through `SysEndTime`.

The `Billing.RedeemFeeSettings` source table defines how much customers pay to "redeem" their earnings - converting realized equity into a crypto wallet withdrawal or NFT redemption. The fee structure is tiered by:
- **Instrument**: which crypto/asset is being redeemed (InstrumentID)
- **Player Level**: the customer's loyalty tier (Bronze through Diamond), allowing higher-tier customers to receive better fee rates
- **Redeem Type**: the type of redemption event (cash, NFT, etc.)

Note: `Billing.RedeemFeeSettings` currently uses `Billing.MSSQL_TemporalHistoryFor_941102989` as its active system-versioned history. `History.RedeemFeeSettings` holds earlier historical records from before the temporal configuration was changed, with 49 rows covering the period up to August 2022. The RedeemTypeID column is NULL in these older history rows because it was added to the source table only in June 2022 (PTL-76).

---

## 2. Business Logic

### 2.1 Fee Calculation Structure

**What**: The fee charged on each redemption is a percentage of the redeemed amount, bounded by minimum and maximum caps.

**Columns/Parameters Involved**: `FeeInPercentage`, `MinimumFee`, `MaximumFee`

**Rules**:
- Fee = `FeeInPercentage` % of the redeemed amount
- Fee is floored at `MinimumFee` (e.g., 1.00 USD minimum ensures small redemptions still yield a flat fee)
- Fee is capped at `MaximumFee` (e.g., 50.00 USD cap protects large redemptions from excessive fees)
- Different player levels receive different fee structures for the same instrument
- `Billing.GetRedeemFeeSettings` retrieves the current active fee by InstrumentID + PlayerLevelID + RedeemTypeID

**Diagram**:
```
Redeem Amount X for InstrumentID + PlayerLevelID + RedeemTypeID
  |
  +--> Fee = X * FeeInPercentage / 100
  +--> Fee = MAX(Fee, MinimumFee)
  +--> Fee = MIN(Fee, MaximumFee)
  +--> Customer pays final Fee
```

### 2.2 Temporal Validity and History Tracking

**What**: Each row represents a fee configuration that was active for a specific time window.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `ModificationDate`

**Rules**:
- `SysStartTime`: when this fee configuration became effective in `Billing.RedeemFeeSettings`
- `SysEndTime`: when this configuration was replaced by a new one (UPDATE) or removed (DELETE)
- `ModificationDate`: the application-managed timestamp of the change, set via default `getutcdate()`
- `RedeemTypeID = NULL` in rows predating June 2022 (before PTL-76 added this column to the source table)

---

## 3. Data Overview

| InstrumentID | PlayerLevelID | FeeInPercentage | MinimumFee | MaximumFee | RedeemTypeID | SysStartTime | SysEndTime | Meaning |
|---|---|---|---|---|---|---|---|---|
| 100026 | 7 (Diamond) | 0.5% | 1.00 | 50.00 | null | 2021-11-15 | 2022-08-11 | Diamond-tier customers redeeming InstrumentID 100026 were charged 0.5% (min $1, max $50) from Nov 2021 until Aug 2022 when the fee structure was updated |
| 100026 | 6 (Platinum Plus) | 0.5% | 1.00 | 50.00 | null | 2021-11-15 | 2022-08-11 | Same fee structure for Platinum Plus tier; all tiers had uniform rates on this instrument prior to Aug 2022 |
| 100026 | 5 (Silver) | 0.5% | 1.00 | 50.00 | null | 2021-11-15 | 2022-08-11 | Silver-tier customers had identical fee structure - the pre-Aug 2022 configuration did not differentiate by loyalty tier |
| 100026 | 4 (Internal) | 0.5% | 1.00 | 50.00 | null | 2021-11-15 | 2022-08-11 | Internal accounts had the same fee configuration; RedeemTypeID=null indicates these rows predate the Redeem Type feature (PTL-76, Jun 2022) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | The financial instrument (typically a cryptocurrency) being redeemed. Part of the composite key (InstrumentID + PlayerLevelID + RedeemTypeID) identifying the fee rule. Implicit FK to Trade.Instrument or equivalent instrument dictionary. Indexed together with PlayerLevelID and RedeemTypeID in source table PK. |
| 2 | PlayerLevelID | int | NO | - | VERIFIED | Customer loyalty tier for which this fee applies. FK to Dictionary.PlayerLevel. Values: 1=Bronze, 2=Platinum, 3=Gold, 4=Internal, 5=Silver, 6=Platinum Plus, 7=Diamond. Higher-tier customers may be configured with lower fees or higher caps. In the pre-Aug 2022 data, all tiers had identical rates per instrument. |
| 3 | MinimumFee | decimal(18,2) | YES | - | CODE-BACKED | The floor for the redemption fee in USD. If the calculated percentage fee falls below this amount, this minimum is charged instead. Ensures each redemption transaction yields a base fee regardless of amount size. Nullable - some instruments/configurations may have no minimum. |
| 4 | MaximumFee | decimal(18,2) | YES | - | CODE-BACKED | The ceiling for the redemption fee in USD. If the calculated percentage fee exceeds this amount, this maximum is charged instead. Protects customers making large redemptions from disproportionate fees. Nullable - some configurations may have no cap. |
| 5 | FeeInPercentage | decimal(18,2) | NO | - | CODE-BACKED | The percentage of the redeemed amount charged as a fee. Applied before MinimumFee/MaximumFee clamping. In the historical data, 0.5% was the rate for all tiers on InstrumentID 100026. |
| 6 | ModificationDate | datetime | YES | getutcdate() | CODE-BACKED | Application-managed timestamp of the last modification to this fee row. Set by the default to UTC now on INSERT; updated on UPDATE by the calling application or procedure. Distinct from SysStartTime (SQL Server-managed temporal start). |
| 7 | SysStartTime | datetime2(7) | NO | sysutcdatetime() | CODE-BACKED | The precise UTC moment when this fee configuration became the current row in `Billing.RedeemFeeSettings`. Automatically set by SQL Server's temporal system versioning. Nanosecond precision. Leading candidate for point-in-time fee queries: `ValidFrom <= @AsOf`. |
| 8 | SysEndTime | datetime2(7) | NO | CONVERT(datetime2,'9999-12-31...') | CODE-BACKED | The precise UTC moment when this fee configuration was superseded or removed from `Billing.RedeemFeeSettings`. Automatically set by SQL Server. Leading key of the clustered index - enables efficient range scans for temporal queries. |
| 9 | RedeemTypeID | int | YES | - | CODE-BACKED | Identifies the type of redemption event: standard wallet redeem vs. NFT redeem, etc. Added to the source table in June 2022 (PTL-76, comment: "Alexei 30/06/2022 Add @RedeemTypeID PTL-76"). All 49 rows in this history table have NULL for this column because they predate the column addition. In the current source table, this is NOT NULL with default 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument (presumed) | Implicit | Financial instrument being redeemed. No explicit FK in history table (FK defined on source table). |
| PlayerLevelID | Dictionary.PlayerLevel | Implicit (FK on source) | Customer loyalty tier: 1=Bronze, 2=Platinum, 3=Gold, 4=Internal, 5=Silver, 6=Platinum Plus, 7=Diamond. |
| RedeemTypeID | Billing or Dictionary lookup | Implicit | Type of redemption (standard/NFT); exact lookup table not confirmed from available code. NULL for all pre-Jun 2022 rows. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.RedeemFeeSettings | HISTORY_TABLE (previous) | Temporal History | Source table previously used this as its system-versioned history. Currently using Billing.MSSQL_TemporalHistoryFor_941102989. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.RedeemFeeSettings (table)
  (temporal history - no code-level dependencies; populated by SQL Server from Billing.RedeemFeeSettings)
```

---

### 6.1 Objects This Depends On

No dependencies. Temporal history table populated by SQL Server.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.RedeemFeeSettings | Table | Original source table. SQL Server moved expired rows here when rows were updated or deleted. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_RedeemFeeSettings | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

Note: DATA_COMPRESSION = PAGE applied to both table and clustered index.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Page compression reduces storage for this archival/historical table. |

---

## 8. Sample Queries

### 8.1 View all historical fee configurations with human-readable lookups
```sql
SELECT
    h.InstrumentID,
    h.PlayerLevelID,
    dp.Name AS PlayerLevel,
    h.FeeInPercentage,
    h.MinimumFee,
    h.MaximumFee,
    h.RedeemTypeID,
    h.ModificationDate,
    h.SysStartTime AS ValidFrom,
    h.SysEndTime AS ValidTo
FROM [History].[RedeemFeeSettings] h WITH (NOLOCK)
JOIN [Dictionary].[PlayerLevel] dp WITH (NOLOCK) ON dp.PlayerLevelID = h.PlayerLevelID
ORDER BY h.SysEndTime DESC, h.InstrumentID, h.PlayerLevelID
```

### 8.2 What were the fee settings for a specific instrument on a past date
```sql
-- Query source table with temporal AS OF clause (SQL Server reads history automatically)
SELECT InstrumentID, PlayerLevelID, FeeInPercentage, MinimumFee, MaximumFee, RedeemTypeID
FROM [Billing].[RedeemFeeSettings]
FOR SYSTEM_TIME AS OF '2022-06-01T00:00:00'
WHERE InstrumentID = @InstrumentID
ORDER BY PlayerLevelID
```

### 8.3 Track fee changes over time for a specific instrument+level combination
```sql
SELECT
    InstrumentID,
    PlayerLevelID,
    FeeInPercentage,
    MinimumFee,
    MaximumFee,
    RedeemTypeID,
    SysStartTime AS EffectiveFrom,
    SysEndTime AS EffectiveTo,
    DATEDIFF(day, SysStartTime, SysEndTime) AS DaysActive
FROM [History].[RedeemFeeSettings] WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID
  AND PlayerLevelID = @PlayerLevelID
ORDER BY SysStartTime ASC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HLD: Redeem service](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/11685691393) | Confluence | High-level design for the Redeem service (Feb 2025); page not accessible - low confidence context only. |

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.RedeemFeeSettings | Type: Table | Source: etoro/etoro/History/Tables/History.RedeemFeeSettings.sql*
