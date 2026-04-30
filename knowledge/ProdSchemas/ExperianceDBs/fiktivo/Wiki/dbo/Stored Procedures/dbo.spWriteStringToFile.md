# dbo.spWriteStringToFile

> OLE Automation procedure that writes a string to a file on the database server's filesystem using Scripting.FileSystemObject, used for exporting data to flat files.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Writes file to server filesystem |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.spWriteStringToFile uses SQL Server's OLE Automation (sp_OACreate, sp_OAMethod) to write string content to a file on the database server's local filesystem. It creates a Scripting.FileSystemObject instance, opens a text file, writes the content, and cleans up the COM objects.

This is a utility procedure for server-side file export - likely used by payment export, report generation, or data export workflows that need to write files to network shares or local paths. Requires the 'Ole Automation Procedures' server configuration option to be enabled.

---

## 2. Business Logic

### 2.1 OLE Automation File Write

**What**: Creates and writes to a text file using COM automation.

**Columns/Parameters Involved**: `@String`, `@Path`, `@Filename`

**Rules**:
- Creates Scripting.FileSystemObject via sp_OACreate
- Calls CreateTextFile with overwrite mode (parameter 2) and Unicode (True)
- Writes the entire @String content via the Write method
- Closes the stream and destroys COM objects
- Error handling captures OLE error info but does NOT raise it (raiserror is commented out)
- File path: @Path + '\' + @Filename

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @String | varchar(max) | IN | - | VERIFIED | The content to write to the file. |
| 2 | @Path | varchar(2550) | IN | - | VERIFIED | Directory path on the server filesystem. E.g., 'C:\exports' or a UNC path. |
| 3 | @Filename | varchar(1000) | IN | - | VERIFIED | The filename to create. E.g., 'report.csv'. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| sp_OACreate | System | OLE Automation | Creates Scripting.FileSystemObject COM instance |
| sp_OAMethod | System | OLE Automation | Calls CreateTextFile, Write, Close methods |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Likely called by export/report procedures.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.spWriteStringToFile (procedure)
  +-- sp_OACreate (system)
  +-- sp_OAMethod (system)
  +-- sp_OAGetErrorInfo (system)
  +-- sp_OADestroy (system)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| sp_OACreate/sp_OAMethod/sp_OADestroy | System procedures | OLE Automation for file I/O |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes
N/A for stored procedure.

### 7.2 Constraints
N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Write a CSV file
```sql
EXEC dbo.spWriteStringToFile
    @String = 'AffiliateID,Name,Email\n1,Test,test@test.com',
    @Path = 'C:\temp',
    @Filename = 'affiliates.csv'
```

### 8.2 Write a report to network share
```sql
EXEC dbo.spWriteStringToFile
    @String = @ReportContent,
    @Path = '\\server\share\reports',
    @Filename = 'monthly_report.txt'
```

### 8.3 Check if OLE Automation is enabled
```sql
EXEC sp_configure 'Ole Automation Procedures'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Quality: 7.8/10*
*Object: dbo.spWriteStringToFile | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.spWriteStringToFile.sql*
