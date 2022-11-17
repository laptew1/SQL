create   procedure [dbo].[client.edit]
	@js varchar(max),
	@rp varchar(max) = '{}' out

AS
BEGIN
	declare 
	@id					varchar(50) = JSON_VALUE(@js, '$.id')
	,@data_add			datetime	= JSON_VALUE(@js, '$.data_add')
	,@name				varchar(50) = JSON_VALUE(@js, '$.name')
	,@number_license	varchar(50) = JSON_VALUE(@js, '$.number_license')
	,@phone				varchar(50) = JSON_VALUE(@js, '$.phone')

	if not exists (select [a] from [dbo].[client] 
					where [id] = @id 
					and [a] = 'N')
	begin 
		set @rp=
			(
			select * from [dbo].[client]
			where  (@id is not null				and [id] = @id)
				or (@data_add is not null		and [data_add] = @data_add)
				or (@name is not null			and [name] = @name)
				or (@number_license is not null	and [number_license] = @number_license)
				or (@phone is not null			and [phone] = @phone)
			for json path, without_array_wrapper
			)
 	end
		
	goto ok
	
	ok:
		set @rp=
		(
		select 'ok' [status],json_query(@rp) response 
		for json path, without_array_wrapper
		)
		RETURN

END


