



--	if @action like 'state.ba_pi_%'
--			begin
--				declare 
--					@ba_doc_id varchar(50),
--					@liq_i int,
--					@ba_inn varchar(20),
--					@ba_num nvarchar(50)

--				if @action in ('state.ba_pi_data_request')
--				begin

--					goto ok
--				end
--				{"state":"ba_pi_response"}
--				if @action in ('state.ba_pi_response')
--				begin
--					select top 1 
--						@liq_id = cls_org.[id] 
--					from 
--						[OPERBLOCK].[dbo].[closure_organization] cls_org with(nolock) 
--						inner join [OPERBLOCK].[dbo].[object_map] map with(nolock) 
--						on cls_org.[id] = map.[bid] 
--						and map.[btype] = 'task/obj' 
--						and map.[act] = 1
--					where
--						map.[oid] = @task_id


--					--if object_id('tempdb..#inns') is not null
--					--drop table #inns

--					declare @liqTable_inns table ([inn] varchar(20))

--					insert into @liqTable_inns 
--						select [value] from 
--							string_split((select [value] from [OPERBLOCK].[dbo].[object_key_values] where oid = @liq_id and kid = '83759CE6-7248-4C41-9448-A514E5382575' and act = '1'), char(10))
--						where [value] <> ''

--					set @liq_i = 0

--					while 1 = 1
--					begin
--					  select distinct
--						@liq_inn = [inn]
--					  from
--						@liqTable_inns
--					  order by [inn] offset @liq_i rows fetch next 1 rows only

--					  if @@rowcount = 0 break

--					  set @tempjs = null
--					  set @tempjs =
--						(
--						  select
--							'D8B84E56-BB14-4CFA-8100-AE132040E791' [userid], --��������
--							'liquid_close' [type],
--							json_query((
--							  select top 1
--								json_query((
--								select top 1
--								  @liq_inn [client_inn]
--								for json path, without_array_wrapper
--								)) [client]
--							  for json path, without_array_wrapper
--							)) [form]
--						  for json path, without_array_wrapper
--						)

--					  set @temprp = null
--					  exec [tasks].[dbo].[ms_api] 'task.create',@tempjs,@temprp out

--					  set @liq_code = json_value(@temprp,'$.response.task_id')

--					  insert into [OPERBLOCK].[dbo].[cls_orgs_logs]
--						values(newid(),getdate(),@liq_inn, @liq_code)

--					  waitfor delay '00:00:02'

--					  set @liq_i += 1
--					end


--				end

--				if @action in ('state.ba_pi_response')
--				begin

--					--��� ��������� ��� � ����� - ��������� � �������				
--					if @state_pr_id is null
--						begin
--							select top 1
--								@state_pr_id = prf.[id]
--							from
--								[wcf_new].[dbo].[process_flow] prf with(nolock)
--							where
--								prf.[flow_obj_id] = @state_task_id and prf.[status] <> 'complete'
--							order by [dadd] desc
--						end
				
--					if @state_pr_id is not null
--						begin
--							set @state_js =
--								(
--									select
--										@state_pr_id [id]
--									for json path, without_array_wrapper
--								)

--							exec [wcf_new].[dbo].[ms_api] 'process.complete_manual',@state_js,@state_rp out
--						end

--					goto ok
--				end

--			end


--go


declare @tempjs varchar(max), @temprp2 varchar(max), @client_id varchar(50), @temprp varchar(max)
declare @tempjs varchar(max), @temprp2 varchar(max), @client_id varchar(50), @temprp varchar(max)
set @tempjs =
(
  select 
    '82104615974' [id]
  for json path, without_array_wrapper
)           
exec [operblock].[operblock].[ms_api] 'payment.docInfo',@tempjs,@temprp2 out
select @temprp2

--set @tempjs =
--(
--  select 
--    '2022-08-05' [date_beg],
--    '2022-08-05' [date_end],
--    'OUT' [filter]
--  for json path, without_array_wrapper
--)           
--exec [operblock].[operblock].[ms_api] 'rc.docInfo',@tempjs,@temprp2 out
--select @temprp2

--select 
--   id
--from 
--  [operblock].[dbo].[v_clients] 
--where client_inn = '771586352171'
go


declare @tempjs varchar(max), @temprp2 varchar(max), @temprp varchar(max),  @tsk__array  varchar(max), @task_id varchar(50), @client_id varchar(50), @client_sum varchar(50), @doc_sum varchar(50), @car_sum varchar(50), @arest_sum varchar(50)

select
      @tsk__array = 
        json_query(case
                  when [type] = 4 then [value]
                  else '['+[value]+']'
                end)
    from
      openjson(@temprp2,'$.response.response.DOC_INFO.DOCS')
    where
      [key] = 'DOC' and 
      [type] in (4,5)


set @doc_sum = json_query (@tsk__array, '$.sum')

