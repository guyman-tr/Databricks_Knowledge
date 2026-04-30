# Billing.UnionPaySupportedBanksGet

> Returns the list of active UnionPay banks (name + terminal) that customers can select when initiating a UnionPay deposit, by joining the three-table UnionPay routing configuration.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; returns a result set of active (BankID, BankAbbreviation, TerminalName) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UnionPaySupportedBanksGet` is the deposit setup query that populates the bank selection UI for UnionPay deposits. When a customer chooses UnionPay as their deposit method, the front-end or deposit service calls this procedure to get the list of Chinese banks the customer can select. Only banks that are active in the routing matrix - active in UnionPayBanks, routed to an active terminal in UnionPayRouting, and with a valid non-zero BankID - are returned.

This procedure was created as part of the Deposit Setup service creation (PAYIL-4442, June 2022). The DepositSetupUser role has EXECUTE permission, confirming it is called by the deposit setup service.

**Important current state**: Due to the current routing configuration, this procedure returns 0 rows. The only active routing entry (Zotapay, BankID=0) is excluded by the `BankID <> 0` filter. This means UnionPay is currently configured as a generic payment method without bank selection - customers do not see a bank list when using UnionPay via Zotapay. BaoFoo's 20 bank-specific routings are active at the routing level but BaoFoo's terminal itself is inactive.

---

## 2. Business Logic

### 2.1 Three-Layer Active Filter

**What**: A bank is only returned if it is simultaneously active at the routing level, the terminal level, and the bank level - all three flags must be true.

**Columns/Parameters Involved**: `UnionPayRouting.IsActive`, `UnionPayTerminal.IsActive`, `UnionPayBanks.IsActive`, `UnionPayBanks.BankID`

**Rules**:
- `UnionPayRouting.IsActive = 1`: the routing assignment (bank->terminal) is enabled
- `UnionPayTerminal.IsActive = 1`: the terminal provider is currently operational
- `UnionPayBanks.IsActive = 1`: the bank itself is enabled for selection
- `BankID <> 0`: BankID=0 is the catch-all/unknown sentinel used when no specific bank is required; it is excluded from bank selection lists
- All four conditions must be satisfied; any inactive component removes the bank from the list

**Diagram**:
```
UnionPayBanks (bank catalog)
    |
    | BankID JOIN
    v
UnionPayRouting (which banks route to which terminal)  -- IsActive=1 filter
    |
    | TerminalID JOIN
    v
UnionPayTerminal (terminal provider: BaoFoo/RichFoo/Zotapay)  -- IsActive=1 filter
    |
UnionPayBanks filter: IsActive=1 AND BankID<>0
    |
    v
Result: list of (BankID, BankAbbreviation, TerminalName) for customer bank selection

Current state (as of 2026-03-18): returns 0 rows
  - BaoFoo: 20 active bank routings but BaoFoo terminal IsActive=0 -> excluded
  - RichFoo: IsActive=0 on all routings -> excluded
  - Zotapay: BankID=0 only -> excluded by BankID<>0 filter
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

This procedure has no input parameters; it returns a result set.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| OUT1 | BankID | INT | NO | - | CODE-BACKED | Identifier of the selectable bank. Sourced from `Billing.UnionPayBanks.BankID`. BankID=0 is excluded (catch-all sentinel). Non-zero IDs represent specific Chinese bank institutions (ICBC, ABC, BOC, CCB, etc.). |
| OUT2 | BankAbbreviation | VARCHAR | NO | - | CODE-BACKED | Short name/code of the bank as displayed in the UI (e.g., "ICBC", "ABC", "BOC"). Sourced from `Billing.UnionPayBanks.BankAbbreviation`. |
| OUT3 | TerminalName | VARCHAR | NO | - | CODE-BACKED | Name of the UnionPay terminal provider processing transactions for this bank (e.g., "BaoFoo", "Zotapay", "RichFoo"). Sourced from `Billing.UnionPayTerminal.TerminalName`. Tells the calling service which payment gateway to route the deposit to. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN | Billing.UnionPayRouting | SELECT JOIN | Provides the active routing assignments (bank -> terminal); filtered to IsActive=1 |
| JOIN | Billing.UnionPayBanks | SELECT JOIN (via BankID) | Provides bank names and active status; filtered to IsActive=1 AND BankID<>0 |
| JOIN | Billing.UnionPayTerminal | SELECT JOIN (via TerminalID) | Provides terminal names and active status; filtered to IsActive=1 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Deposit Setup service | - | EXEC (DepositSetupUser role) | Called when loading the UnionPay bank selection list for the deposit flow |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UnionPaySupportedBanksGet (procedure)
├── Billing.UnionPayRouting (table)
├── Billing.UnionPayBanks (table)
└── Billing.UnionPayTerminal (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.UnionPayRouting | Table | SELECT FROM - provides routing assignments; filtered to IsActive=1 |
| Billing.UnionPayBanks | Table | INNER JOIN on BankID - provides bank names; filtered to IsActive=1 AND BankID<>0 |
| Billing.UnionPayTerminal | Table | INNER JOIN on TerminalID - provides terminal names; filtered to IsActive=1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found in SSDT. | - | Called externally by Deposit Setup service (DepositSetupUser role). |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Note: All joins use WITH (NOLOCK) for non-blocking reads of the configuration tables.

---

## 8. Sample Queries

### 8.1 Execute the procedure to see current supported banks
```sql
EXEC Billing.UnionPaySupportedBanksGet;
-- Currently returns 0 rows due to Zotapay BankID=0 configuration
```

### 8.2 Diagnose why no banks are returned
```sql
-- Check routing activity by terminal
SELECT
    t.TerminalName,
    t.IsActive AS TerminalActive,
    r.BankID,
    b.BankAbbreviation,
    b.IsActive AS BankActive,
    r.IsActive AS RoutingActive
FROM Billing.UnionPayRouting r WITH (NOLOCK)
INNER JOIN Billing.UnionPayBanks b WITH (NOLOCK) ON r.BankID = b.BankID
INNER JOIN Billing.UnionPayTerminal t WITH (NOLOCK) ON r.TerminalID = t.TerminalID
ORDER BY t.TerminalName, r.BankID;
```

### 8.3 Count potential banks per terminal if terminal were activated
```sql
SELECT
    t.TerminalName,
    t.IsActive AS TerminalActive,
    COUNT(CASE WHEN r.IsActive=1 AND b.IsActive=1 AND b.BankID<>0 THEN 1 END) AS PotentialBanksIfActive
FROM Billing.UnionPayRouting r WITH (NOLOCK)
INNER JOIN Billing.UnionPayBanks b WITH (NOLOCK) ON r.BankID = b.BankID
INNER JOIN Billing.UnionPayTerminal t WITH (NOLOCK) ON r.TerminalID = t.TerminalID
GROUP BY t.TerminalName, t.IsActive
ORDER BY t.TerminalName;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PAYIL-4442: DB STG + PROD Required updates](https://etoro-jira.atlassian.net/browse/PAYIL-4442) | Jira | Confirms SP was created 2022-06-26 as part of the Deposit Setup service creation (parent: PAYIL-4367). Assigned to Shay Oren, reported by Elrom Behar. |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 1 Jira (PAYIL-4442) | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.UnionPaySupportedBanksGet | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UnionPaySupportedBanksGet.sql*
