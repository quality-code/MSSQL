USE MASTER
GO

CREATE TABLE #TMPSPACEUSED (
  DBNAME    VARCHAR(300),
  FILENME   VARCHAR(300),
  MAXSIZE    int,
  GROWTH   int, 
  SPACEUSED FLOAT)

INSERT INTO #TMPSPACEUSED
EXEC( 'sp_msforeachdb''use [?]; Select ''''?'''' DBName, Name FileNme,maxsize,growth, fileproperty(Name,''''SpaceUsed'''') SpaceUsed from sysfiles''')


--select distinct concat('DBCC SHRINKDATABASE(N''',tt.databasename,''')') from 
select distinct 'DBCC SHRINKDATABASE(N''' + tt.databasename + ''')' from 
( 
SELECT
         A.NAME AS DATABASENAME,
         B.NAME AS FILENAME,
         CASE B.TYPE 
           WHEN 0 THEN 'DATA'
           ELSE TYPE_DESC
         END AS FILETYPE,
         /*
         CASE 
           WHEN (B.SIZE * 8 / 1024.0) > 1000 THEN CAST(CAST(((B.SIZE * 8 / 1024) / 1024.0) AS DECIMAL(18,2)) AS VARCHAR(20)) --+ ' GB'
           ELSE CAST(CAST((B.SIZE * 8 / 1024.0) AS DECIMAL(18,2)) AS VARCHAR(20)) --+ ' MB'
         END AS FILESIZEMB,
         */
          CAST(CAST(((B.SIZE * 8 / 1024) / 1024.0) AS DECIMAL(18,2)) AS VARCHAR(100))  FILESIZEGB,
          CAST(CAST((B.SIZE * 8 / 1024.0) AS DECIMAL(18,2)) AS VARCHAR(100)) FILESIZEMB,
          CAST((B.SIZE * 8 / 1024.0) - (D.SPACEUSED / 128.0) AS DECIMAL(15,2))    SPACEFREEMB,
          CAST(CAST((B.GROWTH * 8 / 1024.0) AS DECIMAL(18,2)) AS VARCHAR(100)) GROWTHMB,
          case D.MAXSIZE
                                    when 0 then 'No growth'
                                    when -1 then 'File will grow until the disk is full' 
                                    else 'Log file will grow to a maximum size of 2 TB' 
                          end MAXSIZE ,
          B.PHYSICAL_NAME
FROM     SYS.DATABASES A
         JOIN SYS.MASTER_FILES B
           ON A.DATABASE_ID = B.DATABASE_ID
   
         JOIN #TMPSPACEUSED D
           ON A.NAME = D.DBNAME
              AND B.NAME = D.FILENME
where  b.physical_name like 'E:\mssqlserverdata1%'   
--and (CAST(CAST((B.GROWTH * 8 / 1024.0) AS DECIMAL(18,2)) AS VARCHAR(100))) > 0.00
and (CAST(CAST((B.GROWTH * 8 / 1024.0) AS DECIMAL(18,2)) AS VARCHAR(100))) not in ('0.00')
--where --A.name not in ( 'master','msdb','ReportServer','ReportServerTempDB','model','tempdb') 
            --a.name in ('WSS_Logging')  
--          b.physical_name like '%WSS_Logging.md'         
) tt
DROP TABLE #TMPSPACEUSED
