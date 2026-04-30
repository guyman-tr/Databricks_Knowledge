# Billing.RedeemFeeSettings

> Per-instrument, per-player-level fee configuration for cryptocurrency redemptions, defining the percentage fee and min/max caps applied when a user redeems a crypto position. Temporal table tracking fee change history.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (InstrumentID, PlayerLevelID, RedeemTypeID) (INT composite, CLUSTERED PK) |
| **Partition** | No ([DICTIONARY] filegroup) |
| **Indexes** | 1 (PK only) |
| **Temporal** | Yes - SYSTEM_VERSIONING ON -> Billing.MSSQL_TemporalHistoryFor_941102989 |

---

## 1. Business Meaning

Billing.RedeemFeeSettings defines the fee structure applied to every crypto redemption transaction. When a user requests redemption of a crypto position, the fee engine looks up this table to determine: what percentage of the redeemed amount to charge as a fee, what the minimum fee is (so small redemptions still pay a floor), and what the maximum fee is (so large redemptions are capped).

The table is keyed on three dimensions: instrument (which crypto asset), player level (VIP tier), and redeem type (standard vs. special/NFT). This allows the business to configure different fees by asset class, offer reduced fees to premium customers, and apply distinct structures for NFT redemptions (added June 2022 via PTL-76).

Current data structure (469 rows): 60 crypto instruments x 7 player levels x 2 redeem types. All player levels have identical fees per instrument (no VIP differentiation in current configuration), but the schema supports it. Standard redemptions (Type 0) carry 2% fee capped at $100; NFT/special redemptions (Type 1) carry 0.5% fee capped at $50.

The table resides on the [DICTIONARY] filegroup, reflecting its classification as configuration data (small, read-heavy, rarely updated). System-versioning captures every fee change for audit history.

---

## 2. Business Logic

### 2.1 Fee Calculation Formula

**What**: The actual dollar fee charged on a crypto redemption is computed from the percentage, floored by MinimumFee, and capped by MaximumFee.

**Columns/Parameters Involved**: `FeeInPercentage`, `MinimumFee`, `MaximumFee`

**Rules**:
- Fee = GREATEST(MinimumFee, LEAST(MaximumFee, RedemptionAmount * FeeInPercentage / 100))
- Standard (RedeemTypeID=0): 2% fee, min $1, max $100
  - A $50 redemption: fee = max($1, min($100, $1.00)) = $1.00 (floored by minimum)
  - A $500 redemption: fee = max($1, min($100, $10.00)) = $10.00
  - A $6,000 redemption: fee = max($1, min($100, $120.00)) = $100.00 (capped by maximum)
- NFT/Special (RedeemTypeID=1): 0.5% fee, min $1, max $50
  - A $200 redemption (NFT): fee = max($1, min($50, $1.00)) = $1.00
  - A $1,000 redemption (NFT): fee = max($1, min($50, $5.00)) = $5.00
  - A $12,000 redemption (NFT): fee = max($1, min($50, $60.00)) = $50.00 (capped)

**Diagram**:
```
Redemption amount
        |
        v
fee_raw = amount * FeeInPercentage / 100
        |
        v
fee = CLAMP(fee_raw, MinimumFee, MaximumFee)
        |
        v
Applied to redemption transaction
```

### 2.2 Fee Lookup by Instrument + Player Level + Redeem Type

**What**: GetRedeemFeeSettings retrieves the fee configuration for a specific instrument/level/type combination. Called by the fee engine during redemption processing.

**Columns/Parameters Involved**: `InstrumentID`, `PlayerLevelID`, `RedeemTypeID`

**Rules**:
- `GetRedeemFeeSettings(@InstrumentID, @PlayerLevelID, @RedeemTypeID)` returns one row via exact PK lookup
- @RedeemTypeID defaults to 0 (standard) if not specified by caller - pre-PTL-76 callers always get standard fees
- PTL-76 (June 2022) added the @RedeemTypeID parameter to support NFT redemption fee differentiation
- If no row matches, the procedure returns empty result (caller must handle missing config)

