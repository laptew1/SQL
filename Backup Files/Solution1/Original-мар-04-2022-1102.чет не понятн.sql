-- =============================================
-- Create Request Response contract Template
-- =============================================
-- =============================================
-- Author:		<Author,,>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

CREATE CONTRACT <contract-name, sysname, test_contract>
	AUTHORIZATION <owner-name ,database-user  ,dbo> 
	( <message-type-name, sysname, to_msg> SENT BY INITIATOR, 
      <message-type-name2, sysname, from_msg> SENT BY TARGET )

CREATE CONTRACT  test_contract
	--AUTHORIZATION <owner-name ,database-user  ,dbo> 
	(  DemoMessageType  SENT BY INITIATOR, 
       DemoMessageType1  SENT BY TARGET )

-- =============================================
-- Create Message Type Template
-- =============================================

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

CREATE MESSAGE TYPE DemoMessageType1 
VALIDATION = NONE; 


-- =============================================
-- Create Queue with Activation Template
-- =============================================
-- =============================================
-- Author:		<Author,,>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE QUEUE test_queue

use [auto_repair_shops]

CREATE QUEUE test_queue2
   WITH 
   STATUS = ON ,
   RETENTION = OFF ,
   ACTIVATION (
		STATUS = ON,
		PROCEDURE_NAME = [auto_repair_shops].[dbo].[ms_api],
		MAX_QUEUE_READERS = 10 ,
		EXECUTE AS SELF 
		),
   POISON_MESSAGE_HANDLING (STATUS = ON) 
   ON [DEFAULT]

   print object_id('[auto_repair_shops].[dbo].[ms_api]')
   SELECT DB_NAME(12) AS ThatDB;
   print object_name('338100245')

  Create service test_service
on QUEUE test_queue

Create service test_service1
on QUEUE test_queue1
(test_contract)

Create service test_service2
on QUEUE test_queue2
-- =============================================

   ALTER DATABASE auto_repair_shops SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE
   ALTER DATABASE auto_repair_shops SET NEW_BROKER WITH ROLLBACK IMMEDIATE;
   ALTER DATABASE auto_repair_shops SET disable_BROKER WITH ROLLBACK IMMEDIATE

-- =============================================

SELECT name, is_broker_enabled FROM sys.databases
SELECT * FROM sys.services

SELECT * FROM sys.service_queues
SELECT * FROM sys.service_contracts
SELECT * FROM sys.service_message_types
SELECT * FROM sys.conversation_groups --queue
SELECT * FROM sys.conversation_endpoints
SELECT *,cast (message_body as nvarchar) as message_body_nvarchar 
		 FROM test_queue
SELECT *,cast (message_body as nvarchar) as message_body_nvarchar 
		 FROM test_queue1
SELECT * FROM SingleDB_Broker_TargetQueue --test_queue
SELECT * FROM sys.transmission_queue
SELECT * FROM sys.dm_broker_queue_monitors
SELECT * FROM sys.dm_os_server_diagnostics_log_configurations

--DECLARE @h uniqueidentifier
BEGIN TRY
 BEGIN TRAN
 BEGIN DIALOG CONVERSATION @h
 FROM SERVICE <initiator_service> TO SERVICE '<target_service>'
 ON CONTRACT <service_contract>;
 -- Подготовка данных
 -- Формирование сообщений
 SEND ON CONVERSATION @h MESSAGE TYPE <message_type_name> (<message_body>);
 -- Финальная обработка данных
 /* Завершение одностороннего диалога
 END CONVERSATION @h; */
 COMMIT
END TRY
BEGIN CATCH
 -- Распознавание локальной ошибки
 -- Протоколирование ошибки
 ROLLBACK
END CATCH
go

-- =============================================
--создание диалога отправка сообщения инициатором
begin tran

DECLARE @h uniqueidentifier
DECLARE @message nvarchar (100)

begin dialog conversation @h
from service test_service to service 'test_service1'--
on contract test_contract
with
encryption = off, LIFETIME = 120

set @message = 'c7b99c10-9450-43ac-bf17-66d7c6993575';

 SEND ON CONVERSATION @h MESSAGE TYPE [DemoMessageType](@message) ;

 select @message  as fmoprfgmpo;

commit tran
go

-- =============================================
--получение данных из полученого собщения и ответ сервиса цели сервису инициатора
begin tran

declare @RecvReqHandle uniqueidentifier; --= conversation_handle
declare @RecvReqMsg nvarchar (100);
declare @RecvReqMsgName sysname;

waitfor
(receive top (1)
	@RecvReqHandle = conversation_handle
	, @RecvReqMsg = message_body
	, @RecvReqMsgName = message_type_name
from test_queue1
), timeout 1000;

