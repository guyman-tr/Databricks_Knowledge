# Billing.GetWithdrawToFundingByID

> Single-record lookup for Billing.WithdrawToFunding by primary key: returns ID, WithdrawID, FundingID, Amount, and DepotID for the specified WithdrawToFunding record.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawToFundingID; returns one row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetWithdrawToFundingByID is a simple primary key lookup for `Billing.WithdrawToFunding`. It retrieves the key fields of a single withdrawal-to-funding routing record: which withdrawal it belongs to (WithdrawID), which funding method it uses (FundingID), the routed amount, and which payment depot processed it (DepotID).

Called when a caller has a WithdrawToFundingID (e.g., from a scheduled task or notification) and needs the full routing context to process or validate the withdrawal.

---

## 2. Business Logic

### 2.1 Primary Key Lookup

**What**: Direct equality filter on Billing.WithdrawToFunding.ID.

**Columns/Parameters Involved**: `@WithdrawToFundingID`, `Billing.WithdrawToFunding.ID`

**Rules**:
- `WHERE ID = @WithdrawToFundingID` - exact match on primary key
- Returns at most 1 row
- No NOLOCK - reads committed data

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawToFundingID | INT | NO | - | CODE-BACKED | Primary key of the WithdrawToFunding record to retrieve. |
| - | ID | INT | NO | - | CODE-BACKED | Primary key of the record. Echoed from Billing.WithdrawToFunding.ID. |
| - | WithdrawID | INT | NO | - | CODE-BACKED | Foreign key to Billing.Withdraw. The parent withdrawal this funding routing belongs to. |
| - | FundingID | INT | NO | - | CODE-BACKED | Foreign key to Billing.Funding. The payment method (card, bank account, etc.) used for this withdrawal routing. |
| - | Amount | DECIMAL | YES | - | CODE-BACKED | Amount being routed to this funding method for the withdrawal. |
| - | DepotID | INT | YES | - | CODE-BACKED | Payment depot (terminal/MID) assigned to process this withdrawal-to-funding routing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ID, WithdrawID, FundingID, Amount, DepotID | Billing.WithdrawToFunding | SELECT (PK lookup) | Source record retrieved by primary key |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Withdrawal processing service | @WithdrawToFundingID | EXEC | Fetches routing context for a specific WithdrawToFunding record during withdrawal processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetWithdrawToFundingByID (procedure)
+-- Billing.WithdrawToFunding (table) [PK lookup]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | SELECT by primary key; returns routing fields |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Withdrawal processing service | External | Record lookup for withdrawal-to-funding routing context |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No NOLOCK | Concurrency | No WITH (NOLOCK) hint - reads committed data; ensures consistent routing data for processing |
| No NOCOUNT | Design | No SET NOCOUNT ON; returns row count message |

---

## 8. Sample Queries

### 8.1 Lookup a single WithdrawToFunding record

```sql
EXEC [Billing].[GetWithdrawToFundingByID] @WithdrawToFundingID = 12345
-- Returns: ID, WithdrawID, FundingID, Amount, DepotID (single row or empty)
```

### 8.2 Equivalent direct query

```sql
SELECT ID, WithdrawID, FundingID, Amount, DepotID
FROM [Billing].[WithdrawToFunding] WITH (NOLOCK)
WHERE ID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 8.5/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1,8,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.GetWithdrawToFundingByID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetWithdrawToFundingByID.sql*
