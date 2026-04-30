# Trade.Provider

> Master table of trading execution providers that route customer CFD positions to backend liquidity venues (e.g., Tradonomi, Interactive Brokers).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ProviderID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (PK + unique Name) |

---

## 1. Business Meaning

Trade.Provider is the registry of trading execution providers - the backend systems that execute customer CFD trades. Each row represents one provider (e.g., Tradonomi, Interactive Brokers) that eToro routes positions to for hedging and execution. The table holds provider identity, commission rates, configuration XML, and flags that control funding and execution behavior.

This table exists because eToro uses multiple execution providers for different products and regions. Without it, the system cannot determine which provider executes an instrument, what commission to apply, or whether special funding rules (e.g., IsIB) apply. Trade.ProviderToInstrument links providers to instruments; Trade.PositionTbl stores ProviderID per position; hedge exposure queries filter by IsActive providers.

Data is created and maintained by back-office/admin procedures. The table is read by Trade.GetProvider (active providers only), Trade.GetProviderToInstrument, hedge exposure procedures (HedgeExposureQuery, HedgeExposureQueryWithActiveParent), pip value functions (History.GetOnePipValueDollarForDealing, Internal.GetOnePipValueDollar, etc.), and Billing procedures for withdrawal/cashout routing.

---

## 2. Business Logic

### 2.1 IsIB - Introducing Broker / Special Funding Routing

**What**: Distinguishes providers that use virtual deposits and different withdrawal flows from standard execution providers.

**Columns/Parameters Involved**: `IsIB`

**Rules**:
- IsIB = 1: Provider is an Introducing Broker (IB) or Interactive Brokers-style provider. Used in Billing.CashoutProcess, Billing.WithdrawRequestAdd, Billing.WithdrawToFundingUpdate, Billing.CustomerRemove, etc., to route withdrawals and cashouts differently. Virtual deposits (CreditTypeID=1) are handled specially when IsIB=1; balance updates may skip certain operations.
- IsIB = 0: Standard provider (e.g., Tradonomi). Customer.SynchronizeAccount filters TPRV.IsIB = 0; BackOffice.SanityCheck excludes IsIB=1 providers from certain checks.

**Diagram**:
```
IsIB=0 (Tradonomi) -> Standard withdrawal flow, normal sync
IsIB=1 (IB)       -> Virtual deposit logic, special cashout/withdraw routing
```

### 2.2 Occuracy - Decimal Precision for Pip Calculations

**What**: Number of decimal places used when rounding pip value and P&L calculations (typo for "Accuracy").

**Columns/Parameters Involved**: `Occuracy`

**Rules**:
- Default 3 (TPRV_OCCURACY constraint). Stored values observed: 6 for Tradonomi.
- Used in History.GetOnePipValueDollarForDealing, History.GetOnePipValueDollar, History.GetOnePipValueDollarHedge, Internal.GetOnePipValueDollar, Internal.GetOnePipValueDollarOnLine: `SELECT @Occuracy = Occuracy FROM Trade.Provider WHERE ProviderID = @ProviderID` then `RETURN ROUND(@Result, @Occuracy)`.
- Higher Occuracy = more decimal precision in dollar pip value results.

---

## 3. Data Overview

| ProviderID | Name | Occuracy | Commission | IsIB | IsActive | Meaning |
|------------|------|----------|------------|------|----------|---------|
| 1 | TRADONOMI | 6 | 0 | 0 | 1 | Primary CFD execution provider. Standard flow (IsIB=0), 6-decimal pip precision, zero commission. Configuration holds LotSize, DefaultLeverage, WebLink, and Tradonomi connection settings. |

