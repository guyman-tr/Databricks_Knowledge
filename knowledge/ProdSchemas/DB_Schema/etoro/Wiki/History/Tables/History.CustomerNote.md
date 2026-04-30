# History.CustomerNote

> Back-office manager notes for customers and registration requests - 127 entries (2016-2017) containing free-text notes including email-style withdrawal notifications; linked to either a registered customer (CID) or a pending registration request.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | CustomerNoteID - int IDENTITY PK CLUSTERED |
| **Partition** | No |
| **Temporal** | No |
| **Indexes** | 1 (PK clustered, FILLFACTOR=90, on [HISTORY]), TEXTIMAGE_ON [HISTORY] |

---

## 1. Business Meaning

History.CustomerNote is the back-office note system for eToro managers. Managers write notes against either a registered customer (CID) or a pending registration request (RegistrationRequestID) to record communications, observations, and notifications.

127 rows covering September 2016 to April 2017 (inactive since 2017). The content from the observed data shows notes were used to record **withdrawal notification emails** sent to customers - "Dear [user], your withdrawal request of EUR 300.00 has been processed..." - formatted as template-based notifications.

The CHECK constraint (HCNT_NULLABILITY) enforces that either CID or RegistrationRequestID (or both) must be non-NULL - a note cannot exist without being linked to a customer or registration.

**NoteType values** (from Dictionary.NoteType): 1=General, 2=Support, 3=Telemarketing, 4=Campaign. All 127 rows use NoteTypeID=1 (General).

---

## 2. Business Logic

### 2.1 Note Association

**What**: Links a manager's note to either a registered customer or a pending registration.

**Rules**:
- CID IS NOT NULL -> note is for a registered customer (FK to Customer.CustomerStatic)
- RegistrationRequestID IS NOT NULL -> note is for a pending registration (FK to Customer.RegistrationRequest)
- Both can be set simultaneously (customer who also has a RegistrationRequest)
- CHECK constraint HCNT_NULLABILITY: `(RegistrationRequestID IS NOT NULL OR CID IS NOT NULL)` - at least one is required

### 2.2 Note Types

| NoteTypeID | Name | Usage in this table |
|-----------|------|---------------------|
| 1 | General | 100% of rows - general manager notes |
| 2 | Support | Customer support notes (not used in this data) |
| 3 | Telemarketing | Sales/telemarketing notes |
| 4 | Campaign | Campaign-related notes |

### 2.3 Note Content

The observed notes contain formatted email content sent to customers about withdrawal approvals:
```
"Dear [username], We are happy to inform you that your withdrawal request
of the sum of 300.00 EUR made on 3/8/2017 9:05:03 ..."
```
This suggests the note system was used to store the text of automated notification emails sent to customers, creating an audit trail of communications.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| **Total Rows** | 127 |
| **Date Range** | 2016-09-27 to 2017-04-23 |
| **Distinct Managers** | 3 |
| **Distinct Note Types** | 1 (all NoteTypeID=1=General) |
| **Status** | Inactive since April 2017 |

Sample notes (truncated):

| CustomerNoteID | CID | ManagerID | NoteTypeID | Occurred | Note (snippet) |
|---------------|-----|----------|-----------|---------|----------------|
| 127 | 28 | 723 | 1 | 2017-04-23 | "Dear qqq, We are happy to inform you that your withdrawal request of the sum of 300.00 EUR..." |
| 126 | 28 | 728 | 1 | 2017-03-21 | "Dear qqq, We are happy to inform you that your withdrawal request of 23.00 USD..." |

