# Trade.GetIsRedeemAllowed

> Returns the global feature flag indicating whether stock redemption (converting CFD to real stock) is currently enabled in the system.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: single INT value (0=disabled, 1=enabled) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetIsRedeemAllowed is a lightweight feature flag reader that checks whether stock redemption is globally enabled across the eToro platform. "Redeem" in this context means converting a CFD (Contract for Difference) position into actual stock ownership - a key feature of eToro's real stock offering.

This procedure exists because eToro needs a kill switch to disable redemptions system-wide during maintenance, market events, or regulatory holds. Multiple services (Trading API, Equity Calculator, Portfolio Alignment, Trading Settings) check this flag before allowing redemption workflows to proceed.

The flag is stored in Maintenance.Feature (FeatureID=52) with description "Is redeem allowed (0-not allowed, 1 is allowed)". The current production value is 1 (enabled). No parameters are needed - this is a simple global config lookup.

---

## 2. Business Logic

### 2.1 Feature Flag Lookup

**What**: Reads a single row from the Maintenance.Feature configuration table to determine if redemption is enabled.

**Columns/Parameters Involved**: `Maintenance.Feature.FeatureID`, `Maintenance.Feature.Value`

**Rules**:
- FeatureID=52 is the hardcoded identifier for the "Is Redeem Allowed" flag
- Value is stored as string in Maintenance.Feature and cast to INT for the return
- 0 = Redemption is NOT allowed (global disable)
- 1 = Redemption IS allowed (normal operation)
- No parameters - this is a system-wide setting, not per-user or per-instrument

**Diagram**:
```
Caller Service (TradingAPI, EquityCalc, etc.)
     |
     v
EXEC Trade.GetIsRedeemAllowed
     |
     v
Maintenance.Feature WHERE FeatureID=52
     |
     +--> Value=1 --> Redemption allowed, proceed with workflow
     +--> Value=0 --> Redemption blocked, reject/queue request
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### 4.1 Parameters

This procedure has no parameters.

### 4.2 Result Set

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | Value | int | YES | CODE-BACKED | Global redemption feature flag: 1=redemption allowed (normal), 0=redemption disabled (kill switch active). Cast from Maintenance.Feature.Value (varchar) to INT. Current production value: 1. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FeatureID=52 | Maintenance.Feature | SELECT (READER) | Reads the global redemption feature flag from the centralized feature configuration table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| TradingEquityCalculator | GRANT EXECUTE | Application User | Equity calculation service checks redemption eligibility |
| TDAPIUser | GRANT EXECUTE | Application User | Trading Data API checks before processing redemption |
| TDAPIUserProd | GRANT EXECUTE | Application User | Production Trading Data API user |
| TAPIUser | GRANT EXECUTE | Application User | Trading API checks before allowing redemption requests |
| PortfolioAlignmentService | GRANT EXECUTE | Application User | Portfolio alignment checks redemption availability |
| TradingSettingsAPI | GRANT EXECUTE | Application User | Settings API exposes redemption availability to frontends |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetIsRedeemAllowed (procedure)
+-- Maintenance.Feature (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | SELECT WHERE FeatureID=52 to read the redemption feature flag |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| TradingEquityCalculator | Application User | Calls to check redemption availability |
| TDAPIUser / TDAPIUserProd | Application User | Calls to gate redemption workflows |
| TAPIUser | Application User | Calls to validate redemption requests |
| PortfolioAlignmentService | Application User | Calls during portfolio alignment |
| TradingSettingsAPI | Application User | Calls to expose flag to clients |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check if redemption is currently allowed

```sql
EXEC Trade.GetIsRedeemAllowed;
```

### 8.2 Check the raw feature flag with description

```sql
SELECT  FeatureID,
        Value,
        Description
FROM    Maintenance.Feature WITH (NOLOCK)
WHERE   FeatureID = 52;
```

### 8.3 Check all trading-related feature flags

```sql
SELECT  FeatureID,
        Value,
        Description
FROM    Maintenance.Feature WITH (NOLOCK)
WHERE   Description LIKE '%redeem%'
        OR Description LIKE '%allowed%'
ORDER BY FeatureID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Confluence search returned tangentially related pages (Credit Lines, transfer-related test plans) with no direct reference to the redemption feature flag.

---

*Generated: 2026-03-16 | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetIsRedeemAllowed | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetIsRedeemAllowed.sql*
