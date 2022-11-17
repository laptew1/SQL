if (select * from table1  for json path, without_array_wrapper) is null
select 1

declare @a nvarchar(10) = 1
select @a=2
select @a=1
select @a

declare @auto_order_id		nvarchar(20)	 = null
select @auto_order_id	= [value] from table1
select @auto_order_id