select @RecvReqMsg  as fmoprfgmpo,
@RecvReqMsgName as message_type_name;

	if @RecvReqMsgName = 'DemoMessageType'
	begin
		declare @ReplyMsg nvarchar(100);
		select @ReplyMsg = 'Replay';

		send on conversation @RecvReqHandle
		message type [DemoMessageType1] (@ReplyMsg);
	end

select @ReplyMsg as SentReplyMsg1213

commit tran
go

--получение ответа от цели завершение диалога инициатором
begin tran

declare @RecvReqHandle uniqueidentifier; --= conversation_handle
declare @RecvReqMsg nvarchar (100);
declare @RecvReqMsgName sysname;

waitfor
(receive top (1)
	@RecvReqHandle = conversation_handle
	, @RecvReqMsg = message_body
	, @RecvReqMsgName = message_type_name
from test_queue
), timeout 1000;

if @RecvReqMsgName = 'DemoMessageType1'
	begin
		end conversation @RecvReqHandle
	end

	select @RecvReqMsg as ReceivedReplyMsgtext

commit tran
go


-- получение сообщения об завершении диалога инициатором завершение диалога целью
begin tran

declare @RecvReqHandle uniqueidentifier; 
declare @RecvReqMsg nvarchar (100);
declare @RecvReqMsgName sysname;

waitfor
(receive top (1)
	@RecvReqHandle = conversation_handle
	, @RecvReqMsg = message_body
	, @RecvReqMsgName = message_type_name
from test_queue1
), timeout 1000;

if @RecvReqMsgName = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
	begin
		end conversation @RecvReqHandle
	end

commit tran
go

--declare @Handle uniqueidentifier; 

--while (1=1)
--if ( SELECT top (1) [conversation_group_id] FROM sys.conversation_groups) is not null
--begin
--	SELECT top (1) @Handle = [conversation_group_id] FROM sys.conversation_groups
--		SELECT top (1) @Handle
--		begin dialog conversation @Handle
--		from service test_service to service 'test_service1'--
--		on contract test_contract
--		with
--		encryption = off, LIFETIME = 120

--		end conversation @Handle
--end







-- =============================================
--создание диалога отправка сообщения инициатором
begin tran

	DECLARE @h uniqueidentifier
	DECLARE @message nvarchar (100)

	begin dialog conversation @h
	from service test_service to service 'test_service1'
	on contract test_contract
	with
	encryption = off, LIFETIME = 120

	set @message = '{"id":"c7b99c10-9450-43ac-bf17-66d7c6993575"}';

	SEND ON CONVERSATION @h MESSAGE TYPE [DemoMessageType](@message) ;

	select @message  as fmoprfgmpo;

commit tran
go

--получение данных из полученого собщения и ответ сервиса цели сервису инициатора
begin tran

declare @RecvReqHandle uniqueidentifier; --= conversation_handle
declare @RecvReqMsg nvarchar (100);
declare @RecvReqMsgName sysname;

waitfor
(receive top (1)
	@RecvReqHandle = conversation_handle
	, @RecvReqMsg = message_body
	, @RecvReqMsgName = message_type_name
from test_queue1
), timeout 1000;

select @RecvReqMsg  as fmoprfgmpo,
@RecvReqMsgName as message_type_name;

	if @RecvReqMsgName = 'DemoMessageType'
	begin
		declare @ReplyMsg nvarchar(100);
		exec [dbo].[ms_api] 'client.get',@RecvReqMsg,@ReplyMsg out;
		--select @ReplyMsg = 'Replay';

		send on conversation @RecvReqHandle
		message type [DemoMessageType1] (@ReplyMsg);
	end

select @ReplyMsg as SentReplyMsg1213

commit tran
go

--получение ответа от цели завершение диалога инициатором
begin tran

declare @RecvReqHandle uniqueidentifier; --= conversation_handle
declare @RecvReqMsg nvarchar (100);
declare @RecvReqMsgName sysname;

waitfor
(receive top (1)
	@RecvReqHandle = conversation_handle
	, @RecvReqMsg = message_body
	, @RecvReqMsgName = message_type_name
from test_queue
), timeout 1000;

if @RecvReqMsgName = 'DemoMessageType1'
	begin
		end conversation @RecvReqHandle
	end

	select @RecvReqMsg as ReceivedReplyMsgtext

commit tran
go

-- получение сообщения об завершении диалога инициатором завершение диалога целью
begin tran

declare @RecvReqHandle uniqueidentifier; 
declare @RecvReqMsg nvarchar (100);
declare @RecvReqMsgName sysname;

waitfor
(receive top (1)
	@RecvReqHandle = conversation_handle
	, @RecvReqMsg = message_body
	, @RecvReqMsgName = message_type_name
from test_queue1
), timeout 1000;