**Diagram**:
```
Redemption initiation
  @InstrumentID, @PlayerLevelID, @RedeemTypeID
        |
        v
Billing.GetRedeemFeeSettings
        |
        v
SELECT FROM RedeemFeeSettings
  WHERE InstrumentID = @InstrumentID
    AND PlayerLevelID = @PlayerLevelID
    AND RedeemTypeID = @RedeemTypeID
        |
        v
Returns: FeeInPercentage, MinimumFee, MaximumFee
        |
        v
Fee engine computes actual fee amount
```

### 2.3 Player Level Fee Configuration (No Differentiation in Current Data)

**What**: The schema supports per-VIP-tier fee differentiation, but current data is flat (all levels have identical fees per instrument).

**Rules**:
- PlayerLevelID values in use: 1=Bronze, 2=Platinum, 3=Gold, 4=Internal, 5=Silver, 6=Platinum Plus, 7=Diamond
- Each instrument has 7 rows (one per level) for Type 0 and 7 rows for Type 1 = 14 rows per instrument
- All 7 levels have the same FeeInPercentage/MinimumFee/MaximumFee per instrument
- To offer VIP discount: update rows for PlayerLevelID > 1 with lower fees

---

## 3. Data Overview

| RedeemTypeID | Type Name | FeeInPercentage | MinimumFee | MaximumFee | Row Count | Meaning |
|--------------|-----------|-----------------|------------|------------|-----------|---------|
| 0 | Standard | 2.00% | 1.00 | 100.00 | ~420 rows | Standard crypto redemption fee. Applied to all normal crypto position redemptions. |
| 1 | NFT/Special | 0.50% | 1.00 | 50.00 | ~49 rows | Special redemption fee (NFT or other non-standard crypto types). Lower percentage and lower cap vs. standard. Added PTL-76. |

