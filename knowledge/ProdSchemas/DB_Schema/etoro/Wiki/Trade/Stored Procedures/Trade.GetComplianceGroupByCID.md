# Trade.GetComplianceGroupByCID

> Retrieves the compliance group assignment for a specific customer, used to determine trading restrictions and compliance rules applicable to the customer.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns ComplianceGroupID for a given CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure looks up which compliance group a customer belongs to. Compliance groups define sets of trading restrictions, instrument limitations, and regulatory requirements that apply to groups of customers. For example, customers from certain jurisdictions may be in a compliance group that restricts leverage or prohibits certain instruments.

The procedure exists to centralize the compliance group lookup so that trading services can quickly determine which rules apply to a customer before allowing trade execution.

Data flow: Trading service provides a CID -> procedure queries dbo.TradingComplianceGroup -> returns the ComplianceGroupID -> caller uses this to load the applicable rules.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple point-lookup procedure. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to look up. Filters dbo.TradingComplianceGroup to find the customer's assigned compliance group. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ComplianceGroupID | INT | - | - | CODE-BACKED | Identifier of the compliance group the customer belongs to. Used to load the applicable trading restrictions and regulatory rules for this customer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | dbo.TradingComplianceGroup | Read | Looks up compliance group by customer ID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trading Services | EXEC | Caller | Determines applicable compliance rules before trade execution |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetComplianceGroupByCID (procedure)
└── dbo.TradingComplianceGroup (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.TradingComplianceGroup | Table | Source of customer-to-compliance-group mappings |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trading Services | External | Compliance group lookup before trade execution |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute for a specific customer

```sql
EXEC Trade.GetComplianceGroupByCID @CID = 12345;
```

### 8.2 Query compliance groups directly

```sql
SELECT CID, ComplianceGroupID
FROM dbo.TradingComplianceGroup WITH (NOLOCK)
WHERE CID = 12345;
```

### 8.3 Find customers in a specific compliance group

```sql
SELECT CID, ComplianceGroupID
FROM dbo.TradingComplianceGroup WITH (NOLOCK)
WHERE ComplianceGroupID = 5
ORDER BY CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetComplianceGroupByCID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetComplianceGroupByCID.sql*
