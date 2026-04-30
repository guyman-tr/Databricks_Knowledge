# Customer.ApplicationActivation

> Tracks when users activated specific applications/platforms, recording the activation date per GCID and application combination.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | GCID + ApplicationID (composite PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Customer.ApplicationActivation records the date when a user activated a specific application or platform feature. The composite primary key (GCID, ApplicationID) allows tracking multiple application activations per user. This supports multi-product analytics and onboarding tracking across eToro's product suite.

---

## 2. Business Logic

No complex multi-column business logic patterns detected.

---

## 3. Data Overview

N/A - transactional table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Part of composite PK. Global Customer ID. |
| 2 | ApplicationID | int | NO | - | CODE-BACKED | Part of composite PK. Identifier for the application/platform being activated. |
| 3 | ActivationDate | datetime | NO | - | CODE-BACKED | When the user activated this application. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.ActivateApplication | GCID | SP writes | Records application activation |
| Customer.GetApplicationActivationDate | GCID | SP reads | Returns activation date |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.ActivateApplication | Stored Procedure | Inserts rows |
| Customer.GetApplicationActivationDate | Stored Procedure | Reads from |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ApplicationActivation | CLUSTERED PK | GCID, ApplicationID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get activation date for a user
```sql
SELECT ApplicationID, ActivationDate FROM Customer.ApplicationActivation WITH (NOLOCK) WHERE GCID = @GCID
```

### 8.2 Check if user activated a specific app
```sql
SELECT CASE WHEN EXISTS (SELECT 1 FROM Customer.ApplicationActivation WITH (NOLOCK) WHERE GCID = @GCID AND ApplicationID = @AppID) THEN 1 ELSE 0 END AS IsActivated
```

### 8.3 Recent activations
```sql
SELECT TOP 100 GCID, ApplicationID, ActivationDate FROM Customer.ApplicationActivation WITH (NOLOCK) ORDER BY ActivationDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Customer.ApplicationActivation | Type: Table | Source: UserApiDB/UserApiDB/Customer/Tables/Customer.ApplicationActivation.sql*
