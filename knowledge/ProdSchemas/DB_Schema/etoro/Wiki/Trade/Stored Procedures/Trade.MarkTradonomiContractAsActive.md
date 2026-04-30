# Trade.MarkTradonomiContractAsActive

> Activates a specific Tradonomi contract for its instrument and deactivates all sibling contracts for the same instrument, ensuring only one active contract per instrument at any time.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ContractID - the contract to activate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.MarkTradonomiContractAsActive switches the active contract for a trading instrument. When an instrument's contract period changes (e.g., a futures rollover or a new LP contract takes effect), this procedure sets the chosen contract to IsActive=1 and simultaneously sets all other contracts for the same instrument to IsActive=0. This guarantees the single-active-contract-per-instrument invariant enforced by the trading and hedging system.

This procedure exists because Trade.TradonomiContracts may hold multiple historical and future contract rows for a given instrument, but only one can be routed at a time. Without this procedure, activating a new contract would require manual UPDATE logic that risks leaving multiple contracts active simultaneously. The procedure encapsulates the atomic "swap active" operation.

Data flows: called by DBA operations (PROD_BIadmins has permission). Reads InstrumentID for the target ContractID, then issues a single UPDATE affecting all contracts for that InstrumentID. Returns 0 on success, -1 on failure (TRY/CATCH).

---

## 2. Business Logic

### 2.1 Atomic Active-Contract Swap

**What**: In one UPDATE statement, activates one contract and deactivates all others for the same instrument.

**Columns/Parameters Involved**: `Trade.TradonomiContracts.IsActive`, `Trade.TradonomiContracts.ContractID`, `Trade.TradonomiContracts.InstrumentID`

**Rules**:
- Step 1: SELECT InstrumentID from Trade.TradonomiContracts WHERE ContractID = @ContractID.
- Step 2: UPDATE all rows WHERE InstrumentID = @InstrumentID - set IsActive = CASE WHEN ContractID = @ContractID THEN 1 ELSE 0 END.
- Result: exactly one row has IsActive=1; all others for the same instrument have IsActive=0.
- If @ContractID does not exist, @InstrumentID remains NULL, the UPDATE affects 0 rows (no error; RETURN 0).
- TRY/CATCH returns -1 on any error; no explicit RAISERROR.

**Diagram**:
```
Before:
  ContractID=10, InstrumentID=5, IsActive=1  (currently active)
  ContractID=11, InstrumentID=5, IsActive=0  (upcoming)

EXEC Trade.MarkTradonomiContractAsActive @ContractID=11

After:
  ContractID=10, InstrumentID=5, IsActive=0  (deactivated)
  ContractID=11, InstrumentID=5, IsActive=1  (now active)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ContractID | INT | NO | - | CODE-BACKED | ID of the Tradonomi contract to activate. Must exist in Trade.TradonomiContracts. The procedure resolves its InstrumentID and sets this contract to IsActive=1, all siblings to IsActive=0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ContractID | Trade.TradonomiContracts | Read/Write | Reads InstrumentID for the target contract; updates IsActive for all contracts with that InstrumentID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DBA operations / PROD_BIadmins | - | Caller | Called by database administrators to roll contracts or activate new LP contract periods; no SP callers found in Trade schema |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.MarkTradonomiContractAsActive (procedure)
└── Trade.TradonomiContracts (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.TradonomiContracts | Table | SELECTed to resolve InstrumentID; UPDATEd to set IsActive per CASE |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No SP callers found) | - | Called directly by DBA operations; no stored procedure consumers in the schema |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. SET NOCOUNT ON. Returns: 0 = success, -1 = exception caught.

---

## 8. Sample Queries

### 8.1 View all contracts for an instrument with active status

```sql
SELECT TC.ContractID, TC.InstrumentID, TC.Description,
       TC.IsActive, TC.FromDate, TC.ToDate
FROM Trade.TradonomiContracts AS TC WITH (NOLOCK)
WHERE TC.InstrumentID = (
    SELECT InstrumentID FROM Trade.TradonomiContracts WITH (NOLOCK)
    WHERE ContractID = <ContractID>
)
ORDER BY TC.FromDate DESC;
```

### 8.2 Find instruments with multiple active contracts (should be zero after procedure runs)

```sql
SELECT TC.InstrumentID, COUNT(*) AS ActiveCount
FROM Trade.TradonomiContracts AS TC WITH (NOLOCK)
WHERE TC.IsActive = 1
GROUP BY TC.InstrumentID
HAVING COUNT(*) > 1;
```

### 8.3 Find instruments with no active contract

```sql
SELECT DISTINCT TC.InstrumentID
FROM Trade.TradonomiContracts AS TC WITH (NOLOCK)
WHERE NOT EXISTS (
    SELECT 1 FROM Trade.TradonomiContracts AS TC2 WITH (NOLOCK)
    WHERE TC2.InstrumentID = TC.InstrumentID AND TC2.IsActive = 1
);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for this procedure.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SP callers | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Trade.MarkTradonomiContractAsActive | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.MarkTradonomiContractAsActive.sql*
