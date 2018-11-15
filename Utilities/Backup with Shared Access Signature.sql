CREATE CREDENTIAL [https://bk20765.blob.core.windows.net/backups]   
WITH IDENTITY = 'SHARED ACCESS SIGNATURE',    
SECRET = 'sv=2018-03-28&si=Backups&sr=c&sig=wkhPWqAxGDIxJO1Sv5m%2FQ5ExJVadUW2B6O0%2B1hcqwwA%3D';  


BACKUP DATABASE ExampleDB
TO URL = 'https://bk20765.blob.core.windows.net/backups/data.bak'
WITH COMPRESSION, FORMAT,
	MEDIANAME = 'MigrationBackups',
	NAME = 'Full Backup of ExampleDB'

RESTORE DATABASE Andres 
FROM URL = 'https://bk20765.blob.core.windows.net/backups/data.bak'
WITH  REPLACE,
	MOVE 'TSQL' TO 'T:\ExampleDB.mdf', 
	MOVE 'TSQL_log' TO 'T:\ExampleDB_log.ldf';