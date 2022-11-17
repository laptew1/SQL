--create   procedure [dbo].[client.edit]
--	@js varchar(max),
--	@rp varchar(max) out

--AS
	declare 

@js varchar(max) = '{"id": "ccc","data_add": "ccc","name": "ccc","number_license":"dcsd","phone":"43534"}' ,
	@rp varchar(max)
	
BEGIN
	declare 

	@err				varchar(50)
	,@errdesc			varchar(50)
	,@id				varchar(50) = JSON_VALUE(@js, '$.id')
	,@data_add			datetime	= JSON_VALUE(@js, '$.data_add')
	,@name				varchar(50) = JSON_VALUE(@js, '$.name')
	,@number_license	varchar(50) = JSON_VALUE(@js, '$.number_license')
	,@phone				varchar(50) = JSON_VALUE(@js, '$.phone')

	if (@id is null 
		or @data_add is null 
		or @number_license is null 
		or @name is null 
		or @phone is null) 
	begin
		set @err = 'err.client_insert.unset_field'
		set @errdesc = --'Неуказанны ключевые параметры'
						case
							when @id is null		  	 then 'Неуказанны ключевые параметры id'
							when @data_add is null		 then 'Неуказанны ключевые параметры data_add'
							when @name is null			 then 'Неуказанны ключевые параметры name'
							when @number_license is null then 'Неуказанны ключевые параметры number_license'
							when @phone is null			 then 'Неуказанны ключевые параметры phone'
						end
		goto err
	end

	if exists (select * from [dbo].[client] 
				where [id] <>  @id	
				and  [number_license] = @number_license)
	begin 
		set @err = 'err.client_insert.invalid_license'
		set @errdesc = 'Существует другой клиент с такими же правами'
		goto err
	end
 
	if (ISNUMERIC (@phone) <> 1 
		or ascii(@phone) <> ascii (8) 
		or len (@phone) <> 11)
	begin 
		set @err = 'err.client_insert.invalid_phone'
		set @errdesc = 'Неверно набран номер'
		goto err
	end

	if (ISNUMERIC (@number_license) <> 1 and len (@phone) = 10)
	begin 
		set @err = 'err.client_insert.invalid_number_license'
		set @errdesc = 'Неверно набран номер водительских прав'
		goto err
	end

	if not exists (select * from [dbo].[client] 
					where id =  @id )
	begin 
		set @err = 'err.client_insert.invalid_value'
		set @errdesc = 'Такого клиента не существует'
		goto err
	end

	if exists (select [a] from [dbo].[client] 
				where [id] = @id 
				and [a] = 'N')
	begin 
		set @err = 'err.client_insert.diactive'
		set @errdesc = 'Такого клиента нет'
		goto err
	end

	if exists (select [a] from [dbo].[client] --сохраняем изменения
				where [id] = @id 
				and [a] = 'Y')
	begin
		update [dbo].[client]
		set		[id] = @id
				,[data_add] = @data_add
				,[name] = @name
				,[number_license] = @number_license
				,[phone] = @phone
		from  [dbo].[client]
		where [id]=@id
 
		set @rp =  --выводим результат
			(
			select * from [dbo].[client] where [id]= @id
			for json path, without_array_wrapper
			)
		goto ok
	end

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

END

select json_query ( @rp )