if json_value(@temprp, '$.TYPE') = '����. �����.' and json_value(@temprp, '$.STATE') = '�����������' 
begin
	if json_value(@temprp, '$.TEXT_VOZV') like '%������%��������%������������%'
	begin
		set @temprp = null
		set @tempjs =
			(
			select 
				@task_id [oid],
				'������ �� �������������� ��������, ��������� ������ � ���� ����� 1 ���.' [ba_answer_for_ba],
				'������ ������ ��������� �� �������� �����. �� ���������� �� ������� ��� � ������� 2-� �����.' [ba_answer_for_client]
			for json path, without_array_wrapper
			)
		exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
		goto ok
	end

	if json_value(@temprp, '$.TEXT_VOZV') like '%������%�������%' or json_value(@temprp, '$.TEXT_VOZV') like '%�����%���%�������%'
	begin
		select top 1
			@client_id = cli.[id]
		from              
			[operblock].[dbo].[clients] cli with(nolock) 
			inner join [operblock].[dbo].[object_map] map with(nolock) on cli.[id] = map.[bid] and map.[btype] = 'task/obj' and map.[act] = 1
		where
			map.[oid] = @task_id

		set @tempjs = (select @client_id [client_id] for json path, without_array_wrapper)
		set @temprp = null
		exec [operblock].[operblock].[ms_api] 'account.propertyGet',@tempjs,@temprp out

		if (select top 1 1 from [operblock].[dbo].[rko_lims] with(nolock) where client_id = @client_id and act = 1 and ([lim_source] like '%CRM%' or [lim_source] like '%AML%' or [lim_source] like '%��%' or [lim_source] like '%������%������������%')) is not null
		begin
			set @temprp = null
			set @tempjs =
			(
				select 
				@task_id [oid],
				'������ �� �������������� ��������, ��������� ������ � ���� ����� 1 ���.' [ba_answer_for_ba],
				'������ ������ ��������� �� �������� �����. �� ���������� �� ������� ��� � ������� 2-� �����.' [ba_answer_for_client]
				for json path, without_array_wrapper
			)
			exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
			goto ok
		end
	end

	if json_value(@temprp, '$.TEXT_VOZV') like '%������%�������%' -- ������ ��������
	begin
		select top 1
			@client_id = cli.[id]
		from              
			[operblock].[dbo].[clients] cli with(nolock) 
			inner join [operblock].[dbo].[object_map] map with(nolock) on cli.[id] = map.[bid] and map.[btype] = 'task/obj' and map.[act] = 1
		where
			map.[oid] = @task_id

		set @tempjs = (select @client_id [client_id] for json path, without_array_wrapper)
		set @temprp = null
		exec [operblock].[operblock].[ms_api] 'account.propertyGet',@tempjs,@temprp out

		if (select top 1 1 from [operblock].[dbo].[rko_lims] with(nolock) where client_id = @client_id and act = 1 and ([lim_source] like '%BANKRUPT%' or  [lim_source] like '%�������%')) is not null
		begin
			set @temprp = null
			set @tempjs =
			(
				select 
				@task_id [oid],
				'������ ��������� � ��������� �����������, ��� ������� �������� ����� ������ �������� ����������� ���.' [ba_answer_for_ba],
				'��� ��� �� ���������� � ��������� �����������, ������ ������ �� ����� �������� �������������� ��������. � ������� ���� ������� ��� �� ����������.' [ba_answer_for_client]
				for json path, without_array_wrapper
			)
			exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
			goto ok
		end
	end

	if json_value(@temprp, '$.TEXT_VOZV') like '%��������%��������%�����%' --���������� �������� � ������������ 5  � ����������� ���
	begin
		select top 1
			@client_id = cli.[id]
		from              
			[operblock].[dbo].[clients] cli with(nolock) 
			inner join [operblock].[dbo].[object_map] map with(nolock) on cli.[id] = map.[bid] and map.[btype] = 'task/obj' and map.[act] = 1
		where
			map.[oid] = @task_id

		set @tempjs = (select @client_id [client_id] for json path, without_array_wrapper)
		set @temprp = null
		exec [operblock].[operblock].[ms_api] 'account.refreshsaldo',@tempjs,@temprp out
		
		select @client_sum = sum([saldo]) from [operblock].[dbo].[accounts] where clid = @client_id and act = 1

		set @tempjs = (select @client_id [client_id] for json path, without_array_wrapper)
		set @temprp = null
		exec [operblock].[operblock].[ms_api] 'account.getcardindex',@tempjs,@temprp out

		select @car_sum = sum(cast(json_value([value],'$.DOC_SUM')as integer)) from openjson (@temprp, '$.response.GET_KARTOTEKA.BODY')

		if (select top 1 1 from [operblock].[dbo].[rko_lims] with(nolock) where client_id = @client_id and act = 1) is not null
		begin
			if @client_sum !< (@doc_sum + @car_sum)
			begin
				set @temprp = null
				set @tempjs =
				(
					select 
					@task_id [oid],
					'- ���������� ������ �� �������� ���������� ���. ������ ��� �������� �� ����� 15 �����.' [ba_answer_for_ba],
					'�� ����� ����� ���� ����������� �� ���, ������� ���������� ������� �� ���������� ����� ������ ������� ������ �������. ������ �� ��� ����� �� ����� 30 �����.' [ba_answer_for_client]
					for json path, without_array_wrapper
				)
				exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
				goto ok
			end
			else
			begin
				set @temprp = null
				set @tempjs =
				(
					select 
					@task_id [oid],
					'- �� ����� ������� ������������ �������� �������, ������ ����� �������� ����� ���������� �����.' [ba_answer_for_ba],
					'��� ���������� ������� �� ������� ����� �� �����. ����� ������� �� ���������� ����� ������, ��������� ��������� ����.' [ba_answer_for_client]
					for json path, without_array_wrapper
				)
				exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
				goto ok
			end
		end
		
	end
	
	if json_value(@temprp, '$.TEXT_VOZV') like '%��������%��������%�����%' --���������� ��������� � �����������
	begin
		select top 1
			@client_id = cli.[id]
		from              
			[operblock].[dbo].[clients] cli with(nolock) 
			inner join [operblock].[dbo].[object_map] map with(nolock) on cli.[id] = map.[bid] and map.[btype] = 'task/obj' and map.[act] = 1
		where
			map.[oid] = @task_id

		set @tempjs = (select @client_id [client_id] for json path, without_array_wrapper)
		set @temprp = null
		exec [operblock].[operblock].[ms_api] 'account.refreshsaldo',@tempjs,@temprp out
		
		select @client_sum = sum([saldo]) from [operblock].[dbo].[accounts] where clid = @client_id and act = 1

		set @tempjs = (select @client_id [client_id] for json path, without_array_wrapper)
		set @temprp = null
		exec [operblock].[operblock].[ms_api] 'account.getcardindex',@tempjs,@temprp out

		select @car_sum = sum(cast(json_value([value],'$.DOC_SUM')as integer)) from openjson (@temprp, '$.response.GET_KARTOTEKA.BODY')

		if (select top 1 1 from [operblock].[dbo].[rko_lims] with(nolock) where client_id = @client_id and act = 1 ) is not null
		begin
			if @client_sum !< (@doc_sum + @car_sum)
			begin
				set @temprp = null
				set @tempjs =
				(
					select 
					@task_id [oid],
					'-  ������ �� ��������� �� �������� ���������� ���, ��������� ������ � ���� ����� 1 ���. ��� ������������� ���.�������� �� ����� ��������, ��������� ��� ��������� ������ �� ��. ' [ba_answer_for_ba],
					'- �� ����� ����� ���� ����������� �� ���, ������� ���������� ������� �� ������ ��������� ������ ������� ������ �������. �� ������� �� ���������� � ������� ����.' [ba_answer_for_client]
					for json path, without_array_wrapper
				)
				exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
				goto ok
			end
			else
			begin
				set @temprp = null
				set @tempjs =
				(
					select 
					@task_id [oid],
					'- �� ����� ������� ������������ �������� �������, ������ ����� �������� ����� ���������� �����.' [ba_answer_for_ba],
					'- ��� ���������� ������� �� ������� ����� �� �����. ����� ������� �� ��������� ������, ��������� ��������� ����.' [ba_answer_for_client]
					for json path, without_array_wrapper
				)
				exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
				goto ok
			end
		end
	end
	
	if json_value(@temprp, '$.TEXT_VOZV') like '%��������%��������%�����%' --������ ��� �����������/���������
	begin
		select top 1
			@client_id = cli.[id]
		from              
			[operblock].[dbo].[clients] cli with(nolock) 
			inner join [operblock].[dbo].[object_map] map with(nolock) on cli.[id] = map.[bid] and map.[btype] = 'task/obj' and map.[act] = 1
		where
			map.[oid] = @task_id

		set @tempjs = (select @client_id [client_id] for json path, without_array_wrapper)
		set @temprp = null
		exec [operblock].[operblock].[ms_api] 'account.refreshsaldo',@tempjs,@temprp out
		
		select @client_sum = sum([saldo]) from [operblock].[dbo].[accounts] where clid = @client_id and act = 1

		set @tempjs = (select @client_id [client_id] for json path, without_array_wrapper)
		set @temprp = null
		exec [operblock].[operblock].[ms_api] 'account.getcardindex',@tempjs,@temprp out

		select @car_sum = sum(cast(json_value([value],'$.DOC_SUM')as integer)) from openjson (@temprp, '$.response.GET_KARTOTEKA.BODY')
		select top 1 @arest_sum = [debt_amount] from [operblock].[dbo].[rko_lims] with(nolock) where client_id = @client_id and act = 1 and [lim_source] like '%�����%'

		if (select top 1 1 from [operblock].[dbo].[rko_lims] with(nolock) where client_id = @client_id and act = 1 and ([lim_source] like '%���%' or  [lim_source] like '%�����%')) is not null
		begin
			if ((select top 1 1 from [operblock].[dbo].[rko_lims] with(nolock) where client_id = @client_id and act = 1 and [lim_source] like '%���%') is not null and @client_sum !<  @car_sum)
			begin
				set @temprp = null
				set @tempjs =
				(
					select 
					@task_id [oid],
					'������ �������� ��������� ������ �� ������� ��� ����������� �� ��� � ��������� ������������ 3 ��� 4. ���������� ������� ��� � ����� �������� ���������.' [ba_answer_for_ba],
					'' [ba_answer_for_client]
					for json path, without_array_wrapper
				)
				exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
				goto ok
			end
			else
			begin
				set @temprp = null
				set @tempjs =
				(
					select 
					@task_id [oid],
					'������ �������� ��������� ������ �� ������� ��� ����������� �� ���. ������� ��������� �� �������������� �������� ���, ��������� ������ � ���� ����� 30 �����.' [ba_answer_for_ba],
					'' [ba_answer_for_client]
					for json path, without_array_wrapper
				)
				exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
				goto ok
			end
			if ((select top 1 1 from [operblock].[dbo].[rko_lims] with(nolock) where client_id = @client_id and act = 1 and [lim_source] like '%�����%') is not null and @client_sum !< @arest_sum)
			begin
				set @temprp = null
				set @tempjs =
				(
					select 
					@task_id [oid],
					'������ �������� ��������� ������ �� ������� ��� ������ �����. ��������� ������� ��� ���������� �������� ������������.' [ba_answer_for_ba],
					'' [ba_answer_for_client]
					for json path, without_array_wrapper
				)
				exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
				goto ok
			end
		end
		
	end

	if json_value(@temprp, '$.TEXT_VOZV') like ''   --������ �� 30 �����
	begin
		if  @doc_sum > 30000000
		set @temprp = null
		set @tempjs =
			(
			select 
				@task_id [oid],
				'������ �� ������� �����, ��� ���������� ��������� ���. �������� �������� ������ �� �������� �����. ��������� ������ � ���� ����� 30 �����.' [ba_answer_for_ba],
				'' [ba_answer_for_client]
			for json path, without_array_wrapper
			)
		exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
		goto ok
	end
	
	if json_value(@temprp, '$.TEXT_VOZV') like '%��������%��������%�����%' --���������� �������� �������  �� �����
	begin
		select top 1
			@client_id = cli.[id]
		from              
			[operblock].[dbo].[clients] cli with(nolock) 
			inner join [operblock].[dbo].[object_map] map with(nolock) on cli.[id] = map.[bid] and map.[btype] = 'task/obj' and map.[act] = 1
		where
			map.[oid] = @task_id

		set @tempjs = (select @client_id [client_id] for json path, without_array_wrapper)
		set @temprp = null
		exec [operblock].[operblock].[ms_api] 'account.refreshsaldo',@tempjs,@temprp out
		
		select @client_sum = sum([saldo]) from [operblock].[dbo].[accounts] where clid = @client_id and act = 1

		if (select top 1 1 from [operblock].[dbo].[rko_lims] with(nolock) where client_id = @client_id and act = 1) is not null
		begin
			if @client_sum = 0
			begin
				set @temprp = null
				set @tempjs =
				(
					select 
					@task_id [oid],
					'�� ����� ������� ������������ ������� ��� ���������� �������.' [ba_answer_for_ba],
					' ' [ba_answer_for_client]
					for json path, without_array_wrapper
				)
				exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
				goto ok
			end
		end
		
	end

	if json_value(@temprp, '$.TEXT_VOZV') like '%�������%�������%' --���������������� �� �� ����� �������� ���������� � ��������
	begin
		set @temprp = null
		set @tempjs =
		(
			select 
			@task_id [oid],
			'���� �������� ������� � ��������. ������ �����  ��������, ����� ����, ��� ������� ���� ����������. ���� ���� �� ����� ������ �� 20,00 ��� ���������� �������� ���, �� ������ ������ �����������.' [ba_answer_for_ba],
			' ' [ba_answer_for_client]
			for json path, without_array_wrapper
		)
		exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
		goto ok
	end

	if json_value(@temprp, '$.TEXT_VOZV') like '%��%��������%' --�� �� ���������
	begin
		set @temprp = null
		set @tempjs =
		(
			select 
			@task_id [oid],
			'�� ������� ������� ���������� ������ (��������������) � ����������. ��� ��� ��������� ������ �� ����� ����������� ���� ��� ������� ��������. ��������� ������ � ���� ����� 1 ���. ' [ba_answer_for_ba],
			'�� ����� ������� ��������� ����������� �������, ������� ���������� � ������� ��� � ������� 2-� �����. ' [ba_answer_for_client]
			for json path, without_array_wrapper
		)
		exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
		goto ok
	end

	if json_value(@temprp, '$.TEXT_VOZV') like '%�� ������%��������%' --'�� �������� �������� ��������
	begin
		set @temprp = null
		set @tempjs =
		(
			select 
			@task_id [oid],
			'�� ������� ������� ���������� ������ (��������������) � ����������. ��� ��� ��������� ������ �� ����� ����������� ���� ��� ������� ��������. ��������� ������ � ���� ����� 1 ���. ' [ba_answer_for_ba],
			'�� ����� ������� ��������� ����������� �������, ������� ���������� � ������� ��� � ������� 2-� �����.' [ba_answer_for_client]
			for json path, without_array_wrapper
		)
		exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
		goto ok
	end

	if json_value(@temprp, '$.TEXT_VOZV') like '%�������%�������%' --'�� ���� ��������� �������
	begin
		set @temprp = null
		set @tempjs =
		(
			select 
			@task_id [oid],
			'������ ������� �� ���.�������� �������� ��������� ������� �� �������� ����������. ��� ��� ��������� ������ �� ����� �������� ��� ������� ��������. ��������� ������ � ���� ����� 1 ���. ' [ba_answer_for_ba],
			'��� ��� �� ����������� ������ �� ���� ��������� �������, ��� ����� ������� ������� ��� ��� ��������. ������� �� ���������� � ������� 2-� �����.' [ba_answer_for_client]
			for json path, without_array_wrapper
		)
		exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
		goto ok
	end

	set @temprp = null
	set @tempjs =
	(
		select 
		@task_id [oid],
		'���������� �� �������' [ba_error]
		for json path, without_array_wrapper
	)
	exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
	goto ok
