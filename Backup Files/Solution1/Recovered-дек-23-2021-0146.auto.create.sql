create   procedure [dbo].[auto.create]
	@js varchar(max),
	@rp varchar(max) out

AS
BEGIN
		declare 
		@err				varchar(50)
		,@errdesc			varchar(50)
		,@id_client			varchar(50) = JSON_VALUE(@js, '$.id_client')
		,@mark				varchar(50) = JSON_VALUE(@js, '$.mark')
		,@number			varchar(50) = JSON_VALUE(@js, '$.number')
   
	 if ( @number		is null 
		or @mark		is null 
		or @id_client	is null) 
		begin
			set @err = 'err.auto_create.unset_field'
			set @errdesc = 'Неуказанны ключевые параметры'
			goto err
		end

 
	 if ( 9 < len (@number) or len (@number) < 8)
		begin 
			set @err = 'err.auto_insert.invalid_number_license'
			set @errdesc = 'Неверно набран номер автомобиля'
			goto err
		end

	 if exists (select  [number] from [dbo].[auto] where [number] =  @number )
		begin 
			set @err = 'err.auto_add.invalid_number_license'
			set @errdesc = 'Клиент с указанным водительским номером уже существует'
			goto err
		end

	insert into [dbo].[auto] --сохранияем
	values (	
			newid()
			,GETDATE() 
			,JSON_VALUE(@js, '$.id_client')
			,JSON_VALUE(@js, '$.mark')
			,JSON_VALUE(@js, '$.number')
			,'Y'
			)

	set @rp =  --выводим
		(
		select	newid() as									[id]
				,GETDATE() as								[data_add]
				,JSON_VALUE([value], '$.id_client') as		[id_client]
				,JSON_VALUE([value], '$.mark') as			[mark]
				,JSON_VALUE([value], '$.number') as			[number]
		from  openjson (@js)
		)
	goto ok

	err:
		set @rp=
			(
			select 'err' [status],lower(@err) err , @errdesc errdesc 
			for json path, without_array_wrapper
			)
			RETURN

	ok:
		set @rp=
			(
			select 'ok' [status],json_query(@rp) response 
			for json path, without_array_wrapper
			)
			RETURN
end


