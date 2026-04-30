# BackOffice.GetProcessDepositValidationInfo

> Batch deposit status lookup - returns key validation fields (status, amount, currency, depot, protocol MID) for a set of deposit IDs provided as a TVP, used by the MassOperationsService to validate deposits before bulk processing.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositIDs (TVP of DepositIDs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides deposit validation data for the MassOperationsService - the service responsible for bulk BackOffice operations on deposits (e.g., mass approval, status updates, reconciliation). Given a list of deposit IDs, it returns the key fields needed to validate whether each deposit is eligible for the intended bulk operation: its current payment status, amount, currency, depot assignment, and payment protocol/MID settings.

The `BackOffice.IDs_DUP` TVP (IDs with Duplicates allowed) is used instead of the standard `BackOffice.IDs` - this supports scenarios where the same DepositID may appear multiple times in the batch (e.g., retry processing or multi-step validation workflows).

**Permission**: EXECUTE granted to MassOperationsServiceUser.

---

## 2. Business Logic

### 2.1 Batch Deposit Lookup

**What**: Returns validation fields for all deposit IDs in the input TVP.

**Columns/Parameters Involved**: @DepositIDs, Billing.Deposit.DepositID

**Rules**:
- `INNER JOIN @DepositIDs DI ON BD.DepositID = DI.ID`: Only deposit IDs present in the TVP are returned. DepositIDs not found in Billing.Deposit produce no output rows (no LEFT JOIN).
- The `IDs_DUP` TVP type allows duplicate IDs in the input - multiple rows with the same DepositID in the TVP will produce multiple output rows for that deposit (one per occurrence). Callers must handle potential duplicates in results.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositIDs | BackOffice.IDs_DUP (TVP) | NO | - | CODE-BACKED | Table-valued parameter containing deposit IDs to validate. BackOffice.IDs_DUP allows duplicate ID values (unlike BackOffice.IDs which requires unique values). Each row has one ID column (INT). |

**Output Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DepositID | INT | NO | - | CODE-BACKED | Deposit record identifier. Primary key of Billing.Deposit. |
| 2 | CID | INT | NO | - | CODE-BACKED | Customer account ID who made this deposit. |
| 3 | PaymentStatus | INT | NO | - | CODE-BACKED | Current deposit payment status (PaymentStatusID). Common values: 1=Pending, 2=Approved, 3=Rejected/Cancelled, 4=In Process. Used to validate whether the deposit is in a state eligible for the bulk operation. |
| 4 | Amount | DECIMAL | YES | - | CODE-BACKED | Deposit amount in the original deposit currency. |
| 5 | OriginalDepositCurrency | INT | YES | - | CODE-BACKED | Currency identifier (CurrencyID) of the deposit's original currency. References Dictionary.Currency. Important for multi-currency validation. |
| 6 | DepotID | INT | YES | - | CODE-BACKED | Depot/routing institution identifier (Billing.Depot). Determines which payment routing path was used for this deposit. |
| 7 | ProtocolMIDSettingsID | INT | YES | - | CODE-BACKED | Payment protocol MID (Merchant ID) settings identifier. References the specific payment provider configuration used for this deposit. Used for routing validation and reconciliation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All columns | Billing.Deposit | Read (INNER JOIN) | Sole data source for all output columns |
| @DepositIDs | BackOffice.IDs_DUP (UDT) | TVP | Input type allowing duplicate deposit ID values |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MassOperationsServiceUser | EXECUTE | Caller | Mass operations service uses this for pre-validation before bulk deposit processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MassOperationsService
  -> BackOffice.GetProcessDepositValidationInfo (this SP)
     +-- Billing.Deposit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | INNER JOIN; source of all output columns |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MassOperationsService | External service | Batch deposit validation before bulk BackOffice operations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH (NOLOCK) on Billing.Deposit | Locking | Non-blocking read; deposit table is heavily written during active processing |
| INNER JOIN (not LEFT) | Data integrity | Missing deposit IDs produce no output - callers must handle absent rows |
| IDs_DUP TVP type | Design | Allows duplicate IDs in input; output may have duplicate DepositID rows if input has duplicates |

---

## 8. Sample Queries

### 8.1 Validate a batch of deposits

```sql
DECLARE @DepositIDs BackOffice.IDs_DUP;
INSERT INTO @DepositIDs (ID) VALUES (1001), (1002), (1003), (1001);  -- 1001 appears twice (IDs_DUP allows this)

EXEC BackOffice.GetProcessDepositValidationInfo @DepositIDs = @DepositIDs;
```

### 8.2 Check deposit status values

```sql
SELECT PaymentStatusID, Name
FROM Dictionary.PaymentStatus WITH (NOLOCK)
ORDER BY PaymentStatusID;
-- 1 = Pending, 2 = Approved, 3 = Cancelled/Rejected, 4 = In Process
```

### 8.3 Check deposit details directly

```sql
SELECT DepositID, CID, PaymentStatusID, Amount, CurrencyID, DepotID, ProtocolMIDSettingsID
FROM Billing.Deposit WITH (NOLOCK)
WHERE DepositID IN (1001, 1002, 1003);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 app service consumer | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetProcessDepositValidationInfo | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetProcessDepositValidationInfo.sql*
