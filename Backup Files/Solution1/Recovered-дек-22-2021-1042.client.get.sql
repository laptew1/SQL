--create   procedure [dbo].[client.edit]
--	@js varchar(max),
--	@rp varchar(max) = '{}' output

--AS

declare
	@js varchar(max) = '{"name":"name","number_license":"1234567890","phone":"89856784544"}',
	@rp varchar(max)  = '"response":{}'

BEGIN
	declare 
	@id					int			 = JSON_VALUE(@js, '$.id')
	,@data_add			datetime	= JSON_VALUE(@js, '$.data_add')
	,@name				varchar(100) = JSON_VALUE(@js, '$.name')
	,@number_license	varchar(10) = JSON_VALUE(@js, '$.number_license')
	,@phone				varchar(11) = JSON_VALUE(@js, '$.phone')
	
	begin 
		set @rp=
			(									--поиск нужного элемента
			select * from [dbo].[client]
			where  ([a] = 'Y' and 
								(
								(@id is not null				and @id = [id])
								or (@data_add is not null		and @data_add = [data_add])
								or (@name is not null			and @name = [name])
								or (@number_license is not null	and @number_license = [number_license])
								or (@phone is not null			and @phone = [phone])
								)
					)
			for json path --, without_array_wrapper --вывод всех элементов\вывод первого
			)
 	end
		
	goto ok
	
	ok:
		set  @rp = (select 'ok' [status],json_query(@rp) response for json path, without_array_wrapper) 
		RETURN

END