Note: CID=28 appears to be a test/demo account (username "qqq").

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CustomerNoteID | int IDENTITY | NO | - | VERIFIED | Auto-incremented unique ID. PK. NOT FOR REPLICATION. |
| 2 | CID | int | YES | - | VERIFIED | Customer ID. FK to Customer.CustomerStatic(CID). NULL if note is for a registration request only. CHECK: CID or RegistrationRequestID must be non-NULL. |
| 3 | RegistrationRequestID | uniqueidentifier | YES | - | VERIFIED | Registration request ID. FK to Customer.RegistrationRequest(RegistrationRequestID). Used for notes on pre-registered (pending) customers. NULL if note is for a registered CID only. |
| 4 | ManagerID | int | NO | - | VERIFIED | Back-office manager who wrote the note. FK to BackOffice.Manager(ManagerID). |
| 5 | NoteTypeID | int | NO | - | VERIFIED | Category of note. FK to Dictionary.NoteType. Values: 1=General, 2=Support, 3=Telemarketing, 4=Campaign. All rows: NoteTypeID=1 (General). |
| 6 | Note | varchar(max) | NO | - | VERIFIED | Free-text note content. Can be email body text, manager observation, or any customer-related information. Stored in TEXTIMAGE_ON [HISTORY] filegroup. |
| 7 | Occurred | datetime | NO | getdate() | VERIFIED | When the note was written. DEFAULT = getdate(). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | FK (FK_CCST_HCNT) | The registered customer this note is for. |
| RegistrationRequestID | Customer.RegistrationRequest | FK (FK_CRRQ_HCNT) | The registration request this note is for (pre-registered customer). |
| ManagerID | BackOffice.Manager | FK (FK_BMNG_HCNT) | The manager who wrote the note. |
| NoteTypeID | Dictionary.NoteType | FK (FK_DCNT_HCNT) | Note category: 1=General, 2=Support, 3=Telemarketing, 4=Campaign. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CustomerNote (table)
  -> Customer.CustomerStatic (FK - registered customer, optional)
  -> Customer.RegistrationRequest (FK - pending registration, optional)
  -> BackOffice.Manager (FK - note author)
  -> Dictionary.NoteType (FK - note category)
```

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Options |
|-----------|------|-------------|---------|
| PK_HCNT | CLUSTERED PK | CustomerNoteID ASC | FILLFACTOR=90, on [HISTORY] |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HCNT | PRIMARY KEY | CustomerNoteID, FILLFACTOR=90 |
| FK_BCST_HCNT | Wait - FK_CCST_HCNT | FOREIGN KEY CID -> Customer.CustomerStatic(CID) |
| FK_CRRQ_HCNT | FOREIGN KEY | RegistrationRequestID -> Customer.RegistrationRequest |
| FK_BMNG_HCNT | FOREIGN KEY | ManagerID -> BackOffice.Manager(ManagerID) |
| FK_DCNT_HCNT | FOREIGN KEY | NoteTypeID -> Dictionary.NoteType(NoteTypeID) |
| HCNT_NULLABILITY | CHECK | (RegistrationRequestID IS NOT NULL OR CID IS NOT NULL) |
| HCNT_LASTUPDATE | DEFAULT | Occurred = getdate() |

---

## 8. Sample Queries

### 8.1 Get all notes for a customer
```sql
SELECT cn.CustomerNoteID, cn.Occurred, nt.Name AS NoteType,
       cn.ManagerID, cn.Note
FROM History.CustomerNote cn WITH (NOLOCK)
INNER JOIN Dictionary.NoteType nt ON cn.NoteTypeID = nt.NoteTypeID
WHERE cn.CID = 28
ORDER BY cn.Occurred DESC;
```

### 8.2 Notes by manager
```sql
SELECT cn.ManagerID, COUNT(*) AS NoteCount, MIN(cn.Occurred) AS First, MAX(cn.Occurred) AS Last
FROM History.CustomerNote cn WITH (NOLOCK)
GROUP BY cn.ManagerID
ORDER BY NoteCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. Table represents legacy back-office CRM notes from 2016-2017.

---

*Generated: 2026-03-19 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 6.5/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Dictionary.NoteType values verified via live query*
*Object: History.CustomerNote | Type: Table | Source: etoro/etoro/History/Tables/History.CustomerNote.sql*
