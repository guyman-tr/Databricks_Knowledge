# Billing.GetMIDDescriptionV2

> Simplified variant of `Billing.GetMIDDescription` that resolves the merchant identifier (MID) and description for a deposit or cashout transaction; functionally equivalent but removes the eToroMoney channel branch and allows a nullable Description return.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Multi-Statement Table-Valued Function (MSTVF) |
| **Key Identifier** | Returns TABLE(MID, Description) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetMIDDescriptionV2` is a revised version of `Billing.GetMIDDescription` that resolves the merchant identifier (MID) and back-office description for a payment transaction. It uses the same two-step approach: first resolving the transaction context (deposit or cashout), then applying a decision tree based on FundingTypeID and available MID configuration.

The V2 variant was created to address two changes: (1) eToroMoney (FundingTypeID=33) was removed from the decision tree, and (2) the Description return column is nullable rather than forced NOT NULL. As of the current codebase, this function has **no callers** - it is not referenced by any stored procedure or view. It appears to be an intermediate or planned replacement that was not deployed into production use.

The original `Billing.GetMIDDescription` remains the active version used by all BI reporting stored procedures (BI_Deposit_State_Report, BI_Cashout_State_Report, and PIPS reports). See `Billing.GetMIDDescription` for the full business context and decision tree documentation.

---

## 2. Business Logic

### 2.1 Differences from GetMIDDescription (V1)

**What**: V2 makes three key changes relative to the V1 function.

**Columns/Parameters Involved**: `@FundingTypeID`, `@ProtocolMIDSettingsID`, `@MerchantAccountID`

**Rules**:
- **eToroMoney branch removed**: V1 had a dedicated branch for FundingTypeID=33 (eToroMoney) with eToroMoneyUK/eToroMoneyEU resolution. V2 removes this branch entirely - eToroMoney transactions fall through to the default branch.
- **WireTransfer guard removed**: V1 checked `@ProtocolMIDSettingsID <> 0 AND @ProtocolMIDSettingsID is not null` before entering the WireTransfer branch. V2 enters the WireTransfer branch unconditionally for FundingTypeID=2, querying ProtocolMIDSettings with whatever ID is present (may return NULL).
- **Description return nullable**: V1 returns Description as NOT NULL (depot name fallback). V2 returns Description as NULL-able; the final COALESCE is `COALESCE(@Description, @RegulationName)` without the final DepotName fallback - Description can be NULL if neither is resolved.

**Diagram**:
```
V1 vs V2 Decision Tree Differences:

WireTransfer(2):
  V1: Only enters branch if ProtocolMIDSettingsID IS SET
  V2: Always enters branch for FundingTypeID=2 (unconditional)

eToroMoney(33):
  V1: Dedicated branch -> eToroMoneyUK or eToroMoneyEU
  V2: Branch does not exist -> falls to default

Default fallback (Description):
  V1: COALESCE(@Description, @RegulationName, @DepotName) -> always NOT NULL
  V2: COALESCE(@Description, @RegulationName) -> can be NULL
