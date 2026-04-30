# BackOffice.CustomerRiskOccurredCheck

> Checks whether a specific risk status has been flagged for a customer (by CID or GCID), querying BackOffice.CustomerRisk. Returns boolean result via OUTPUT parameter.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ID + @IsCID (customer identifier) + @RiskStatusID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure checks whether a particular risk status has ever been flagged for a customer by querying `BackOffice.CustomerRisk`. It accepts either a CID or GCID as the customer identifier (controlled by the `@IsCID` flag), resolving CID to GCID via `Customer.CustomerStatic` when needed.

`BackOffice.CustomerRisk` stores risk events (AML flags, fraud alerts, suspicious activity markers) associated with customers at the global customer identity level (GCID). The GCID model means risk flags are shared across all accounts belonging to the same real-world person, regardless of which specific account (CID) triggered the risk.

This SP is used in risk management workflows to gate actions: before allowing certain operations (deposits, withdrawals, account upgrades), callers verify that no blocking risk status has been recorded for the customer's global identity.

---

## 2. Business Logic

### 2.1 CID-to-GCID Resolution

**What**: Normalizes the identifier to GCID before checking CustomerRisk.

**Rules**:
- If @IsCID=1: SELECT @GCID = GCID FROM Customer.CustomerStatic WITH(NOLOCK) WHERE CID=@ID
- If @IsCID=0: SET @GCID = @ID (treat @ID directly as GCID)
- If @IsCID=1 and CID not found in Customer.CustomerStatic: @GCID remains NULL; the subsequent EXISTS check will return false (@IsOccurred=0) - no error raised

### 2.2 Risk Status Existence Check

**What**: Returns whether the specific risk status is flagged for this global customer identity.

**Rules**:
- IF EXISTS (SELECT * FROM BackOffice.CustomerRisk WITH(NOLOCK) WHERE GCID=@GCID AND RiskStatusID=@RiskStatusID): @IsOccurred=1
- ELSE: @IsOccurred=0
- WITH(NOLOCK): non-blocking read
- Returns false (0) if @GCID is NULL (CID not found path)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | INT | NO | - | CODE-BACKED | Customer identifier. Interpreted as CID when @IsCID=1, or directly as GCID when @IsCID=0. |
| 2 | @IsCID | BIT | NO | - | CODE-BACKED | Identifier type flag. 1=@ID is a CID (resolved to GCID via Customer.CustomerStatic). 0=@ID is already a GCID (no resolution needed). |
| 3 | @RiskStatusID | INT | NO | - | CODE-BACKED | Risk status to check. FK to risk status lookup (BackOffice.CustomerRisk.RiskStatusID). Procedure checks if this specific risk has been flagged for the customer. |

**Output Parameters:**

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 4 | @IsOccurred | BIT OUT | NO | CODE-BACKED | Risk occurrence result. 1=the specified RiskStatusID has been flagged for this customer's GCID in BackOffice.CustomerRisk. 0=not flagged (or GCID not found). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ID (when @IsCID=1) | Customer.CustomerStatic | SELECT (NOLOCK) | Resolves CID to GCID |
| @GCID + @RiskStatusID | BackOffice.CustomerRisk | SELECT (NOLOCK) | EXISTS check for the specified risk status |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice risk management workflows | External | Direct call | Check for blocking risk flags before allowing operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerRiskOccurredCheck (procedure)
|- Customer.CustomerStatic (table) [SELECT NOLOCK: CID->GCID resolution, only when @IsCID=1]
|- BackOffice.CustomerRisk (table) [SELECT NOLOCK: risk status existence check]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | SELECT: resolves CID to GCID when @IsCID=1 |
| BackOffice.CustomerRisk | Table | SELECT: EXISTS check for GCID + RiskStatusID combination |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice risk management workflows | External | Risk gate checks before sensitive operations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| GCID-level check | Design | Risk is checked at global identity level (GCID) - risk flags shared across all customer accounts |
| WITH(NOLOCK) | Concurrency | Dirty reads permitted on both tables |
| SET NOCOUNT ON | Performance | Suppresses row count messages |
| Silent NULL path | Behavior | If CID not found, @GCID=NULL, EXISTS returns false, @IsOccurred=0 |

---

## 8. Sample Queries

### 8.1 Check if a risk status has occurred (by CID)

```sql
DECLARE @IsOccurred BIT;
EXEC BackOffice.CustomerRiskOccurredCheck
    @ID = 12345,
    @IsCID = 1,
    @RiskStatusID = 3,
    @IsOccurred = @IsOccurred OUTPUT;
SELECT @IsOccurred AS IsRiskOccurred;
-- 1 = risk flagged, 0 = not flagged
```

### 8.2 Check by GCID directly

```sql
DECLARE @IsOccurred BIT;
EXEC BackOffice.CustomerRiskOccurredCheck
    @ID = 9876543,   -- GCID
    @IsCID = 0,
    @RiskStatusID = 5,
    @IsOccurred = @IsOccurred OUTPUT;
SELECT @IsOccurred AS IsRiskOccurred;
```

### 8.3 View risk statuses for a customer

```sql
SELECT cr.GCID, cr.RiskStatusID, cr.CreatedDate
FROM BackOffice.CustomerRisk cr WITH (NOLOCK)
INNER JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON cs.GCID = cr.GCID
WHERE cs.CID = 12345
ORDER BY cr.CreatedDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: not searched (BackOffice schema) | Corrections: 0 applied*
*Object: BackOffice.CustomerRiskOccurredCheck | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerRiskOccurredCheck.sql*