**Selection criteria**: Single row returned from live query. Table is small; ProviderID=0 is excluded by GetProvider view.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | NO | - | CODE-BACKED | Primary key. Referenced by Trade.ProviderToInstrument, Trade.PositionTbl, Trade.PositionRequest. ProviderID=0 is system placeholder (excluded from Trade.GetProvider). |
| 2 | Name | varchar(20) | NO | - | CODE-BACKED | Provider display name (e.g., TRADONOMI). Unique per TPRV_NAME index. |
| 3 | Occuracy | int | NO | 3 | CODE-BACKED | Decimal precision for pip value rounding (typo for Accuracy). Used in ROUND(@Result, @Occuracy) by History.GetOnePipValueDollarForDealing, Internal.GetOnePipValueDollar, etc. Default 3. |
| 4 | Commission | dbo.dtPercentage | NO | - | CODE-BACKED | Commission percentage (decimal(5,2)). 0 = no commission. |
| 5 | Configuration | xml | YES | - | CODE-BACKED | Provider-specific XML (LotSize, DefaultLeverage, AvailableBet, UserName, WebLink, AccountLeverage, etc.). Drives connection and trading parameters. |
| 6 | IsIB | bit | NO | - | CODE-BACKED | 1 = Introducing Broker / Interactive Brokers - special withdrawal, cashout, and virtual deposit handling in Billing procedures. 0 = standard provider (e.g., Tradonomi). |
| 7 | IsActive | bit | NO | - | CODE-BACKED | 1 = active provider. Trade.GetProvider and Trade.GetProviderToInstrument filter WHERE IsActive=1. HedgeExposureQuery uses P.IsActive=1 when resolving Unit from ProviderToInstrument. |
| 8 | Description | varchar(100) | YES | - | NAME-INFERRED | Optional human-readable description of the provider. |
| 9 | Passport | timestamp | NO | - | CODE-BACKED | Row version for optimistic concurrency. Automatically maintained by SQL Server. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ProviderToInstrument | ProviderID | FK | Per-instrument provider settings (precision, fees, leverage). FK_TPVI_TSPRV. |
| Trade.PositionTbl | ProviderID | Implicit | Provider that executed the position. |
| Trade.PositionRequest | ProviderID | Implicit | Provider for position request. |
| Trade.ProviderInstrumentToLeverage | ProviderID | Implicit (via ProviderToInstrument) | Leverage config per provider-instrument. |
| Trade.ProviderInstrumentToLotCount | ProviderID | Implicit (via ProviderToInstrument) | Lot count config per provider-instrument. |
| Trade.ProviderMarginMarkupByInstrument | ProviderID | Implicit | Margin markup per provider-instrument. |
| Trade.GetProvider | - | JOIN | Base table; filters ProviderID != 0 AND IsActive=1. |
| Trade.GetProviderToInstrument | - | JOIN | JOINs Trade.Provider for active provider check. |
| Trade.HedgeExposureQuery | - | JOIN | JOINs ProviderToInstrument and Provider WHERE IsActive=1. |
| History.GetOnePipValueDollarForDealing | @ProviderID | Lookup | Reads Occuracy for ROUND. |
| Internal.GetOnePipValueDollar | @ProviderID | Lookup | Reads Occuracy for ROUND. |
| Billing.CashoutProcess, WithdrawRequestAdd, etc. | - | JOIN | Filter TPRV.IsIB=1 for IB withdrawal routing. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.Provider (table)
(no code-level dependencies - leaf node)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | FK ProviderID -> Trade.Provider(ProviderID) |
| Trade.GetProvider | View | FROM Trade.Provider |
| Trade.GetProviderToInstrument | View | INNER JOIN Trade.Provider on ProviderID |
| Trade.HedgeExposureQuery | Procedure | JOINs ProviderToInstrument and Provider |
| Trade.HedgeExposureQueryWithActiveParent | Procedure | JOINs ProviderToInstrument and Provider |
| Trade.HedgeExposureQuery_Org | Procedure | JOINs ProviderToInstrument and Provider |
| History.GetOnePipValueDollarForDealing | Function | SELECT Occuracy WHERE ProviderID=@ProviderID |
| History.GetOnePipValueDollar | Function | SELECT Occuracy WHERE ProviderID=@ProviderID |
| Internal.GetOnePipValueDollar | Function | SELECT Occuracy WHERE ProviderID=@ProviderID |
| Internal.GetOnePipValueDollarOnLine | Function | SELECT Occuracy WHERE ProviderID=@ProviderID |
| Billing.CashoutProcess, WithdrawRequestAdd, WithdrawToFundingUpdate, etc. | Procedure | JOIN Trade.Provider TPRV for IsIB filtering |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TPRV | CLUSTERED | ProviderID | - | - | Active |
| TPRV_NAME | NC (UNIQUE) | Name | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TPRV | PK | Primary key on ProviderID |
| TPRV_NAME | UNIQUE | Name must be unique |
| TPRV_OCCURACY | DEFAULT | Occuracy defaults to 3 |

---

## 8. Sample Queries

### 8.1 List all active providers with commission
```sql
SELECT ProviderID,
       Name,
       Commission,
       IsIB,
       IsActive,
       Description
  FROM Trade.Provider WITH (NOLOCK)
 WHERE ProviderID != 0
   AND IsActive = 1
 ORDER BY ProviderID
```

### 8.2 Get provider configuration for Tradonomi
```sql
SELECT ProviderID,
       Name,
       Configuration,
       Occuracy,
       Commission
  FROM Trade.Provider WITH (NOLOCK)
 WHERE Name = 'TRADONOMI'
```

### 8.3 List IB providers (special withdrawal routing)
```sql
SELECT P.ProviderID,
       P.Name,
       P.Commission,
       P.IsActive
  FROM Trade.Provider P WITH (NOLOCK)
 WHERE P.IsIB = 1
   AND P.IsActive = 1
 ORDER BY P.ProviderID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.8/10 (Elements: 8.9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8+ analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Provider | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.Provider.sql*