end
------------------------------------------------------------------------------------------------------------------------------------------------------------	
		
			
		
		 
		

-------------------------------------------------------------------�����-------------------------------------------------------------------------------------
----------------------------------------------------------------������ �����---------------------------------------------------------------------------------

declare @dop_status nvarchar(100), @doc_status nvarchar(100), @Reason nvarchar(500), @errdesc nvarchar(300), @dap_analis nvarchar(300), @for_ba nvarchar(300), @for_client nvarchar(300), @client_id nvarchar(50), @cl_saldo nvarchar(50), @account nvarchar(50), @sum_pay nvarchar(50),
		@tempjs varchar(max), @temprp2 varchar(max), @temprp varchar(max),  @tsk__array  varchar(max)

set @tempjs =
(
  select 
    '82104615974' [id]
  for json path, without_array_wrapper
)           
exec [operblock].[operblock].[ms_api] 'payment.docInfo',@tempjs,@temprp2 out
select @temprp2

select
      @tsk__array = 
        json_query(case
                  when [type] = 4 then [value]
                  else '['+[value]+']'
                end)
    from
      openjson(@temprp2,'$.response.response.DOC_INFO.DOCS')
    where
      [key] = 'DOC' and 
      [type] in (4,5)

select @dop_status = json_query([value], '$.TYPE') from openjson (@tsk__array, '$.')
select @doc_status = json_query([value], '$.STATE') from openjson (@tsk__array, '$.')
@dop_status
select @account = json_query([value], '$.P_ACC') from openjson (@tsk__array, '$.')
select @sum_pay = json_query([value], '$.SUM') from openjson (@tsk__array, '$.')
select  @cl_saldo = [saldo] from [operblock].[dbo].[accounts] where [clid] = @client_id and [account] = @account

