# BackOffice.SuitabilityAdd

> Adds a customer to the BackOffice.Suitability whitelist, granting the customer regulatory approval to trade complex financial instruments under MiFID II suitability requirements.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - the customer to whitelist |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.SuitabilityAdd is the write entry point for marking a customer as "suitable" under regulatory frameworks such as MiFID II. When a customer passes the suitability assessment - demonstrating they understand the risks of complex financial instruments (CFDs, leveraged products) - a BackOffice compliance officer calls this procedure to record the approval.

The procedure inserts the customer's CID into BackOffice.Suitability, which is a pure membership whitelist (presence = approved, absence = not approved). Downstream trading systems check this table before allowing access to restricted product types. The paired procedure, BackOffice.SuitabilityDelete, removes approval when needed.

The procedure was introduced in October 2013 (author: elik, FreshBase case 19119: "Add suitability attribute to customer card in BO"). The suitability flag also supports bulk KYC updates via the Bulk_UpdateRiskUserInfoRemote procedure when a cohort of customers passes or fails reassessment.

---

## 2. Business Logic

### 2.1 Simple Whitelist Insertion

**What**: Adds the CID to the suitability whitelist table.

**Columns/Parameters Involved**: `@CID`

**Rules**:
- INSERT INTO BackOffice.Suitability (CID) VALUES (@CID)
- No return value or error code (SET NOCOUNT ON, implicit 0 return on success)
- If @CID already exists in Suitability: INSERT will fail with PK violation (clustered PK on CID) - the caller must check before calling or handle the duplicate
- No transaction wrapping - atomic single-row insert

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | VERIFIED | The customer to mark as suitable. Inserted as the sole column into BackOffice.Suitability (CID). Must be unique - calling this procedure for a CID already in Suitability will raise a PK violation error. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Suitability | WRITER (INSERT) | Adds customer to the regulatory suitability whitelist |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice compliance/KYC workflows | - | Caller | Called when a customer passes the regulatory suitability assessment |
| Bulk_UpdateRiskUserInfoRemote | SuitabilityTestStatusID | Caller | Calls this procedure when bulk KYC update payload indicates suitability pass |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.SuitabilityAdd (procedure)
└── BackOffice.Suitability (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Suitability | Table | INSERT (CID) - adds customer to the regulatory whitelist |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.SuitabilityDelete | Stored Procedure | Paired inverse - removes what this procedure adds |
| Trading restriction systems | External | Checks BackOffice.Suitability to gate complex instrument access |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Origin

FB (FreshBase) case 19119 (October 2013, author: elik): "Add suitability attribute to customer card in BO." Part of the original MiFID suitability compliance feature.

---

## 8. Sample Queries

### 8.1 Mark a customer as suitable
```sql
EXEC BackOffice.SuitabilityAdd @CID = 12345678
```

### 8.2 Check if a customer is already in the whitelist before adding
```sql
IF NOT EXISTS (SELECT 1 FROM BackOffice.Suitability WITH (NOLOCK) WHERE CID = 12345678)
    EXEC BackOffice.SuitabilityAdd @CID = 12345678
```

### 8.3 Count customers with suitability approval
```sql
SELECT COUNT(*) AS SuitableCustomers
FROM BackOffice.Suitability WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 8.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11 (1,8,10,11; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.SuitabilityAdd | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.SuitabilityAdd.sql*
