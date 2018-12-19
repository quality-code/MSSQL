--**********************************************************************************
--*************OPCION 1 - CORRE EL SP_WHO2 PARA PODERLO MANIPULAR*******************
--**********************************************************************************
CREATE TABLE #sp_who2 (SPID INT,Status VARCHAR(255),
      Login  VARCHAR(255),HostName  VARCHAR(255),
      BlkBy  VARCHAR(255),DBName  VARCHAR(255),
      Command VARCHAR(255),CPUTime INT,
      DiskIO INT,LastBatch VARCHAR(255),
      ProgramName VARCHAR(255),SPID2 INT,
      REQUESTID INT)
INSERT INTO #sp_who2 EXEC sp_who2 'ACTIVE'
SELECT      *
FROM        #sp_who2
-- Add any filtering of the results here :
WHERE       DBName NOT IN ('master','msdb','tempdb')
-- Add any sorting of the results here :
ORDER BY    DBName ASC,CPUTime DESC
 
DROP TABLE #sp_who2

--**********************************************************************************
--********************* OPCION 2 - RETORNA PROCESOS BLOQUEADOS *********************
--**********************************************************************************
USE Master
GO
SELECT 
  SDER.session_id,
  [DataBase] = DB_NAME(SDER.database_id),
  SES.host_name,
  SES.program_name,
  SES.login_name,
  CASE  
     WHEN SDER.[statement_start_offset] > 0 THEN 
        --The start of the active command is not at the beginning of the full command text
        CASE SDER.[statement_end_offset] 
           WHEN -1 THEN 
              --The end of the full command is also the end of the active statement
              SUBSTRING(DEST.TEXT, (SDER.[statement_start_offset]/2) + 1, 2147483647)
           ELSE  
              --The end of the active statement is not at the end of the full command
              SUBSTRING(DEST.TEXT, (SDER.[statement_start_offset]/2) + 1, (SDER.[statement_end_offset] - SDER.[statement_start_offset])/2 + 1)  
        END 
     ELSE 
        --1st part of full command is running
        CASE SDER.[statement_end_offset] 
           WHEN -1 THEN 
              --The end of the full command is also the end of the active statement
              RTRIM(LTRIM(DEST.[text])) 
           ELSE 
              --The end of the active statement is not at the end of the full command
              LEFT(DEST.TEXT, (SDER.[statement_end_offset]/2) +1) 
        END 
     END AS [executing statement], 
  DEST.[text] AS [full statement code],
  SDER.wait_time,
  SDER.cpu_time,
  SDER.total_elapsed_time,
  SDER.reads,
  SDER.writes,
  SDER.logical_reads
FROM sys.[dm_exec_requests] SDER 
	JOIN sys.dm_exec_sessions SES ON SDER.session_id = SES.session_id
	CROSS APPLY sys.[dm_exec_sql_text](SDER.[sql_handle]) DEST 
WHERE SDER.session_id > 50 
AND DB_NAME(SDER.database_id) NOT IN ('master','msdb','tempdb')
AND SDER.blocking_session_id <> 0
ORDER BY SDER.[session_id], SDER.[request_id]
GO
--Query Enviado por Ana Lopez
SELECT session_id , client_net_address , t.text
FROM sys.dm_exec_connections c
CROSS APPLY sys.dm_exec_sql_text (c.most_recent_sql_handle) t
WHERE c.session_id in (SELECT distinct blocking_session_id
FROM sys.dm_os_waiting_tasks
WHERE blocking_session_id IS NOT NULL)
GO

--**********************************************************************************
--**** OPCION 3 - Devuelve Info sobre tareas que están a la espera de recursos. ****
--**********************************************************************************
USE Master
GO
SELECT session_id, wait_duration_ms, wait_type, blocking_session_id 
FROM sys.dm_os_waiting_tasks 
WHERE blocking_session_id <> 0
GO
