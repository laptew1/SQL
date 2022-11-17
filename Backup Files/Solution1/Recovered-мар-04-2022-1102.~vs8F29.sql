SELECT *,cast (message_body as nvarchar) as message_body_nvarchar 
		 FROM test_queue2

SELECT *,cast (last_send_tran_id as nvarchar) as message_body_nvarchar  FROM sys.conversation_endpoints
go
--очередь для сервиса
alter queue test_queue2
   with status = on ,
	   retention = off ,
	   activation (
				status = on,
				procedure_name = [LaptevD].[dbo].[fdfd],
				max_queue_readers = 10 ,
				execute as 'd.laptev'
				),
	   poison_message_handling (status = on) 
	   on [PRIMARY]
go

-- создание сервиса
create service test_service2
on queue test_queue2
([DEFAULT]);
go

--хранимая процедура
create procedure fdfd
as
begin

	declare @RecvReqHandle uniqueidentifier;
	declare @RecvReqMsg nvarchar (100);
	declare @RecvReqMsgName sysname;

	waitfor
	(receive top (1)
		@RecvReqHandle = conversation_handle
		, @RecvReqMsg = message_body
		, @RecvReqMsgName = message_type_name
	from test_queue2), timeout 1000;

	exec [dbo].[ms_api] 'client.active',@RecvReqMsg, @RecvReqMsg out

	end conversation @RecvReqHandle	with cleanup
end
go

SELECT * FROM sys.transmission_queue
go

-- инициатор

begin tran

	declare @h uniqueidentifier
	declare @message nvarchar (100)

	begin dialog conversation @h
		from service test_service2 to service 'test_service2'
		with encryption = off
		begin
			set @message = '{"id":"573A4552-E4CA-41E9-8AED-315C4B2FBD74"}';
			
			send on conversation @h message type [DEFAULT](@message) ;
		end
	end conversation @h
commit tran
go
