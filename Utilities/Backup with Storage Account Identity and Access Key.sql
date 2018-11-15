CREATE CREDENTIAL backupSql 
WITH IDENTITY = 'bk20765'  ,
SECRET = 'BOf5hAtak3QyzOjNWTT7TcRmOSpysHHPv5yciznNU5IZnRHa/xZePSrCIjhaiQyY9A86oKunRnMzEdrIbiFdYw==';  

BACKUP DATABASE ExampleDB
TO URL = 'https://bk20765.blob.core.windows.net/backups/data2.bak'
WITH CREDENTIAL = 'backupSql',
	COMPRESSION, FORMAT,
	MEDIANAME = 'MigrationBackups',
	NAME = 'Full Backup of ExampleDB'

--From URL using Storage Account Access Key
RESTORE DATABASE AndresT 
FROM URL = 'https://bk20765.blob.core.windows.net/backups/data2.bak'
WITH  CREDENTIAL = 'backupSql'
	,REPLACE
	,MOVE 'TSQL' TO 'T:\ExampleDB2.mdf'
	,MOVE 'TSQL_log' TO 'T:\ExampleDB_log2.ldf'
	,NORECOVERY  
	,STATS = 5;
	
RESTORE LOG AdventureWorks2016 
FROM URL = 'https://bk20765.blob.core.windows.net/backups/data.trn'   
WITH CREDENTIAL = 'backupSql'
	,RECOVERY  
	,STOPAT = 'May 18, 2015 5:35 PM'   
GO  
