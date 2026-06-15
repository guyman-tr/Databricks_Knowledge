import pyodbc
conn=pyodbc.connect(
    "Driver={ODBC Driver 18 for SQL Server};"
    "Server=stg-synapse-dataplatform-we.sql.azuresynapse.net;"
    "Database=sql_dp_stg_we_BI_no_retention;"
    "UID=guyman@etoro.com;"
    "Authentication=ActiveDirectoryInteractive;"
    "Encrypt=yes;TrustServerCertificate=no;Connection Timeout=60",
    timeout=60)
conn.autocommit=True
c=conn.cursor()

c.execute("SELECT SCHEMA_NAME(schema_id) AS s, name FROM sys.tables WHERE name LIKE '%External%Customer%' OR name LIKE '%External_etoro%' ORDER BY name")
for r in c.fetchall():
    print(r)