if @RecvReqMsgName = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
	begin
		end conversation @RecvReqHandle
	end

commit tran
go


alter procedure fdfd
 -- @js nvarchar(max), 
  --@rp nvarchar(max) output
  as
begin
	declare @RecvReqHandle uniqueidentifier; --= conversation_handle
	declare @RecvReqMsg nvarchar (100);
	declare @RecvReqMsgName sysname;
	waitfor
	(receive top (1)
		@RecvReqHandle = conversation_handle
		, @RecvReqMsg = message_body
		, @RecvReqMsgName = message_type_name
	from test_queue2
	 
	), 
	
	timeout 1000;
	select  @RecvReqHandle  f1
		, @RecvReqMsg  f2
		, @RecvReqMsgName  f3 into ##test 
	select * from ##test
end

ALTER DATABASE auto_repair_shops SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE
   
ALTER QUEUE test_queue2
   WITH 
   ACTIVATION (
    STATUS = ON,
    PROCEDURE_NAME = [auto_repair_shops].[dbo].[fdfd] ,
    MAX_QUEUE_READERS = 1 ,
    EXECUTE AS SELF 
    );






	SELECT *,cast (message_body as nvarchar) as message_body_nvarchar 
		 FROM test_queue2

SELECT *,cast (last_send_tran_id as nvarchar) as message_body_nvarchar  FROM sys.conversation_endpoints
go
DROP QUEUE [auto_repair_shops].[dbo].[test_queue2]


if object_id('tempdb..##test') is not null
	 drop table ##test

begin tran

	DECLARE @h uniqueidentifier
	DECLARE @message nvarchar (100)

	begin dialog conversation @h
	from service test_service2 to service 'test_service1'
	--on contract test_contract
	with
	encryption = off--, LIFETIME = 120

	set @message = '{"id":"c7b99c10-9450-43ac-bf17-66d7c6993575"}';

	SEND ON CONVERSATION @h (@message) ;
	
	

	declare @RecvReqHandle uniqueidentifier; --= conversation_handle
	declare @RecvReqMsg nvarchar (100);
	declare @RecvReqMsgName sysname;
	waitfor
	(receive top (1)
		@RecvReqHandle = conversation_handle
		, @RecvReqMsg = message_body
		, @RecvReqMsgName = message_type_name
	from test_queue2
	 
	), 
	
	timeout 1000;
	select  @RecvReqHandle  f1
			, @RecvReqMsg  f2
			, @RecvReqMsgName  f3 into ##test 
	select * from ##test
	
	select @message  as fmoprfgmpo;

commit tran
go




--получение данных из полученого собщения и ответ сервиса цели сервису инициатора
begin tran

declare @RecvReqHandle uniqueidentifier; --= conversation_handle
declare @RecvReqMsg nvarchar (100);
declare @RecvReqMsgName sysname;

--waitfor
--(receive top (1)
--	@RecvReqHandle = conversation_handle
--	, @RecvReqMsg = message_body
--	, @RecvReqMsgName = message_type_name
--from test_queue1
--), timeout 1000;

select @RecvReqMsg  as fmoprfgmpo,
@RecvReqMsgName as message_type_name;

	if @RecvReqMsgName = 'DemoMessageType'
	begin
		declare @ReplyMsg nvarchar(100);
		exec [dbo].[ms_api] 'client.get',@RecvReqMsg,@ReplyMsg out;
		--select @ReplyMsg = 'Replay';

		send on conversation @RecvReqHandle
		message type [DEFAULT] (@ReplyMsg);
		
	end

select @ReplyMsg as SentReplyMsg1213

commit tran
go

--получение ответа от цели завершение диалога инициатором
begin tran

declare @RecvReqHandle uniqueidentifier; --= conversation_handle
declare @RecvReqMsg nvarchar (100);
declare @RecvReqMsgName sysname;

waitfor
(receive top (1)
	@RecvReqHandle = conversation_handle
	, @RecvReqMsg = message_body
	, @RecvReqMsgName = message_type_name
from test_queue
), timeout 1000;

if @RecvReqMsgName = 'DemoMessageType1'
	begin
		end conversation @RecvReqHandle
	end

	select @RecvReqMsg as ReceivedReplyMsgtext

commit tran
go

-- получение сообщения об завершении диалога инициатором завершение диалога целью
begin tran

declare @RecvReqHandle uniqueidentifier; 
declare @RecvReqMsg nvarchar (100);
declare @RecvReqMsgName sysname;

waitfor
(receive top (1)
	@RecvReqHandle = conversation_handle
	, @RecvReqMsg = message_body
	, @RecvReqMsgName = message_type_name
from test_queue1
), timeout 1000;

if @RecvReqMsgName = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
	begin
		end conversation @RecvReqHandle
	end

commit tran
go

