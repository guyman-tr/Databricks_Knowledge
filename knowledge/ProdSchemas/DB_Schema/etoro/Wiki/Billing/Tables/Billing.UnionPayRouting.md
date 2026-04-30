# Billing.UnionPayRouting

> Junction table defining which Chinese banks are routed to which UnionPay terminal providers - the active routing configuration for UnionPay deposits.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, IDENTITY, CLUSTERED PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 (PK only) |
| **Temporal** | No |

---

## 1. Business Meaning

Billing.UnionPayRouting is the many-to-many junction table connecting Chinese banks (Billing.UnionPayBanks) to UnionPay terminal providers (Billing.UnionPayTerminal). A routing row with IsActive=1 means "transactions from bank X should be processed via terminal Y."

**49 rows** across 3 terminal configurations:
- TerminalID=2 (RichFoo): 26 rows, all IsActive=false (decommissioned routing)
- TerminalID=1 (BaoFoo): 20 bank rows, all IsActive=true - BUT BaoFoo terminal itself is inactive, so these don't route
- TerminalID=3 (Zotapay): 1 row (BankID=0 Unknown), IsActive=true - the currently active path but with no specific bank selection

`UnionPaySupportedBanksGet` JOINs all three tables filtering for all IsActive=1 AND BankID<>0, resulting in **0 selectable banks currently** - UnionPay bank selection is effectively disabled or pending configuration.

---

## 2. Business Logic

### 2.1 Active Routing Determination

**What**: `UnionPaySupportedBanksGet` uses this table to determine which banks a customer can select for UnionPay deposits.

**Rules**:
- A bank is selectable if: `UnionPayRouting.IsActive=1 AND UnionPayTerminal.IsActive=1 AND UnionPayBanks.IsActive=1 AND BankID<>0`
- Current state: Only TerminalID=3 (Zotapay) is active as a terminal
- Zotapay's only routing row uses BankID=0 (Unknown/catch-all), which is excluded by `BankID<>0`
- Effective result: no specific banks shown to customer; Zotapay handles UnionPay as a generic payment method without bank selection

---

## 3. Data Overview

| TerminalID | Terminal | Row Count | IsActive | Meaning |
|-----------|---------|-----------|----------|---------|
| 1 | BaoFoo | 20 (BankIDs 1-16, 18, 22, 25, 27, 28) | true | Bank-level routing active but terminal inactive - historical config for BaoFoo |
| 2 | RichFoo | 26 (BankIDs 1-26) | false | All routing disabled - RichFoo was fully decommissioned |
| 3 | Zotapay | 1 (BankID=0) | true | Generic/any-bank routing to Zotapay (no specific bank required) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | INT | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate PK. Auto-incremented. |
| 2 | TerminalID | INT | NO | - | CODE-BACKED | Terminal provider for this routing. Implicit FK to Billing.UnionPayTerminal(TerminalID). 1=BaoFoo, 2=RichFoo, 3=Zotapay. |
| 3 | BankID | INT | NO | - | CODE-BACKED | Chinese bank for this routing. Implicit FK to Billing.UnionPayBanks(BankID). BankID=0 means "any bank" / no specific bank required. |
| 4 | IsActive | BIT | NO | 0 | CODE-BACKED | Whether this specific bank-to-terminal routing is enabled. Default=0. Only rows where routing.IsActive=1 AND terminal.IsActive=1 AND bank.IsActive=1 AND BankID<>0 produce customer-visible banks. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type |
|---------|---------------|-------------------|
| TerminalID | Billing.UnionPayTerminal | Implicit FK (no DDL constraint) |
| BankID | Billing.UnionPayBanks | Implicit FK (no DDL constraint) |

### 5.2 Referenced By

| Source Object | Relationship |
|--------------|-------------|
| Billing.UnionPaySupportedBanksGet | READER - primary consumer, JOINs all three UnionPay tables |

---

## 6. Technical Details

### 6.1 Indexes

| Index Name | Type | Key Columns | Status |
|-----------|------|-------------|--------|
| PK_Billing.UnionPayRouting | CLUSTERED PK | ID ASC | Active |

---

## 7. Sample Query

```sql
-- Get currently active UnionPay bank-terminal combinations
SELECT ur.ID, ur.BankID, upb.BankAbbreviation, upb.Description,
       ur.TerminalID, upt.TerminalName, ur.IsActive AS RoutingActive
FROM [Billing].[UnionPayRouting] ur WITH (NOLOCK)
INNER JOIN [Billing].[UnionPayBanks] upb WITH (NOLOCK) ON upb.BankID = ur.BankID
INNER JOIN [Billing].[UnionPayTerminal] upt WITH (NOLOCK) ON upt.TerminalID = ur.TerminalID
ORDER BY ur.TerminalID, ur.BankID
```

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.0/10 (Elements: 8.0/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 6.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.UnionPayRouting | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.UnionPayRouting.sql*