select  @dap_analis = [lim_sourse] from [operblock].[dbo].[rko_lims] where [client_id] = @client_id --�� ������...
select  @Reason = [reason] from [operblock].[dbo].[rko_lims] where [client_id] = @client_id --�� ������...

select  @errdesc = ???  @dap_analis = ???  @cartotec @sum_arest @account_data @account_status

if @dop_status = '������� ��������� ���������'
	if @doc_status = '�����������' 
	begin
	--	if @Reason in('����������, ��������������, ���������������� �������� �� �������������','���� ����-�����������, ��, ��','') 
		and @errdesc in ('������: �������� ������������ �� "�������� �� ������ ������ �������������� ���" ==��������� ��������� ��== 57 ������������� �� ������ � ��������������� 3569319824 FOREIGN TRADE BANK (FTB)','������ ������������ ����� ��������','������ ���� �������� ')
		and @dap_analis = '���������� AML, ���������� ������ ������������'
			select @for_ba = '������ �� �������������� ��������, ��������� ������ � ���� ����� 1 ���.', @for_client = '������ ������ ��������� �� �������� �����. �� ���������� �� ������� ��� � ������� 2-� �����.' 
--		if @Reason = '����������� ��������� �� �������� �����' 
		and @errdesc in ('������ ����������� ����� ��������', '������ ����������� ����� ��������', '������ ����������� � ������������ ����� ��������') 
		and @dap_analis = '[CRM] ���������� ����� ��������� ������ �������' 
			select @for_ba = '������ ����� ������ �� �������� �����, �������� � ��������� ������� ����������.', @for_client = '��� ��� �� ��������� ��������� �� �������� �����, ����� ������� �� ����� ����������.'  
--		if @Reason = '������ ��������' 
		and @errdesc = '������ ����������� ����� ��������'
		and @dap_analis in ('[BANKRUPT]', '����������� �������', '�������', '�������. �������� ����������� ��������' )
			select @for_ba = '������ ��������� � ��������� �����������, ��� ������� �������� ����� ������ �������� ����������� ���.', @for_client = '��� ��� �� ���������� � ��������� �����������, ������ ������ �� ����� �������� �������������� ��������. � ������� ���� ������� ��� �� ����������.'  
--		if @Reason = '���������� �������� � ������������ 5  � ����������� ���' 
		and @errdesc like '%� ������ ��������� ���������� ����  ������� � ����� ��%' 
			if (@cl_saldo !< @sum_pay) 
				select @for_ba = '- ���������� ������ �� �������� ���������� ���. ������ ��� �������� �� ����� 15 �����. ', @for_client = '�� ����� ����� ���� ����������� �� ���, ������� ���������� ������� �� ���������� ����� ������ ������� ������ �������. ������ �� ��� ����� �� ����� 30 �����.'  
			else select @for_ba = '- �� ����� ������� ������������ �������� �������, ������ ����� �������� ����� ���������� �����.', @for_client = ' ��� ���������� ������� �� ������� ����� �� �����. ����� ������� �� ���������� ����� ������, ��������� ��������� ����.' 
--		if @Reason = '���������� ��������� � �����������'
		and @errdesc like '%� ������ ��������� ���������� ����  ������� � ����� ��%'
			if (@cl_saldo !< @sum_pay) 
				select @for_ba = '-  ������ �� ��������� �� �������� ���������� ���, ��������� ������ � ���� ����� 1 ���. ��� ������������� ���.�������� �� ����� ��������, ��������� ��� ��������� ������ �� ��. ', @for_client = '- �� ����� ����� ���� ����������� �� ���, ������� ���������� ������� �� ������ ��������� ������ ������� ������ �������. �� ������� �� ���������� � ������� ����.' 
			else select @for_ba = ' - �� ����� ������� ������������ �������� �������, ������ ����� �������� ����� ���������� �����.', @for_client = '- ��� ���������� ������� �� ������� ����� �� �����. ����� ������� �� ��������� ������, ��������� ��������� ����.' 
--		if @Reason = '������ ��� �����������/���������'
		and @errdesc like '%� ������ ��������� ���������� ����  ������� � ����� ��%'
			if @dap_analis = '��� (����������� ��������� ������)' and @cartotec is null
				select @for_ba = '������ �������� ��������� ������ �� ������� ��� ����������� �� ��� � ��������� ������������ 3 ��� 4. ���������� ������� ��� � ����� �������� ���������. '	
			if @dap_analis = '��� (����������� ��������� ������)' and @cartotec is not null
				select @for_ba = '������ �������� ��������� ������ �� ������� ��� ����������� �� ���. ������� ��������� �� �������������� �������� ���, ��������� ������ � ���� ����� 30 �����.'	
			if @dap_analis = 'MIN SUM (�����)' and @cl_saldo < @sum_arest
			select @for_ba = '������ �������� ��������� ������ �� ������� ��� ������ �����. ��������� ������� ��� ���������� �������� ������������.'	
--		if @sum_pay > 30000000 
			select @for_ba = '������ �� ������� �����, ��� ���������� ��������� ���. �������� �������� ������ �� �������� �����. ��������� ������ � ���� ����� 30 �����.'
--		if @cl_saldo !> 0
		and @errdesc like '%� ������ ��������� ���������� ����  ������� � ����� ��%' 
			select @for_ba = '�� ����� ������� ������������ ������� ��� ���������� �������.'
--		if @Reason = '���������������� �� �� ����� �������� ���������� � ��������' 
		and @errdesc = '���� ���������� ������� � ��������'
		and @account_status = 'opening' 
			select @for_ba = '���� �������� ������� � ��������. ������ �����  ��������, ����� ����, ��� ������� ���� ����������. ���� ���� �� ����� ������ �� 20,00 ��� ���������� �������� ���, �� ������ ������ �����������.'
--		if @Reason = '�� �� ���������' 
		and @errdesc = '�� �� ���������'
			select @for_ba = '�� ������� ������� ���������� ������ (��������������) � ����������. ��� ��� ��������� ������ �� ����� ����������� ���� ��� ������� ��������. ��������� ������ � ���� ����� 1 ���. ', @for_client = '�� ����� ������� ��������� ����������� �������, ������� ���������� � ������� ��� � ������� 2-� �����.'
--		if @Reason = '�� �������� �������� ��������' 
		and @errdesc = '�� �������� �������� ��������'
			select @for_ba = '�� ������� ������� ���������� ������ (��������������) � ����������. ��� ��� ��������� ������ �� ����� ����������� ���� ��� ������� ��������. ��������� ������ � ���� ����� 1 ���. ', @for_client = '�� ����� ������� ��������� ����������� �������, ������� ���������� � ������� ��� � ������� 2-� �����.'