Note: 60 instruments x 7 player levels = 420 standard rows + 49 special rows (7 instruments support Type 1 fees). Fee values are identical across all player levels for a given instrument and type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | INT | NO | - | CODE-BACKED | Crypto instrument identifier. Part of the composite PK. References Trade.InstrumentMetaData(InstrumentID) - no DDL FK constraint defined. Identifies which crypto asset (e.g., BTC, ETH, ADA) this fee row applies to. 60 distinct instruments in current data. |
| 2 | PlayerLevelID | INT | NO | - | CODE-BACKED | Customer VIP tier for this fee row. Part of the composite PK. No DDL FK constraint. Values: 1=Bronze, 2=Platinum, 3=Gold, 4=Internal, 5=Silver, 6=Platinum Plus, 7=Diamond. All 7 levels currently have identical fees per instrument - schema supports differentiation but it is not in use. |
| 3 | RedeemTypeID | INT | NO | 0 | CODE-BACKED | Type of redemption this fee applies to. Part of the composite PK. 0=Standard crypto redemption (default), 1=NFT/special redemption. Default=0. Added via PTL-76 (June 2022) to support NFT redemption differentiation. `GetRedeemFeeSettings` defaults @RedeemTypeID=0 for backward compatibility. |
| 4 | MinimumFee | DECIMAL(18,2) | YES | - | CODE-BACKED | Floor fee amount in USD. The actual fee will never be less than this value regardless of how small the redemption amount is. Current value for all rows: 1.00 ($1 minimum fee). NULL would mean no floor (not observed in current data). |
| 5 | MaximumFee | DECIMAL(18,2) | YES | - | CODE-BACKED | Cap on the fee amount in USD. The actual fee will never exceed this value regardless of how large the redemption amount is. Type 0 (standard): 100.00. Type 1 (NFT): 50.00. NULL would mean no cap (not observed in current data). |
| 6 | FeeInPercentage | DECIMAL(18,2) | NO | - | CODE-BACKED | Percentage of the redemption amount charged as fee. Type 0 (standard): 2.00 (2%). Type 1 (NFT/special): 0.50 (0.5%). Applied as: `amount * FeeInPercentage / 100` before clamping with Min/MaximumFee. |
| 7 | ModificationDate | DATETIME | YES | getutcdate() | CODE-BACKED | UTC timestamp of the last modification to this fee row. Defaults to getutcdate() on INSERT. Should be updated by the application on every fee change, though not enforced by a trigger. Used to track when fees were last adjusted. |
| 8 | SysStartTime | DATETIME2(7) HIDDEN | NO | sysutcdatetime() | CODE-BACKED | Temporal period start - UTC timestamp when this version of the fee row became effective. HIDDEN column - not returned in `SELECT *`. Set automatically by SQL Server. Use `FOR SYSTEM_TIME AS OF` to see historical values. |
| 9 | SysEndTime | DATETIME2(7) HIDDEN | NO | 9999-12-31 | CODE-BACKED | Temporal period end - UTC timestamp when this version expired. HIDDEN column. 9999-12-31 for all current rows. When a fee is updated, the old version moves to Billing.MSSQL_TemporalHistoryFor_941102989 with this field set to the moment of change. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.InstrumentMetaData | Implicit FK (no DDL constraint) | Links each fee row to the crypto instrument it prices. No DDL FK enforced - referential integrity maintained by application. |
| PlayerLevelID | Dictionary.PlayerLevel | Implicit FK (no DDL constraint) | Links each fee row to the VIP tier. No DDL FK enforced despite the pattern matching Dictionary.PlayerLevel. |
| RedeemTypeID | (inline enum) | Inline enum (no FK) | 0=Standard redemption, 1=NFT/special redemption. Not backed by a dictionary table. |
| - | Billing.MSSQL_TemporalHistoryFor_941102989 | TEMPORAL HISTORY | System-versioned history table for all superseded fee versions. Auto-managed by SQL Server. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetRedeemFeeSettings | InstrumentID, PlayerLevelID, RedeemTypeID | READER | Primary consumer - retrieves fee configuration for a specific redemption. Called during fee calculation in the redemption pipeline. @RedeemTypeID parameter added PTL-76. |
| Billing.MSSQL_TemporalHistoryFor_941102989 | - | TEMPORAL HISTORY | Receives superseded fee versions on UPDATE. Enables point-in-time fee history queries. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.RedeemFeeSettings (table)
|- Trade.InstrumentMetaData (implicit - no DDL constraint)
|- Dictionary.PlayerLevel (implicit - no DDL constraint)
└-- Billing.MSSQL_TemporalHistoryFor_941102989 (temporal history, auto-managed)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | Implicit FK - InstrumentID references instrument definitions |
| Dictionary.PlayerLevel | Table | Implicit FK - PlayerLevelID references VIP tier definitions |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetRedeemFeeSettings | Stored Procedure | READER - PK lookup for fee configuration during redemption |
| Billing.MSSQL_TemporalHistoryFor_941102989 | History Table | TEMPORAL - receives superseded fee versions |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RedeemFeeSettings | CLUSTERED PK | InstrumentID ASC, PlayerLevelID ASC, RedeemTypeID ASC | - | - | Active |

Table resides on [DICTIONARY] filegroup (configuration/lookup classification).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_RedeemFeeSettings | PRIMARY KEY CLUSTERED | (InstrumentID, PlayerLevelID, RedeemTypeID) must be unique - one fee row per instrument-level-type combination |
| DF_RedeemFeeSettings_ModificationDate | DEFAULT | ModificationDate defaults to getutcdate() on INSERT |
| DF_PaymentExecution_SysStart | DEFAULT | SysStartTime defaults to sysutcdatetime() on INSERT |
| DF_PaymentExecution_SysEnd | DEFAULT | SysEndTime defaults to 9999-12-31 on INSERT |
| BRFS_RedeemType | DEFAULT | RedeemTypeID defaults to 0 (standard) on INSERT |

