create   procedure [dbo].[client.create]
	@js varchar(max),
	@rp varchar(max) out

AS
--declare
--	@js varchar(max) = '{"name":"name","number_license":"123456789","phone":"898856784745"}',
--	@rp varchar(max)

BEGIN
		declare 
		@err				varchar(50)
		,@errdesc			varchar(100)
	--	,@id				varchar(50) = newid()
		,@data_add			datetime = GETDATE() 
		,@name				varchar(100) = JSON_VALUE(@js, '$.name')
		,@number_license	varchar(10) = JSON_VALUE(@js, '$.number_license')
		,@phone				varchar(11) = JSON_VALUE(@js, '$.phone')
   
	 if ( @number_license is null 
		or @name is null 
		or @phone is null) 
		begin
			set @err = 'err.client_create.unset_field'
			set @errdesc = 'Неуказанны ключевые параметры'
			goto err
		end

	if (ISNUMERIC (@phone) <> 1 
		or ascii(@phone) <> ascii (8) 
		or len (@phone) <> 11)
		begin 
			set @err = 'err.client_create.invalid_phone'
			set @errdesc = 'Неверно указан номер телефона'
			goto err
		end
 
	 if (ISNUMERIC (@number_license) <> 1 
		or len (@number_license) <> 10)
		begin 
			set @err = 'err.client_create.invalid_number_license'
			set @errdesc = 'Неверно указан номер водительских прав'
			goto err
		end

	 if exists (select  [number_license] from [dbo].[client] where [number_license] =  @number_license )
		begin 
			set @err = 'err.client_create.invalid_number_license'
			set @errdesc = 'Клиент с указанными водительскими правами уже существует'
			goto err
		end

	insert into [dbo].[client] --сохранияем
	values (	
			@data_add			
			,@name				
			,@number_license	
			,@phone				
			,'Y'
			)

	set @rp =  --выводим
		(
		select	@name as			[name]
				,@number_license as	[number_license]
				,@phone	 as			[phone]
		for json path, without_array_wrapper
		)
	goto ok

	err:
		set @rp = (select 'err' [status],lower(@err) err , @errdesc errdesc for json path, without_array_wrapper)
		RETURN

	ok:
		set @rp = (select 'ok' [status],json_query(@rp) response for json path, without_array_wrapper)
		RETURN
end

--select @rp
