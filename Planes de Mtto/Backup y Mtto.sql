--PASO 0 - CREAR EL SIGUIENTE PROCEDIMIENTO EN LA BD msdb

USE [msdb]
GO
/****** Object:  StoredProcedure [dbo].[sp_DBbackup]    Script Date: 26/12/2018 12:09:57 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER  PROCEDURE [dbo].[sp_DBbackup]
					@path VARCHAR(256)=NULL,
					@NoBackup varchar(1000)
AS
SET NOCOUNT ON
DECLARE @name VARCHAR(100) -- database name
DECLARE @vl_vName VARCHAR(100) -- database name
DECLARE @fileName VARCHAR(500) -- filename for backup  
declare @SQLString nvarchar(1500); 
declare @ListBackup varchar(450);

set  @ListBackup =  char(39) + 'model' + char(39) + ',' +
					char(39) + 'tempdb' + char(39) + ',' +
					char(39) + 'SS_DBA_Dashboard' + char(39) + ',' +
					char(39) + 'ReportServerTempDB' + char(39) + ',' +
					char(39) + 'DataCollection' + char(39);
						

if @NoBackup = 'NULL'

	set @SQLString = 'DECLARE db_cursor CURSOR FOR 
					SELECT name 
					FROM master.sys.databases 
					WHERE state = 0 and 
					name NOT IN (' + @ListBackup + ')'
	
else
	set @SQLString = 'DECLARE db_cursor CURSOR FOR 
					SELECT name 
					FROM master.sys.databases 
					WHERE state = 0 and 
					name NOT IN (' + @ListBackup + ',' + REPLACE(REPLACE(REPLACE(@NoBackup,'!',''''),'¡',''''),'-',''',''') +')'
EXECUTE sp_executesql @SQLString
OPEN db_cursor   
FETCH NEXT FROM db_cursor INTO @name   
WHILE @@FETCH_STATUS = 0   
BEGIN   
		 SET @fileName = @path + @@servername + '_' + @name + '_full.BAK'
		 set @vl_vName =  @name + '-Full Database Backup'
		 print 'BACKUP DATABASE ['+ @name + '] TO DISK = ' + char(39) + @fileName + char(39) +
		 ' WITH NOFORMAT, INIT,  NAME = '+ char(39) + @vl_vName +  char(39) +
		 ',SKIP, NOREWIND, NOUNLOAD'     
		 FETCH NEXT FROM db_cursor INTO @name 
END   
CLOSE db_cursor   
DEALLOCATE db_cursor;


--PASO 1 - CREAR LA SIGUIENTE RUTINA COMO PASO 1 EN UN SCRIPT DENTRO DEL JOB
--Step Name -> DBCretaeFileBackup
--OnFailure -> GoTo Step 8 - DBUserMonitoring
--Retry Attemps -> 3
--Retry Interval Minutes -> 3
USE msdb;
GO
BEGIN TRY


	declare @vlv_command as varchar(1000);
	declare @vl_vClient as varchar(50);
	declare @vlv_path as varchar(1000);
	declare @path_backup as varchar(256);
	
	set @vl_vClient = 'Century'
	set @vlv_path = 'C:\CarpetaMantenimiento\' 
	set @path_backup = 'C:\CarpetaMantenimiento\dbbackup\' 
			 
	set @vlv_command = 'sqlcmd  -S '+@@servername+' -Q "SET NOCOUNT ON exec msdb.dbo.sp_DBbackup ' +char(39)+ @path_backup +char(39) + ','+char(39)+ 'NULL'+char(39)+'" -o '+char(34)+@vlv_path+''+@vl_vClient+'_backup.sql'+char(34)
		       exec msdb.sys.xp_cmdshell @vlv_command
	
END TRY
BEGIN CATCH
		--declare @vl_vClient as varchar (50)
		Declare @vl_subject varchar (100)
		Declare @vl_@body1 varchar(1000)
		Set @vl_vClient = 'Century'
		set @vl_subject = 'FAILURE ' + @vl_vClient + ' (' + substring(@@servername,1,20) + '), L3_MaintenancePlan_MSSQL'
		set @vl_@body1 =  'Step: DBCretaeFileBackup ' +  CHAR(13)+
											'Client: ' + @vl_vClient +','+ char(13)+
											'Server/instance: ' + substring(@@servername,1,20) +','+ char(13)+
											'Edition: ' + cast(SERVERPROPERTY ('edition') as varchar(30)) +','+  CHAR(13) + 
											'ProductVersion: ' + cast(SERVERPROPERTY('productversion') as varchar(20)) +','+ char(13)+ 
											'ProducLevel: ' + cast(SERVERPROPERTY ('productlevel') as varchar(20)) +','+ CHAR(13) +
											'Number Error: ' + cast(ERROR_NUMBER() as varchar(10)) +','+  CHAR(13)  +
											'Message: ' + ERROR_MESSAGE() 
	  print @vl_@body1
	  EXEC dbo.sp_notify_operator
			@profile_name = N'sqlserver_databasemail',
			@name = N'DbaLevel3',
			@subject = @vl_subject,
			@body = @vl_subject 
		select 0/0 
END CATCH


--PASO 2 - CREAR LA SIGUIENTE RUTINA COMO PASO 2 EN UN SCRIPT DENTRO DEL JOB
--Step Name -> DBExcuteFileBackup
--OnFailure -> GoTo Step 8 - DBUserMonitoring
--Retry Attemps -> 3
--Retry Interval Minutes -> 3
USE msdb;
GO
BEGIN TRY
	declare @vlv_command as varchar(500);
	declare @vl_vClient as varchar(50);
	declare @vlv_path as varchar(1000);
	
	set @vlv_path = 'C:\CarpetaMantenimiento\'  
	set @vl_vClient = 'Century'
	
	set @vlv_command = 'sqlcmd  -S '+@@servername+' -i '+char(34)+@vlv_path+''+@vl_vClient+'_backup.sql'+CHAR(34)+' -o '+char(34)+@vlv_path+''+@vl_vClient+'_baclup_log.log'+CHAR(34)
	exec msdb.sys.xp_cmdshell @vlv_command
	
		

END TRY
BEGIN CATCH
		Declare @vl_subject varchar (100)
		Declare @vl_@body1 varchar(1000)
		set @vl_subject = 'FAILURE ' + @vl_vClient + ' (' + substring(@@servername,1,20) + '), L3_MaintenancePlan_MSSQL'
		set @vl_@body1 =  'Step: DBExcuteFileBackup ' +  CHAR(13)+
											'Client: ' + @vl_vClient +','+ char(13)+
											'Server/instance: ' + substring(@@servername,1,20) +','+ char(13)+
											'Edition: ' + cast(SERVERPROPERTY ('edition') as varchar(30)) +','+  CHAR(13) + 
											'ProductVersion: ' + cast(SERVERPROPERTY('productversion') as varchar(20)) +','+ char(13)+ 
											'ProducLevel: ' + cast(SERVERPROPERTY ('productlevel') as varchar(20)) +','+ CHAR(13) +
											'Number Error: ' + cast(ERROR_NUMBER() as varchar(10)) +','+  CHAR(13)  +
											'Message: ' + ERROR_MESSAGE() 
	  print @vl_@body1
	  EXEC dbo.sp_notify_operator
			@profile_name = N'sqlserver_databasemail',
			@name = N'DbaLevel3',
			@subject = @vl_subject,
			@body = @vl_subject 
		select 0/0 
END CATCH


--PASO 3 - CREAR EL SIGUIENTE PROCEDIMIENTO EN LA BD msdb

USE [msdb]
GO
/****** Object:  StoredProcedure [dbo].[sp_DBDefrag]    Script Date: 26/12/2018 3:15:13 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER  PROCEDURE [dbo].[sp_DBDefrag]
				@DBName VARCHAR(80)=NULL,
				@TableName VARCHAR(100)=NULL,
				@frag float=10.0


AS

SET NOCOUNT ON

--declare @DBName VARCHAR(80)
--declare @TableName VARCHAR(100)
--declare @frag float
DECLARE @objectid int
DECLARE @indexid int
DECLARE @partitioncount bigint
DECLARE @schemaname sysname
DECLARE @objectname sysname
DECLARE @indexname sysname
DECLARE @partitionnum bigint
DECLARE @partitions bigint
DECLARE @DB_id INT
DECLARE @StrSQL NVARCHAR(800)
DECLARE @UpdSQL NVARCHAR(800)
DECLARE @command varchar(1000)
DECLARE @command2 varchar(1000)
DECLARE @sDbname VARCHAR(80)
DECLARE @OuterLoop INT
DECLARE @InnerLoop INT
DECLARE @databaseName VARCHAR(80)
declare @vl_irecovery_model int
--DECLARE @ObjectName sysname
DECLARE @StatsName sysname
declare @LogShipping bit
DECLARE @Version bit
declare @compatibility_level int;
 
--set  @DBName = null
--set  @TableName = NULL
--set  @frag =10.0

--Create a table to store databaseNames.
CREATE TABLE #TempDBList
             (DBName VARCHAR(80),
			  compatibility_level int,
              Process INT DEFAULT 0)

CREATE TABLE #Tempobjects
			 (DatabaseName VARCHAR(100),
			  objectID INT,
			  ObjectName VARCHAR(100),
			  SchemaName VARCHAR(100)
			  )

CREATE TABLE #TempIndexes
			 (DatabaseName VARCHAR(80),
			  objectID INT,
			  IndexID INT,
			  IndexName VARCHAR(100)
			  )

CREATE TABLE #TempPartitions
			 (DatabaseName VARCHAR(80),
			  objectID INT,
			  IndexID INT,
			  PartitionID BIGINT,
			  partitioncount BIGINT
			  )

CREATE TABLE #TableList 
			(Tabname VARCHAR(80))


CREATE TABLE #work_to_do
			(DatabaseName VARCHAR(80),
			 objectid int NULL,
		     	 objectName VARCHAR(80),
			 SchemaName VARCHAR(60),
			 indexid  int NULL,
			 PartitionID BIGINT,
			 IndexName VARCHAR(100),
			 partitionnum int NULL,
			 partitioncount bigint,
			 frag float NULL,
			 Status INT Default 0
			) 

IF @DBName IS NULL
BEGIN

	INSERT INTO #TempDBList(DBName,compatibility_level) 
	SELECT [NAME] AS DBName,
			compatibility_level 
	FROM master.sys.databases AS A
	WHERE [NAME] NOT IN ('master','msdb','tempdb','model','pubs')
	--AND status &512 = 0
	AND   isnull(databaseproperty(a.name,'isReadOnly'),0) = 0
	AND    isnull(databaseproperty(a.name,'isOffline'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsSuspect'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsShutDown'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsNotRecovered'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsInStandBy'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsInRecovery'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsInLoad'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsEmergencyMode'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsDetached'),0)  = 0
END

ELSE
BEGIN

	INSERT INTO #TempDBList(DBName,compatibility_level) 
	SELECT [NAME] AS DBName,
			compatibility_level 
	FROM master.sys.databases AS A
	WHERE [NAME] NOT IN ('master','msdb','tempdb','model','pubs')
	--AND status &512 = 0
	AND   isnull(databaseproperty(a.name,'isReadOnly'),0) = 0
	AND    isnull(databaseproperty(a.name,'isOffline'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsSuspect'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsShutDown'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsNotRecovered'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsInStandBy'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsInRecovery'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsInLoad'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsEmergencyMode'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsDetached'),0)  = 0
	AND [Name]=@DBName

END



--Loop over the databases
DECLARE DBCursor CURSOR
FOR SELECT DBNAME,compatibility_level
        FROM #TempDBList
       WHERE Process=0
	   ORDER BY DBNAME ASC

OPEN DBCursor

FETCH DBCursor INTO @sDbname,@compatibility_level 

--Save the fetch status to a variable
SELECT @OuterLoop = @@FETCH_STATUS

WHILE @OuterLoop = 0
BEGIN

		

-- Conditionally select tables and indexes from the sys.dm_db_index_physical_stats function 
-- and convert object and index IDs to names.

--Get the DBID

SET @db_id = DB_ID(@sDbname)


SELECT @StrSQL = N'SELECT'+' ''' +@sDbName+''' AS DatabaseName'+ ','+'soj.object_id, QUOTENAME'+'('+'sc.[Name]'+')'+'AS SchemaName,'+
		         'QUOTENAME'+'('+ 'soj.[Name])AS objectName FROM '+ QuoteName(@sDbName) 
		         +'.'+'sys.objects soj JOIN '+QuoteName(@sDbName)+'.'+
                 'sys.schemas sc ON soj.schema_id=sc.schema_id WHERE [type] = ''U'''      

INSERT INTO #Tempobjects(DatabaseName,
			 objectid,
			 SchemaName,
			 ObjectName
			 )

EXEC sp_executesql @StrSQL


INSERT INTO #work_to_do 
		(DatabaseName,
		 objectID,
		 IndexID,
	     	 PartitionID,
	         Partitionnum,
		 Frag
		 )
SELECT
    DB_NAME(@db_id) AS DatabaseName,
    object_id AS objectid,
    index_id AS indexid,
	NULL AS PartitionID,
    partition_number AS partitionnum,
    avg_fragmentation_in_percent AS frag
FROM sys.dm_db_index_physical_stats (@db_id, NULL, NULL , NULL, 'limited')
WHERE 
	avg_fragmentation_in_percent > @Frag 
	AND index_id > 0
	--and record_count  > 10000
	--and avg_fragmentation_in_percent > 60

IF (SELECT COUNT(DISTINCT DatabaseName) FROM #work_to_do
	 WHERE DatabaseName=@sDbname) = 0
		BEGIN
		PRINT ''
		--PRINT 'Indexing in Database: ' + @sDbname
		--PRINT '___________________________________'
		--PRINT 'Re indexing for tables not needed in this Database. Fragmentation levels ok.'
		--PRINT ''
END

ELSE
BEGIN
		--PRINT ''
		--PRINT ''
		--PRINT ''
		PRINT 'SET NOCOUNT ON'
		PRINT 'Use ' + @sDbname
		PRINT 'go'
		
		
		select @vl_irecovery_model = recovery_model 
		from sys.databases 
		where name in (@sDbname)
		
		select @LogShipping=COUNT(1) 
			from msdb.dbo.log_shipping_monitor_primary 
			where primary_database=@sDbname
		
		if(@LogShipping=0)
			begin
				if (@vl_irecovery_model = 1) or (@vl_irecovery_model = 2) 
				begin 
					print 'ALTER DATABASE [' + @sDbname  +'] SET RECOVERY SIMPLE WITH NO_WAIT'
					print 'GO'
					print ''
				end
			end
		  
END

SELECT @StrSQL= N'SELECT '+' ''' +@sDbName+''' AS DatabaseName'+ ','+ 'si.name, si.object_id,si.Index_ID
  				 FROM ' + QuoteName(@sDbName)+'.'+'sys.indexes si INNER JOIN #work_to_do W' +
				 ' ON  si.object_id = W.objectid' +
				 ' AND si.index_id = W.indexid '  +
				 ' AND EXISTS (SELECT DatabaseName FROM #work_to_do WHERE DatabaseName='+' ''' +@sDbName+''')'

INSERT INTO #TempIndexes 
			(DatabaseName,
			 IndexName,
			 objectID,
			 IndexID)

EXEC sp_executesql @StrSQL

SELECT @StrSQL= N'SELECT '+' ''' +@sDbName+''' AS DatabaseName'+','+'count (*) AS Partitioncount ' +','+
				 'spi.object_id, spi.index_id  
				  FROM ' + QuoteName(@sDbName)+'.'+' sys.partitions spi INNER JOIN #work_to_do W' +
				 ' ON  spi.object_id = W.objectid' +
				 ' AND spi.index_id = W.indexid' +
				 ' GROUP BY DatabaseName,spi.object_ID,spi.index_id' 


INSERT INTO #TempPartitions
			(DatabaseName,
			 partitioncount,
			 objectID,
			 IndexID
			 )

EXEC sp_executesql @StrSQL
			  

--Update ObjectName and SchemaName
UPDATE W
SET W.ObjectName=T.objectName,
	W.SchemaName=T.SchemaName
FROM #work_to_do W,
     #Tempobjects T
WHERE W.DatabaseName=T.DatabaseName
AND   T.DatabaseName=@sDbName
AND W.objectid=T.objectID

--Update the IndexName
UPDATE W
SET W.IndexName=T.IndexName
FROM #work_to_do W,
	 #TempIndexes T
WHERE W.DatabaseName=T.DatabaseName
AND   T.DatabaseName=@sDbName
AND   W.objectid=T.objectID
AND   W.IndexID = T.IndexID



--Update the PartitionCount

UPDATE W
SET W.Partitioncount=T.partitioncount
FROM #work_to_do W,
     #TempPartitions T
WHERE W.DatabaseName=T.DatabaseName
AND   T.DatabaseName=@sDbName
AND   W.objectid=T.objectID
AND   W.IndexID = T.IndexID


--Select * from #Work_to_do


-- Declare the cursor for the list of partitions to be processed.
IF @TableName IS NULL
BEGIN
		DECLARE partitions CURSOR 
		FOR 
		SELECT DatabaseName,
			   objectID,
			   objectName,
			   SchemaName,
			   indexID,
			   indexName,
			   Partitionnum,
			   partitioncount,
			   frag
		FROM   #work_to_do
		WHERE Status=0
		ORDER BY DatabaseName ASC
END
ELSE
	BEGIN

			INSERT INTO #TableList (Tabname)
			SELECT TABLENAME
			FROM dbo.fnCSV_To_Table(@TableName)

		DECLARE partitions CURSOR 
		FOR 
		SELECT DatabaseName,
			   objectID,
			   objectName,
			   SchemaName,
			   indexID,
			   indexName,
			   Partitionnum,
			   partitioncount,
			   frag
		FROM   #work_to_do
		WHERE Status=0
		AND  objectName IN 
					(SELECT QUOTENAME(TabName) FROM #TableList)
		ORDER BY DatabaseName ASC

	END

-- Open the cursor.
OPEN partitions

-- Loop through the partitions.
FETCH NEXT
   FROM partitions
   INTO @databaseName,
		@objectid, 
		@objectName,
		@schemaname,
		@indexid, 
		@indexName,
		@partitionnum, 
		@partitioncount,
		@frag



WHILE @@FETCH_STATUS = 0
    BEGIN

	
	
	if	(@frag > 5 and @frag < 30) 
		begin 
			--PRINT ''
			if(@LogShipping=0)
			begin
				SELECT @command = 'ALTER INDEX ' + QuoteName(@indexname) + ' ON ' + QuoteName(@databaseName) + '.' + @schemaname + '.' + @objectname + ' REORGANIZE WITH ( LOB_COMPACTION = ON )';
		 	end 
		 	--select @command2 = 'UPDATE STATISTICS ' + QuoteName(@databaseName)+'.'+ @schemaname +'.'+@objectname+' ' +QuoteName(@indexname) +' WITH FULLSCAN '
			--print @command
			/*
			IF @partitioncount > 1
				BEGIN
					SELECT @command = @command + ' PARTITION=' + CONVERT (CHAR, @partitionnum);
				END
			*/
		end 
	else 
		begin 
			--PRINT ''
			if(@LogShipping=0)
			begin
				if  @compatibility_level in (90,10,11)
					SELECT @command = 'ALTER INDEX ' + QuoteName(@indexname) + ' ON ' + QuoteName(@databaseName) + '.' + @schemaname + '.' + @objectname + 
													' REBUILD PARTITION = ALL WITH ( FILLFACTOR = 90, PAD_INDEX  = OFF, '+
			  									'STATISTICS_NORECOMPUTE  = ON, ALLOW_ROW_LOCKS  = ON, ' + 		
			  									'ALLOW_PAGE_LOCKS  = ON, ONLINE = OFF, SORT_IN_TEMPDB = ON )';
				else 
					SELECT @command = 'ALTER INDEX ' + QuoteName(@indexname) + ' ON ' + QuoteName(@databaseName) + '.' + @schemaname + '.' + @objectname + 
												' REBUILD  WITH ( FILLFACTOR = 90, PAD_INDEX  = OFF, '+
			  									'STATISTICS_NORECOMPUTE  = ON, ALLOW_ROW_LOCKS  = ON, ' + 		
			  									'ALLOW_PAGE_LOCKS  = ON, ONLINE = OFF, SORT_IN_TEMPDB = ON )';
			
		   	end
		   	--select @command2 = 'UPDATE STATISTICS ' + QuoteName(@databaseName)+'.'+ @schemaname +'.'+@objectname+' ' +QuoteName(@indexname) +' WITH FULLSCAN '
			
			
			--SELECT @command = 'DBCC DBREINDEX ('+ char(39) + @databaseName  + '.' + @schemaname  + '.' + @objectname +  char(39) + ',' + char(39) +char(39)  + ',' + '90); '
			 

			--print @command
			/*
			IF @partitioncount >= 1
				BEGIN
					SELECT @command = @command + ' PARTITION=' + CONVERT (CHAR, @partitionnum);
					
				END
			*/
		end 
		--print @command
		--print @partitioncount
	
	print  (@command);
	--print  (@command2);
	


	--PRINT 'Executed ' + @command + ' Successfully.';

				UPDATE #work_to_do
				SET Status=1
				WHERE DatabaseName=@databaseName

