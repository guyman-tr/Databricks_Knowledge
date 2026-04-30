# Billing.GetAccountHistory

> Retrieves the complete audit history of a Billing.Account record by AccountID from the History.Account temporal table.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @AccountID INTEGER - PK of Billing.Account |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetAccountHistory` is the history retrieval companion to `Billing.Account`. It queries `History.Account` - the temporal audit table that records every state change to a customer's Billing.Account record over time. Each row in `History.Account` captures a point-in-time snapshot with `ValidFrom`/`ValidTo` timestamps defining the period during which that state was active.

`Billing.Account` was the legacy customer account balance table, predating `Customer.CustomerMoney` as the authoritative balance source (see `Billing.GetAccount`, which is now a stub). The History table persists the full change log even though the live table is largely superseded. This procedure supports compliance audit, dispute resolution, and forensic analysis of historical account states.

The procedure performs a full `SELECT *` - returning all columns from `History.Account` without filtering by date range. Callers receive the complete lifecycle of that account record, from creation to the most recent state.

---

## 2. Business Logic

### 2.1 Full Account Lifecycle Retrieval

**What**: Returns all historical rows for a given AccountID, ordered implicitly by `ValidFrom`.

**Columns/Parameters Involved**: `@AccountID`, `History.Account.*`

**Rules**:
- `SELECT * FROM History.Account WITH (NOLOCK) WHERE AccountID = @AccountID`: retrieves every audit row for the account.
- No date filter - returns the complete history from the oldest to the most recent snapshot.
- `WITH (NOLOCK)`: dirty-read hint for the history table, acceptable given the append-only nature of audit tables.
- `RETURN 0`: always returns 0 regardless of rows found. Callers must check the result set for presence of rows.
- If `@AccountID` has no rows in History.Account (e.g., account was never modified or predates history capture), returns an empty result set.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AccountID | INTEGER | NO | - | CODE-BACKED | PK of the Billing.Account record whose history is requested. Passed directly to WHERE AccountID = @AccountID in History.Account. |

**Return columns** (all columns from History.Account):

| # | Column | Type | Confidence | Description |
|---|--------|------|------------|-------------|
| R1 | AccountID | INTEGER | CODE-BACKED | PK of the Billing.Account row. Same as @AccountID parameter. |
| R2 | ValidFrom | DATETIME2 | CODE-BACKED | Timestamp when this state became active (row was inserted or previous state ended). |
| R3 | ValidTo | DATETIME2 | CODE-BACKED | Timestamp when this state was superseded. Open row has ValidTo = '9999-12-31' or '3000-01-01'. |
| R4+ | (all Billing.Account columns) | various | CODE-BACKED | Full snapshot of the Billing.Account row as it existed between ValidFrom and ValidTo. Includes CID, CurrencyID, balance fields, and any other Account columns at time of history capture. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AccountID | History.Account | Reader | SELECT * WHERE AccountID = @AccountID - retrieves full history |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Account management / audit tools | External | Caller | Called by back-office or compliance tooling to retrieve account change history for dispute/audit |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetAccountHistory (procedure)
└── History.Account (temporal/audit table) [cross-schema]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Account | Table (cross-schema audit) | SELECT * WHERE AccountID = @AccountID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Account audit tooling | External | Called to retrieve full change history for a Billing.Account record |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. Uses SELECT * with WITH (NOLOCK). RETURN 0. No SET NOCOUNT ON. No TRY/CATCH. No transaction. No date filter - returns full history.

---

## 8. Sample Queries

### 8.1 Retrieve full account history

```sql
EXEC [Billing].[GetAccountHistory]
    @AccountID = 12345;
-- Returns all History.Account rows for AccountID 12345, ordered by ValidFrom implicitly
```

### 8.2 View history with explicit date range (ad-hoc without the SP)

```sql
SELECT *
FROM [History].[Account] WITH (NOLOCK)
WHERE AccountID = 12345
  AND ValidFrom >= '2023-01-01'
  AND ValidTo > '2023-01-01'
ORDER BY ValidFrom;
```

### 8.3 Find current state from history

```sql
SELECT *
FROM [History].[Account] WITH (NOLOCK)
WHERE AccountID = 12345
  AND ValidTo >= '9999-12-31'; -- or '3000-01-01' depending on sentinel used
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 8/10, Logic: 7/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetAccountHistory | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetAccountHistory.sql*
