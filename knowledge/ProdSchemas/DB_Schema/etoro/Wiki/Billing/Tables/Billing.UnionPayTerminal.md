# Billing.UnionPayTerminal

> Registry of UnionPay payment terminal providers (acquirer gateways) used to process Chinese UnionPay deposits.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | TerminalID (INT, CLUSTERED PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 (PK only) |
| **Temporal** | No |

---

## 1. Business Meaning

Billing.UnionPayTerminal defines the terminal providers (payment gateways) used to process UnionPay transactions. Each terminal represents a different acquirer/gateway integration for the UnionPay payment network. When a customer selects UnionPay and a specific bank, the routing system uses Billing.UnionPayRouting to determine which terminal to send the transaction to.

**4 rows** - 3 terminals plus the "Unknown" sentinel:
- BaoFoo (TerminalID=1): Previously active UnionPay processor, now **inactive**
- RichFoo (TerminalID=2): Previously configured, now **inactive**
- Zotapay (TerminalID=3): **Currently active** terminal (Zotapay gateway)
- Unknown (TerminalID=0): Sentinel/default row, inactive

The transition from BaoFoo to Zotapay represents a migration of the UnionPay processing relationship.

---

## 2. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TerminalID | INT | NO | - | CODE-BACKED | Primary key. TerminalID=0=Unknown (sentinel), 1=BaoFoo (inactive), 2=RichFoo (inactive), 3=Zotapay (active). Referenced by Billing.UnionPayRouting. |
| 2 | TerminalName | VARCHAR(50) | NO | - | CODE-BACKED | Display name of the terminal provider. Values: "Unknown", "BaoFoo", "RichFoo", "Zotapay". Used in `UnionPaySupportedBanksGet` result to indicate which terminal services a bank. |
| 3 | IsActive | BIT | NO | - | CODE-BACKED | Whether this terminal is currently available for processing. Only Zotapay (TerminalID=3) is active=1. BaoFoo and RichFoo are inactive (decommissioned). `UnionPaySupportedBanksGet` filters on IsActive=1. |

---

## 3. Relationships

### 3.1 Referenced By

| Source Object | Relationship |
|--------------|-------------|
| Billing.UnionPayRouting | TerminalID - routes bank-to-terminal assignments |
| Billing.UnionPaySupportedBanksGet | READER - filters active terminals |

---

## 4. Technical Details

### 4.1 Indexes

| Index Name | Type | Key Columns | Status |
|-----------|------|-------------|--------|
| PK_Billing.UnionPayTerminal | CLUSTERED PK | TerminalID ASC | Active |

---

*Generated: 2026-03-17 | Enriched: - | Quality: 7.8/10 (Elements: 8.0/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.UnionPayTerminal | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.UnionPayTerminal.sql*