FETCH NEXT 
FROM partitions 
INTO @databaseName,@objectid, @objectName,@schemaName,@indexid, @indexName,@partitionnum,@partitioncount, @frag
END
-- Close and deallocate the cursor.
CLOSE partitions
DEALLOCATE partitions

--Update the processed database status
	 UPDATE #TempDBList 
	 SET Process = 1
	 WHERE DBName = @sDbname  

	 DELETE FROM #TempDBList 
	 WHERE Process=1
	 AND DBName=@sdbName

    --Fetch next database
    --PRINT 'Fetching the next database'
    
    if(@LogShipping=0)
		begin
    	if (@vl_irecovery_model = 1)  
			begin
				print '' 
				print 'ALTER DATABASE [' + @sDbname  +'] SET RECOVERY FULL WITH NO_WAIT'
				print 'GO'
			end
		else if (@vl_irecovery_model = 2)
				begin 
					print ''
					print 'ALTER DATABASE [' + @sDbname  +'] SET RECOVERY BULK_LOGGED WITH NO_WAIT'
					print 'GO'
					
				end 
	end

    FETCH DBCursor into @sDbname,@compatibility_level 


    SELECT @OuterLoop = @@FETCH_STATUS

END

CLOSE DBCursor
DEALLOCATE DBCursor

