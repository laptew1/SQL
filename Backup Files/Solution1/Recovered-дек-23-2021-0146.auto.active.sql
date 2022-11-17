create   procedure [dbo].[auto.active]
	@js varchar(max),
	@rp varchar(max) output

AS
BEGIN
	declare 
	@err				varchar(50)
	,@errdesc			varchar(50)
	,@id				varchar(50) = JSON_VALUE(@js, '$.id')
	
	if @id is null 
	begin
		set @err = 'err.auto_active.unset_field'
		set @errdesc = 'Неуказанны ключевые параметры сущности'
		goto err
	end

	if not exists (select  * from [dbo].[auto] 
						where [id] =  @id )
		begin 
			set @err = 'err.auto_active.invalid_value'
			set @errdesc = 'Такой машины не существует'
			goto err
		end

	if exists 
		(
		select  * from [dbo].[auto] 
		where [id] =  @id 
		and [a] = 'Y'
		)
	begin 
		set @err = 'err.auto_active.active'
		set @errdesc = 'Указанный объект уже активен'
		goto err
	end

	update	[dbo].[auto]   --изменение активности
	set		[a]= 'Y'
	from	[dbo].[auto]
	where	[id]=@id

	update	[dbo].[order]   --изменение активности
	set		[a]= 'Y'
	from	[dbo].[order]
	where	[id_auto]=@id
 
	set @rp =     
		(
		select * from [dbo].[auto] where [id]= @id
		for json path, without_array_wrapper
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

END


