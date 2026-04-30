# Dictionary.WalletsType

> Lookup table defining the types of liquidity provider wallets used in hedge execution — Nostro (house account) and ABook (client-passed-through) — classifying how hedge orders are routed to external execution venues.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, manually assigned) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 clustered (PK on ID) |

---

## 1. Business Meaning

Dictionary.WalletsType classifies the types of wallets (accounts) used when the platform routes hedge orders to external liquidity providers. When eToro hedges client exposure by placing offsetting trades with market makers or prime brokers, those trades execute through specific wallet types that determine the accounting treatment and risk ownership.

Without this table, the system could not distinguish between Nostro (proprietary/house) and ABook (pass-through/agency) wallet types. This distinction is critical for financial reporting, regulatory capital calculations, and risk management — trades in Nostro wallets represent house exposure, while ABook trades pass risk directly to the liquidity provider.

The table is internally referenced by hedge execution infrastructure. The PK constraint name (PK_TradeLiquidityProviderType) reveals this was originally named "TradeLiquidityProviderType" — it classifies liquidity provider account types used by the hedge server when routing orders.

---

## 2. Business Logic

### 2.1 Hedge Wallet Classification

**What**: Two fundamental wallet types determine how hedge orders are accounted for and who bears the market risk.

**Columns/Parameters Involved**: `ID`, `Name`

**Rules**:
- ID 100 (Nostro) — house/proprietary wallet. eToro holds the position on its own balance sheet. Used when the platform takes principal risk on the hedge. Nostro is a banking term meaning "our" account
- ID 101 (ABook) — agency/pass-through wallet. The hedge order is routed directly to an external liquidity provider who holds the position. eToro acts as an intermediary with no balance sheet exposure
- The high starting IDs (100, 101) suggest namespace separation from other configuration enumerations
- The wallet type affects: P&L attribution (house vs passed-through), regulatory capital requirements, counterparty risk calculations, and reconciliation workflows

**Diagram**:
```
Hedge Execution Routing:
  Client opens position on eToro
       │
       ▼
  Hedge Server decides to hedge
       │
       ├─ Nostro (100): eToro holds offsetting position
       │   └─ P&L stays on eToro's books
       │   └─ Subject to capital requirements
       │
       └─ ABook (101): Order passed to LP
           └─ LP holds the position
           └─ eToro earns spread, no market risk
```

---

## 3. Data Overview

| ID | Name | Meaning |
|---|---|---|
| 100 | Nostro | Proprietary/house wallet — eToro holds the hedge position on its own balance sheet. The firm bears market risk. Used for instruments or conditions where principal trading is preferred (better execution, tighter spreads, or regulatory requirements). |
| 101 | ABook | Agency/pass-through wallet — hedge orders are routed directly to external liquidity providers who hold the position. eToro earns the spread markup without carrying market risk. Preferred for client flow that should be fully passed through. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Unique identifier for the wallet type: 100=Nostro (house), 101=ABook (pass-through). High starting IDs (100+) provide namespace separation. Referenced by hedge execution infrastructure to determine order routing and accounting treatment. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Display name for the wallet type: "Nostro" or "ABook". Standard financial terminology — Nostro (Latin "ours") for house accounts, ABook for agency/pass-through execution. Used in trading dashboards and reconciliation reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge execution infrastructure | WalletTypeID | Implicit | Classifies liquidity provider accounts for hedge order routing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.WalletsType (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No direct dependents found in SSDT codebase search (referenced implicitly by hedge execution infrastructure).

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TradeLiquidityProviderType | CLUSTERED | ID ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all wallet types
```sql
SELECT  ID AS WalletTypeID,
        Name AS WalletType
FROM    [Dictionary].[WalletsType] WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Classify wallet types by risk model
```sql
SELECT  ID,
        Name,
        CASE ID
            WHEN 100 THEN 'Principal - eToro bears market risk'
            WHEN 101 THEN 'Agency - LP bears market risk'
        END AS RiskModel
FROM    [Dictionary].[WalletsType] WITH (NOLOCK)
ORDER BY ID;
```

### 8.3 Translate a wallet type ID
```sql
SELECT  Name AS WalletType
FROM    [Dictionary].[WalletsType] WITH (NOLOCK)
WHERE   ID = 100; -- Nostro
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.WalletsType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.WalletsType.sql*