-- Drop the temporary table

DROP TABLE #work_to_do
DROP TABLE #TempDBList
DROP TABLE #Tempobjects
DROP TABLE #TempIndexes
DROP TABLE #TempPartitions
DROP TABLE #TableList

--PASO 3.1 - CREAR LA SIGUIENTE RUTINA COMO PASO 3 EN UN SCRIPT DENTRO DEL JOB
--Step Name -> DBCreateFileIndexDefrag
--OnFailure -> GoTo Step 5 - DBCreateFileUpdateStats
--Retry Attemps -> 3
--Retry Interval Minutes -> 3

USE msdb;
GO
BEGIN TRY

	declare @vlv_namedatabase varchar(100)
	declare @vlv_command varchar(1000)
	declare @vlv_path varchar(1000)
	DECLARE @OuterLoop INT

	set @vlv_path = 'C:\Test\' 

	DECLARE DBCursor CURSOR
	FOR SELECT [NAME] AS DBName 
		FROM master.dbo.sysdatabases AS A
		WHERE [NAME] NOT IN ('master','msdb','tempdb','model','pubs','SS_DBA_Dashboard')
		

	OPEN DBCursor
	FETCH DBCursor INTO @vlv_namedatabase 
	SELECT @OuterLoop = @@FETCH_STATUS
	WHILE @OuterLoop = 0
	BEGIN
		set @vlv_command = 'sqlcmd  -S '+@@servername+' -Q "SET NOCOUNT ON exec msdb.dbo.sp_DBDefrag ' + CHAR(39)+ @vlv_namedatabase + CHAR(39) + ',null,10.0" -o '+char(34)+@vlv_path+''+@vlv_namedatabase+'defrag.sql'+char(34)
		exec msdb.sys.xp_cmdshell @vlv_command
		
			
		FETCH DBCursor into @vlv_namedatabase
		SELECT @OuterLoop = @@FETCH_STATUS
	END

	CLOSE DBCursor
	DEALLOCATE DBCursor
  
END TRY
BEGIN CATCH
		declare @vl_vClient as varchar (50)
		Declare @vl_subject varchar (100)
		Declare @vl_@body1 varchar(1000)
		Set @vl_vClient = 'Century'
		set @vl_subject = 'FAILURE ' + @vl_vClient + ' (' + substring(@@servername,1,20) + '), L3_MaintenancePlan_MSSQL'
		set @vl_@body1 =  'Step: DBCreateFileIndexDefrag, ' +  CHAR(13)+
											'Client: ' + @vl_vClient +','+ char(13)+
											'Server/instance: ' + substring(@@servername,1,20) +','+ char(13)+
											'Edition: ' + cast(SERVERPROPERTY ('edition') as varchar(30)) +','+  CHAR(13) + 
											'ProductVersion: ' + cast(SERVERPROPERTY('productversion') as varchar(20)) +','+ char(13)+ 
											'ProducLevel: ' + cast(SERVERPROPERTY ('productlevel') as varchar(20)) +','+ CHAR(13) +
											'Number Error: ' + cast(ERROR_NUMBER() as varchar(10)) +','+  CHAR(13)  +
											'Message: ' + ERROR_MESSAGE() 
		
		print @vl_@body1 
		EXEC dbo.sp_notify_operator
			@profile_name = N'sqlserver_databasemail',
			@name = N'DbaLevel3',
			@subject = @vl_subject,
			@body = @vl_subject 
	select 0/0
END CATCH


--PASO 4 - CREAR LA SIGUIENTE RUTINA COMO PASO 4 EN UN SCRIPT DENTRO DEL JOB
--Step Name -> DBExecuteFileIndexDefrag
--OnFailure -> GoTo Step 5 - DBCreateFileUpdateStats
--Retry Attemps -> 3
--Retry Interval Minutes -> 3


