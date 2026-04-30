# dbo.PaymentSpecificationDueStatusForMappingType

> User-defined table type for mapping payment specification due statuses with their provider-side identifiers in batch operations.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | User Defined Type |
| **Key Identifier** | Table type with WalletPaymentSpecificationDueId + PaymentSpecificationDueGuid + status fields |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

PaymentSpecificationDueStatusForMappingType is a table-valued parameter type used to pass payment specification due status data that includes both internal and provider-side identifiers. This type bridges the gap between the internal database IDs and the provider's (Tribe) GUID-based identifiers when querying or mapping due status records.

This type exists to support the GetPaymentSpecificationDueStatusesMapping procedure, which needs to correlate internal due records with their external representations. When payment specification dues change status (e.g., a direct debit payment is collected or fails), the mapping between internal and external IDs must be maintained.

Data flows through this type when the application queries for the mapping between wallet-side due IDs and database-side due records. The WalletPaymentSpecificationDueId represents the provider's identifier, while PaymentSpecificationDueGuid is the platform's external identifier for the same due.

---

## 2. Business Logic

### 2.1 Due Status Mapping Between Internal and Provider Systems

**What**: Correlates internal payment due records with their provider-side identifiers for status synchronization.

**Columns/Parameters Involved**: `WalletPaymentSpecificationDueId`, `PaymentSpecificationDueGuid`, `DueStatusId`, `CorrelationId`, `Amount`

**Rules**:
- WalletPaymentSpecificationDueId is the provider's (Tribe/wallet) ID for the due
- PaymentSpecificationDueGuid is the platform's GUID for the same due
- DueStatusId maps to the payment due status progression
- CorrelationId links the status event to its triggering business operation
- Amount captures the due amount at the time of the status event

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WalletPaymentSpecificationDueId | bigint | NO | - | CODE-BACKED | Provider-side (wallet/Tribe) identifier for the payment specification due. Used to map between the external provider system and internal records. |
| 2 | PaymentSpecificationDueGuid | uniqueidentifier | NO | - | CODE-BACKED | Platform's external GUID for the payment specification due. Corresponds to PaymentSpecificationDueGuid in dbo.PaymentSpecificationDues. |
| 3 | DueStatusId | tinyint | NO | - | CODE-BACKED | Status of the payment due. Business meaning depends on the payment specification lifecycle. |
| 4 | CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Unique identifier linking this status event to the business operation that triggered it. Enables end-to-end tracing across services. |
| 5 | EventTimestamp | datetime2(7) | NO | - | CODE-BACKED | Timestamp when the status change event occurred in the source system. May differ from Created (when it was recorded in the database). |
| 6 | Created | datetime2(7) | NO | - | CODE-BACKED | Timestamp when this status record was created in the database. |
| 7 | Amount | decimal(36,18) | NO | - | CODE-BACKED | Monetary amount associated with this due status event. Represents the payment amount at the time of the status change. High precision (18 decimal places) supports multi-currency calculations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PaymentSpecificationDueGuid | dbo.PaymentSpecificationDues | Implicit | Maps to the platform's payment specification due record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.GetPaymentSpecificationDueStatusesMapping | Parameter | Parameter Type | Accepts batch of due status records for mapping resolution |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.GetPaymentSpecificationDueStatusesMapping | Stored Procedure | TVP parameter type for due status mapping queries |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for mapping lookup
```sql
DECLARE @DueStatuses dbo.PaymentSpecificationDueStatusForMappingType;
INSERT INTO @DueStatuses (WalletPaymentSpecificationDueId, PaymentSpecificationDueGuid, DueStatusId, CorrelationId, EventTimestamp, Created, Amount)
VALUES (5001, 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890', 1, NEWID(), SYSUTCDATETIME(), SYSUTCDATETIME(), 100.000000000000000000);
EXEC dbo.GetPaymentSpecificationDueStatusesMapping @DueStatuses = @DueStatuses;
```

### 8.2 Populate multiple due status records
```sql
DECLARE @DueStatuses dbo.PaymentSpecificationDueStatusForMappingType;
INSERT INTO @DueStatuses (WalletPaymentSpecificationDueId, PaymentSpecificationDueGuid, DueStatusId, CorrelationId, EventTimestamp, Created, Amount)
VALUES (5001, 'A1B2C3D4-0000-0000-0000-000000000001', 1, NEWID(), SYSUTCDATETIME(), SYSUTCDATETIME(), 50.00),
       (5002, 'A1B2C3D4-0000-0000-0000-000000000002', 2, NEWID(), SYSUTCDATETIME(), SYSUTCDATETIME(), 75.50);
```

### 8.3 Check the type definition
```sql
SELECT c.name AS ColumnName, t.name AS DataType, c.precision, c.scale, c.is_nullable
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.system_type_id = t.system_type_id AND c.user_type_id = t.user_type_id
WHERE tt.name = 'PaymentSpecificationDueStatusForMappingType' AND tt.schema_id = SCHEMA_ID('dbo')
ORDER BY c.column_id;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.PaymentSpecificationDueStatusForMappingType | Type: User Defined Type | Source: FiatDwhDB/dbo/User Defined Types/dbo.PaymentSpecificationDueStatusForMappingType.sql*
