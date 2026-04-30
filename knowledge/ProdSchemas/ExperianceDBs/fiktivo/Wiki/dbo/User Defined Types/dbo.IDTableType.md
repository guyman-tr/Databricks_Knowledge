# dbo.IDTableType

> General-purpose table-valued parameter type for passing a list of integer IDs to stored procedures. The most widely used TVP in the fiktivo database.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | ID (INT, no PK) |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

This is the most widely used table-valued parameter in the fiktivo database. It provides a generic mechanism for passing a list of integer IDs to stored procedures - the ID can represent affiliate IDs, group IDs, type IDs, or any other integer identifier depending on the context of the consuming procedure.

The type has no primary key, allowing duplicate IDs to be passed. This flexibility is important because the same type serves many different use cases across multiple stored procedures.

Known consumers in dbo schema include: `dbo.UpdateAffiliatesWithAffiliateType`, `dbo.ReportSummaryByAffiliate`, `dbo.ReportSummaryPerAffiliate`, `dbo.GetUnpaidCommissions`, `dbo.GetLastPositionDateByCID`. It is also heavily used across AffiliateAdmin and AffiliateReport schemas.

---

## 2. Business Logic

### 2.1 Multi-Purpose ID Parameter Pattern

**What**: A single type serves as a universal integer list parameter across many procedures.

**Columns/Parameters Involved**: `ID`

**Rules**:
- The semantic meaning of `ID` depends entirely on the consuming procedure's parameter name and context
- In `UpdateAffiliatesWithAffiliateType`: ID = AffiliateID (list of affiliates to update)
- In `ReportSummaryByAffiliate`: ID = AffiliateID (list of affiliates to report on)
- In `GetLastPositionDateByCID`: ID = CID (customer ID to look up)
- In `MoveAffiliatesToAffiliateGroup`: ID = AffiliateID (list of affiliates to move)
- In `GetUnpaidCommissions`: ID = AffiliateID (list of affiliates to check)
- In `GetNumberOfAffiliatesInGroups`: ID = AffiliatesGroupsID (list of groups to count)

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Generic integer identifier. Meaning varies by consuming procedure - can represent AffiliateID, CID, GroupID, or any other integer key. No PK constraint allows duplicates. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.UpdateAffiliatesWithAffiliateType | @AffiliateIDs | Parameter | Passes list of affiliate IDs to bulk-update their type |
| dbo.ReportSummaryByAffiliate | @AffiliateIDs | Parameter | Passes list of affiliate IDs for summary reporting |
| dbo.ReportSummaryPerAffiliate | @AffiliateIDs | Parameter | Passes list of affiliate IDs for per-affiliate reports |
| dbo.GetUnpaidCommissions | @AffiliateIDs | Parameter | Passes list of affiliate IDs to check unpaid commissions |
| dbo.GetLastPositionDateByCID | @CIDs | Parameter | Passes list of customer IDs to find last position dates |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.UpdateAffiliatesWithAffiliateType | Stored Procedure | Parameter type |
| dbo.ReportSummaryByAffiliate | Stored Procedure | Parameter type |
| dbo.ReportSummaryPerAffiliate | Stored Procedure | Parameter type |
| dbo.GetUnpaidCommissions | Stored Procedure | Parameter type |
| dbo.GetLastPositionDateByCID | Stored Procedure | Parameter type |
| AffiliateAdmin.MoveAffiliatesToAffiliateGroup | Stored Procedure | Parameter type |
| AffiliateAdmin.UpdateAffiliatesWithAffiliateType | Stored Procedure | Parameter type |
| AffiliateAdmin.GetNumberOfAffiliatesInGroups | Stored Procedure | Parameter type |
| AffiliateReport.ReportSummaryByAffiliate | Stored Procedure | Parameter type |
| AffiliateReport.PortalReportSummaryByAffiliate | Stored Procedure | Parameter type |
| AffiliateReport.PortalReportSummaryPerAffiliate | Stored Procedure | Parameter type |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for affiliate IDs
```sql
DECLARE @affiliateIDs dbo.IDTableType
INSERT INTO @affiliateIDs (ID) VALUES (100), (200), (300)
```

### 8.2 Use to filter affiliates
```sql
DECLARE @ids dbo.IDTableType
INSERT INTO @ids (ID) VALUES (100), (200)
SELECT a.AffiliateID, a.LoginName, a.Email
FROM dbo.tblaff_Affiliates a WITH (NOLOCK)
JOIN @ids i ON i.ID = a.AffiliateID
```

### 8.3 Pass to a stored procedure
```sql
DECLARE @ids dbo.IDTableType
INSERT INTO @ids (ID) VALUES (100), (200), (300)
EXEC dbo.GetUnpaidCommissions @AffiliateIDs = @ids
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.IDTableType | Type: User Defined Type | Source: fiktivo/dbo/User Defined Types/dbo.IDTableType.sql*