USE msdb;
GO
BEGIN TRY

	declare @vlv_namedatabase varchar(100)
	declare @vlv_command varchar(1000)
	declare @vlv_path varchar(1000)
	DECLARE @OuterLoop INT

	set @vlv_path = 'C:\Test\' 

	DECLARE DBCursor CURSOR
	FOR SELECT [NAME] AS DBName 
		FROM master.dbo.sysdatabases AS A
		WHERE [NAME] NOT IN ('master','msdb','tempdb','model','pubs','SS_DBA_Dashboard')
		

	OPEN DBCursor
	FETCH DBCursor INTO @vlv_namedatabase 
	SELECT @OuterLoop = @@FETCH_STATUS
	WHILE @OuterLoop = 0
	BEGIN
		set @vlv_command = 'sqlcmd  -S '+@@servername+' -d '+ @vlv_namedatabase + ' -i '+ char(34) + @vlv_path+''+@vlv_namedatabase+'defrag.sql' + CHAR(34) +' -o '+ char(34) + @vlv_path+''+@vlv_namedatabase+'defrag_log.log' + CHAR(34)
		exec msdb.sys.xp_cmdshell @vlv_command
		
		FETCH DBCursor into @vlv_namedatabase
		SELECT @OuterLoop = @@FETCH_STATUS
	END

	CLOSE DBCursor
	DEALLOCATE DBCursor
  
END TRY
BEGIN CATCH
		declare @vl_vClient as varchar (50)
		Declare @vl_subject varchar (100)
		Declare @vl_@body1 varchar(1000)
		Set @vl_vClient = 'Century'
		set @vl_subject = 'FAILURE ' + @vl_vClient + ' (' + substring(@@servername,1,20) + '), L3_MaintenancePlan_MSSQL'
		set @vl_@body1 =  'Step: DBExecuteFileIndexDefrag, ' +  CHAR(13)+
											'Client: ' + @vl_vClient +','+ char(13)+
											'Server/instance: ' + substring(@@servername,1,20) +','+ char(13)+
											'Edition: ' + cast(SERVERPROPERTY ('edition') as varchar(30)) +','+  CHAR(13) + 
											'ProductVersion: ' + cast(SERVERPROPERTY('productversion') as varchar(20)) +','+ char(13)+ 
											'ProducLevel: ' + cast(SERVERPROPERTY ('productlevel') as varchar(20)) +','+ CHAR(13) +
											'Number Error: ' + cast(ERROR_NUMBER() as varchar(10)) +','+  CHAR(13)  +
											'Message: ' + ERROR_MESSAGE() 
	  print @vl_@body1 
	  EXEC dbo.sp_notify_operator
			@profile_name = N'sqlserver_databasemail',
			@name = N'DbaLevel3',
			@subject = @vl_subject,
			@body = @vl_subject 
	select 0/0
END CATCH

--PASO 5 - CREAR LA SIGUIENTE FUNCION EN LA BD msdb

USE [msdb]
GO
/****** Object:  UserDefinedFunction [dbo].[fnCSV_To_Table]    Script Date: 27/12/2018 8:43:41 a. m. ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO


/**************************************************************************************
 Purpose:  The Purpose of this User Defined fucntion is to separate a comma separated value list
	   and create a table based on that list and return the table to the calling process.
                     


Date Created: May 02, 2006

Modification History:
Date          	Who              What

=============  ===============  ====================================      
*/


CREATE OR ALTER  FUNCTION [dbo].[fnCSV_To_Table] (@List varchar(1000))  

RETURNS @retListTable TABLE (TABLENAME varchar(80) NULL)  AS
BEGIN

   -- table variable to hold accumulated results

   DECLARE @ListTable TABLE (TABLENAME VARCHAR(80) NULL)
   DECLARE @Pos int
   DECLARE @NextPos int
   DECLARE @ListLen int

-- Get first value

SET @List=@List + ','
SET @ListLen=LEN(@List)
SET @Pos=CHARINDEX(',',@List) 

--Check if the position is greater than zero.

IF  (@Pos > 0 )
BEGIN
	INSERT INTO @ListTable (TABLENAME)
	VALUES (convert(VARCHAR(80),substring(@List,1,@Pos-1)))
END
ELSE
BEGIN
	INSERT INTO @ListTable (TABLENAME)
	VALUES (convert(VARCHAR(80),substring(@List,1,@ListLen-1)))
END

SET @NextPos=CHARINDEX(',',@List,@Pos+1)

--Loop through to find all other occurances

WHILE @NextPos>0
BEGIN

	INSERT INTO @ListTable (TABLENAME)
	values (convert(VARCHAR(80),substring(@List,@Pos+1,@NextPos-@Pos-1)))

	SET @Pos=CHARINDEX(',',@List,@Pos+1)  
	SET @NextPos=CHARINDEX(',',@List,@Pos+1)
END


   
-- copy to the result of the function the required columns
INSERT INTO @retListTable
SELECT TABLENAME
FROM @ListTable
RETURN

END


--PASO 5.1 - CREAR LA SIGUIENTE FUNCION EN LA BD msdb


USE [msdb]
GO
/****** Object:  UserDefinedFunction [dbo].[fnCSV_To_Database]    Script Date: 27/12/2018 8:49:35 a. m. ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO


/**************************************************************************************
 Purpose:  The Purpose of this User Defined fucntion is to separate 
	   a comma separated value list and create a Database list
           based on that list and return the table to the calling process.
                     


Date Created: July 07, 2006

Modification History:
Date          	Who              What

=============  ===============  ====================================      
*/


CREATE OR ALTER  FUNCTION [dbo].[fnCSV_To_Database] (@List varchar(1000))  

RETURNS @retListDB TABLE (DBName varchar(80) NULL)  AS
BEGIN

   -- table variable to hold accumulated results

   DECLARE @ListDB TABLE (DatabaseName VARCHAR(80) NULL)
   DECLARE @Pos int
   DECLARE @NextPos int
   DECLARE @ListLen int

-- Get first value

SET @List=@List + ','
SET @ListLen=LEN(@List)
SET @Pos=CHARINDEX(',',@List) 

--Check if the position is greater than zero.

IF  (@Pos > 0 )
BEGIN
	INSERT INTO @ListDB (DatabaseName)
	VALUES (convert(VARCHAR(80),substring(@List,1,@Pos-1)))
END
ELSE
BEGIN
	INSERT INTO @ListDB (DatabaseName)
	VALUES (convert(VARCHAR(80),substring(@List,1,@ListLen-1)))
END

SET @NextPos=CHARINDEX(',',@List,@Pos+1)

--Loop through to find all other occurances

WHILE @NextPos>0
BEGIN

	INSERT INTO @ListDB (DatabaseName)
	values (convert(VARCHAR(80),substring(@List,@Pos+1,@NextPos-@Pos-1)))

	SET @Pos=CHARINDEX(',',@List,@Pos+1)  
	SET @NextPos=CHARINDEX(',',@List,@Pos+1)
END


   
-- copy to the result of the function the required columns
INSERT INTO @retListDB
SELECT DatabaseName
FROM @ListDB
RETURN

END


--PASO 5.2 - CREAR EL SIGUIENTE PROCEDIMIENTO EN LA BD msdb

USE [msdb]
GO
/****** Object:  StoredProcedure [dbo].[sp_DBUpdateStats]    Script Date: 27/12/2018 8:37:28 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_DBUpdateStats]
		       @DBName VARCHAR(80)=NULL,
		       @TableName VARCHAR(80)=NULL,
		       @Sample INT=10,
		       @Scanflag bit=0
AS

SET NOCOUNT ON

DECLARE @StrSQL NVARCHAR(2000)
DECLARE @sDbname VARCHAR(80)
DECLARE @tblName VARCHAR(80)
DECLARE @schmaName VARCHAR(80)
DECLARE @OuterLoop INT
DECLARE @InnerLoop INT
DECLARE @Version VARCHAR(255)
DECLARE @ErrorMessage VARCHAR(400)

SELECT @Version=CASE 
						/*
			      WHEN CHARINDEX ('8.00',@@version)>0 then 'SQL Server 2000'
			      WHEN CHARINDEX ('9.00',@@version)>0 then 'SQL Server 2005'
			      WHEN CHARINDEX ('10.00',@@version)>0 then 'SQL Server 2008'
			      */
			      WHEN CHARINDEX ('8.',@@version)>0 then 'SQL Server 2000'
			      WHEN CHARINDEX ('9.',@@version)>0 then 'SQL Server 2005'
			      WHEN CHARINDEX ('10.',@@version)>0 then 'SQL Server 2008'
			      WHEN CHARINDEX ('11.',@@version)>0 then 'SQL Server 2008'
			      
		                   ELSE 'UnKnown'
		END



--Create a Temp table to store
-- the table Names