--		if @Reason = '�� ���� ��������� �������' 
		and @errdesc = '��������������� ����������� ������� ��� ���������� �������'
			select @for_ba = '������ ������� �� ���.�������� �������� ��������� ������� �� �������� ����������. ��� ��� ��������� ������ �� ����� �������� ��� ������� ��������. ��������� ������ � ���� ����� 1 ���. ', @for_client = '��� ��� �� ����������� ������ �� ���� ��������� �������, ��� ����� ������� ������� ��� ��� ��������. ������� �� ���������� � ������� 2-� �����.'
		if @Reason = '������� ��������� � ����� �������' 
		and @errdesc = '%�� ����� % ���� ���������.%������� ������� ��������� !%'
			select @for_ba = '�� ����� ������� ���� ������������ ���������. ����� ������ ������, �� ����� ��������.', @for_client = '�� �� ����� �������� ������, ��� ��� �� ����� ����� ���� �������������. ����� �� ������ �� �������� ������.'
		if @Reason is null
		and @errdesc is null
			select @for_ba = '������� �� ����������, ��������� ������ � ���� ����� 15 �����. ', @for_client = '������� ���������� �� �������, ������� ��� � ������� ����.'
		if @Reason = '����������� �� ����� �������'
		and @errdesc like '%�� ����� 40702% ��������� ������� � ������������ �� ���� 3%'
			select @for_ba = '������ �� ����� ���� ��������. ����������� �������� ��� ����������� ������������ ������ ���� �� ���� 3-��', @for_client = '�� �� ����� �������� ������ ������ ��� ����������� ������������.'
		if @Reason = '��������� �� ������� �� ����������'
		and @dap_analis = '������������'
			select @for_ba = '������ �� ������� ���������� ����� �������� ����� ����, ��� �� ������� ���� ������ �������� ������ ��������. ��������� ������ � ���� ����� 1 ���.', @for_client = '������ �� ������ ���������� ��������� �� �������������� ��������, �� �������� ��� � ������� ����.'
	end
	if @doc_status = '�� �������� ��������'
		select @for_ba = '������ �� �������� ��������� ��������. ����������� �������� � �������� ��� ������� �������� � ������� �����.', @for_client = '��� ������ ��������� �� �������� ��������� ��������, ������ ��� �������� �� ������ �����. ���� � ������������ ��������� ������� �� ����������, ��� �������� � ���� � ����.'
	if @doc_status = '��������'
		select @for_ba = '������ �������� ' + @account_data + '.'
	if @doc_status = '���������� �������'
	begin
		if  @errdesc = '������� ��������'
			select @for_ba = '������ ������� �������� ����� ������ �������'	
		if  @errdesc in ('��� ������ �������� � ����������� �� �������:�������� ������������ ����������', '������ ����������� �� �������: ������������ ���������� �� ������������� �/�����.', '������ ����������� �� �������: �������� ������������ ����������', '������ ����������� �� �������: �������� ��������� ����������', '�� ������������ �� �������: ������������ ���������� �� ������������� ���������� � ���������.', '�� ������������ �� �������: ��������������-�������� ����� ���������� �� ��������� � ��������� � ���������.')
			select @for_ba = '������ ����������� �� �������: �������� ������������ ����������.',	 @for_client = '������ ��� �������� ��-�� ��������� ���������. �� ��������� ������ � ������������ ����������. ��������� �������� � �������� ����� ������.'	
		if  @errdesc in ('��� ������ �������� � ����������� �� �������:�������� ��������� ���������� (������������ � ���)', '������ ����������� �� �������: ������������ � ��� ���������� �� ������������� �/�����.', '������ �������� � ����������� �� �������:�������� ������������ ����������')
			select @for_ba = '������ ����������� �� �������: �������� ������������ ���������� � ���', @for_client = '������ ��� �������� ��-�� �������� ����������. �� ��������� ������ � ������������ ���������� � ���. ��������� ��������� � �������� ����� ������.'
		if  @errdesc in ('������ ����������� �� �������: �������� ��� ����������', '������ �������� � ����������� �� �������: �������� ��� ����������.', '�� ������������ �� �������: ��� ���������� �� ��������� � ��� ��������� � ���������.')
			select @for_ba = '������ �����������  �� �������: �������� ���', @for_client = '������ ��� �������� ��-�� ��������� ���������. �� ��������� ������ � ��� ����������. ��������� �������� � �������� ����� ������.'
		if  @errdesc in ('������ ����������� �� �������: ���� ���������� ������', '������ �������� � ����������� �� ������� : ���� ���������� ������.')
			select @for_ba = '������ �����������  �� �������: ���� ���������� ������.', @for_client = '������� ��� �������� �� ������� �������� ����� ���������� �������. �������� ���������� ��������� � ����������� � �������� ����� ������.'
		if  @errdesc in ('������ �������� � ����������� �� �������:�������� ���� ����������', '�� ������������ �� ������� ������� ��������� ���������� ����������', '�� ������������ �� �������: ���������� �� ��������� ���������� ����������.', '�������� ��������� ����������. �������� ���� � ���')
			select @for_ba = '������ �����������  �� �������: �������� ��������� ����������.', @for_client = '������ ��� �������� ��-�� �������� ���������� ����������. �������� ���������� ��������� � ����������� � �������� ����� ������.'
		if  @errdesc in ('�� ������������ �� �������: ���������� �� ��� �������� ������ � ���������� ����� ��� ���� "�� ��������".')
			select @for_ba = '��� ����� ����������� �� �������: ���������� �� ��� �������� ������ � ���������� ����� ����� ��� ���� "�� ��������"', @for_client = '��� ����� ����������� �� �������: ���������� �� ��� �������� ������ � ���������� ����� ����� ��� ���� "�� ��������"'
		if  @errdesc in ('������������ �������� �� ����� ��������� ����������� ����������')
			select @for_ba = '������ �������� ������� �� ������� ������������ ����������.�������� ���������� ����� � �����-����������', @for_client = '��� ������ ������ ����-���������� �� ������� ������������ ����������. ����������� ���������� � ���������� ������� � �������� ���������� ���������.'
		if  @errdesc in ('���� �������� ��������� ������ �������� ������� �� 10+ ����', '����� ���� �������� �������', '����� ���� ���������� ���������')
			select @for_ba = '���� ���������� ��������� �����. ��������� ��������� ��������� � ������� 10 ���� ����� ��� �����������.', @for_client = '���� ������ ���������� ��������� �����. ��������� ��������� ��������� � ������� 10 ���� ����� ��� �����������. ����������� ������� ����� ������. '
		if  @errdesc in ('������������ ������� �� �����')
			select @for_ba = '��� ���������� ������� �� ������� ����� �� ����� �������. ', @for_client = '��� ������ ��������, ��� ��� ��� ��� ���������� �� ������� ����� �� �����. �������� ����� ������, �������� ������� �� �����, � ����� ������� �� �������� �����.'
		if  @errdesc in ('������� ����������� ������� �� ���������� ��� �������� ���������.', '�������� �� ����� ���� �������� �� ���� ��������� �������.', '��������� ������������� ��������� �������.')
			select @for_ba = '������ ��������, ��� ��� ������ ������� �������� ��������� ������ �� ���� ��������� �������. ', @for_client = '�� ��������� ������, ��� ��� �� �� ������ � ������� ������������� ��������� �������.'
	end
