# Billing.GetRedeemFeeSettings

> Retrieves the fee configuration (percentage, minimum, and maximum) for a specific instrument, player level, and redemption type from the Billing.RedeemFeeSettings configuration table.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (@InstrumentID, @PlayerLevelID, @RedeemTypeID) - matches the composite PK of Billing.RedeemFeeSettings; returns at most one row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetRedeemFeeSettings` is the fee configuration lookup for the crypto redemption fee calculation engine. Before processing a redemption, the application calls this procedure to retrieve the applicable fee rules - what percentage to charge, and what the floor/ceiling amounts are - for the specific combination of crypto instrument, customer player level (VIP tier), and redemption type (standard vs. NFT/special).

The procedure exists as an encapsulated lookup to isolate the application from direct `Billing.RedeemFeeSettings` table access. It was extended in June 2022 (PTL-76, Alexei) to support the `@RedeemTypeID` parameter, enabling different fee structures for NFT redemptions (RedeemTypeID=1) alongside the original standard redemptions (RedeemTypeID=0 default).

Data flow: the caller (application fee calculation service) provides the instrument, player level, and type. The procedure returns the row from `Billing.RedeemFeeSettings` whose (InstrumentID, PlayerLevelID, RedeemTypeID) composite PK matches. The application then computes the actual fee as: GREATEST(MinimumFee, LEAST(MaximumFee, RedemptionAmount * FeeInPercentage / 100)). See `Billing.RedeemFeeSettings` Section 2.1 for the full fee formula with examples.

---

## 2. Business Logic

### 2.1 Three-Dimensional Fee Configuration Lookup

**What**: The fee rules are differentiated on three axes - instrument (which crypto), player level (customer VIP tier), and redemption type (standard vs. special).

**Columns/Parameters Involved**: `@InstrumentID`, `@PlayerLevelID`, `@RedeemTypeID`

**Rules**:
- All three parameters must match the composite PK `(InstrumentID, PlayerLevelID, RedeemTypeID)` - if any dimension has no configured row, no results are returned (empty result set = no fee config found)
- `@RedeemTypeID` defaults to 0 (standard redemption), making it backward-compatible with callers that pre-date PTL-76 NFT support
- Current data: 60 instruments x 7 player levels x 2 types = up to 840 possible rows. All player levels share the same fee per instrument in current configuration, but the schema supports tier-differentiated fees
- Standard (RedeemTypeID=0): 2% fee, $1 min, $100 max per `Billing.RedeemFeeSettings` Section 2
- NFT/Special (RedeemTypeID=1): 0.5% fee, $1 min, $50 max per `Billing.RedeemFeeSettings` Section 2

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | Crypto instrument identifier for the redemption. FK to `Trade.Instrument`. Determines which asset-specific fee configuration applies (e.g., Bitcoin may have different settings from a smaller altcoin). |
| 2 | @PlayerLevelID | INT | NO | - | CODE-BACKED | Customer VIP/player level tier. FK to `Dictionary.PlayerLevel`. Allows fee discounts for premium tiers. In current configuration all tiers share the same rates, but the schema supports differentiation. |
| 3 | @RedeemTypeID | INT | YES | `0` | CODE-BACKED | Redemption type: 0 = standard crypto redemption, 1 = NFT/special redemption (added PTL-76, June 2022). Controls which fee schedule applies. Defaults to 0 for backward compatibility with callers that do not specify a type. |

### Result Set Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | InstrumentID | INT | NO | - | CODE-BACKED | Echoed from the matched row. Confirms which instrument the returned configuration applies to. |
| 5 | PlayerLevelID | INT | NO | - | CODE-BACKED | Echoed from the matched row. Confirms which player level the returned configuration applies to. |
| 6 | MinimumFee | DECIMAL | NO | - | CODE-BACKED | Floor fee in USD. Even if the percentage calculation yields less, this minimum is charged. Current config: $1.00 for both standard and NFT types. See `Billing.RedeemFeeSettings` Section 2.1. |
| 7 | MaximumFee | DECIMAL | NO | - | CODE-BACKED | Ceiling fee in USD. Even if the percentage calculation yields more, this cap is applied. Current config: $100.00 for standard, $50.00 for NFT. Protects large redemptions from excessive fees. See `Billing.RedeemFeeSettings` Section 2.1. |
| 8 | FeeInPercentage | DECIMAL | NO | - | CODE-BACKED | Fee rate as a percentage of the redemption amount. Current config: 2.00 for standard, 0.50 for NFT. Applied as: `RedemptionAmount * FeeInPercentage / 100`, then clamped by MinimumFee/MaximumFee. |
| 9 | ModificationDate | DATETIME | NO | - | CODE-BACKED | UTC timestamp of the last update to this fee configuration row. Useful for auditing when a fee change took effect. System-versioning on `Billing.RedeemFeeSettings` captures full history. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID / @PlayerLevelID / @RedeemTypeID | Billing.RedeemFeeSettings | Lookup (composite PK match) | Configuration source for the fee structure |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application fee calculation service | @InstrumentID, @PlayerLevelID, @RedeemTypeID | EXEC | Called before each redemption to retrieve applicable fee rules |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetRedeemFeeSettings (procedure)
└── Billing.RedeemFeeSettings (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.RedeemFeeSettings | Table | SELECT with NOLOCK; filtered by (PlayerLevelID, RedeemTypeID, InstrumentID) composite PK |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application redemption fee service | External | Calls to retrieve fee config before computing the fee for a new redemption |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Composite PK match | Design | All three parameters must match (InstrumentID, PlayerLevelID, RedeemTypeID) - no partial match possible |
| Default @RedeemTypeID | Design | Defaults to 0 - pre-PTL-76 callers transparently get standard redemption fees |
| NOLOCK | Concurrency | Read without shared lock - appropriate for config table reads where stale reads by milliseconds are acceptable |

---

## 8. Sample Queries

### 8.1 Get fee settings for Bitcoin (standard redemption)
```sql
EXEC Billing.GetRedeemFeeSettings
    @InstrumentID = 55,  -- Bitcoin InstrumentID
    @PlayerLevelID = 1;
-- Returns standard (RedeemTypeID=0) fee config: 2% fee, $1-$100 range
```

### 8.2 Get fee settings for an NFT redemption
```sql
EXEC Billing.GetRedeemFeeSettings
    @InstrumentID = 55,
    @PlayerLevelID = 1,
    @RedeemTypeID = 1;
-- Returns NFT fee config: 0.5% fee, $1-$50 range
```

### 8.3 View all configured fee settings for an instrument across player levels
```sql
SELECT
    rfs.InstrumentID,
    rfs.PlayerLevelID,
    rfs.RedeemTypeID,
    rfs.FeeInPercentage,
    rfs.MinimumFee,
    rfs.MaximumFee,
    rfs.ModificationDate
FROM Billing.RedeemFeeSettings rfs WITH (NOLOCK)
WHERE rfs.InstrumentID = 55
ORDER BY rfs.RedeemTypeID, rfs.PlayerLevelID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PTL-76 (referenced in DDL comment, Alexei, 30/06/2022) | Jira | Added @RedeemTypeID parameter to support NFT redemption fee configuration (Jira unavailable for full details) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (Jira unavailable) | Procedures: 0 callers analyzed | App Code: 0 repos (billing repos not configured) | Corrections: 0 applied*
*Object: Billing.GetRedeemFeeSettings | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetRedeemFeeSettings.sql*
