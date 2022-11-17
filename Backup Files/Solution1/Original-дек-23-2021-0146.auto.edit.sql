create   procedure [dbo].[auto.edit]
	@js varchar(max),
	@rp varchar(max) out

AS
BEGIN
	declare 
	@err				varchar(50)
	,@errdesc			varchar(50)
	,@id				varchar(50) = JSON_VALUE(@js, '$.id')
	,@data_add			datetime	= JSON_VALUE(@js, '$.data_add')
	,@id_client			varchar(50) = JSON_VALUE(@js, '$.id_client')
	,@mark				varchar(50) = JSON_VALUE(@js, '$.mark')
	,@number			varchar(50) = JSON_VALUE(@js, '$.number')

	if (@id is null 
		or @data_add is null 
		or @id_client	 is null 
		or @mark is null 
		or @number is null) 
	begin
		set @err = 'err.auto_insert.unset_field'
		set @errdesc = --'���������� �������� ���������'
						case
							when @id is null		 then '���������� �������� ��������� id'
							when @data_add is null	 then '���������� �������� ��������� data_add'
							when @id_client is null	 then '���������� �������� ��������� id_client'
							when @mark is null		 then '���������� �������� ��������� mark'
							when @number is null	 then '���������� �������� ��������� number'
						end
		goto err
	end

	if exists (select * from [dbo].[auto] 
				where [id] <>  @id	
				and  [number] = @number)
	begin 
		set @err = 'err.auto_insert.invalid_license'
		set @errdesc = '���������� ������ ���������� � ����� �� �������'
		goto err
	end
 
	 if ( 9 >= len (@number) and len (@number) >= 8)
	begin 
		set @err = 'err.auto_insert.invalid_number_license'
		set @errdesc = '������� ������ ����� ����������'
		goto err
	end

	if not exists (select * from [dbo].[auto] 
					where id =  @id )
	begin 
		set @err = 'err.auto_insert.invalid_value'
		set @errdesc = '����� ������ �� ����������'
		goto err
	end

	if exists (select [a] from [dbo].[auto] 
				where [id] = @id 
				and [a] = 'N')
	begin 
		set @err = 'err.auto_insert.diactive'
		set @errdesc = '������ ���������� ���'
		goto err
	end

	if exists (select [a] from [dbo].[auto] --��������� ���������
				where [id] = @id 
				and [a] = 'Y')
	begin
		update [dbo].[auto]
		set		[id] = @id
				,[data_add] = @data_add
				,[id_client] = @id_client
				,[mark] = @mark
				,[number] = @number
		from  [dbo].[auto]
		where [id]=@id
 
		set @rp =  --������� ���������
			(
			select * from [dbo].[auto] where [id]= @id
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