if @dop_status = '��������� ������� �������� �� ���������  � ��������� ������'
	if @doc_status = '��' 
	begin
		if @Reason = '������� �������������� ������������ 1 � 2'
		and @errdesc = '������� 1 � 2'
			select @for_ba = '������ ��������� � ��������� ������, ��������� ������ � ���� ����� 15 �����.', @for_client = '��� ������ �������� � ���������, � ������� 15-20 ����� �� �������.'
		if @Reason = '������� ������ � ������� ��������, ������� 5,5/6� 6'
		and @errdesc in ('��������������� �� �� ����� �������', '�� �������� �������� ��������')
			select @for_ba = '�� ������� ������� ���������� ������ (��������������) � ����������. ��� ��� ��������� ������ �� ����� ����������� ���� ��� ������� ��������. ��������� ������ � ���� ����� 1 ���. ', @for_client = '�� ����� ������� ��������� ����������� �������, ������� ���������� � ������� ��� � ������� 2-� �����.'
		if @Reason = '������� ������ � ������� ��������, ������� 5,5/6� 6'
		and @errdesc = '��������������� ����������� ������� ��� ���������� �������'
			select @for_ba = '������ ������� �� ���.�������� �������� �� �������� ����������. ��� ��� ��������� ������ �� ����� ��������  ��� ������� ��������. ��������� ������ � ���� ����� 1 ���.', @for_client = '��� ��� �� ����������� ������ �� ���� ��������� �������, ��� ����� ������� ������� ��� ��� ��������. ������� �� ���������� � ������� 2-� �����.'
		if @Reason = '������� ������ � ������� ��������, ������� 5,5/6� 6'
		and @errdesc = '������� ���������'
			select @for_ba = '�� ����� ������� ���� ������������ ���������. ����� ������ ������, �� ����� ��������.', @for_client = '�� �� ����� �������� ������, ��� ��� �� ����� ����� ���� �������������. ����� �� ������ �� �������� ������.'
		if @Reason = '������� ������ � ������� ��������, ������� 5,5/6� 6'
		and @errdesc = '���� �����. - �������� ����������� ���� �����,������������ �������� ���� 108 (����� ��������� ��������� �������, ������������� �������� � ���������� ����)'
			select @for_ba = '������ �������� ��-�� ������������ ����������', @for_client = '������ ���������, ��� ��� � ��� ����������� ��������� ���������. ����������� ��������� ��� ���� � �������� ����� ������.'
		if @Reason = '������� ������ � ������� ��������, ������� 5,5/6� 6,  �������� ������� 3 '
		and @errdesc = '��������������� �������� ������� �� ����� �������'
			select @for_ba = '�� ����� ������� ������������ �������� �������, ������ ����� �������� ����� ���������� �����.', @for_client = '��� ���������� ������� �� ������� ����� �� �����. ����� ������� ������, ��������� ��������� ����'
		if @Reason = '������� 5,5/6 � 6'
		and @errdesc = '���� �������'
			select @for_ba = '������ �� �������� ���������� ���. ������ ��� �������� �� ����� 15 �����.', @for_client = '��� ������ ��������� �� �������������� ��������. ������ ��� �� ���������� � ������� 30 �����.'
	end
if @dop_status = '�������� ������� �� 47416 (������������ ����)'
	if @doc_status = '��������' and @dap_analis = '47416' --����� ��������� ���
	begin
		if @Reason = '������ ������ �� ���� ���������� � ��������.'
		and @errdesc = 'C��� ������� .................  � ��������� "������� � ��������"'
			select @for_ba = '���� ��� �� ������. ������ ����� ��������� 5 ������� ����, ���� �� ��� ����� ���� �� ������� - �������� �������.', @for_client = '������ ������ ��������� �� ����� �����, ��� ��� ��� ��������� ���� ��� �� ������. � ����� ��� ����� ��������� �� 5 ������� ����, �� ��� ����� ����� ������ ������� ����.'
		if @Reason = '�� ��������� ��������� ����������'
		and @errdesc = '��� ���������� "........" �� ��������� � ���, ��������� � ���������'
			select @for_ba = '�� �������� ������� �� ��������� ��� ����������. �� ��������� ������� ���� ������ ����� ��������� �������. (����)', @for_client = '� ������� ���� �������� ������ � ����� ���. (����) �� ������ ������ ������� �����������.'
		if @Reason = '�� ��������� ��������� ����������'
		and @errdesc = '������������ ��������� ����� �� ��������� � ������������� ����������'
			select @for_ba = '�� �������� ������� �� ��������� ������������ ���������� �������. �� ��������� ������� ���� ������ ����� ��������� �������. (����)', @for_client = '� ������� ���� �������� ������ � ������������ ����� ��������. (����) �� ������ ������ ������� �����������.'
		if @Reason = '�� ��������� ��������� ����������'
		and @errdesc = '������� ��� ����������,������ ��� ����������'
			select @for_ba = '�� �������� ������� �� ������ ��� ����������. �� ��������� ������� ���� ������ ����� ��������� �������.  (����)', @for_client = '� ������� �� ������ ��� ����� ��������. (����) �� ������ ������ ������� �����������.'
		if @Reason = '��������� ���� �� ���������� ��������� ������� �� ���� �������'
		and @errdesc = '�� ����� ......... ���� ����������� �� ������������. ���������: ���� ������ ������������. ���� �� ���������. �������� �����������'
			select @for_ba = '������ �� �������������� ��������. ������ ����� ������� ������� � ���������� ��� �������� � ������� 5 ������� ����. ��������� ������ � ���� ������.', @for_client = '������ ��������� �� �������������� �������� �����. �� ���������� �� ������� ��� ������ � ������� ���.'
		if @Reason = '�������� ������ �� �������� ���� ����������'
		and @errdesc = '���� ������� .......... ������, ����� ����������� ���� ������������ ����'
			select @for_ba = '���� ���������� ������. �� ��������� ������� ���� ������ ����� ��������� �������. (����)', @for_client = '��� ��� ��� ���� ������, �� ������ ������ (����) ������� �����������.'
	end
if @dop_status = '�������� ������, ������������ ������������� �� ���� ������������ ����, �������� �� ���� �������, �������� ��������� ��� �������������'
	if @doc_status = '��������'
		if @Reason = '�������� ������, ������� ����� �� ���� ������������ ����, ����� ���� �������� �� ���� ������� �� ������������ ��������� ��� �������� ����������� ������������� ������.'
		and @dap_analis = '47416' --�������� ���������� � ����������� ����
			select @for_ba = '������, ������� ����� �������� �� ���� ������������ ����, �������� �� ���� ������� ���� (���� �������� ���� ���������� �� ���� �������) ��������.... (��������� ���������� ������� ����� ������� � ���������� ���� ���������). ', @for_client = '�� ��������� ���� ������ �� ��� ���� �� ���������...'
if @dop_status = '�������� ������, ������������ ������������� �� ���� ������������ ����, ��������� � ���� �����������'
	if @doc_status = '��������'
		if @Reason = '� ������ �� ��������� ��������� �� ����� �����������, � ������������ ������ �������, ������ �� ����� ������������ ���� �������� ��������. '
		and @dap_analis = '47416' --�������� �������� � ����
			select @for_ba = '������, ����������� �� ���� ������������ ����, ��������� � ���� �����������. ', @for_client = '�� �� ������ ��������� ���� ������ � ������� ������� ����������� ��-�� ������������ ����������. �������� ����������� ������ ��������� ������ ���������� ����� � ��������� ��������� ������.'
if @doc_status = '��������� ������ �� ������'
	if @Reason = '������� - ���� �� ��������� ������� ��������� �������, ���� ������ �� �������� � ���'
		select @for_ba = '��������� ������ �� ������. ���������:1. �������� �� ������ ������ ����� ��. 2. ������������ ��������� ������ �������. 3. ��������� ������. � ������ ������������ �������� ���������� �� ������� � �� ���������� ��� ����� ���� - �������� ������ �� CS, ������ �� �������� � ���.', @for_client = '������� ���������� �� ������ �������. ������� �� ���������� � ������� 2-� �����.'
if @doc_status = '�������� ������ �� ������'
	if @Reason = '������� - ���� �� ��������� ������� ��������� �������, ���� ������ �� ����� �� �����.'
		select @for_ba = '��������� ������ �� ������. ���������:1. �������� �� ������ ������ ����� ��. 2. ������������ ��������� ������ �������. 3. ��������� ������. � ������ ������������ �������� ���������� �� ������� � �� ���������� ��� ����� ���� - �������� ������ �� CS, ������ �� �������� � ���.', @for_client = '������� ���������� �� ������ �������. ������� �� ���������� � ������� 2-� �����.'


go















if 1 !< 1
select 3

1. ���� ��������� �������� ������� ����������: 
 - ���������� ������ �� �������� ���������� ���. ������ ��� �������� �� ����� 15 �����. 

