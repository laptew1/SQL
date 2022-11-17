alter procedure [dbo].[ms_api]
	@action varchar(50),
	@js nvarchar(max), 
	@rp nvarchar(max) out
as
begin
	begin try

		set dateformat dmy

		declare 
			@id	uniqueidentifier = newid()
			,@data_add datetime	= GETDATE() 
			,@sba varchar(50) = substring(@action, 1, charindex('.', @action)-1)
			,@js_ varchar(max), @rp_ varchar(max)
			,@err varchar(100), @errdesc varchar(100) 
			
		if @sba in ('auto')
		begin
			declare 
			@auto_id			uniqueidentifier = JSON_VALUE(@js, '$.id')
			,@auto_data_add		datetime = JSON_VALUE(@js, '$.data_add') 
			,@auto_id_client	uniqueidentifier = JSON_VALUE(@js, '$.id_client')
			,@auto_mark			varchar(20) = JSON_VALUE(@js, '$.mark')
			,@auto_number		varchar(10) = JSON_VALUE(@js, '$.number')

			if @action in ('auto.create')
			begin
				if (@id is null or @auto_number	is null or @auto_mark is null or @auto_id_client is null) 
				begin
					set @err = 'err.auto_create.unset_field'
					set @errdesc = 'Неверно указаны ключевые параметры'
					goto err
				end

 
				if ( 9 < len (@auto_number) or len (@auto_number) < 8)
				begin 
					set @err = 'err.auto_create.invalid_number_license'
					set @errdesc = 'Неверно указан номер автомобиля'
					goto err
				end

				if exists (select [number] from [dbo].[auto] with(nolock) where [number] = @auto_number )
				begin 
					set @err = 'err.auto_create.invalid_number_license'
					set @errdesc = 'Автомобиль с указанным номером уже существует'
					goto err
				end

				if not exists (select [id] from [dbo].[client] with(nolock) where [id] = @auto_id_client )
				begin 
					set @err = 'err.auto_create.invalid_id_client'
					set @errdesc = 'Клиента с таким индификатором не существует'
					goto err
				end

				--сохранияем
				insert into [dbo].[auto]
				values (@id, @data_add, @auto_id_client, @auto_mark, @auto_number,'Y')

				--выводим
				set @rp = (select	@id as				[id]	
									,@data_add as		[data_add]	
									,@auto_id_client as	[id_client]
									,@auto_mark as		[mark]
									,@auto_number as	[number]
							for json path, without_array_wrapper)
				goto ok
			end
				
			if @action in ('auto.get')
			begin 
				set @rp = (select * from [dbo].[auto] with(nolock)
							where [a] = 'Y' and (	(@auto_id is not null		and [id] = @auto_id)
									 			or (@auto_data_add is not null	and [data_add] = @auto_data_add)
												or (@auto_id_client is not null	and [id_client] = @auto_id_client)
												or (@auto_mark is not null		and [mark] = @auto_mark)
												or (@auto_number is not null	and [number] = @auto_number)
												)
							for json path, without_array_wrapper
						   )
 	
				goto ok  
			end

			if @action in ('auto.active')
			begin
				if @auto_id is null 
				begin
					set @err = 'err.auto_active.unset_field'
					set @errdesc = 'Неуказанны ключевые параметры сущности'
					goto err
				end

				if not exists (select * from [dbo].[auto] with(nolock) where [id] = @auto_id)
				begin 
					set @err = 'err.auto_active.invalid_value'
					set @errdesc = 'Такой машины не существует'
					goto err
				end

				if exists (select * from [dbo].[auto] with(nolock) where [id] = @auto_id and [a] = 'Y' )
				begin 
					set @err = 'err.auto_active.active'
					set @errdesc = 'Указанный объект уже активен'
					goto err
				end

				update	[dbo].[auto]   --изменение активности
				set		[a] = 'Y'
				from	[dbo].[auto]
				where	[id] = @auto_id

				update	[dbo].[order]   --изменение активности
				set		[a] = 'Y'
				from	[dbo].[order]
				where	[id_auto] = @auto_id
 
				set @rp = (select * from [dbo].[auto] with(nolock) where [id] = @auto_id for json path, without_array_wrapper)
				goto ok

			end

			if @action in ('auto.diactive')
			begin
				if @auto_id is null 
				begin
					set @err = 'err.auto_diactive.unset_field'
					set @errdesc = 'Неуказанны ключевые параметры сущности'
					goto err
				end

				if not exists (select * from [dbo].[auto] with(nolock) where [id] = @auto_id )
				begin 
					set @err = 'err.auto_diactive.invalid_value'
					set @errdesc = 'Такой машины не существует'
					goto err
				end

				if exists (select * from [dbo].[auto] with(nolock) where [id] = @auto_id and [a] = 'N'	)
				begin 
					set @err = 'err.auto_diactive.diactive'
					set @errdesc = 'Указанный объект уже неактивен'
					goto err
				end

				update	[dbo].[auto]   --изменение активности
				set		[a] = 'N'
				from	[dbo].[auto]
				where	[id] = @auto_id

				update	[dbo].[order]   --изменение активности
				set		[a] = 'N'
				from	[dbo].[order]
				where	[id_auto] = @auto_id
 
 				set @rp = (select * from [dbo].[auto] with(nolock) where [id] = @auto_id for json path, without_array_wrapper)
				goto ok

			end

			if @action in ('auto.edit')
			begin
				if (@auto_id is null or @auto_data_add is null or @auto_id_client is null or @auto_mark is null or @auto_number is null) 
				begin
					set @err = 'err.auto_edit.unset_field'
					set @errdesc = --'Неуказанны ключевые параметры'
									case
										when @auto_id is null		 then 'Неуказанны ключевые параметры id'
										when @auto_data_add is null	 then 'Неуказанны ключевые параметры data_add'
										when @auto_id_client is null then 'Неуказанны ключевые параметры id_client'
										when @auto_mark is null		 then 'Неуказанны ключевые параметры mark'
										when @auto_number is null	 then 'Неуказанны ключевые параметры number'
									end
					goto err
				end

				if exists (select * from [dbo].[auto] with(nolock) where [id] <> @auto_id and [number] = @auto_number)
				begin 
					set @err = 'err.auto_edit.invalid_license'
					set @errdesc = 'Существует другой автомобиль с таким же номером'
					goto err
				end
 
				 if ( 9 < len (@auto_number) or len (@auto_number) < 8)
				begin 
					set @err = 'err.auto_edit.invalid_number_license'
					set @errdesc = 'Неверно указан номер автомобиля'
					goto err
				end

				if not exists (select * from [dbo].[auto] with(nolock) where [id] = @auto_id )
				begin 
					set @err = 'err.auto_edit.invalid_value'
					set @errdesc = 'Такой машины не существует'
					goto err
				end

				if exists (select [a] from [dbo].[auto] with(nolock) where [id] = @auto_id and [a] = 'N')
				begin 
					set @err = 'err.auto_edit.diactive'
					set @errdesc = 'Такого автомобиля нет'
					goto err
				end
				
					if not exists (select [id] from [dbo].[client] with(nolock) where [id] = @auto_id_client )
				begin 
					set @err = 'err.auto_edit.invalid_id_client'
					set @errdesc = 'Клиента с таким индификатором не существует'
					goto err
				end
				--сохраняем изменения
				if exists (select [a] from [dbo].[auto] with(nolock) where [id] = @auto_id and [a] = 'Y')
				begin
					update [dbo].[auto]
					set	[id] = @auto_id
						,[data_add] = @auto_data_add
						,[id_client] = @auto_id_client
						,[mark] = @auto_mark
						,[number] = @auto_number
					from  [dbo].[auto]
					where [id] = @auto_id

					--выводим результат
					set @rp = (select * from [dbo].[auto] with(nolock) where [id] = @auto_id for json path, without_array_wrapper)
					goto ok
				end

			end

		end

		if @sba in ('client')
		begin
			declare
				@client_id				uniqueidentifier = JSON_VALUE(@js, '$.id')
				,@client_data_add		datetime		= JSON_VALUE(@js, '$.data_add')
				,@client_name			varchar(200)	= JSON_VALUE(@js, '$.name')
				,@client_number_license	varchar(11)		= JSON_VALUE(@js, '$.number_license')
				,@client_phone			varchar(12)		= JSON_VALUE(@js, '$.phone')

			if @action in ('client.create')
			begin
				if ( @client_number_license is null 
					or @client_name is null 
					or @client_phone is null) 
				begin
					set @err = 'err.client_create.unset_field'
					set @errdesc = 'Неуказанны ключевые параметры'
					goto err
				end

				if (ISNUMERIC (@client_phone) <> 1 
					or ascii(@client_phone) <> ascii (8) 
					or len (@client_phone) <> 11)
				begin 
					set @err = 'err.client_create.invalid_phone'
					set @errdesc = 'Неверно указан номер телефона'
					goto err
				end
 
				if (ISNUMERIC (@client_number_license) <> 1 
					or len (@client_number_license) <> 10)
				begin 
					set @err = 'err.client_create.invalid_number_license'
					set @errdesc = 'Неверно указан номер водительских прав'
					goto err
				end

				if exists (select [number_license] from [dbo].[client] with(nolock)
							where [number_license] = @client_number_license )
				begin 
					set @err = 'err.client_create.invalid_number_license'
					set @errdesc = 'Клиент с указанными водительскими правами уже существует'
					goto err
				end

				insert into [dbo].[client] --сохранияем
				values (@id, @data_add, @client_name, @client_number_license, @client_phone, 'Y')

				set @rp = (select	@id as						[id]		--выводим
									,@data_add as				[data_add]	 
									,@client_name as			[name]
									,@client_number_license as	[number_license]
									,@client_phone	 as			[phone]
							for json path, without_array_wrapper )
				goto ok
			end

			if @action in ('client.edit')
			begin
				
				if (@client_id is null 
					or @client_data_add is null 
					or @client_number_license is null 
					or @client_name is null 
					or @client_phone is null) 
				begin
					set @err = 'err.client_edit.unset_field'
					set @errdesc = --'Неуказанны ключевые параметры'
									case
										when @client_id is null				 then 'Неуказанны ключевые параметры id'
										when @client_data_add is null		 then 'Неуказанны ключевые параметры data_add'
										when @client_name is null			 then 'Неуказанны ключевые параметры name'
										when @client_number_license is null	 then 'Неуказанны ключевые параметры number_license'
										when @client_phone is null			 then 'Неуказанны ключевые параметры phone'
									end
					goto err
				end

				if exists (select * from [dbo].[client] with(nolock)
							where [id] <> @client_id	
							  and [number_license] = @client_number_license)
				begin 
					set @err = 'err.client_edit.invalid_license'
					set @errdesc = 'Существует другой клиент с такими же водительскими правами'
					goto err
				end
 
				if (ISNUMERIC (@client_phone) <> 1 
					or ascii(@client_phone) <> ascii (8) 
					or len (@client_phone) <> 11)
				begin 
					set @err = 'err.client_edit.invalid_phone'
					set @errdesc = 'Неверно указан номер телефона'
					goto err
				end

				if (ISNUMERIC (@client_number_license) <> 1 or len (@client_number_license) <> 10)
				begin 
					set @err = 'err.client_edit.invalid_number_license'
					set @errdesc = 'Неверно указан номер водительских прав'
					goto err
				end

				if not exists (select * from [dbo].[client] with(nolock) where [id] = @client_id )
				begin 
					set @err = 'err.client_edit.invalid_value'
					set @errdesc = 'Такого клиента не существует'
					goto err
				end

				if exists (select [a] from [dbo].[client] with(nolock) where [id] = @client_id and [a] = 'N')
				begin 
					set @err = 'err.client_edit.diactive'
					set @errdesc = 'Такого клиента нет'
					goto err
				end
				
				--сохраняем изменения
				if exists (select [a] from [dbo].[client] with(nolock) where [id] = @client_id and [a] = 'Y')
				begin
					update [dbo].[client]
					set		[data_add] = @client_data_add
							,[name] = @client_name
							,[number_license] = @client_number_license
							,[phone] = @client_phone
					from  [dbo].[client]
					where [id] = @client_id
					
					--выводим результат
					set @rp = (select * from [dbo].[client] with(nolock) where [id] = @client_id for json path, without_array_wrapper)
					goto ok
				end

			end

			if @action in ('client.get')
			begin
				set @rp = (select * from [dbo].[client]	with(nolock)								--поиск нужного элемента
							where [a] = 'Y' 
							and (	(@client_id is not null					and @client_id = [id])
									or (@client_data_add is not null		and @client_data_add = [data_add])
									or (@client_name is not null			and @client_name = [name])
									or (@client_number_license is not null	and @client_number_license = [number_license])
									or (@client_phone is not null			and @client_phone = [phone]) 
								)
							for json path, without_array_wrapper 
							)
				goto ok
			end

			if @action in ('client.active')
			begin
				if @client_id is null 
				begin
					set @err = 'err.client_active.unset_field'
					set @errdesc = 'Неуказанны ключевые параметры сущности'
					goto err
				end

				if not exists (select * from [dbo].[client] with(nolock) where id = @client_id )
				begin 
					set @err = 'err.client_active.invalid_value'
					set @errdesc = 'Такого клиента не существует'
					goto err
				end

				if exists	(select * from [dbo].[client] with(nolock) where [id] = @client_id and [a] = 'Y')
				begin 
					set @err = 'err.client_active.active'
					set @errdesc = 'Указанный объект уже активен'
					goto err
				end

				update	[dbo].[client]   --изменение активности
				set		[a] = 'Y'
				from	[dbo].[client]
				where	[id] = @client_id

				update	[dbo].[auto]   --изменение активности
				set		[a] = 'Y'
				from	[dbo].[auto] 
				where	[id_client] = @client_id

				update	[dbo].[order]   --изменение активности
				set		[a] = 'Y'
				from	[dbo].[order]
				where	[id_client] = @client_id

				set @rp = (select * from [dbo].[client] with(nolock) where [id] = @client_id for json path, without_array_wrapper)
				goto ok
			end

			if @action in ('client.diactive')
			begin
				if @client_id is null 
				begin
					set @err = 'err.client_diactive.unset_field'
					set @errdesc = 'Неуказанны ключевые параметры сущности'
					goto err
				end

				if not exists (select * from [dbo].[client] with(nolock) where [id] = @client_id )
				begin 
					set @err = 'err.client_diactive.invalid_value'
					set @errdesc = 'Такого клиента не существует'
					goto err
				end

				if exists (select * from [dbo].[client] with(nolock) where [id] = @client_id and [a] = 'N')
				begin 
					set @err = 'err.client_diactive.diactive'
					set @errdesc = 'Указанный объект уже неактивен'
					goto err
				end

				update	[dbo].[client]   --изменение активности
				set		[a] = 'N'
				from	[dbo].[client]
				where	[id] = @client_id
	
				update	[dbo].[auto]   --изменение активности
				set		[a] = 'N'
				from	[dbo].[auto] 
				where	[id_client] = @client_id

				update	[dbo].[order]   --изменение активности
				set		[a] = 'N'
				from	[dbo].[order]
				where	[id_client] = @client_id
  
				set @rp = (select * from [dbo].[client] with(nolock) where [id] = @client_id for json path, without_array_wrapper)
				goto ok
			end
		end

		if @sba in ('garage')
		begin
			declare
			@garage_id					uniqueidentifier = JSON_VALUE(@js, '$.id')
			,@garage_data_add			datetime		= JSON_VALUE(@js, '$.data_add')
			,@garage_address			varchar(200)	= JSON_VALUE(@js, '$.address')
			,@garage_number_places		varchar(10)		= JSON_VALUE(@js, '$.number_places')

			if @action in ('garage.create')
			begin
				if ( @garage_number_places is null 
					or @garage_address is null ) 
				begin
					set @err = 'err.garage_create.unset_field'
					set @errdesc = 'Неуказанны ключевые параметры'
					goto err
				end

				if (ISNUMERIC (@garage_number_places) <> 1) or @garage_number_places <=0
				begin 
					set @err = 'err.garage_create.invalid_number_places'
					set @errdesc = 'Неверно указан номер места'
					goto err
				end
	
				if exists (select [number_places] from [dbo].[garage] with(nolock)
							where [address] = @garage_address)
				begin 
					set @err = 'err.garage_create.invalid_number_places'
					set @errdesc = 'Место с указанным адресом уже существует'
					goto err
				end

				insert into [dbo].[garage] --сохранияем
				values (@id, @data_add, @garage_address, @garage_number_places, 'Y')

				set @rp = (select	@id as				[id]		--выводим
									,@data_add as		[data_add]	 
									,@garage_address as	[address]
									,@garage_number_places as [number_places]
							for json path, without_array_wrapper )
				goto ok

			end

			if @action in ('garage.edit')
			begin
				if (@garage_id is null 
					or @garage_data_add is null 
					or @garage_number_places is null 
					or @garage_address is null) 
				begin
					set @err = 'err.garage_edit.unset_field'
					set @errdesc = --'Неуказанны ключевые параметры'
									case
										when @garage_id is null		  		then 'Неуказанны ключевые параметры id'
										when @garage_data_add is null		then 'Неуказанны ключевые параметры data_add'
										when @garage_address is null		then 'Неуказанны ключевые параметры address'
										when @garage_number_places is null	then 'Неуказанны ключевые параметры number_places'
									end
					goto err
				end

				if exists (select * from [dbo].[garage] with(nolock)
							where [id] <> @garage_id	
							  and [address] = @garage_address)
				begin 
					set @err = 'err.garage_edit.invalid_places'
					set @errdesc = 'Уже существует рабочее место с таким адресом'
					goto err
				end
 
				if (ISNUMERIC (@garage_number_places) <> 1) or @garage_number_places <=0
				begin 
					set @err = 'err.garage_create.invalid_number_places'
					set @errdesc = 'Неверно указан номер места'
					goto err
				end

				if not exists (select * from [dbo].[garage] with(nolock) where [id] = @garage_id )
				begin 
					set @err = 'err.garage_edit.invalid_value'
					set @errdesc = 'Такого объекта не существует'
					goto err
				end

				if exists (select [a] from [dbo].[garage] with(nolock) where [id] = @garage_id and [a] = 'N')
				begin 
					set @err = 'err.garage_edit.diactive'
					set @errdesc = 'Такого объекта нет'
					goto err
				end
				
				--сохраняем изменения
				if exists (select [a] from [dbo].[garage] with(nolock) where [id] = @garage_id and [a] = 'Y')
				begin
					update [dbo].[garage]
					set	[data_add] = @garage_data_add
						,[address] = @garage_address
						,[number_places] = @garage_number_places
					from  [dbo].[garage]
					where [id] = @garage_id
 
					set @rp = (select * from [dbo].[garage] with(nolock) where [id]= @garage_id	for json path, without_array_wrapper)--выводим результат
					goto ok
				end
			end

			if @action in ('garage.get')
			begin
				set @rp = (select * from [dbo].[garage]	with(nolock)								--поиск нужного элемента
						where [a] = 'Y' 
						and (	(@garage_id is not null					and @garage_id = [id])
								or (@garage_data_add is not null		and @garage_data_add = [data_add])
								or (@garage_address is not null			and @garage_address = [address])
								or (@garage_number_places is not null	and @garage_number_places = [number_places])
							)
								
						for json path, without_array_wrapper 
						)
				goto ok
			end

			if @action in ('garage.active')
			begin
				if @garage_id is null 
				begin
					set @err = 'err.garage_active.unset_field'
					set @errdesc = 'Неуказанны ключевые параметры сущности'
					goto err
				end

				if not exists (select * from [dbo].[garage] with(nolock) where [id] = @garage_id )
				begin 
					set @err = 'err.garage_active.invalid_value'
					set @errdesc = 'Такого объекта не существует'
					goto err
				end

				if exists (select * from [dbo].[garage] with(nolock) where [id] = @garage_id and [a] = 'Y')
				begin 
					set @err = 'err.garage_active.active'
					set @errdesc = 'Указанный объект уже активен'
					goto err
				end

				update	[dbo].[garage]   --изменение активности
				set		[a] = 'Y'
				from	[dbo].[garage]
				where	[id] = @garage_id

				update	[dbo].[order]   --изменение активности
				set		[a] = 'Y'
				from	[dbo].[order]
				where	[id_garage] = @garage_id

				set @rp = (select * from [dbo].[garage] with(nolock) where [id] = @garage_id for json path, without_array_wrapper)
				goto ok
			end

			if @action in ('garage.diactive')
			begin
				if @garage_id is null 
				begin
					set @err = 'err.garage_diactive.unset_field'
					set @errdesc = 'Неуказанны ключевые параметры сущности'
					goto err
				end

				if not exists (select * from [dbo].[garage] with(nolock) where [id] = @garage_id )
				begin 
					set @err = 'err.garage_diactive.invalid_value'
					set @errdesc = 'Такого объекта не существует'
					goto err
				end

				if exists (select * from [dbo].[garage] with(nolock) where [id] = @garage_id and [a] = 'N')
				begin 
					set @err = 'err.garage_diactive.diactive'
					set @errdesc = 'Указанный объект уже неактивен'
					goto err
				end

				update	[dbo].[garage]   --изменение активности
				set		[a] = 'N'
				from	[dbo].[garage]
				where	[id] = @garage_id
	
				update	[dbo].[order]   --изменение активности
				set		[a] = 'N'
				from	[dbo].[order]
				where	[id_garage] = @garage_id
  
				set @rp = (select * from [dbo].[garage] with(nolock) where [id] = @garage_id for json path, without_array_wrapper)
				goto ok
			end
		end

		if @sba in ('personal')
		begin
			declare 
			@personal_id				uniqueidentifier = JSON_VALUE(@js, '$.id')
			,@personal_data_add			datetime		= JSON_VALUE(@js, '$.data_add')
			,@personal_name				varchar(200)	= JSON_VALUE(@js, '$.name')
			,@personal_number_passport	varchar(11)		= JSON_VALUE(@js, '$.number_passport')
			,@personal_post				varchar(50)		= JSON_VALUE(@js, '$.post')
	
			if @action in ('personal.create')
			begin 
				if ( @personal_number_passport is null 
					or @personal_name is null 
					or @personal_post is null) 
				begin
					set @err = 'err.personal_create.unset_field'
					set @errdesc = 'Неуказанны ключевые параметры'
					goto err
				end

 
				if (ISNUMERIC (@personal_number_passport) <> 1 
					or len (@personal_number_passport) <> 10)
				begin 
					set @err = 'err.personal_create.invalid_number_passport'
					set @errdesc = 'Неверно указаны паспортные данные сотрудника'
					goto err
				end

				if exists (select [number_passport] from [dbo].[personal] with(nolock)
							where [number_passport] = @personal_number_passport )
				begin 
					set @err = 'err.personal_create.invalid_number_passport'
					set @errdesc = 'Работник с указанными паспортными данными уже существует'
					goto err
				end

				insert into [dbo].[personal] --сохранияем
				values (@id, @data_add, @personal_name, @personal_post, @personal_number_passport, 'Y')

				set @rp = (select	@id as						[id]		--выводим
									,@data_add as				[data_add]	 
									,@personal_name as			[name]
									,@personal_number_passport as [number_passport]
									,@personal_post	 as			[post]
							for json path, without_array_wrapper )
				goto ok
			end

			if @action in ('personal.edit')
			begin 
				if (@personal_id is null 
					or @personal_data_add is null 
					or @personal_number_passport is null 
					or @personal_name is null 
					or @personal_post is null) 
				begin
					set @err = 'err.personal_edit.unset_field'
					set @errdesc = --'Неуказанны ключевые параметры'
									case
										when @personal_id is null		  	 then 'Неуказанны ключевые параметры id'
										when @personal_data_add is null		 then 'Неуказанны ключевые параметры data_add'
										when @personal_name is null			 then 'Неуказанны ключевые параметры name'
										when @personal_number_passport is null then 'Неуказанны ключевые параметры number_passport'
										when @personal_post is null			 then 'Неуказанны ключевые параметры post'
									end
					goto err
				end

				if exists (select * from [dbo].[personal] with(nolock)
							where [id] <> @personal_id	
							  and [number_passport] = @personal_number_passport)
				begin 
					set @err = 'err.personal_edit.invalid_passport'
					set @errdesc = 'Существует другой работник с такими же паспортными данными'
					goto err
				end

				if (ISNUMERIC (@personal_number_passport) <> 1 or len (@personal_number_passport) <> 10)
				begin 
					set @err = 'err.personal_edit.invalid_number_passport'
					set @errdesc = 'Неверно указаны паспортные данные сотрудника'
					goto err
				end

				if not exists (select * from [dbo].[personal] with(nolock) where id = @personal_id )
				begin 
					set @err = 'err.personal_edit.invalid_value'
					set @errdesc = 'Такого сотрудника не существует'
					goto err
				end

				if exists (select [a] from [dbo].[personal] with(nolock) where [id] = @personal_id and [a] = 'N')
				begin 
					set @err = 'err.personal_edit.diactive'
					set @errdesc = 'Такого сотрудника нет'
					goto err
				end

				if exists (select [a] from [dbo].[personal] with(nolock) where [id] = @personal_id and [a] = 'Y')--сохраняем изменения
				begin
					update [dbo].[personal]
					set	[data_add] = @personal_data_add
						,[name] = @personal_name
						,[number_passport] = @personal_number_passport
						,[post] = @personal_post
					from  [dbo].[personal]
					where [id] = @personal_id
					
					--выводим результат
					set @rp = (select * from [dbo].[personal] with(NOLOCK) where [id] = @personal_id for json path, without_array_wrapper)
					goto ok
				end
			end

			if @action in ('personal.get')
			begin 
				set @rp = (select * from [dbo].[personal] with(nolock)									--поиск нужного элемента
							where [a] = 'Y' 
							and (	(@personal_id is not null					and @personal_id = [id])
									or (@personal_data_add is not null			and @personal_data_add = [data_add])
									or (@personal_name is not null				and @personal_name = [name])
									or (@personal_number_passport is not null	and @personal_number_passport = [number_passport])
									or (@personal_post is not null				and @personal_post = [post]) 
								)
							for json path, without_array_wrapper 
							)
				goto ok
 			end

			if @action in ('personal.active')
			begin
				if @personal_id is null 
				begin
					set @err = 'err.personal_active.unset_field'
					set @errdesc = 'Неуказанны ключевые параметры сущности'
					goto err
				end

				if not exists (select * from [dbo].[personal] with(nolock) where id = @personal_id )
				begin 
					set @err = 'err.personal_active.invalid_value'
					set @errdesc = 'Такого сотрудника не существует'
					goto err
				end

				if exists (select * from [dbo].[personal] with(nolock) where [id] = @personal_id and [a] = 'Y')
				begin 
					set @err = 'err.personal_active.active'
					set @errdesc = 'Указанный объект уже активен'
					goto err
				end

				update	[dbo].[personal]   --изменение активности
				set		[a] = 'Y'
				from	[dbo].[personal]
				where	[id] = @personal_id

				update	[dbo].[order]   --изменение активности
				set		[a] = 'Y'
				from	[dbo].[order]
				where	[id_personal] = @personal_id
 
				set @rp = (select * from [dbo].[personal] where [id] = @personal_id for json path, without_array_wrapper)
				goto ok
			end

			if @action in ('personal.diactive')
			begin
				if @personal_id is null 
				begin
					set @err = 'err.personal_diactive.unset_field'
					set @errdesc = 'Неуказанны ключевые параметры сущности'
					goto err
				end

				if not exists (select * from [dbo].[personal] with(nolock) where [id] = @personal_id )
				begin 
					set @err = 'err.personal_diactive.invalid_value'
					set @errdesc = 'Такого сотрудника не существует'
					goto err
				end

				if exists (select * from [dbo].[personal] with(nolock) where [id] = @personal_id and [a] = 'N')
				begin 
					set @err = 'err.personal_diactive.diactive'
					set @errdesc = 'Указанный объект уже неактивен'
					goto err
				end

				update	[dbo].[personal]   --изменение активности
				set		[a] = 'N'
				from	[dbo].[personal]
				where	[id] = @personal_id
	
				update	[dbo].[order]   --изменение активности
				set		[a] = 'N'
				from	[dbo].[order]
				where	[id_personal] = @personal_id
  
				set @rp = (select * from [dbo].[personal] with(nolock) where [id] = @personal_id for json path, without_array_wrapper)
				goto ok
			end
		
		end

		if @sba in ('repair')
		begin
			declare 
			@repair_id				uniqueidentifier = JSON_VALUE(@js, '$.id')
			,@repair_data_add		datetime		= JSON_VALUE(@js, '$.data_add')
			,@repair_description	varchar(300)	= JSON_VALUE(@js, '$.description')
			,@repair_price			varchar(10)		= JSON_VALUE(@js, '$.price')
			,@repair_execution_time	datetime		= JSON_VALUE(@js, '$.execution_time')

			if @action in ('repair.create')
			begin
				if ( @repair_price is null 
					or @repair_description is null 
					or @repair_execution_time is null) 
				begin
					set @err = 'err.repair_create.unset_field'
					set @errdesc = 'Неуказанны ключевые параметры'
					goto err
				end

				if (ISNUMERIC (@repair_price) <> 1)  or @repair_price < 0
				begin 
					set @err = 'err.repair_create.invalid_price'
					set @errdesc = 'Неверно указан стоимость ремонта'
					goto err
				end
 
				if exists (select [description] from [dbo].[repair] with(nolock) 
							where [description] = @repair_description )
				begin 
					set @err = 'err.repair_create.invalid_price'
					set @errdesc = 'Такое описание услуги уже есть'
					goto err
				end

				insert into [dbo].[repair] --сохранияем
				values (@id, @data_add, @repair_description, @repair_price, @repair_execution_time, 'Y')

				set @rp = (select	@id as					[id]		--выводим
									,@data_add as			[data_add]	 
									,@repair_description as	[description]
									,@repair_price as		[price]
									,@repair_execution_time as	[execution_time]
							for json path, without_array_wrapper )
				goto ok
			end

			if @action in ('repair.edit')
			begin
				if (@repair_id is null 
					or @repair_data_add is null 
					or @repair_price is null 
					or @repair_description is null 
					or @repair_execution_time is null) 
				begin
					set @err = 'err.repair_edit.unset_field'
					set @errdesc = --'Неуказанны ключевые параметры'
									case
										when @repair_id is null		  	 then 'Неуказанны ключевые параметры id'
										when @repair_data_add is null	 then 'Неуказанны ключевые параметры data_add'
										when @repair_description is null then 'Неуказанны ключевые параметры description'
										when @repair_price is null		 then 'Неуказанны ключевые параметры price'
										when @repair_execution_time is null then 'Неуказанны ключевые параметры execution_time'
									end
					goto err
				end

				if exists (select * from [dbo].[repair] with(nolock)
							where [id] <> @repair_id	
							  and [description] = @repair_description)
				begin 
					set @err = 'err.repair_edit.invalid_description'
					set @errdesc = 'Уже существует подобное описание ремонта'
					goto err
				end
	
				if (ISNUMERIC (@repair_price) <> 1) or @repair_price < 0
				begin 
					set @err = 'err.repair_edit.invalid_price'
					set @errdesc = 'Неверно указана цена ремонта'
					goto err
				end

				if not exists (select * from [dbo].[repair] with(nolock) where id = @repair_id )
				begin 
					set @err = 'err.repair_edit.invalid_value'
					set @errdesc = 'Такого ремонта не существует'
					goto err
				end

				if exists (select [a] from [dbo].[repair] with(nolock) where [id] = @repair_id and [a] = 'N')
				begin 
					set @err = 'err.repair_edit.diactive'
					set @errdesc = 'Такого ремонта нет'
					goto err
				end

				if exists (select [a] from [dbo].[repair] with(nolock) where [id] = @repair_id and [a] = 'Y')--сохраняем изменения
				begin
					update [dbo].[repair]
					set	 [data_add]		 = @repair_data_add
						,[description]	 = @repair_description
						,[price]		 = @repair_price
						,[execution_time] = @repair_execution_time
					from  [dbo].[repair]
					where [id] = @repair_id
 
					set @rp = (select * from [dbo].[repair] with(nolock) where [id] = @repair_id for json path, without_array_wrapper)--выводим результат
					goto ok
				end

			end
			
			if @action in ('repair.get')
			begin
				set @rp = (select * from [dbo].[repair]	with(nolock)								--поиск нужного элемента
							where [a] = 'Y' 
							and (	(@repair_id is not null					and @repair_id = [id])
									or (@repair_data_add is not null		and @repair_data_add = [data_add])
									or (@repair_description is not null		and @repair_description = [description])
									or (@repair_price is not null			and @repair_price = [price])
									or (@repair_execution_time is not null	and @repair_execution_time = [execution_time]) 
								)
									
							for json path, without_array_wrapper
							)
				goto ok
			end
			
			if @action in ('repair.active')
			begin
				if @repair_id is null 
				begin
					set @err = 'err.repair_active.unset_field'
					set @errdesc = 'Неуказанны ключевые параметры сущности'
					goto err
				end

				if not exists (select * from [dbo].[repair] with(nolock) where id = @repair_id )
				begin 
					set @err = 'err.repair_active.invalid_value'
					set @errdesc = 'Такого объекта не существует'
					goto err
				end

				if exists (select * from [dbo].[repair] vwith(nolock) where [id] = @repair_id and [a] = 'Y')
				begin 
					set @err = 'err.repair_active.active'
					set @errdesc = 'Указанный объект уже активен'
					goto err
				end

				update	[dbo].[repair]   --изменение активности
				set		[a] = 'Y'
				from	[dbo].[repair]
				where	[id] = @repair_id

				update	[dbo].[order]   --изменение активности
				set		[a] = 'Y'
				from	[dbo].[order]
				where	[id_repair] = @repair_id
 
				set @rp = (select * from [dbo].[repair] with(nolock) where [id] = @repair_id for json path, without_array_wrapper)
				goto ok

			end
			
			if @action in ('repair.diactive')
			begin
				if @repair_id is null 
				begin
					set @err = 'err.repair_diactive.unset_field'
					set @errdesc = 'Неуказанны ключевые параметры сущности'
					goto err
				end

				if not exists (select * from [dbo].[repair] with(nolock) where [id] = @repair_id )
				begin 
					set @err = 'err.repair_diactive.invalid_value'
					set @errdesc = 'Такого объекта не существует'
					goto err
				end

				if exists (select * from [dbo].[repair] with(nolock) where [id] = @repair_id and [a] = 'N')
				begin 
					set @err = 'err.repair_diactive.diactive'
					set @errdesc = 'Указанный объект уже неактивен'
					goto err
				end

				update	[dbo].[repair]   --изменение активности
				set		[a] = 'N'
				from	[dbo].[repair]
				where	[id] = @repair_id
	
				update	[dbo].[order]   --изменение активности
				set		[a] = 'N'
				from	[dbo].[order]
				where	[id_repair] = @repair_id
  
				set @rp = (select * from [dbo].[repair] with(nolock) where [id] = @repair_id for json path, without_array_wrapper)
				goto ok

			end
		end

		if @sba in ('order')
		begin

			declare 
			@order_id				uniqueidentifier = JSON_VALUE(@js, '$.id')
			,@order_data_add		datetime		 = JSON_VALUE(@js, '$.data_add	')
			,@order_id_personal		uniqueidentifier = JSON_VALUE(@js, '$.id_personal')
			,@order_id_client		uniqueidentifier = JSON_VALUE(@js, '$.id_client')
			,@order_id_auto			uniqueidentifier = JSON_VALUE(@js, '$.id_auto')
			,@order_id_garage		uniqueidentifier = JSON_VALUE(@js, '$.id_garage')
			,@order_id_repair		uniqueidentifier = JSON_VALUE(@js, '$.id_repair')
			,@order_start_time		datetime = JSON_VALUE(@js, '$.start_time')
			,@order_end_time		datetime = JSON_VALUE(@js, '$.end_time')

			if @action in ('order.create') 
			begin
				set @order_end_time = @order_start_time + (select [execution_time] from [dbo].[repair] with(nolock) where [id] = @order_id_repair)
	   
				if ( @order_id_personal	is null 
					or @order_id_client	is null
					or @order_id_auto		is null
					or @order_id_garage	is null
					or @order_id_repair	is null
					or @order_start_time	is null
					) 
				begin
					set @err = 'err.order_create.unset_field'
					set @errdesc = 
						case
							when (select [id] from [dbo].[personal] with(nolock) where [id] = @order_id_personal) is null then 'Неверно указанны ключевые параметры id_personal'
							when (select [id] from [dbo].[client] with(nolock)	where [id] = @order_id_client) is null	then 'Неверно указанны ключевые параметры id_client'
							when (select [id] from [dbo].[auto] with(nolock)	where [id] = @order_id_auto) is null	then 'Неверно указанны ключевые параметры id_auto'
							when (select [id] from [dbo].[garage] with(nolock)	where [id] = @order_id_garage) is null	then 'Неверно указанны ключевые параметры id_garage'
							when (select [id] from [dbo].[repair] with(nolock)	where [id] = @order_id_repair) is null	then 'Неверно указанны ключевые параметры id_repair'
							else 'Неверно указанны ключевые параметры'
						end
					goto err
				end
	
				if exists(select 1 from [dbo].[garage] 
							where [number_places] < (select count([start_time]) from [dbo].[order] with(nolock)
													  where @order_end_time > [start_time]
														and [end_time] > @order_start_time 
														and [id_garage] = @order_id_garage)
						)
				begin
					set @err = 'err.order_create.incorrect_time'
					set @errdesc = 'Указанное время уже занято другим заказом'
					goto err
				end

				insert into [dbo].[order] --сохранияем
				values (
						@id				
						,@data_add		
						,@order_id_personal		
						,@order_id_client			
						,@order_id_auto			
						,@order_id_garage			
						,@order_id_repair			
						,@order_start_time
						,@order_end_time
						,'Y'
						)

				set @rp = (select	@id as					[id]		--выводим
									,@data_add as			[data_add]	
									,@order_id_personal as	[id_personal]
									,@order_id_client as	[id_client]
									,@order_id_auto as		[id_auto]	
									,@order_id_garage as	[id_garage]
									,@order_id_repair as	[id_repair]	
									,@order_start_time as	[start_time]
									,@order_end_time as		[end_time]
							for json path, without_array_wrapper )
				goto ok
			end

			if @action in ('order.edit') 
				begin
						if (@order_id is null 
					or @order_data_add is null 
					or @order_id_personal is null 
					or @order_id_client is null 
					or @order_id_auto is null) 
				begin
					set @err = 'err.order_edit.unset_field'
					set @errdesc = --'Неуказанны ключевые параметры'
									case
										when @order_id is null		  	 then 'Неуказанны ключевые параметры id'
										when @order_data_add is null	 then 'Неуказанны ключевые параметры data_add'
										when @order_id_personal is null	 then 'Неуказанны ключевые параметры id_personal'
										when @order_id_client is null	 then 'Неуказанны ключевые параметры id_client	'
										when @order_id_auto is null		 then 'Неуказанны ключевые параметры id_auto'
										when @order_id_garage is null	 then 'Неуказанны ключевые параметры id_garage'
										when @order_id_repair is null	 then 'Неуказанны ключевые параметры id_repair'
										when @order_start_time is null	 then 'Неуказанны ключевые параметры start_time'
										when @order_end_time is null	 then 'Неуказанны ключевые параметры end_time'
									end
					goto err
				end

				if exists(select 1 from [dbo].[garage] 
							where [id] <> @order_id 
							and [number_places] < (select count([start_time]) from [dbo].[order] with(nolock)
													where @order_end_time > [start_time]
													  and [end_time] > @order_start_time 
													  and [id_garage] = @order_id_garage)
						)
				begin
					set @err = 'err.order_create.incorrect_time'
					set @errdesc = 'Указанное время уже занято другим заказом'
					goto err
				end
				
				if exists (select * from [dbo].[order] with(nolock)
							where [a] = 'Y'
							  and [id]			= @order_id 
				 			  and [data_add]	= @order_data_add
				 			  and [id_personal] = @order_id_personal
							  and [id_client]	= @order_id_client
							  and [id_auto]		= @order_id_auto
							  and [id_garage]	= @order_id_garage
							  and [id_repair]	= @order_id_repair
							  and [start_time]	= @order_start_time
							  and [end_time]	= @order_end_time)
				begin 
					set @err = 'err.order_edit.invalid_value'
					set @errdesc = 'Такой заказ уже существует'
					goto err
				end

				if exists (select [a] from [dbo].[order] with(nolock) where [id] = @order_id and [a] = 'N')
				begin 
					set @err = 'err.order_edit.diactive'
					set @errdesc = 'Такого заказа нет'
					goto err
				end

				if exists (select [a] from [dbo].[order] with(nolock) where [id] = @order_id and [a] = 'Y')--сохраняем изменения
				begin
					update [dbo].[order]
					set		[data_add]		= @order_data_add
							,[id_personal]  = @order_id_personal
							,[id_client]	= @order_id_client
							,[id_auto]		= @order_id_auto
							,[id_garage]	= @order_id_garage
							,[id_repair]	= @order_id_repair
							,[start_time]	= @order_start_time
							,[end_time]		= @order_end_time
					from  [dbo].[order]
					where [id] = @order_id
			  --выводим результат
					set @rp = (select * from [dbo].[order] with(nolock) where [id] = @order_id for json path, without_array_wrapper)
					goto ok
				end
			end

			if @action in ('order.get') 
			begin
				set @rp = (select * from [dbo].[order] with(nolock)								--поиск нужного элемента
							where [a] = 'Y' 
							and (	(@order_id				is not null	and @order_id = [id])
									or (@order_data_add		is not null	and @order_data_add		= [data_add])
									or (@order_id_personal	is not null	and @order_id_personal	= [id_personal])
									or (@order_id_client	is not null	and @order_id_client	= [id_client])
									or (@order_id_auto		is not null	and @order_id_auto		= [id_auto]) 
									or (@order_id_garage	is not null	and @order_id_garage	= [id_garage]) 
									or (@order_id_repair	is not null	and @order_id_repair	= [id_repair]) 
									or (@order_start_time	is not null	and @order_start_time	= [start_time]) 
									or (@order_end_time		is not null	and @order_end_time		= [end_time]) 
								)	
						for json path, without_array_wrapper 
						)
 				goto ok
			end

			if @action in ('order.active') 
			begin
				if @order_id is null 
				begin
					set @err = 'err.order_active.unset_field'
					set @errdesc = 'Неуказанны ключевые параметры сущности'
					goto err
				end

				if not exists (select * from [dbo].[order] with(nolock) where id = @order_id )
				begin 
					set @err = 'err.order_active.invalid_value'
					set @errdesc = 'Такого объекта не существует'
					goto err
				end

				if exists (select * from [dbo].[order] with(nolock) where [id] = @order_id and [a] = 'Y')
				begin 
					set @err = 'err.order_active.active'
					set @errdesc = 'Указанный объект уже активен'
					goto err
				end

				update	[dbo].[order]   --изменение активности
				set		[a] = 'Y'
				from	[dbo].[order]
				where	[id] = @order_id
 
				set @rp = (select * from [dbo].[order] with(nolock) where [id] = @order_id for json path, without_array_wrapper)
				goto ok
			end

			if @action in ('order.diactive') 
			begin
				if @order_id is null 
				begin
					set @err = 'err.order_diactive.unset_field'
					set @errdesc = 'Неуказанны ключевые параметры сущности'
					goto err
				end

				if not exists (select * from [dbo].[order] with(nolock) where [id] = @order_id )
				begin 
					set @err = 'err.order_diactive.invalid_value'
					set @errdesc = 'Такого объекта не существует'
					goto err
				end

				if exists (select * from [dbo].[order] with(nolock)	where [id] = @order_id and [a] = 'N')
				begin 
					set @err = 'err.order_diactive.diactive'
					set @errdesc = 'Указанный объект уже неактивен'
					goto err
				end
	
				update	[dbo].[order]	--изменение активности
				set		[a] = 'N'
				from	[dbo].[order]
				where	[id] = @order_id

				set @rp = (select * from [dbo].[order] with(nolock) where [id] = @order_id for json path, without_array_wrapper)
				goto ok
			end
		end

		set @errdesc = 'Не существует action '+@action+' в системе'
		set @err = 'unknow_action'

		goto err
	end try

	begin catch

		set @errdesc = ERROR_MESSAGE()
		set @err = 'err.sys'

		goto err

	end catch

			err:
				set @rp = (select 'err' [status],lower(@err) err , @errdesc errdesc for json path, without_array_wrapper)
				select @rp
				RETURN

			ok:
				set @rp = (select 'ok' [status],json_query(@rp) response for json path, without_array_wrapper)
				select @rp
				RETURN
end

	
