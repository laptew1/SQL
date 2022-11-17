begin tran 
SET TRANSACTION ISOLATION LEVEL serializable
--update  [dbo].[order] 
--set [status] = 'tt'
select [id] from [dbo].[order]
where [id] = '83821726-889d-4c97-b88e-002f87769c62'
--WAITFOR DELAY '00:00:04'
 
COMMIT tran 

begin tran 
--SET TRANSACTION ISOLATION LEVEL serializable
update  [dbo].[order] 
set [status] = 'tt'

where [id] = '7471f469-66e9-49ee-9fc1-0dcfd23602e2' --локалка
COMMIT tran





SELECT
trans.session_id AS [SESSION ID],
ESes.host_name AS [HOST NAME],login_name AS [Login NAME],
trans.transaction_id AS [TRANSACTION ID],
tas.name AS [TRANSACTION NAME],tas.transaction_begin_time AS [TRANSACTION 
BEGIN TIME],
tds.database_id AS [DATABASE ID],DBs.name AS [DATABASE NAME]
FROM sys.dm_tran_active_transactions tas
JOIN sys.dm_tran_session_transactions trans
ON (trans.transaction_id=tas.transaction_id)
LEFT OUTER JOIN sys.dm_tran_database_transactions tds
ON (tas.transaction_id = tds.transaction_id )
LEFT OUTER JOIN sys.databases AS DBs
ON tds.database_id = DBs.database_id
LEFT OUTER JOIN sys.dm_exec_sessions AS ESes
ON trans.session_id = ESes.session_id
WHERE ESes.session_id IS NOT NULL