# BackOffice.GetTotalDepositsOfAllLinkedAccounts

> Returns the sum of all-time deposits for a list of CIDs - used to calculate the combined deposit exposure across linked/related customer accounts.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CIDs (table-valued, required); returns single SUM value from BackOffice.CustomerAllTimeAggregatedData |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetTotalDepositsOfAllLinkedAccounts` aggregates the total deposited amount across multiple customer accounts, returning a single `LinkedDeposits` sum. It is used in Back Office risk and fraud workflows where multiple accounts are identified as linked (same person, household, or device fingerprint), and the combined financial exposure must be evaluated. By passing a list of CIDs (typically all accounts linked to a risk subject), the caller gets the total deposits across all those accounts in a single call.

---

## 2. Business Logic

### 2.1 Sum of Total Deposits Across CID List

**What**: Aggregates TotalDeposit from CustomerAllTimeAggregatedData for all provided CIDs.

**Columns/Parameters Involved**: `@CIDs`, `BackOffice.CustomerAllTimeAggregatedData.TotalDeposit`

**Rules**:
- `SUM(TotalDeposit)` across all CIDs in @CIDs (dbo.IDIntList UDT, column named `ID`)
- Returns a single scalar row with column `LinkedDeposits`
- Returns NULL if no matching CIDs found (SUM of empty set)
- `TotalDeposit` is the all-time cumulative deposit total per customer from `BackOffice.CustomerAllTimeAggregatedData`

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CIDs | dbo.IDIntList (TABLE TYPE) | NO | - | CODE-BACKED | Table-valued parameter containing CIDs to aggregate. Uses dbo.IDIntList UDT with column `ID`. Typically all CIDs identified as linked to a risk subject. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LinkedDeposits | MONEY/DECIMAL | YES | - | CODE-BACKED | Sum of TotalDeposit across all CIDs in @CIDs from BackOffice.CustomerAllTimeAggregatedData. NULL if no matching CIDs. Represents total financial exposure across all linked accounts. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CIDs -> ID | BackOffice.CustomerAllTimeAggregatedData | Read (WHERE IN filter) | Aggregates TotalDeposit for provided CID list |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (BO fraud/risk workflow) | @CIDs | Application | Called when evaluating combined deposit exposure of linked accounts |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetTotalDepositsOfAllLinkedAccounts (procedure)
├── BackOffice.CustomerAllTimeAggregatedData (table)
└── dbo.IDIntList (user defined type - parameter type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerAllTimeAggregatedData | Table | SUM(TotalDeposit) WHERE CID IN @CIDs |
| dbo.IDIntList | User Defined Type | Table-valued parameter type for @CIDs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called by BO application layer for linked-account risk assessment. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| dbo.IDIntList UDT | Implementation | Parameter uses dbo.IDIntList (column name `ID`) - distinct from dbo.IdList (column name `CID`) used in other procedures. |
| READONLY parameter | Implementation | @CIDs is declared READONLY - the table cannot be modified inside the procedure. |
| NULL on empty match | Semantic | If no CIDs in @CIDs exist in CustomerAllTimeAggregatedData, SUM returns NULL (not 0). Callers should use ISNULL(LinkedDeposits, 0). |

---

## 8. Sample Queries

### 8.1 Get linked deposits for a set of customer IDs
```sql
DECLARE @LinkedCIDs dbo.IDIntList
INSERT INTO @LinkedCIDs VALUES (100001), (100002), (100003)
EXEC [BackOffice].[GetTotalDepositsOfAllLinkedAccounts] @CIDs = @LinkedCIDs
```

### 8.2 Direct equivalent query
```sql
SELECT SUM(TotalDeposit) AS LinkedDeposits
FROM BackOffice.CustomerAllTimeAggregatedData WITH (NOLOCK)
WHERE CID IN (100001, 100002, 100003)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 8.5/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetTotalDepositsOfAllLinkedAccounts | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetTotalDepositsOfAllLinkedAccounts.sql*