### 7.3 Temporal Configuration

| Property | Value |
|----------|-------|
| System Versioning | ON |
| History Table | Billing.MSSQL_TemporalHistoryFor_941102989 |
| Period Start | SysStartTime (DATETIME2(7), HIDDEN) |
| Period End | SysEndTime (DATETIME2(7), HIDDEN) |
| Point-in-time queries | `FOR SYSTEM_TIME AS OF '{datetime}'` |

Note: SysStartTime/SysEndTime are HIDDEN columns - not returned in `SELECT *`. Use `SELECT *, SysStartTime, SysEndTime FROM ...` to include them.

---

## 8. Sample Queries

### 8.1 Get current fee structure for all instruments and types

```sql
SELECT
    rfs.InstrumentID,
    rfs.PlayerLevelID,
    rfs.RedeemTypeID,
    CASE rfs.RedeemTypeID WHEN 0 THEN 'Standard' WHEN 1 THEN 'NFT/Special' ELSE 'Unknown' END AS RedeemTypeName,
    rfs.FeeInPercentage,
    rfs.MinimumFee,
    rfs.MaximumFee,
    rfs.ModificationDate
FROM [Billing].[RedeemFeeSettings] WITH (NOLOCK)
ORDER BY rfs.InstrumentID, rfs.PlayerLevelID, rfs.RedeemTypeID
```

### 8.2 Look up the fee for a specific redemption

```sql
DECLARE @InstrumentID INT = 100      -- e.g., BTC instrument ID
DECLARE @PlayerLevelID INT = 1       -- Bronze
DECLARE @RedeemTypeID INT = 0        -- Standard

SELECT
    FeeInPercentage,
    MinimumFee,
    MaximumFee
FROM [Billing].[RedeemFeeSettings] WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID
  AND PlayerLevelID = @PlayerLevelID
  AND RedeemTypeID = @RedeemTypeID
```

### 8.3 Calculate example fees for a given redemption amount

```sql
DECLARE @InstrumentID INT = 100
DECLARE @PlayerLevelID INT = 1
DECLARE @RedeemTypeID INT = 0
DECLARE @RedemptionAmount DECIMAL(18,2) = 1500.00

SELECT
    FeeInPercentage,
    MinimumFee,
    MaximumFee,
    @RedemptionAmount * FeeInPercentage / 100 AS RawFee,
    CASE
        WHEN @RedemptionAmount * FeeInPercentage / 100 < MinimumFee THEN MinimumFee
        WHEN @RedemptionAmount * FeeInPercentage / 100 > MaximumFee THEN MaximumFee
        ELSE @RedemptionAmount * FeeInPercentage / 100
    END AS ActualFee
FROM [Billing].[RedeemFeeSettings] WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID
  AND PlayerLevelID = @PlayerLevelID
  AND RedeemTypeID = @RedeemTypeID
```

### 8.4 View fee history for a specific instrument (temporal)

```sql
-- Show all historical fee versions for BTC (instrument 100), standard type
SELECT
    InstrumentID,
    PlayerLevelID,
    RedeemTypeID,
    FeeInPercentage,
    MinimumFee,
    MaximumFee,
    ModificationDate,
    SysStartTime,
    SysEndTime
FROM [Billing].[RedeemFeeSettings]
FOR SYSTEM_TIME ALL
WHERE InstrumentID = 100
  AND PlayerLevelID = 1
  AND RedeemTypeID = 0
ORDER BY SysStartTime
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PTL-76 | Jira | Added @RedeemTypeID parameter to GetRedeemFeeSettings (June 2022) to support NFT redemption type differentiation. Added RedeemTypeID column to table with DEFAULT 0. MEDIUM confidence - referenced in Billing.Redeem documentation context. |

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.8/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 1 Jira (PTL-76) | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.RedeemFeeSettings | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.RedeemFeeSettings.sql*