2. ���� �� ����� ������������ ��������� �������� �������:
- �� ����� ������� ������������ �������� �������, ������ ����� �������� ����� ���������� �����.



select
case 
when @tempjs = 1
then select @tempjs = 2





			declare @tempjs varchar(max), @temprp2 varchar(max), @client_id varchar(50), @temprp varchar(max)

set @tempjs = (select '0A608BA1-4005-4C76-AAF4-260279FD6BC6' [client_id] for json path, without_array_wrapper)

set @temprp = null
exec [operblock].[dbo].[ms_api] 'account.refreshsaldo', @tempjs, @temprp out
select @temprp

set @temprp = null
exec [operblock].[operblock].[ms_api] 'account.propertyGet',@tempjs,@temprp out
select @temprp

set @temprp = null
exec [operblock].[dbo].[ms_api] 'account.getcardindex',@tempjs,@temprp out
select @temprp

select * from [operblock].[dbo].[accounts] where clid = '0A608BA1-4005-4C76-AAF4-260279FD6BC6' and act = 1
select * from [operblock].[dbo].[rko_lims] where client_id = '0A608BA1-4005-4C76-AAF4-260279FD6BC6'
select * from [operblock].[dbo].[client_card_index] where client_id = '0A608BA1-4005-4C76-AAF4-260279FD6BC6'

select
      @tsk__array = 
        json_query(case
                  when [type] = 4 then [value]
                  else '['+[value]+']'
                end)
    from
      openjson(@temprp,'$.response.response.DOC_INFO.DOCS')
    where
      [key] = 'DOC' and 
      [type] in (4,5)



		{"state":"ba_ed_response"}
		{"state":"ba_ed_data_request"}
		{"state":"ba_bpo_response"}
		{"state":"ba_bpo_data_request"}
		{"state":"ba_fnc_response"}
		{"state":"ba_fnc_data_request"}
		{"state":"ba_pi_response"}
		{"state":"ba_pi_data_request"}





		declare @dd varchar(50) = 3, @fd varchar(50) = 2, @dd1 float = 1

		if @dd > 2 and  @dd1 < 0
		select @dd , @fd , @dd1  
		set @dd   = null
		select @dd   
go

--=============================================================================================================================================================
--=============================================================================================================================================================


		@tempjs varchar(max), @temprp varchar(max), @task_id varchar(50),
if @action like 'state.ba_%'
begin
declare 
	@tsk_client_inn  varchar(15),
	@tsk_client_ogrn  varchar(15),
	@flid varchar(50), 
	@id varchar(50),
	@doc_num varchar(50), 
	@hice varchar(50), 
	@actias_i integer = 0,
	@name varchar(50),
	@status varchar(50),
	@data_start varchar(50),
	@data_end varchar(50),
		 
	@for_ba varchar(max)
	declare	@tdoc_ids table
				(
				[name] varchar(50),
				[status] varchar(50),
				[data_start] varchar(50),
				[data_end] varchar(50)
				)

	if @action in ('state.ba_bpo_data_request')
	begin
		

		select
			@tsk_client_inn = json_value([form],'$.doc_info.client_inn'),
			@doc_num = json_value([form],'$.doc_info.doc_num'),
			@hice = json_value([form],'$.doc_info.ba_hice_type')  --true
		FROM [TASKS].[dbo].[ ] 
		where [task_id] = @task_id

		select @tsk_client_ogrn = [client_ogrn]
		from [operblock].[dbo].[v_clients] with(nolock)  --��������� ��� ���...
		where [task_id] = @task_id

		set @tempjs =
		(
		select
			json_query((
			select
				@tsk_client_ogrn [ogrn],
				@tsk_client_inn [inn]
			for json path, without_array_wrapper
			)) [rq]
		for json path, without_array_wrapper
		)
		exec [operblock].[operblock].[ms_api] 'client.IdGet', @tempjs, @temprp out
		@id = json_value(@temprp, '$.response.response.CLIENT_GET') 
		set @temprp = null
		exec [operblock].[operblock].[ms_api] 'client.flIdGet', @tempjs, @temprp out
		@flid = json_value(@temprp, '$.response.response.CLIENT_FL_GET')
		set @temprp = null

		if @doc_num = 'bpGet'
		begin
			if @hice != 'true'
			begin
				set @tempjs = 
				(
					select
					@id [id],
					--'' [fl_id],
					'0' [hice]
					for json path, without_array_wrapper
				)
				exec [operblock].[operblock].[ms_api] 'client.bpGet',@tempjs,@temprp out
				select @temprp
			end
			else
			begin 	--����
					set @tempjs = 
					(
						select
						@id [id],
						@flid [fl_id],
						'1' [hice]
						for json path, without_array_wrapper
					)
					exec [operblock].[operblock].[ms_api] 'client.bpGet',@tempjs,@temprp out
					select @temprp
				end

			select @tdoc_ids = null
			insert into @tdoc_ids
			select json_value([value], '$.NAME'),json_value([value], '$.STATUS'),json_value([value], '$.DATE_START'), null from openjson(@temprp, '$.response.response.CLIENT_BP_GET.BP')
	
			if (select top 1 1 from @tdoc_ids ) is null 
			begin 
				set @for_ba = '� ������� ��� ����������� �������' 
			end

			if (select top 1 1 from @tdoc_ids where [status] like '%������%') is null
			begin 
				set @for_ba = '� ������� ��������� �����  "' + select top 1 [name] from @tdoc_ids + '" ���� ����������� ' + select top 1 [data_start] from @tdoc_ids 
			end
			else
			begin
				set @for_ba = '� ������� ��������� ����� "' + (select top 1 [name] from @tdoc_ids where [status]  like '%��������%') + '". � ' + (select top 1 [data_start] from @tdoc_ids where [status]  like '%������%') + ' ������������ ������� �� ����� "' + (select top 1 [name] from @tdoc_ids where [status]  like '%������%') + '"'
			end

			set @temprp = null
			set @tempjs =
			(
				select 
				@task_id [oid],
				@for_ba [ba_answer_for_ba],
				'' [ba_answer_for_client]
				for json path, without_array_wrapper
			)
			exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
			goto ok
		end

		if @doc_num = 'actiasGet'
		begin
			if @hice = 0
			begin
				set @tempjs = 
				(
					select
					@id [id],
					--'' [fl_id],
					'0' [hice]
					for json path, without_array_wrapper
				)
				exec [operblock].[operblock].[ms_api] 'client.actiasGet',@tempjs,@temprp out
				select @temprp
			end
			else
			begin 	--����
				set @tempjs = 
				(
					select
					@id [id],
					@flid [fl_id],
					'1' [hice]
					for json path, without_array_wrapper
				)
				exec [operblock].[operblock].[ms_api] 'client.actiasGet',@tempjs,@temprp out
				select @temprp
			end
	
			select @tdoc_ids = null
			insert into @tdoc_ids
			select json_value([value], '$.NAME'),null,json_value([value], '$.DATE_START'), iif(json_value([value], '$.DATE_END') is null, '�� �������', json_value([value], '$.DATE_END')) from openjson(@temprp, '$.response.response.CLIENT_ACTIAS_GET.ACTIA')
	
			if @tdoc_ids is null
				set @for_ba = '� ������� �� ���������� �������������� �����'
			else
			begin
				set @for_ba = '� ������� ���������� �����:' + CHAR(13)
				while (1=1)
				begin
					select
						@data_end = [data_end],
						@data_start = [data_start],
						@name = [name]
					from
						@tdoc_ids
					order by [name] offset @actias_i rows fetch next 1 rows only
					if @@ROWCOUNT = 0 break
					set @for_ba = '	' + @name + ' ���� ������ ' + @data_start + ', ���� ��������� ' + @data_end + CHAR(10)
					set @actias_i += 1
				end
			end
			set @temprp = null
			set @tempjs =
			(
				select 
				@task_id [oid],
				@for_ba [ba_answer_for_ba],
				'' [ba_answer_for_client]
				for json path, without_array_wrapper
			)
			exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
			--goto ok
		end

		if @state_pr_id is null
		begin
			select top 1
				@state_pr_id = prf.[id]
			from
				[wcf_new].[dbo].[process_flow] prf with(nolock)
			where
				prf.[flow_obj_id] = @state_task_id and prf.[status] <> 'complete'
			order by [dadd] desc
		end

		if @state_pr_id is not null
		begin
			set @state_js =
				(
					select
						@state_pr_id [id]
					for json path, without_array_wrapper
				)

			exec [wcf_new].[dbo].[ms_api] 'process.complete_manual',@state_js,@state_rp out
		end

		goto ok
	end

	if @action in ('state.ba_bpo_response')
	begin
		goto ok
	end