CREATE TABLE #TempTableList
			 (SchemaName VARCHAR(80),
			  TableName VARCHAR(80)
			  )

--Create a table to store databaseNames.
CREATE TABLE #TempDBList
             (DBName VARCHAR(80),
              Process INT DEFAULT 0
			  )

CREATE TABLE #TableList (Tabname VARCHAR(80))

--Check If dbname is passed as null and a table is passed. 
--Raise an error in that situation.

SET @ErrorMessage='Updating Statistics Requires a Database Name.In order to update statistics on single or multiple tables'+CHAR(13)+CHAR(10)
    		          +'both the database and table names must be passed.'

IF (@DBNAME IS NULL AND @TableName IS NOT NULL)
BEGIN
	RAISERROR (@Errormessage,16,1)
	RETURN
END



--Get the database. Exclude read only databases.
IF @DBName IS NULL
BEGIN

	INSERT INTO #TempDBList(DBName) 
	SELECT [NAME] AS DBName FROM master.dbo.sysdatabases AS A
	WHERE [NAME] NOT IN ('master','msdb','tempdb','Adventureworks','model','pubs')
	AND status &512 = 0
	AND   isnull(databaseproperty(a.name,'isReadOnly'),0) = 0
	AND    isnull(databaseproperty(a.name,'isOffline'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsSuspect'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsShutDown'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsNotRecovered'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsInStandBy'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsInRecovery'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsInLoad'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsEmergencyMode'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsDetached'),0)  = 0
	AND NOT EXISTS (SELECT B.[NAME]
   		     FROM msdb..SQLDBUpdateStatsExclusions b
  		     WHERE A.[NAME] = b.[NAME])
	ORDER BY [Name] ASC

END

