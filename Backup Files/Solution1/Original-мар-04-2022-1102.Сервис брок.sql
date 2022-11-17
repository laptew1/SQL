
--очередь для сервиса
create queue test_queue2
   with status = on ,
	   retention = off ,
	   activation (
				status = on,
				procedure_name = [auto_repair_shops].[dbo].[fdfd],
				max_queue_readers = 10 ,
				execute as owner
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
alter procedure fdfd
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

-- инициатор
begin tran

	declare @h uniqueidentifier
	declare @message nvarchar (100)

	begin dialog conversation @h
		from service test_service2 to service 'test_service2'
		with encryption = off
		begin
			set @message = '{"id":"2f9d9d39-62b7-4292-92d6-731a07786efd"}';
			
			send on conversation @h message type [DEFAULT](@message) ;
		end
	end conversation @h
commit tran
go