end

go
----------------------------------------------------------------------------------------------------------
--==========================================================================================================
	declare
		@tdoc_ids table
			(
			[name] varchar(50),
			[status] varchar(50),
			 [data_start] varchar(50),
			 [data_end] varchar(50)
			--	[id] nvarchar(50)
			)
	declare @rfrfr1 nvarchar(max) ='', @rfrfr nvarchar(max) = '{"status":"ok","response":{"response":{"CLIENT_ACTIAS_GET":{"ACTIA":[{"ID":"19110073433","ACTIA_ID":"19142563819","NAME":"�������_���_����������","DATE_START":"01/03/2019 12:03:00","DATE_END":"19/06/2019 12:06:00","PAY_START":"01/06/2019","PAY_END":"30/06/2019"},{"ID":"19110073433","ACTIA_ID":"19798784200","NAME":"�����_������_��_�������","DATE_START":"26/03/2019 12:03:00","DATE_END":"31/01/2020 11:01:59","PAY_START":"01/01/2020","PAY_END":"31/01/2020"},{"ID":"19110073433","ACTIA_ID":"19164209407","NAME":"�����_�����_1","DATE_START":"02/03/2019 02:03:44","DATE_END":"26/03/2019 02:03:04"},{"ID":"19110073433","ACTIA_ID":"20751176995","NAME":"����������_������","DATE_START":"29/04/2019 12:04:00","DATE_END":"01/01/2199 11:01:59"},{"ID":"19110073433","ACTIA_ID":"21556211517","NAME":"��������_��������","DATE_START":"27/05/2019 12:05:00"},{"ID":"19110073433","ACTIA_ID":"23752251633","NAME":"���������_�����������_12_�","DATE_START":"01/08/2019 12:08:00","PAY_START":"01/08/2021","PAY_END":"31/07/2022"},{"ID":"19110073433","ACTIA_ID":"22537274578","NAME":"BP_ACTIVE","DATE_START":"01/06/2019 12:06:00","DATE_END":"30/06/2022 12:06:00"},{"ID":"19110073433","ACTIA_ID":"30619400151","NAME":"�����_������_��_�������_12_�","DATE_START":"01/02/2020 12:02:00","PAY_START":"01/02/2022","PAY_END":"31/01/2023"},{"ID":"19110073433","ACTIA_ID":"42061101240","NAME":"�������","DATE_START":"02/09/2020 09:09:12","DATE_END":"17/02/2021 11:02:59"},{"ID":"19110073433","ACTIA_ID":"52747219797","NAME":"���_������_��","DATE_START":"11/03/2021 12:03:00","DATE_END":"31/03/2021 12:03:00"},{"ID":"19110073433","ACTIA_ID":"51606527956","NAME":"�������","DATE_START":"18/02/2021 12:02:00","DATE_END":"29/04/2021 11:04:59"},{"ID":"19110073433","ACTIA_ID":"55473288658","NAME":"�������","DATE_START":"30/04/2021 12:04:00"},{"ID":"19110073433","ACTIA_ID":"77271391144","NAME":"������_����","DATE_START":"01/05/2022 12:05:00","DATE_END":"31/12/2199 12:12:00"}]}}}}'
	if @rfrfr not like '%fe1r%'
	insert into @tdoc_ids
	select json_value([value], '$.NAME'),null,json_value([value], '$.DATE_START'),iif(json_value([value], '$.DATE_END') is null, '�� �������', json_value([value], '$.DATE_END')) from openjson(@rfrfr, '$.response.response.CLIENT_ACTIAS_GET.ACTIA')
	--while (1=1)
	select top 1 1 from @tdoc_ids  where [name] = 'gg'   --order by [name] offset 1 rows fetch next 1 rows only
	select *  from @tdoc_ids
	DELETE FROM @tdoc_ids 
	select *  from @tdoc_ids
	set @rfrfr1 += '� ������� ���������� �����:'+(select top 1 [name] from @tdoc_ids)+  CHAR(10)
	set @rfrfr1 += '� ������� ���������� �����:'+(select top 1 [name] from @tdoc_ids)+	CHAR(13)
	
	set @rfrfr1	= null
	select @rfrfr1
	if	@rfrfr1	is null 
	select @rfrfr1



					select
						@obj_js = json_query([value])
					from
						openjson(@js, '$.objects')
					where
						[type] = 5
					order by [key] offset @obj_i rows fetch next 1 rows only

					if @@ROWCOUNT = 0 break;

					exec [credit].[dbo].[ms_api] 'object.bound',@obj_js,@obj_rp out

					set @obj_i += 1



go --shablon


--==============================================================================================================
--==============================================================================================================


				if json_value(@js, '$.template.ba_doc_info') is not null or json_query(@js, '$.template.ba_doc_info') is not null 
				begin
					
					exec [operblock].[dbo].[get_task_object] @template_task_id,@template_task_id,'ba_doc_info',@obj_ba_answer out
				
					if @template_task_type = 'ba_business_packages_and_options'
						select @template_tranche =
							(
								select
									'main-tabs' [type],
									'����� ��' [label],
									2 [order],
									json_query((
										select
										
											json_query(@obj_ba_answer,'$.ba_answer_for_ba') [ba_answer_for_ba],
											json_query(@obj_ba_answer,'$.ba_answer_for_client') [ba_answer_for_client],
										
										for json path, without_array_wrapper, include_null_values
									)) [fields],
									json_query('{}') [sections]
								for json path, without_array_wrapper, include_null_values
							)
				end


declare @temprp varchar (max) = '{"status":"ok","response":{"response":{"CLIENT_BP_GET":{"BP":[{"CLIENT_ID":"74319967506","BP_ID":"74574980346","NAME":"�����_����_��_LARGE","DATE_START":"19/03/2022","STATUS":"��������"},{"CLIENT_ID":"74144061298","BP_ID":"74572548839","NAME":"�����_����_��_LARGE","DATE_START":"19/03/2022","STATUS":"��������"}]}}}}'
	--select	
	if (select iif(json_query(@temprp,'$.response.response.CLIENT_BP_GET.BP') is null, '$.response.response.CLIENT_BP_GET', '$.response.response.CLIENT_BP_GET.BP')) = '$.response.response.CLIENT_BP_GET.BP'
		  select json_value([value], '$.NAME'),json_value([value], '$.STATUS'),json_value([value], '$.DATE_START'), null from openjson(@temprp, '$.response.response.CLIENT_BP_GET.BP')
	else  select json_value([value], '$.NAME'),json_value([value], '$.STATUS'),json_value([value], '$.DATE_START'), null from (select json_query(@temprp,'$.response.response.CLIENT_BP_GET') [value]) jj
		


