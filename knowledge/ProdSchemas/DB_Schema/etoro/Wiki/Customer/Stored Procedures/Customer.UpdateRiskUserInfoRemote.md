# Customer.UpdateRiskUserInfoRemote

> Updates DesignatedRegulationID and RegulationID in BackOffice.Customer for a GCID-identified customer; resolves GCID to CID via Customer.Customer JOIN; uses ISNULL-preserve for RegulationID and a WHERE change-detection guard to avoid no-op writes.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID - resolved to CID via Customer.Customer JOIN |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateRiskUserInfoRemote sets regulatory classification fields on BackOffice.Customer. DesignatedRegulationID and RegulationID control which regulatory framework applies to a customer - for example, FCA (UK), CySEC (Cyprus), ASIC (Australia), or other jurisdictions. These fields determine leverage limits, reporting obligations, and eligibility for financial products.

The "Remote" suffix signals it updates only the BackOffice.Customer fields directly, without queuing downstream registration actions (unlike non-Remote variants that trigger internal propagation via ActionsToExecute_Registration).

The GCID-to-CID resolution is done inline via a JOIN to Customer.Customer, allowing external callers to provide a GCID rather than needing to know the internal CID.

A WHERE change-detection guard (`DesignatedRegulationID <> @DesignatedRegulationID OR RegulationID <> @RegulationID OR DesignatedRegulationID IS NULL`) prevents the UPDATE from executing on rows where both fields are already at the target values, avoiding unnecessary write amplification and trigger firing.

---

## 2. Business Logic

### 2.1 GCID-to-CID Resolution and Regulatory Update

**What**: Resolves GCID to CID via Customer.Customer, then updates regulatory fields in BackOffice.Customer.

**Rules**:
- UPDATE BackOffice.Customer bc
  - SET bc.DesignatedRegulationID = @DesignatedRegulationID (direct SET - always overwrites)
  - SET bc.RegulationID = ISNULL(@RegulationID, bc.RegulationID) (ISNULL-preserve - NULL @RegulationID keeps current value)
- FROM BackOffice.Customer bc
  JOIN Customer.Customer cc WITH (NOLOCK) ON bc.CID = cc.CID
- WHERE cc.GCID = @GCID
  AND (bc.DesignatedRegulationID <> @DesignatedRegulationID OR bc.RegulationID <> @RegulationID OR bc.DesignatedRegulationID IS NULL)

**Change-detection guard breakdown**:
- `bc.DesignatedRegulationID <> @DesignatedRegulationID`: fires if DesignatedRegulationID needs to change
- `bc.RegulationID <> @RegulationID`: fires if RegulationID needs to change (note: if @RegulationID is NULL, ISNULL-preserve means no effective change - but the guard still passes on NULL due to NULL inequality behavior)
- `bc.DesignatedRegulationID IS NULL`: fires if DesignatedRegulationID is currently NULL (initialization case)

**Diagram**:
```
@GCID
  |
  v
JOIN Customer.Customer WHERE GCID = @GCID -> resolve CID
  |
  v
UPDATE BackOffice.Customer WHERE CID = cc.CID
  AND (change detected OR DesignatedRegulationID IS NULL)
  SET DesignatedRegulationID = @DesignatedRegulationID
      RegulationID = ISNULL(@RegulationID, current)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID. Used to JOIN Customer.Customer for CID resolution; WHERE cc.GCID = @GCID. |
| 2 | @DesignatedRegulationID | int | NO | - | CODE-BACKED | Regulatory jurisdiction assigned to the customer (e.g., FCA, CySEC, ASIC). Always overwritten directly (no ISNULL guard). Maps to BackOffice.Customer.DesignatedRegulationID. |
| 3 | @RegulationID | int | NO | - | CODE-BACKED | Actual applied regulation ID for the customer. ISNULL-preserve: if NULL, the existing BackOffice.Customer.RegulationID is kept unchanged. Maps to BackOffice.Customer.RegulationID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | Customer.Customer | Reader | JOIN for GCID-to-CID resolution |
| Customer.Customer.CID | BackOffice.Customer | Modifier | UPDATE DesignatedRegulationID + RegulationID via CID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external caller) | - | - | No intra-DB callers found; called from regulatory compliance services |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateRiskUserInfoRemote (procedure)
├── Customer.Customer (view - GCID to CID resolution JOIN)
└── BackOffice.Customer (table - UPDATE target for DesignatedRegulationID + RegulationID)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | GCID-to-CID resolution JOIN (NOLOCK) |
| BackOffice.Customer | Table (cross-schema) | UPDATE target for DesignatedRegulationID and RegulationID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No intra-DB callers found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ISNULL-preserve (RegulationID) | Safety | NULL @RegulationID keeps existing value in BackOffice.Customer |
| Change-detection guard | Performance | WHERE includes OR conditions to skip UPDATE if both fields already at target values |
| IS NULL initialization | Business rule | DesignatedRegulationID IS NULL guard ensures first-time initialization always fires even if no change detected |
| SET NOCOUNT ON | Implementation | Row-count suppressed |

---

## 8. Sample Queries

### 8.1 Update both regulation fields
```sql
EXEC Customer.UpdateRiskUserInfoRemote @GCID = 67890, @DesignatedRegulationID = 3, @RegulationID = 5;
```

### 8.2 Update DesignatedRegulationID only (preserve RegulationID)
```sql
EXEC Customer.UpdateRiskUserInfoRemote @GCID = 67890, @DesignatedRegulationID = 3, @RegulationID = NULL;
-- RegulationID unchanged due to ISNULL-preserve
```

### 8.3 Check current regulation values
```sql
SELECT cc.GCID, bc.CID, bc.DesignatedRegulationID, bc.RegulationID
FROM Customer.Customer cc WITH (NOLOCK)
JOIN BackOffice.Customer bc WITH (NOLOCK) ON bc.CID = cc.CID
WHERE cc.GCID = 67890;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.UpdateRiskUserInfoRemote | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.UpdateRiskUserInfoRemote.sql*
