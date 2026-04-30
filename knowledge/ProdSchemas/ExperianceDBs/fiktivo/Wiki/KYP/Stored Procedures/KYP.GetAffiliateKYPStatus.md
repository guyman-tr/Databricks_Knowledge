# KYP.GetAffiliateKYPStatus

> Simple reader procedure that returns the KYP verification status, progress, popup state, and migration flag for a specific affiliate.

| Property | Value |
|----------|-------|
| **Schema** | KYP |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @AffiliateID (input), returns status row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

KYP.GetAffiliateKYPStatus is a lightweight reader that returns the KYP verification status summary for a specific affiliate. It returns only 5 key fields: AffiliateID, KYPStatusID, Progress, PopupDismissed, and IsMigrated. This is the minimal status check used by the application to determine what KYP UI to show.

This procedure is called by `KYP.UpdateAffiliateKYPStatus` after a status update to return the new state to the caller. It provides a quick status lookup without the overhead of the full `KYP.GetAffiliateData` procedure (which JOINs multiple tables and returns 6 result sets).

Created by Ran Ovadia (11/08/2020) for the KYP feature.

---

## 2. Business Logic

No complex business logic. Simple SELECT with NOLOCK from KYP.Affiliate filtered by AffiliateID.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | int (IN) | NO | - | CODE-BACKED | The affiliate ID to look up KYP status for. |
| 2 | AffiliateID (output) | int | NO | - | CODE-BACKED | Echoed back from KYP.Affiliate. |
| 3 | KYPStatusID (output) | int | NO | - | CODE-BACKED | Current KYP status: 1-7 per Dictionary.KYPStatus. See [KYP Status](../../_glossary.md#kyp-status). |
| 4 | Progress (output) | int | NO | - | CODE-BACKED | Form completion percentage (0-100). |
| 5 | PopupDismissed (output) | bit | NO | - | CODE-BACKED | Whether the KYP reminder popup was dismissed. |
| 6 | IsMigrated (output) | bit | NO | - | CODE-BACKED | Whether this is a migrated legacy KYP record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AffiliateID | KYP.Affiliate | SELECT | Reads status fields |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYP.UpdateAffiliateKYPStatus | @AffiliateID | EXEC call | Called after status update to return new state |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYP.GetAffiliateKYPStatus (procedure)
└── KYP.Affiliate (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYP.Affiliate | Table | SELECT status fields |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYP.UpdateAffiliateKYPStatus | SP | EXEC to return updated status |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get KYP status for an affiliate
```sql
EXEC KYP.GetAffiliateKYPStatus @AffiliateID = 60062
```

### 8.2 Check status directly
```sql
SELECT AffiliateID, KYPStatusID, Progress, PopupDismissed, IsMigrated
FROM KYP.Affiliate WITH (NOLOCK)
WHERE AffiliateID = 60062
```

### 8.3 Find all affiliates at a specific status
```sql
SELECT AffiliateID, KYPStatusID, Progress
FROM KYP.Affiliate WITH (NOLOCK)
WHERE KYPStatusID = 5
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 8.4/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 10.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: KYP.GetAffiliateKYPStatus | Type: Stored Procedure | Source: fiktivo/KYP/Stored Procedures/KYP.GetAffiliateKYPStatus.sql*
