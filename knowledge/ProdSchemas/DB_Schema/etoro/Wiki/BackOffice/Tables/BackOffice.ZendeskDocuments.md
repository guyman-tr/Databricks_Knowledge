# BackOffice.ZendeskDocuments

> Junction table linking Zendesk support tickets to eToro T&C documents for specific customers, mapping ZendeskDocumentID + DocumentID + GCID. Currently empty - likely an unused feature from 2014.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | PK_BackOffice_ZendeskDocuments: ID IDENTITY (NONCLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 (1 nonclustered PK + 1 clustered on DocumentID + 1 nonclustered on GCID) |

---

## 1. Business Meaning

`BackOffice.ZendeskDocuments` was designed to track the relationship between Zendesk support tickets and eToro Terms & Conditions documents on a per-customer basis. The intent: when a customer support agent sends a customer a T&C document via Zendesk (eToro's customer support platform), this table records which Zendesk document ID corresponds to which internal eToro document (`DocumentID` -> `BackOffice.TncDocument`) for which customer (`GCID`).

The table is currently empty (0 rows). Only one SP exists for it: `BackOffice.ZendeskDocumentsAdd` (created 2014-08-12/13 by TRAD\gerire and TRAD\omerbaCREATE). The SP implementation is trivial: `INSERT INTO BackOffice.ZendeskDocuments(GCID, ZendeskDocumentID, DocumentID)`. The 2014 creation date and empty state suggest this was an early integration feature between Zendesk and the T&C document system that was never fully adopted or was later replaced by direct Zendesk functionality.

The unusual index design (NONCLUSTERED PK on ID, but a separate CLUSTERED index on DocumentID+Occurred) suggests the intended primary access pattern was by DocumentID rather than by the surrogate ID.

---

## 2. Business Logic

### 2.1 Zendesk-to-TncDocument Mapping

**What**: Links Zendesk ticket document IDs to eToro internal document IDs for a specific customer.

**Columns/Parameters Involved**: `GCID`, `ZendeskDocumentID`, `DocumentID`

**Rules**:
- Written by `ZendeskDocumentsAdd(@GCID, @ZendeskDocumentID, @DocumentID)`.
- `ZendeskDocumentID` is the ID of the document record as tracked in Zendesk.
- `DocumentID` references `BackOffice.TncDocument.DocumentID` - the eToro internal T&C document.
- `GCID` is the Global Customer ID - the cross-platform customer identifier.
- `Occurred` defaults to GETDATE() on insert.
- No unique constraints - multiple rows per (GCID, ZendeskDocumentID, DocumentID) are theoretically possible.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Row count | 0 (empty) |
| Status | Empty/unused - no operational data |
| Creation date | 2014-08-12 (per SP comment) |
| Intended use | Linking Zendesk support document records to eToro T&C docs |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Surrogate identity PK. Auto-incremented. NOT FOR REPLICATION. Note: NONCLUSTERED PK - the actual clustered index is on (DocumentID, Occurred), making DocumentID the physical access path. |
| 2 | Occurred | datetime | YES | GETDATE() | CODE-BACKED | Timestamp when this Zendesk-document link was created. Defaults to GETDATE(). Nullable despite default. Part of the clustered index key alongside DocumentID. |
| 3 | ZendeskDocumentID | int | NO | - | CODE-BACKED | The document ID as assigned by Zendesk (the external support platform). Used with DocumentID to link external and internal document records. Part of the NC index (GCID, ZendeskDocumentID). |
| 4 | DocumentID | int | NO | - | CODE-BACKED | FK (logical) to BackOffice.TncDocument.DocumentID. The eToro T&C document that was sent via Zendesk. Leading key of the clustered index - designed for document-centric lookups. |
| 5 | GCID | int | NO | - | CODE-BACKED | Global Customer ID - the cross-platform customer identifier (different from CID which is the eToro platform-specific ID). Leading key of the NC index (GCID, ZendeskDocumentID) for per-customer lookups. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DocumentID | BackOffice.TncDocument.DocumentID | Implicit (no DDL FK) | The eToro T&C document sent via Zendesk |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.ZendeskDocumentsAdd | INSERT | Writer | Creates ZendeskDocument-to-TncDocument linkage records |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no formal code-level dependencies (no DDL FK constraints).

### 6.1 Objects This Depends On

No formal dependencies. Logical dependency on `BackOffice.TncDocument` via `DocumentID`.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.ZendeskDocumentsAdd | Stored Procedure | Inserts Zendesk-document link records |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BackOffice_ZendeskDocuments | NONCLUSTERED PK | ID ASC | - | - | Active |
| Idx_BackOffice_ZendeskDocuments_DocumentID | CLUSTERED | DocumentID ASC, Occurred ASC | - | - | Active |
| IDX_BOZD | NONCLUSTERED | GCID ASC, ZendeskDocumentID ASC | - | - | Active |

Note: Having a NONCLUSTERED PK while a separate CLUSTERED index exists on (DocumentID, Occurred) is an unusual pattern. It means the physical row order is by DocumentID (not by ID), and lookups by ID require a nonclustered seek plus a key lookup.

### 7.2 Constraints

No FK constraints. PK only.

---

## 8. Sample Queries

### 8.1 Get all Zendesk documents for a specific customer

```sql
SELECT zd.ID, zd.GCID, zd.ZendeskDocumentID, zd.DocumentID, zd.Occurred,
       tnc.DisplayName, tnc.FileName
FROM BackOffice.ZendeskDocuments zd WITH (NOLOCK)
JOIN BackOffice.TncDocument tnc WITH (NOLOCK) ON tnc.DocumentID = zd.DocumentID
WHERE zd.GCID = 99999
ORDER BY zd.Occurred DESC;
```

### 8.2 Get all customers sent a specific T&C document via Zendesk

```sql
SELECT zd.GCID, zd.ZendeskDocumentID, zd.Occurred
FROM BackOffice.ZendeskDocuments zd WITH (NOLOCK)
WHERE zd.DocumentID = 1
ORDER BY zd.Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 8/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11 (DDL, Live Data, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.ZendeskDocuments | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.ZendeskDocuments.sql*
