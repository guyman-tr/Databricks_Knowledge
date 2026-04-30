# dbo.GetPaymentSpecificationDueStatusesMapping

> Resolves payment specification due GUIDs from the provider (via TVP) to internal DueIds by joining against PaymentSpecificationDues.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT with JOIN: PaymentSpecificationDues.PaymentSpecificationDueGuid = TVP.PaymentSpecificationDueGuid |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetPaymentSpecificationDueStatusesMapping resolves provider-side payment due GUIDs to internal DueIds. Accepts a PaymentSpecificationDueStatusForMappingType TVP containing provider-side due records, copies to temp table, then JOINs against PaymentSpecificationDues on PaymentSpecificationDueGuid to resolve internal DueIds. Returns DueId plus the status fields from the TVP.

This is used when the provider sends payment due status events with GUIDs that need to be mapped to internal Ids before insertion into PaymentSpecificationDueStatuses.

---

## 2. Business Logic

### 2.1 GUID-to-Id Resolution for Provider Events

**What**: Maps provider-side due GUIDs to internal DueIds for status event insertion.

**Rules**:
- TVP copied to temp table for performance
- INNER JOIN resolves PaymentSpecificationDueGuid to PaymentSpecificationDues.Id
- Returns: DueId (resolved), DueStatusId, CorrelationId, EventTimestamp, Created, Amount (from TVP)
- Unresolvable GUIDs are silently dropped (INNER JOIN)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentSpecificationDueStatusForMapping | PaymentSpecificationDueStatusForMappingType | NO | READONLY | CODE-BACKED | TVP with provider-side due status records. See dbo.PaymentSpecificationDueStatusForMappingType. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN | dbo.PaymentSpecificationDues | Read | GUID-to-Id resolution |
| @param | dbo.PaymentSpecificationDueStatusForMappingType | Type | TVP parameter type |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetPaymentSpecificationDueStatusesMapping (procedure)
├── dbo.PaymentSpecificationDues (table)
└── dbo.PaymentSpecificationDueStatusForMappingType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.PaymentSpecificationDues | Table | GUID resolution source |
| dbo.PaymentSpecificationDueStatusForMappingType | UDT | TVP parameter type |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Resolve due GUIDs to internal IDs
```sql
DECLARE @mapping dbo.PaymentSpecificationDueStatusForMappingType;
INSERT INTO @mapping (WalletPaymentSpecificationDueId, PaymentSpecificationDueGuid, DueStatusId, CorrelationId, EventTimestamp, Created, Amount)
VALUES (5001, 'A1B2C3D4-0000-0000-0000-000000000001', 1, NEWID(), SYSUTCDATETIME(), SYSUTCDATETIME(), 100.00);
EXEC dbo.GetPaymentSpecificationDueStatusesMapping @PaymentSpecificationDueStatusForMapping = @mapping;
```

### 8.2 Verify resolution
```sql
SELECT Id, PaymentSpecificationDueGuid FROM dbo.PaymentSpecificationDues WITH (NOLOCK)
WHERE PaymentSpecificationDueGuid = 'A1B2C3D4-0000-0000-0000-000000000001';
```

### 8.3 Pipeline: resolve then insert
```sql
-- Step 1: Resolve GUIDs
EXEC dbo.GetPaymentSpecificationDueStatusesMapping @PaymentSpecificationDueStatusForMapping = @mapping;
-- Step 2: Use resolved DueIds with AddPaymentSpecificationDueStatusBulk
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.GetPaymentSpecificationDueStatusesMapping | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.GetPaymentSpecificationDueStatusesMapping.sql*