```

### 2.2 MID Resolution Decision Tree (V2)

**What**: Same priority-ordered decision tree as V1, minus the eToroMoney branch.

**Columns/Parameters Involved**: `@FundingTypeID`, `@ProtocolMIDSettingsID`, `@MerchantAccountID`, `@RegulationID`, `@CurrencyID`

**Rules**:
- WireTransfer (FundingTypeID=2): query Billing.ProtocolMIDSettings by ProtocolMIDSettingsID (unconditional).
- Redeem (FundingTypeID=27): return 'N/A' for both MID and Description.
- Giropay (FundingTypeID=11): read Dictionary.MerchantAccount WHERE MerchantID=10 (hardcoded; known data gap).
- Skrill (FundingTypeID=8) AND Cashout AND no MerchantAccountID: same fallback chain as V1 (recent deposit lookup, then regulation-based resolution).
- No ProtocolMIDSettingsID AND has MerchantAccountID: direct Dictionary.MerchantAccount lookup.
- Default: COALESCE from ProtocolMIDSettings/MerchantAccount; final `COALESCE(@MIDID, @DepotName)`, `COALESCE(@Description, @RegulationName)`.

---

## 3. Data Overview

N/A for Multi-Statement Table-Valued Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ActionID | INT | NO | - | CODE-BACKED | Transaction identifier. Interpreted as DepositID when @PaymentType=1, or as WithdrawToFunding.ID when @PaymentType=2. Identical semantics to V1. |
| 2 | @PaymentType | INT | NO | - | CODE-BACKED | Payment direction: 1=Deposit (reads Billing.Deposit), 2=Cashout (reads Billing.WithdrawToFunding). Identical semantics to V1. |
| 3 | MID (return) | varchar(100) | NO | - | CODE-BACKED | Resolved merchant identifier code. NOT NULL: COALESCE(@MIDID, @DepotName) ensures a value. Same resolution as V1 except eToroMoney branch removed. |
| 4 | Description (return) | nvarchar(250) | YES | - | CODE-BACKED | Back-office description of the merchant channel. **Nullable in V2** (changed from NOT NULL in V1). Final fallback is COALESCE(@Description, @RegulationName) - no DepotName fallback for Description, so can return NULL if neither is available. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ActionID (Deposit path) | Billing.Deposit | Lookup | Same as V1: reads CID, ProtocolMIDSettingsID, MerchantAccountID, DepotID, CurrencyID, ProcessRegulationID |
| @ActionID (Deposit path) | Billing.Funding | Lookup | JOINed to resolve FundingTypeID |
| @ActionID (Deposit path) | Billing.Depot | Lookup | JOINed to resolve depot name |
| @ActionID (Deposit path) | Dictionary.Regulation | Lookup | LEFT JOINed to resolve regulation name |
| @ActionID (Cashout path) | Billing.WithdrawToFunding | Lookup | Same as V1: reads transaction data for cashouts |
| @ActionID (Cashout path) | Billing.Withdraw | Lookup | JOINed to get CID |
| @ActionID (Cashout path) | BackOffice.Customer | Lookup | JOINed to get RegulationID for cashout |
| MID resolution | Billing.ProtocolMIDSettings | Lookup | Primary MID source |
| MID resolution | Billing.MapMerchantCodeToMid | Lookup | LEFT JOINed to ProtocolMIDSettings for BMMC.MID |
| MID resolution | Dictionary.MerchantAccount | Lookup | Used for Giropay (MerchantID=10 hardcoded) and MerchantAccountID direct lookups |
| Skrill fallback | Billing.Deposit | Lookup | Secondary query for most recent successful deposit for Skrill cashout fallback |

### 5.2 Referenced By (other objects point to this)

No dependents found. This function has no callers in the codebase as of the current SSDT snapshot. It appears to be an inactive or planned replacement for `Billing.GetMIDDescription`.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetMIDDescriptionV2 (function)
|- Billing.Deposit (table) [deposit path and Skrill fallback - leaf]
|- Billing.Funding (table) [deposit and cashout paths - leaf]
|- Billing.Depot (table) [depot name fallback - leaf]
|- Dictionary.Regulation (table) [regulation name resolution - leaf]
|- Billing.WithdrawToFunding (table) [cashout path - leaf]
|- Billing.Withdraw (table) [cashout path - leaf]
|- BackOffice.Customer (table) [cashout path regulation source - leaf]
|- Billing.ProtocolMIDSettings (table) [MID source - leaf]
|- Billing.MapMerchantCodeToMid (table) [MID code mapping - leaf]
|- Dictionary.MerchantAccount (table) [Giropay and MerchantAccountID lookup - leaf]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | FROM/JOIN in deposit path; also Skrill cashout fallback query |
| Billing.Funding | Table | JOINed to resolve FundingTypeID |
| Billing.Depot | Table | JOINed to resolve depot name (MID fallback) |
| Dictionary.Regulation | Table | LEFT JOINed to resolve regulation name |
| Billing.WithdrawToFunding | Table | FROM/JOIN in cashout path |
| Billing.Withdraw | Table | JOINed to get CID in cashout path |
| BackOffice.Customer | Table | JOINed in cashout path for RegulationID |
| Billing.ProtocolMIDSettings | Table | MID resolution for WireTransfer and default branches |
| Billing.MapMerchantCodeToMid | Table | LEFT JOINed to ProtocolMIDSettings for BMMC.MID |
| Dictionary.MerchantAccount | Table | Giropay (MerchantID=10 hardcoded) and direct MerchantAccountID lookups |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Multi-Statement Table-Valued Function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| MID NOT NULL | Return column | MID is NOT NULL in return table; COALESCE(@MIDID, @DepotName) ensures a value |
| Description NULL | Return column | Description is nullable in V2 (changed from NOT NULL in V1); can be NULL if neither @Description nor @RegulationName is resolved |

---

## 8. Sample Queries

### 8.1 Resolve MID for a deposit (using V2)

```sql
SELECT m.MID, m.Description
FROM Billing.Deposit WITH (NOLOCK) AS d
CROSS APPLY Billing.GetMIDDescriptionV2(d.DepositID, 1) AS m
WHERE d.DepositID = 123456
```

### 8.2 Compare V1 and V2 output for the same deposit

```sql
SELECT
    d.DepositID,
    v1.MID AS MID_V1, v1.Description AS Desc_V1,
    v2.MID AS MID_V2, v2.Description AS Desc_V2
FROM Billing.Deposit WITH (NOLOCK) AS d
CROSS APPLY Billing.GetMIDDescription(d.DepositID, 1) AS v1
CROSS APPLY Billing.GetMIDDescriptionV2(d.DepositID, 1) AS v2
WHERE d.DepositID IN (100, 200, 300)
```

### 8.3 Identify cases where V2 Description would be NULL (highlighting the difference)

```sql
SELECT
    d.DepositID,
    v1.Description AS V1_Desc,
    v2.Description AS V2_Desc_Nullable
FROM Billing.Deposit WITH (NOLOCK) AS d
CROSS APPLY Billing.GetMIDDescription(d.DepositID, 1) AS v1
CROSS APPLY Billing.GetMIDDescriptionV2(d.DepositID, 1) AS v2
WHERE v2.Description IS NULL
  AND v1.Description IS NOT NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetMIDDescriptionV2 | Type: Multi-Statement Table-Valued Function | Source: etoro/etoro/Billing/Functions/Billing.GetMIDDescriptionV2.sql*