ELSE
BEGIN



	INSERT INTO #TempDBList(DBName) 
	SELECT [NAME] AS DBName FROM master.dbo.sysdatabases AS A
	WHERE [NAME] NOT IN ('master','msdb','tempdb','Adventureworks','model','pubs')
	AND status &512 = 0
	AND   isnull(databaseproperty(a.name,'isReadOnly'),0) = 0
	AND    isnull(databaseproperty(a.name,'isOffline'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsSuspect'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsShutDown'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsNotRecovered'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsInStandBy'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsInRecovery'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsInLoad'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsEmergencyMode'),0)  = 0
	AND    isnull(databaseproperty(a.name,'IsDetached'),0)  = 0
	AND [Name] IN  (SELECT DBName
			 FROM dbo.fnCSV_To_Database(@DBName)
			)

END



--Loop over the databases
DECLARE DBCursor CURSOR
FOR SELECT DBNAME
        FROM #TempDbList
       WHERE Process=0

OPEN DBCursor

FETCH DBCursor INTO @sDbname 

--Save the fetch status to a variable
SELECT @OuterLoop = @@FETCH_STATUS



WHILE @OuterLoop = 0
BEGIN
--print 'entro'


IF @Version='SQL Server 2012'
BEGIN
	
  SELECT @StrSQL = N'SELECT QUOTENAME'+'('+'sc.[Name]'+')'+'AS SchemaName,'+
		         'QUOTENAME'+'('+ 'soj.[Name])AS TableName FROM '+ QuoteName(@sDbName) 
		         +'.'+'sys.objects soj JOIN '+QuoteName(@sDbName)+'.'+
                  	          'sys.schemas sc ON soj.schema_id=sc.schema_id WHERE [type] = ''U'''      
END

IF @Version='SQL Server 2008'
BEGIN
	
  SELECT @StrSQL = N'SELECT QUOTENAME'+'('+'sc.[Name]'+')'+'AS SchemaName,'+
		         'QUOTENAME'+'('+ 'soj.[Name])AS TableName FROM '+ QuoteName(@sDbName) 
		         +'.'+'sys.objects soj JOIN '+QuoteName(@sDbName)+'.'+
                  	          'sys.schemas sc ON soj.schema_id=sc.schema_id WHERE [type] = ''U'''      
END
	 
IF @Version='SQL Server 2005'
BEGIN
	
  SELECT @StrSQL = N'SELECT QUOTENAME'+'('+'sc.[Name]'+')'+'AS SchemaName,'+
		         'QUOTENAME'+'('+ 'soj.[Name])AS TableName FROM '+ QuoteName(@sDbName) 
		         +'.'+'sys.objects soj JOIN '+QuoteName(@sDbName)+'.'+
                  	          'sys.schemas sc ON soj.schema_id=sc.schema_id WHERE [type] = ''U'''      
END

IF @Version='SQL Server 2000'
BEGIN
	SELECT @StrSQL = N'SELECT QUOTENAME(''dbo'') As SchemaName, QUOTENAME([NAME]) As TableName  FROM ' + QuoteName(@sDbName) +'.'+'dbo.sysobjects where type = ''U'' and uid = 1 AND [NAME] NOT LIKE ''dt%'''
	

END

                           
	    --PRINT 'Inserting into temp table from ' + @sDbname

	    
	
		  --Insert the names into the temp table for processing
			INSERT INTO #TempTableList 
					(SchemaName,
					TableName)
			EXEC sp_executesql @StrSQL
			

		 --Declare the inner cursor to process each table
		PRINT 'SET NOCOUNT ON' 
		PRINT 'Use ' + @sDbname
		PRINT 'go'
		
	
		IF @TableName IS NULL
			BEGIN
				    DECLARE TableCursor CURSOR FOR
					SELECT SchemaName,
                    					TableName 
				    FROM #TempTableList
			        ORDER BY TableName ASC
			END
			ELSE
				BEGIN

					INSERT INTO #TableList (Tabname)
					SELECT TABLENAME
					FROM dbo.fnCSV_To_Table(@TableName)

					DECLARE TableCursor CURSOR FOR
					SELECT SchemaName,
						   TableName 
				    	FROM #TempTableList
			        		WHERE TableName IN 
							(SELECT QUOTENAME(TabName) FROM #TableList)
					ORDER BY TableName ASC

														
				END

							  
			--Open and perform initial fetch
			--PRINT 'Opening table cursor on database: ' + @sDbname

			OPEN TableCursor
		
				
			FETCH TableCursor INTO @schmaName,@tblName

         --Save fetch status into local variable
           SELECT @InnerLoop = @@FETCH_STATUS

    WHILE @InnerLoop = 0
    BEGIN
            --Create the update statstics command and execute
	    IF @Scanflag=0
	    BEGIN
		    --PRINT ('Updating stats on ' + QuoteName(@sDbname) +'.'+@schmaName+'.'+@tblName)+ ' WITH SAMPLE ' + CONVERT(VARCHAR(30),@Sample) + ' Percent'
	        SELECT @StrSQL = N'Update Statistics ' + QuoteName(@sDbname) +'.'+@schmaName+'.'+@tblName + ' WITH SAMPLE ' + CONVERT(VARCHAR(30),@Sample) + ' Percent'
	    END

	    ELSE
		BEGIN
	            --PRINT ('Updating stats on ' + QuoteName(@sDbname) +'.'+@schmaName+'.'+@tblName)+ ' WITH FULLSCAN '
        	    SELECT @StrSQL = N'Update Statistics ' + QuoteName(@sDbname) +'.'+@schmaName+'.'+@tblName + ' WITH FULLSCAN '
		END

            
            --EXEC sp_executesql @StrSQL
            print @StrSQL
            

           --Fetch next table to process
           --PRINT 'Fetching next table'

	       FETCH TableCursor INTO @schmaName,@tblName

           --Save fetch status into local variable
           SELECT @InnerLoop = @@FETCH_STATUS
    END

    --Cleanup temp table and cursor
    --PRINT 'Truncating temp table and deallocating tables cursor'

    TRUNCATE TABLE #TempTableList

    CLOSE TableCursor
    DEALLOCATE TableCursor

	--Update the processed database status
	 UPDATE #TempDbList 
	 SET Process = 1
	 WHERE DBName = @sDbname  

    --Fetch next database
    --PRINT 'Fetching the next database'

    FETCH DBCursor into @sDbname

    --Save fetch status to local variable
    SELECT @OuterLoop = @@FETCH_STATUS


END

CLOSE DBCursor
DEALLOCATE DBCursor

DROP TABLE #TempTableList
DROP TABLE #TableList
DROP TABLE #TempDBList


--PASO 5.3 - CREAR LA SIGUIENTE RUTINA COMO PASO 5 EN UN SCRIPT DENTRO DEL JOB
--Step Name -> DBCreateFileUpdateStats
--OnFailure -> GoTo Step 7 - DBShrinkFile
--Retry Attemps -> 3
--Retry Interval Minutes -> 3


USE msdb;
GO
BEGIN TRY

	declare @vlv_namedatabase varchar(100)
	declare @vlv_command varchar(1000)
	declare @vlv_path varchar(1000)
	DECLARE @OuterLoop INT

	set @vlv_path = 'C:\Test\' 

	DECLARE DBCursor CURSOR
	FOR SELECT [NAME] AS DBName 
		FROM master.dbo.sysdatabases AS A
		WHERE [NAME] NOT IN ('master','msdb','tempdb','model','pubs','SS_DBA_Dashboard')
		

	OPEN DBCursor
	FETCH DBCursor INTO @vlv_namedatabase 
	SELECT @OuterLoop = @@FETCH_STATUS
	WHILE @OuterLoop = 0
	BEGIN
		set @vlv_command = 'sqlcmd  -S '+@@servername+'  -Q "SET NOCOUNT ON exec msdb.dbo.sp_DBUpdateStats ' + CHAR(39)+ @vlv_namedatabase + CHAR(39) + ',null,10.0" -o '+char(34)+@vlv_path+''+@vlv_namedatabase+'stats.sql'+char(34)
		exec msdb.sys.xp_cmdshell @vlv_command
		
		
		FETCH DBCursor into @vlv_namedatabase
		SELECT @OuterLoop = @@FETCH_STATUS
	END

	CLOSE DBCursor
	DEALLOCATE DBCursor
  
END TRY
BEGIN CATCH
		declare @vl_vClient as varchar (50)
		Declare @vl_subject varchar (100)
		Declare @vl_@body1 varchar(1000)
		Set @vl_vClient = 'Century'
		set @vl_subject = 'FAILURE ' + @vl_vClient + ' (' + substring(@@servername,1,20) + '), L3_MaintenancePlan_MSSQL'
		set @vl_@body1 =  'Step: DBCreateFileUpdateStats, ' +  CHAR(13)+
											'Client: ' + @vl_vClient +','+ char(13)+
											'Server/instance: ' + substring(@@servername,1,20) +','+ char(13)+
											'Edition: ' + cast(SERVERPROPERTY ('edition') as varchar(30)) +','+  CHAR(13) + 
											'ProductVersion: ' + cast(SERVERPROPERTY('productversion') as varchar(20)) +','+ char(13)+ 
											'ProducLevel: ' + cast(SERVERPROPERTY ('productlevel') as varchar(20)) +','+ CHAR(13) +
											'Number Error: ' + cast(ERROR_NUMBER() as varchar(10)) +','+  CHAR(13)  +
											'Message: ' + ERROR_MESSAGE() 
		
		print @vl_@body1 
		EXEC dbo.sp_notify_operator
			@profile_name = N'sqlserver_databasemail',
			@name = N'DbaLevel3',
			@subject = @vl_subject,
			@body = @vl_subject 
	select 0/0
END CATCH


--PASO 6 - CREAR LA SIGUIENTE RUTINA COMO PASO 6 EN UN SCRIPT DENTRO DEL JOB
--Step Name -> DBExecuteFileUpdateStats
--OnFailure -> GoTo Step 7 - DBShrinkFile
--Retry Attemps -> 3
--Retry Interval Minutes -> 3


USE msdb;
GO
BEGIN TRY

	declare @vlv_namedatabase varchar(100)
	declare @vlv_command varchar(1000)
	declare @vlv_path varchar(1000)
	DECLARE @OuterLoop INT

	set @vlv_path = 'C:\Test\' 

	DECLARE DBCursor CURSOR
	FOR SELECT [NAME] AS DBName 
		FROM master.dbo.sysdatabases AS A
		WHERE [NAME] NOT IN ('master','msdb','tempdb','model','pubs','SS_DBA_Dashboard')
		

	OPEN DBCursor
	FETCH DBCursor INTO @vlv_namedatabase 
	SELECT @OuterLoop = @@FETCH_STATUS
	WHILE @OuterLoop = 0
	BEGIN
		set @vlv_command = 'sqlcmd  -S '+@@servername+' -d ' + @vlv_namedatabase + ' -i '+char(34)+@vlv_path+''+@vlv_namedatabase+'Stats.sql'+char(34)+' -o '+char(34)+@vlv_path+''+@vlv_namedatabase+'stats_log.log'+char(34)
		exec msdb.sys.xp_cmdshell @vlv_command

		FETCH DBCursor into @vlv_namedatabase
		SELECT @OuterLoop = @@FETCH_STATUS
	END

	CLOSE DBCursor
	DEALLOCATE DBCursor
  
END TRY
BEGIN CATCH
		declare @vl_vClient as varchar (50)
		Declare @vl_subject varchar (100)
		Declare @vl_@body1 varchar(1000)
		Set @vl_vClient = 'Century'
		set @vl_subject = 'FAILURE ' + @vl_vClient + ' (' + substring(@@servername,1,20) + '), L3_MaintenancePlan_MSSQL'
		set @vl_@body1 =  'Step: DBExecuteFileUpdateStats, ' +  CHAR(13)+
											'Client: ' + @vl_vClient +','+ char(13)+
											'Server/instance: ' + substring(@@servername,1,20) +','+ char(13)+
											'Edition: ' + cast(SERVERPROPERTY ('edition') as varchar(30)) +','+  CHAR(13) + 
											'ProductVersion: ' + cast(SERVERPROPERTY('productversion') as varchar(20)) +','+ char(13)+ 
											'ProducLevel: ' + cast(SERVERPROPERTY ('productlevel') as varchar(20)) +','+ CHAR(13) +
											'Number Error: ' + cast(ERROR_NUMBER() as varchar(10)) +','+  CHAR(13)  +
											'Message: ' + ERROR_MESSAGE() 
	  print @vl_@body1 
	  EXEC dbo.sp_notify_operator
			@profile_name = N'sqlserver_databasemail',
			@name = N'DbaLevel3',
			@subject = @vl_subject,
			@body = @vl_subject 
	select 0/0
END CATCH


--PASO 7 - CREAR LA SIGUIENTE RUTINA COMO PASO 7 EN UN SCRIPT DENTRO DEL JOB
--Step Name -> DBShrinkFile
--OnFailure -> GoTo Next Step
--Retry Attemps -> 3
--Retry Interval Minutes -> 3


USE msdb;
GO

declare @vl_vClient as varchar (50)
Declare @vl_subject varchar (100)
Declare @vl_@body1 varchar(4000)
declare @vl_vNameJob varchar(50)
declare @vl_vNameStep varchar(50)

set @vl_vNameJob = 'L3_MaintenancePlan_MSSQL'
set @vl_vNameStep = 'DBShrinkFile'
Set @vl_vClient = 'Century'

BEGIN TRY
	
	DECLARE @Database VARCHAR(MAX), @vl_tRecovery tinyint;
	-- recovery_model 
	-- 1 = full
	-- 3 = simple
	DECLARE log_cursor CURSOR LOCAL FOR 
			SELECT name,recovery_model from sys.databases 
			WHERE name NOT IN('master', 'model', 'msdb', 'tempdb','SS_DBA_Dashboard') 
			and state = 0  
			ORDER BY name 
			
	OPEN log_cursor
	FETCH NEXT FROM log_cursor INTO @Database ,@vl_tRecovery

	WHILE @@FETCH_STATUS = 0
	BEGIN 
		DECLARE @Query NVARCHAR(MAX) 
		
				
		if (@vl_tRecovery = 1 or @vl_tRecovery = 2) 
		begin 
			SET @Query = 'ALTER DATABASE [' + @Database + '] SET RECOVERY SIMPLE WITH NO_WAIT'
			exec (@Query)
		end  
		
		DECLARE @LogFile NVARCHAR(MAX), @ParmDefinition NVARCHAR(500)
		SET @Query = 'USE [' + @Database + '] SELECT @LogFile = name FROM [' + @Database + '].dbo.sysfiles WHERE filename LIKE ''%.ldf'' or filename LIKE ''%.LDF'''
		SET @ParmDefinition = '@LogFile VARCHAR(MAX) OUTPUT'
		EXECUTE sp_executesql @Query, @ParmDefinition, @LogFile = @LogFile OUTPUT 
		SET @Query = 'USE [' + @Database + '] DBCC SHRINKFILE ([' + @LogFile + '], 0)'
		EXEC(@Query) 
		if @vl_tRecovery = 1 
		begin 
			SET @Query = 'ALTER DATABASE [' + @Database + '] SET RECOVERY FULL WITH NO_WAIT'
			exec (@Query)
		end  
		if @vl_tRecovery = 2 
		begin 
			SET @Query = 'ALTER DATABASE [' + @Database + '] SET RECOVERY BULK_LOGGED WITH NO_WAIT'
			exec (@Query)
		end 		
		FETCH NEXT FROM log_cursor INTO @Database,@vl_tRecovery
	END 
	CLOSE log_cursor
	DEALLOCATE log_cursor
			
END TRY
BEGIN CATCH
	DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    set @ErrorSeverity = ERROR_SEVERITY()
    set @ErrorState = ERROR_STATE()
   
	set @vl_subject = 'FAILURE ' + @vl_vClient + ' (' + substring(@@servername,1,20) + '), '+ @vl_vNameJob   
	set @vl_@body1 =  'Step: ' + @vl_vNameStep + ', ' +  CHAR(13)+
										'Client: ' + @vl_vClient +','+ char(13)+
										'Server/instance: ' + substring(@@servername,1,20) +','+ char(13)+
										'Edition: ' + cast(SERVERPROPERTY ('edition') as varchar(30)) +','+  CHAR(13) + 
										'ProductVersion: ' + cast(SERVERPROPERTY('productversion') as varchar(20)) +','+ char(13)+ 
										'ProducLevel: ' + cast(SERVERPROPERTY ('productlevel') as varchar(20)) +','+ CHAR(13) +
										'Number Error: ' + cast(ERROR_NUMBER() as varchar(10)) +','+  CHAR(13)  +
										'Message: ' + ERROR_MESSAGE() +','+  CHAR(13)  +
										'ErrorSeverity: ' + ERROR_SEVERITY() +','+  CHAR(13)  +
										'ErrorState: ' + ERROR_STATE()
	--print   @vl_@body1 
	EXEC dbo.sp_notify_operator
			@profile_name = N'sqlserver_databasemail',
			@name = N'DbaLevel3',
			@subject = @vl_subject,
			@body = @vl_@body1 

		
	RAISERROR (@vl_@body1, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
			   --select 0/0
END CATCH


--PASO 8 - CREAR LA SIGUIENTE RUTINA COMO PASO 8 EN UN SCRIPT DENTRO DEL JOB
--Step Name -> DBUserMonitoring
--OnFailure -> GoTo Next Step
--Retry Attemps -> 3
--Retry Interval Minutes -> 3


USE msdb;
GO

declare @vl_vClient as varchar (50)
Declare @vl_subject varchar (100)
Declare @vl_@body1 varchar(4000)
declare @vl_vNameJob varchar(50)
declare @vl_vNameStep varchar(50)

set @vl_vNameJob = 'L3_MaintenancePlan_MSSQL'
set @vl_vNameStep = 'DBUserMonitoring'
Set @vl_vClient = 'Century'

BEGIN TRY
	
	IF NOT EXISTS(
	SELECT name 
	FROM [master].[sys].[syslogins]
	WHERE NAME = 'usrmonitoreo')
	BEGIN 
		CREATE LOGIN [usrmonitoreo] WITH PASSWORD=N'm0n1t0r30#A', 
		DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
	END
	EXECUTE master.sys.sp_MSforeachdb 
		'USE [?]
			if (select 1 from sys.databases where name = ''?'' and is_read_only = 0 and state = 0 and compatibility_level >= 90) = 1
			begin 
				IF NOT EXISTS(
					SELECT name 
					FROM [?].[sys].[sysusers]
					WHERE NAME = ''usrmonitoreo'')
				begin
					IF ''?'' in (''master'')
					BEGIN
						CREATE USER [usrmonitoreo] FOR LOGIN [usrmonitoreo] WITH DEFAULT_SCHEMA=[sys];
						GRANT create table to usrmonitoreo
						GRANT select ON syscurconfigs to usrmonitoreo
						GRANT select ON sys.sysperfinfo to usrmonitoreo
						GRANT select ON sys.sysprocesses to usrmonitoreo
						GRANT select ON sys.dm_tran_locks to usrmonitoreo
						GRANT select ON sys.sysconfigures to usrmonitoreo
						GRANT select ON sys.databases to usrmonitoreo
						GRANT select ON sys.sysdatabases to usrmonitoreo
						GRANT select ON sys.sysfiles to usrmonitoreo
						GRANT select ON sys.sysindexes to usrmonitoreo
						GRANT select ON sys.sysobjects to usrmonitoreo
						GRANT select ON sys.sysdevices to usrmonitoreo
						GRANT execute ON sys.sp_monitor to usrmonitoreo
						GRANT execute ON sys.xp_sqlagent_enum_jobs to usrmonitoreo
						GRANT VIEW SERVER STATE to usrmonitoreo
					end	
					else
					begin
						IF ''?'' in (''msdb'')
						begin
							CREATE USER [usrmonitoreo] FOR LOGIN [usrmonitoreo] WITH DEFAULT_SCHEMA=[dbo] 
							GRANT select ON msdb..sysjobs to usrmonitoreo
							GRANT select ON msdb..sysjobhistory to usrmonitoreo
							GRANT select ON msdb..sysjobsteps to usrmonitoreo
							GRANT select ON msdb..sysjobschedules to usrmonitoreo
							GRANT select ON msdb..sysjobs_view to usrmonitoreo
						end
						else 
							CREATE USER [usrmonitoreo] FOR LOGIN [usrmonitoreo] WITH DEFAULT_SCHEMA=[sys]
					end
				end
				else
					exec sp_change_users_login ''auto_fix'',''usrmonitoreo''
				end'
	IF EXISTS(select * from msdb.sys.objects where name = 'MSdistributiondbs')
	begin
		GRANT select ON msdb..MSdistributiondbs	to usrmonitoreo
		GRANT select ON distribution..MSmerge_agents to usrmonitoreo
		GRANT select ON distribution..MSmerge_history to usrmonitoreo
		GRANT select ON distribution..MSmerge_sessions to usrmonitoreo
		GRANT select ON distribution..MSsnapshot_agents to usrmonitoreo
		GRANT select ON distribution..MSlogreader_agents to usrmonitoreo
		GRANT select ON distribution..MSdistribution_history to usrmonitoreo
		GRANT select ON distribution..MSsnapshot_history to usrmonitoreo
		GRANT select ON distribution..MSlogreader_history to usrmonitoreo
		GRANT select ON distribution..MSdistribution_agents to usrmonitoreo
	end

	
			
END TRY
BEGIN CATCH
	DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    set @ErrorSeverity = ERROR_SEVERITY()
    set @ErrorState = ERROR_STATE()
   
	set @vl_subject = 'FAILURE ' + @vl_vClient + ' (' + substring(@@servername,1,20) + '), '+ @vl_vNameJob   
	set @vl_@body1 =  'Step: ' + @vl_vNameStep + ', ' +  CHAR(13)+
										'Client: ' + @vl_vClient +','+ char(13)+
										'Server/instance: ' + substring(@@servername,1,20) +','+ char(13)+
										'Edition: ' + cast(SERVERPROPERTY ('edition') as varchar(30)) +','+  CHAR(13) + 
										'ProductVersion: ' + cast(SERVERPROPERTY('productversion') as varchar(20)) +','+ char(13)+ 
										'ProducLevel: ' + cast(SERVERPROPERTY ('productlevel') as varchar(20)) +','+ CHAR(13) +
										'Number Error: ' + cast(ERROR_NUMBER() as varchar(10)) +','+  CHAR(13)  +
										'Message: ' + ERROR_MESSAGE() +','+  CHAR(13)  +
										'ErrorSeverity: ' + ERROR_SEVERITY() +','+  CHAR(13)  +
										'ErrorState: ' + ERROR_STATE()
	--print   @vl_@body1 
	EXEC dbo.sp_notify_operator
			@profile_name = N'sqlserver_databasemail',
			@name = N'DbaLevel3',
			@subject = @vl_subject,
			@body = @vl_@body1 

		
	RAISERROR (@vl_@body1, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
			   --select 0/0
END CATCH


--PASO 8 - CREAR LA SIGUIENTE TABLA EN LA BD msdb


USE [msdb]
GO

/****** Object:  Table [dbo].[DatabaseChangeLogDbar]    Script Date: 27/12/2018 9:40:55 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DatabaseChangeLogDbar](
	[LogId] [int] IDENTITY(1,1) NOT NULL,
	[DatabaseName] [varchar](256) NULL,
	[EventType] [varchar](50) NULL,
	[ObjectName] [varchar](256) NULL,
	[ObjectType] [varchar](25) NULL,
	[SqlCommand] [varchar](max) NULL,
	[EventDate] [datetime] NULL,
	[LoginName] [varchar](256) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[DatabaseChangeLogDbar] ADD  CONSTRAINT [DF_DBChangeLog_EventDate]  DEFAULT (getdate()) FOR [EventDate]
GO


--PASO 8.1 - CREAR LA SIGUIENTE RUTINA COMO PASO 8 EN UN SCRIPT DENTRO DEL JOB
--Step Name -> DBUserAudit
--OnFailure -> GoTo Next Step
--Retry Attemps -> 3
--Retry Interval Minutes -> 3


USE msdb;
GO

declare @vl_vClient as varchar (50)
Declare @vl_subject varchar (100)
Declare @vl_@body1 varchar(4000)
declare @vl_vNameJob varchar(50)
declare @vl_vNameStep varchar(50)

set @vl_vNameJob = 'L3_MaintenancePlan_MSSQL'
set @vl_vNameStep = 'DBUserAudit'
Set @vl_vClient = 'Century'

BEGIN TRY
	
	declare @vl_vName as varchar(500)
	declare @SQLString as nvarchar(1000)
	DECLARE db_cursor CURSOR FOR 
						SELECT name FROM sys.server_principals where type not in ('C','R') and name not in ('sa')
	OPEN db_cursor   
	FETCH NEXT FROM db_cursor INTO @vl_vName   
	WHILE @@FETCH_STATUS = 0   
	BEGIN   
			IF NOT EXISTS (SELECT * FROM DBO.SYSUSERS WHERE NAME = @vl_vName )
			BEGIN
				set @SQLString = 'USE [msdb] CREATE USER [' + @vl_vName + '] FOR LOGIN [' + @vl_vName + '] '
				EXECUTE sp_executesql @SQLString
				set @SQLString = 'GRANT INSERT ON [dbo].[DatabaseChangeLogDbar] TO [' + @vl_vName + ']'
				EXECUTE sp_executesql @SQLString
				PRINT 'Grant  Login ' + @vl_vName
			END ELSE BEGIN  
				PRINT 'already  Login ' + @vl_vName  
			END
		
			 FETCH NEXT FROM db_cursor INTO @vl_vName 
	END   
	CLOSE db_cursor   
	DEALLOCATE db_cursor;	
			
END TRY
BEGIN CATCH
	DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    set @ErrorSeverity = ERROR_SEVERITY()
    set @ErrorState = ERROR_STATE()
   
	set @vl_subject = 'FAILURE ' + @vl_vClient + ' (' + substring(@@servername,1,20) + '), '+ @vl_vNameJob   
	set @vl_@body1 =  'Step: ' + @vl_vNameStep + ', ' +  CHAR(13)+
										'Client: ' + @vl_vClient +','+ char(13)+
										'Server/instance: ' + substring(@@servername,1,20) +','+ char(13)+
										'Edition: ' + cast(SERVERPROPERTY ('edition') as varchar(30)) +','+  CHAR(13) + 
										'ProductVersion: ' + cast(SERVERPROPERTY('productversion') as varchar(20)) +','+ char(13)+ 
										'ProducLevel: ' + cast(SERVERPROPERTY ('productlevel') as varchar(20)) +','+ CHAR(13) +
										'Number Error: ' + cast(ERROR_NUMBER() as varchar(10)) +','+  CHAR(13)  +
										'Message: ' + ERROR_MESSAGE() +','+  CHAR(13)  +
										'ErrorSeverity: ' + ERROR_SEVERITY() +','+  CHAR(13)  +
										'ErrorState: ' + ERROR_STATE()
	--print   @vl_@body1 
	EXEC dbo.sp_notify_operator
			@profile_name = N'sqlserver_databasemail',
			@name = N'DbaLevel3',
			@subject = @vl_subject,
			@body = @vl_@body1 

		
	RAISERROR (@vl_@body1, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
			   --select 0/0
END CATCH


--PASO 9 - CREAR LA SIGUIENTE RUTINA COMO PASO 9 EN UN SCRIPT DENTRO DEL JOB
--Step Name -> DBCleanAudit
--OnFailure -> GoTo Next Step
--Retry Attemps -> 3
--Retry Interval Minutes -> 3


USE msdb;
GO

declare @vl_vClient as varchar (50)
Declare @vl_subject varchar (100)
Declare @vl_@body1 varchar(4000)
declare @vl_vNameJob varchar(50)
declare @vl_vNameStep varchar(50)

set @vl_vNameJob = 'L3_MaintenancePlan_MSSQL'
set @vl_vNameStep = 'DBCleanAudit'
Set @vl_vClient = 'Century'

BEGIN TRY
	
	delete from [msdb].[dbo].[DatabaseChangeLogDbar] where EventDate < DATEADD(month, -3, GETDATE())
			
END TRY
BEGIN CATCH
	DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    set @ErrorSeverity = ERROR_SEVERITY()
    set @ErrorState = ERROR_STATE()
   
	set @vl_subject = 'FAILURE ' + @vl_vClient + ' (' + substring(@@servername,1,20) + '), '+ @vl_vNameJob   
	set @vl_@body1 =  'Step: ' + @vl_vNameStep + ', ' +  CHAR(13)+
										'Client: ' + @vl_vClient +','+ char(13)+
										'Server/instance: ' + substring(@@servername,1,20) +','+ char(13)+
										'Edition: ' + cast(SERVERPROPERTY ('edition') as varchar(30)) +','+  CHAR(13) + 
										'ProductVersion: ' + cast(SERVERPROPERTY('productversion') as varchar(20)) +','+ char(13)+ 
										'ProducLevel: ' + cast(SERVERPROPERTY ('productlevel') as varchar(20)) +','+ CHAR(13) +
										'Number Error: ' + cast(ERROR_NUMBER() as varchar(10)) +','+  CHAR(13)  +
										'Message: ' + ERROR_MESSAGE() +','+  CHAR(13)  +
										'ErrorSeverity: ' + ERROR_SEVERITY() +','+  CHAR(13)  +
										'ErrorState: ' + ERROR_STATE()
	--print   @vl_@body1 
	EXEC dbo.sp_notify_operator
			@profile_name = N'sqlserver_databasemail',
			@name = N'DbaLevel3',
			@subject = @vl_subject,
			@body = @vl_@body1 

		
	RAISERROR (@vl_@body1, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
			   --select 0/0
END CATCH


--PASO 10 - CREAR LA SIGUIENTE RUTINA COMO PASO 10 EN UN SCRIPT DENTRO DEL JOB
--Step Name -> DBSendMailSatisfactory
--OnFailure -> GoTo Next Step
--Retry Attemps -> 0
--Retry Interval Minutes -> 0


USE msdb;
GO
BEGIN TRY
	declare @vl_vClient as varchar (50)
	Declare @vl_subject varchar (100)
	Declare @vl_body1 varchar(1000)
	Declare @vl_vNameJob varchar(50)
	Declare @vl_vNameStep varchar(50)
	
	Set @vl_vClient = 'Century'
	Set @vl_vNameStep = 'DBSendMailSatisfactory'
	set @vl_vNameJob  = msdb.dbo.fn_NameJob (@vl_vNameStep) 
	
	set @vl_subject = 'Satisfactory, ' + @vl_vClient + ' (' + substring(@@servername,1,20) + '), ' + @vl_vNameJob + ' ' 
	set @vl_body1 =  'Job : ' + @vl_vNameJob + ' , ' +  CHAR(13)+
						'Step: ' + @vl_vNameStep + ' , ' +  CHAR(13)+
						'Client: ' + @vl_vClient +','+ char(13)+
						'Server/instance: ' + substring(@@servername,1,20) +','+ char(13)+
						'Edition: ' + cast(SERVERPROPERTY ('edition') as varchar(30)) +','+  CHAR(13) + 
						'ProductVersion: ' + cast(SERVERPROPERTY('productversion') as varchar(20)) +','+ char(13)+ 
						'ProducLevel: ' + cast(SERVERPROPERTY ('productlevel') as varchar(20)) +','+ char(13)+
						'DateHour: ' + convert(varchar(50),getdate(),121);
						
	
	EXEC dbo.sp_notify_operator
			@profile_name = N'sqlserver_databasemail',
			@name = N'DbaLevel3',
			@subject = @vl_subject,
			@body = @vl_body1
	
		
END TRY
BEGIN CATCH
   
	-- get error of system
	DECLARE @ErrorSeverity INT;
    	DECLARE @ErrorState INT;
	set @ErrorSeverity = ERROR_SEVERITY()
    	set @ErrorState = ERROR_STATE()
	
	Set @vl_vClient = 'Century'
	set @vl_subject = 'FAILURE ' + @vl_vClient + ' (' + substring(@@servername,1,20) + '), ' + @vl_vNameJob + ' ' 
	set @vl_body1 =  'Step: '+ @vl_vNameStep + ', ' +  CHAR(13)+
										'Client: ' + @vl_vClient +','+ char(13)+
										'Server/instance: ' + substring(@@servername,1,20) +','+ char(13)+
										'Edition: ' + cast(SERVERPROPERTY ('edition') as varchar(30)) +','+  CHAR(13) + 
										'ProductVersion: ' + cast(SERVERPROPERTY('productversion') as varchar(20)) +','+ char(13)+ 
										'ProducLevel: ' + cast(SERVERPROPERTY ('productlevel') as varchar(20)) +','+ CHAR(13) +
										'Number Error: ' + cast(ERROR_NUMBER() as varchar(10)) +','+  CHAR(13)  +
										'Message: ' + ERROR_MESSAGE() 
		
	--print   @vl_body1 
	EXEC dbo.sp_notify_operator
			@profile_name = N'sqlserver_databasemail',
			@name = N'DbaLevel3',
			@subject = @vl_subject,
			@body = @vl_body1 

		
	RAISERROR (@vl_body1, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
	);
	--select 0/0
END CATCH


