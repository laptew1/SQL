SELECT *,cast (message_body as nvarchar) as message_body_nvarchar 
		 FROM test_queue2

SELECT *,cast (last_send_tran_id as nvarchar) as message_body_nvarchar  FROM sys.conversation_endpoints
go

--clear QUEUE [auto_repair_shops].[dbo].[test_queue2]
--DROP QUEUE [auto_repair_shops].sys.conversation_endpoints

--RECEIVE * FROM [auto_repair_shops].[dbo].[test_queue2]
--if object_id('tempdb..##test') is not null
--	 drop table ##test
go

--create table ##test
--go


-- инициатор
begin tran

	DECLARE @h uniqueidentifier
	DECLARE @message nvarchar (100)

	begin dialog conversation @h
		from service test_service2 to service 'test_service2'
		--on contract test_contract
		with
		encryption = off; --, --LIFETIME = 3
		--begin
		set @message = '{"id":"2f9d9d39-62b7-4292-92d6-731a07786efd"}';

		SEND ON CONVERSATION @h (@message) ;
		--end conversation @h;
		--select @message  as fmoprfgmpo;
		---- Убеждаемся, что диалог открыт успешно
		--	select getdate(), conversation_handle, lifetime, state_desc from sys.conversation_endpoints;
		
		--	set @message = '{"id":"2f9d9d39-62b7-4292-92d6-731a07786efd"}';
		--	if object_id('tempdb..##test') is not null
		--	drop table ##test;
		--	SEND ON CONVERSATION @h message type [DEFAULT](@message) ;
			
		--	exec [dbo].[fdfd];
		--	-- Ждем смерти диалога
		----	WAITFOR DELAY '00:00:04';
		--	-- Убеждаемся, что диалог умер
		--	select getdate(), conversation_handle, lifetime, state_desc from sys.conversation_endpoints;
		--end
	--end conversation @h WITH CLEANUP;
commit tran
go

--select * from ##test;
--go

/* интересн но не нужн...
DECLARE @dialog UNIQUEIDENTIFIER;
		WAITFOR(
			RECEIVE TOP (1) 
				@dialog = conversation_handle 
			from  test_queue2
		), TIMEOUT 0;
		IF @@ROWCOUNT = 0 
		BEGIN
		  PRINT 'No message available.' ;
		END
		ELSE
		BEGIN
		  END CONVERSATION @dialog;
		END
*/