



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
--							'D8B84E56-BB14-4CFA-8100-AE132040E791' [userid], --оперблок
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

--					--это последний шаг в карте - переводим в комплит				
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

if json_value(@temprp, '$.TYPE') = 'Плат. поруч.' and json_value(@temprp, '$.STATE') = 'Необработан' 
begin
	if json_value(@temprp, '$.TEXT_VOZV') like '%Ошибка%Документ%подозрителен%'
	begin
		set @temprp = null
		set @tempjs =
			(
			select 
				@task_id [oid],
				'Платеж на дополнительной проверке, повторите запрос в ТАСК через 1 час.' [ba_answer_for_ba],
				'Сейчас платеж находится на проверке банка. По результату мы сообщим вам в течение 2-х часов.' [ba_answer_for_client]
			for json path, without_array_wrapper
			)
		exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
		goto ok
	end

	if json_value(@temprp, '$.TEXT_VOZV') like '%запрет%договор%' or json_value(@temprp, '$.TEXT_VOZV') like '%Запре%все%операци%'
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

		if (select top 1 1 from [operblock].[dbo].[rko_lims] with(nolock) where client_id = @client_id and act = 1 and ([lim_source] like '%CRM%' or [lim_source] like '%AML%' or [lim_source] like '%СБ%' or [lim_source] like '%Служба%безопасности%')) is not null
		begin
			set @temprp = null
			set @tempjs =
			(
				select 
				@task_id [oid],
				'Платеж на дополнительной проверке, повторите запрос в ТАСК через 1 час.' [ba_answer_for_ba],
				'Сейчас платеж находится на проверке банка. По результату мы сообщим вам в течение 2-х часов.' [ba_answer_for_client]
				for json path, without_array_wrapper
			)
			exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
			goto ok
		end
	end

	if json_value(@temprp, '$.TEXT_VOZV') like '%запрет%договор%' -- Платеж Банкрота
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

		if (select top 1 1 from [operblock].[dbo].[rko_lims] with(nolock) where client_id = @client_id and act = 1 and ([lim_source] like '%BANKRUPT%' or  [lim_source] like '%Банкрот%')) is not null
		begin
			set @temprp = null
			set @tempjs =
			(
				select 
				@task_id [oid],
				'Клиент находится в процедуре банкротства, все платежи проходят через ручной контроль сотрудников РКО.' [ba_answer_for_ba],
				'Так как вы находитесь в процедуре банкротства, каждый платеж по счету проходит дополнительную проверку. В течение часа сообщим вам по результату.' [ba_answer_for_client]
				for json path, without_array_wrapper
			)
			exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
			goto ok
		end
	end

	if json_value(@temprp, '$.TEXT_VOZV') like '%введенны%документ%дебет%' --проведение зарплаты с очередностью 5  в ограничение ФНС
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
					'- Зарплатный платеж на проверке сотрудника РКО. Обычно это занимает не более 15 минут.' [ba_answer_for_ba],
					'На вашем счете есть ограничение от ФНС, поэтому проведение платежа по заработной плате займет немного больше времени. Обычно на это нужно не более 30 минут.' [ba_answer_for_client]
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
					'- На счете клиента недостаточно денежных средств, платеж будет исполнен после пополнения счета.' [ba_answer_for_ba],
					'Для проведения платежа не хватает денег на счете. Чтобы перевод по заработной плате прошел, пополните расчетный счет.' [ba_answer_for_client]
					for json path, without_array_wrapper
				)
				exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
				goto ok
			end
		end
		
	end
	
	if json_value(@temprp, '$.TEXT_VOZV') like '%введенны%документ%дебет%' --проведение алиментов в ограничение
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
					'-  Платеж по алиментам на проверке сотрудника РКО, повторите запрос в ТАСК через 1 час. При возникновении доп.вопросов на этапе проверки, сотрудник РКО поставить задачу на БА. ' [ba_answer_for_ba],
					'- На вашем счете есть ограничение от ФНС, поэтому проведение платежа по уплате алиментов займет немного больше времени. Мы напишем по результату в течение часа.' [ba_answer_for_client]
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
					'- На счете клиента недостаточно денежных средств, платеж будет исполнен после пополнения счета.' [ba_answer_for_ba],
					'- Для проведения платежа не хватает денег на счете. Чтобы перевод по алиментам прошел, пополните расчетный счет.' [ba_answer_for_client]
					for json path, without_array_wrapper
				)
				exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
				goto ok
			end
		end
	end
	
	if json_value(@temprp, '$.TEXT_VOZV') like '%введенны%документ%дебет%' --налоги при ограничении/картотеке
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
		select top 1 @arest_sum = [debt_amount] from [operblock].[dbo].[rko_lims] with(nolock) where client_id = @client_id and act = 1 and [lim_source] like '%арест%'

		if (select top 1 1 from [operblock].[dbo].[rko_lims] with(nolock) where client_id = @client_id and act = 1 and ([lim_source] like '%ФНС%' or  [lim_source] like '%арест%')) is not null
		begin
			if ((select top 1 1 from [operblock].[dbo].[rko_lims] with(nolock) where client_id = @client_id and act = 1 and [lim_source] like '%ФНС%') is not null and @client_sum !<  @car_sum)
			begin
				set @temprp = null
				set @tempjs =
				(
					select 
					@task_id [oid],
					'Клиент пытается отправить платеж по налогам при ограничении от ФНС и картотеки очередностью 3 или 4. Проведение платежа при в такой ситуации запрещено.' [ba_answer_for_ba],
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
					'Клиент пытается отправить платеж по налогам при ограничении от ФНС. Перевод находится на дополнительной проверке РКО, повторите запрос в ТАСК через 30 минут.' [ba_answer_for_ba],
					'' [ba_answer_for_client]
					for json path, without_array_wrapper
				)
				exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
				goto ok
			end
			if ((select top 1 1 from [operblock].[dbo].[rko_lims] with(nolock) where client_id = @client_id and act = 1 and [lim_source] like '%арест%') is not null and @client_sum !< @arest_sum)
			begin
				set @temprp = null
				set @tempjs =
				(
					select 
					@task_id [oid],
					'Клиент пытается отправить платеж по налогам при аресте счета. Свободных средств для исполнения перевода недостаточно.' [ba_answer_for_ba],
					'' [ba_answer_for_client]
					for json path, without_array_wrapper
				)
				exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
				goto ok
			end
		end
		
	end

	if json_value(@temprp, '$.TEXT_VOZV') like ''   --платеж за 30 лямов
	begin
		if  @doc_sum > 30000000
		set @temprp = null
		set @tempjs =
			(
			select 
				@task_id [oid],
				'Платеж на крупную сумму, для проведения требуется доп. проверка денежных средст на корсчете банка. Повторите запрос в ТАСК через 30 минут.' [ba_answer_for_ba],
				'' [ba_answer_for_client]
			for json path, without_array_wrapper
			)
		exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
		goto ok
	end
	
	if json_value(@temprp, '$.TEXT_VOZV') like '%введенны%документ%дебет%' --отсутствие денежных средств  на счете
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
					'На счете клиента недостаточно средств для проведения платежа.' [ba_answer_for_ba],
					' ' [ba_answer_for_client]
					for json path, without_array_wrapper
				)
				exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
				goto ok
			end
		end
		
	end

	if json_value(@temprp, '$.TEXT_VOZV') like '%помечен%открыти%' --внутрибанковские пп на счета клиентов помеченные к открытию
	begin
		set @temprp = null
		set @tempjs =
		(
			select 
			@task_id [oid],
			'Счет получаля помечен к открытию. Платеж будет  проведен, после того, как откроют счет получателя. Если счет не будет открыт до 20,00 МСК следующего рабочего дня, то платеж вернем плательщику.' [ba_answer_for_ba],
			' ' [ba_answer_for_client]
			for json path, without_array_wrapper
		)
		exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
		goto ok
	end

	if json_value(@temprp, '$.TEXT_VOZV') like '%ЛА%картсчет%' --ЛА на картсчете
	begin
		set @temprp = null
		set @tempjs =
		(
			select 
			@task_id [oid],
			'По платежу клиента обнаружена ошибка (несоответствие) в процесинге. РКО уже поставили задачу на отдел пластиковых карт для разбора ситуации. Повторите запрос в ТАСК через 1 час. ' [ba_answer_for_ba],
			'По этому платежу наблюдаем техническую заминку, уточним информацию и напишем вам в течение 2-х часов. ' [ba_answer_for_client]
			for json path, without_array_wrapper
		)
		exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
		goto ok
	end

	if json_value(@temprp, '$.TEXT_VOZV') like '%не закрыт%контракт%' --'не закрытый счетовой контракт
	begin
		set @temprp = null
		set @tempjs =
		(
			select 
			@task_id [oid],
			'По платежу клиента обнаружена ошибка (несоответствие) в процесинге. РКО уже поставили задачу на отдел пластиковых карт для разбора ситуации. Повторите запрос в ТАСК через 1 час. ' [ba_answer_for_ba],
			'По этому платежу наблюдаем техническую заминку, уточним информацию и напишем вам в течение 2-х часов.' [ba_answer_for_client]
			for json path, without_array_wrapper
		)
		exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
		goto ok
	end

	if json_value(@temprp, '$.TEXT_VOZV') like '%едостат%средств%' --'за счет кредитных средств
	begin
		set @temprp = null
		set @tempjs =
		(
			select 
			@task_id [oid],
			'Платеж клиента на доп.проверке расходов кредитных средств по целевому назначению. РКО уже поставили задачу на отдел кредитов для разбора ситуации. Повторите запрос в ТАСК через 1 час. ' [ba_answer_for_ba],
			'Так как вы отправляете платеж за счет кредитных средств, нам нужно немного времени для его проверки. Сообщим по результату в течение 2-х часов.' [ba_answer_for_client]
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
		'блокировок не найдено' [ba_error]
		for json path, without_array_wrapper
	)
	exec [operblock].[dev].[ms_api] 'params.save',@tempjs,@temprp out
	goto ok
end
------------------------------------------------------------------------------------------------------------------------------------------------------------	
		
			
		
		 
		

-------------------------------------------------------------------новое-------------------------------------------------------------------------------------
----------------------------------------------------------------старое гавно---------------------------------------------------------------------------------

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

select  @dap_analis = [lim_sourse] from [operblock].[dbo].[rko_lims] where [client_id] = @client_id --оч спорно...
select  @Reason = [reason] from [operblock].[dbo].[rko_lims] where [client_id] = @client_id --оч спорно...

select  @errdesc = ???  @dap_analis = ???  @cartotec @sum_arest @account_data @account_status

if @dop_status = 'статусы платежных поручений'
	if @doc_status = 'необработан' 
	begin
	--	if @Reason in('террористы, подозрительные, межведомственная комиссия по замораживанию','блок ФРОД-мониторинга, СБ, ФМ','') 
		and @errdesc in ('Ошибка: Документ подозрителен по "Проверка по списку прочих подозрительных лиц" ==Реквизиты документа РЦ== 57 подозрительно по записи с идентификатором 3569319824 FOREIGN TRADE BANK (FTB)','Запрет кредитования счета договора','Запрет всех операций ')
		and @dap_analis = 'Блокировка AML, Блокировка службы безопасности'
			select @for_ba = 'Платеж на дополнительной проверке, повторите запрос в ТАСК через 1 час.', @for_client = 'Сейчас платеж находится на проверке банка. По результату мы сообщим вам в течение 2-х часов.' 
--		if @Reason = 'Подписанное заявление на закрытие счета' 
		and @errdesc in ('Запрет дебетования счета договора', 'Запрет дебетования счета договора', 'Запрет дебетования и кредитования счета договора') 
		and @dap_analis = '[CRM] Блокировка перед закрытием счетов клиента' 
			select @for_ba = 'Клиент подал заявку на закыртие счета, входящие и исходящие платежи ограничены.', @for_client = 'Так как вы подписали заявление на закрытие счета, любые платежи по счету ограничены.'  
--		if @Reason = 'Платеж Банкрота' 
		and @errdesc = 'Запрет дебетования счета договора'
		and @dap_analis in ('[BANKRUPT]', 'Банкротство клиента', 'Банкрот', 'Банкрот. контроль очередности платежей' )
			select @for_ba = 'Клиент находится в процедуре банкротства, все платежи проходят через ручной контроль сотрудников РКО.', @for_client = 'Так как вы находитесь в процедуре банкротства, каждый платеж по счету проходит дополнительную проверку. В течение часа сообщим вам по результату.'  
--		if @Reason = 'проведение зарплаты с очередностью 5  в ограничение ФНС' 
		and @errdesc like '%С учетом введенных документов счет  выходит в дебет на%' 
			if (@cl_saldo !< @sum_pay) 
				select @for_ba = '- Зарплатный платеж на проверке сотрудника РКО. Обычно это занимает не более 15 минут. ', @for_client = 'На вашем счете есть ограничение от ФНС, поэтому проведение платежа по заработной плате займет немного больше времени. Обычно на это нужно не более 30 минут.'  
			else select @for_ba = '- На счете клиента недостаточно денежных средств, платеж будет исполнен после пополнения счета.', @for_client = ' Для проведения платежа не хватает денег на счете. Чтобы перевод по заработной плате прошел, пополните расчетный счет.' 
--		if @Reason = 'проведение алиментов в ограничение'
		and @errdesc like '%С учетом введенных документов счет  выходит в дебет на%'
			if (@cl_saldo !< @sum_pay) 
				select @for_ba = '-  Платеж по алиментам на проверке сотрудника РКО, повторите запрос в ТАСК через 1 час. При возникновении доп.вопросов на этапе проверки, сотрудник РКО поставить задачу на БА. ', @for_client = '- На вашем счете есть ограничение от ФНС, поэтому проведение платежа по уплате алиментов займет немного больше времени. Мы напишем по результату в течение часа.' 
			else select @for_ba = ' - На счете клиента недостаточно денежных средств, платеж будет исполнен после пополнения счета.', @for_client = '- Для проведения платежа не хватает денег на счете. Чтобы перевод по алиментам прошел, пополните расчетный счет.' 
--		if @Reason = 'налоги при ограничении/картотеке'
		and @errdesc like '%С учетом введенных документов счет  выходит в дебет на%'
			if @dap_analis = 'ФНС (Федеральная налоговая служба)' and @cartotec is null
				select @for_ba = 'Клиент пытается отправить платеж по налогам при ограничении от ФНС и картотеки очередностью 3 или 4. Проведение платежа при в такой ситуации запрещено. '	
			if @dap_analis = 'ФНС (Федеральная налоговая служба)' and @cartotec is not null
				select @for_ba = 'Клиент пытается отправить платеж по налогам при ограничении от ФНС. Перевод находится на дополнительной проверке РКО, повторите запрос в ТАСК через 30 минут.'	
			if @dap_analis = 'MIN SUM (арест)' and @cl_saldo < @sum_arest
			select @for_ba = 'Клиент пытается отправить платеж по налогам при аресте счета. Свободных средств для исполнения перевода недостаточно.'	
--		if @sum_pay > 30000000 
			select @for_ba = 'Платеж на крупную сумму, для проведения требуется доп. проверка денежных средст на корсчете банка. Повторите запрос в ТАСК через 30 минут.'
--		if @cl_saldo !> 0
		and @errdesc like '%С учетом введенных документов счет  выходит в дебет на%' 
			select @for_ba = 'На счете клиента недостаточно средств для проведения платежа.'
--		if @Reason = 'внутрибанковские пп на счета клиентов помеченные к открытию' 
		and @errdesc = 'Счет получателя помечен к открытию'
		and @account_status = 'opening' 
			select @for_ba = 'Счет получаля помечен к открытию. Платеж будет  проведен, после того, как откроют счет получателя. Если счет не будет открыт до 20,00 МСК следующего рабочего дня, то платеж вернем плательщику.'
--		if @Reason = 'ЛА на картсчете' 
		and @errdesc = 'ЛА на картсчете'
			select @for_ba = 'По платежу клиента обнаружена ошибка (несоответствие) в процесинге. РКО уже поставили задачу на отдел пластиковых карт для разбора ситуации. Повторите запрос в ТАСК через 1 час. ', @for_client = 'По этому платежу наблюдаем техническую заминку, уточним информацию и напишем вам в течение 2-х часов.'
--		if @Reason = 'не закрытый счетовой контракт' 
		and @errdesc = 'не закрытый счетовой контракт'
			select @for_ba = 'По платежу клиента обнаружена ошибка (несоответствие) в процесинге. РКО уже поставили задачу на отдел пластиковых карт для разбора ситуации. Повторите запрос в ТАСК через 1 час. ', @for_client = 'По этому платежу наблюдаем техническую заминку, уточним информацию и напишем вам в течение 2-х часов.'
--		if @Reason = 'за счет кредитных средств' 
		and @errdesc = 'Недостаточность собственных средств для проведения платежа'
			select @for_ba = 'Платеж клиента на доп.проверке расходов кредитных средств по целевому назначению. РКО уже поставили задачу на отдел кредитов для разбора ситуации. Повторите запрос в ТАСК через 1 час. ', @for_client = 'Так как вы отправляете платеж за счет кредитных средств, нам нужно немного времени для его проверки. Сообщим по результату в течение 2-х часов.'
		if @Reason = 'Имеется картотека к счету клиента' 
		and @errdesc = '%По счету % есть картотека.%СНАЧАЛА СПИШИТЕ КАРТОТЕКУ !%'
			select @for_ba = 'На счете клиента есть неоплаченная картотека. Чтобы платеж прошел, ее нужно погасить.', @for_client = 'Мы не можем провести платеж, так как на вашем счете есть задолженность. После ее оплаты мы исполним платеж.'
		if @Reason is null
		and @errdesc is null
			select @for_ba = 'Причина не определена, повторите запрос в ТАСК через 15 минут. ', @for_client = 'Уточняю информацию по платежу, напишем вам в течение часа.'
		if @Reason = 'ограничения на счете клиента'
		and @errdesc like '%По счету 40702% разрешены платежи с очередностью не выше 3%'
			select @for_ba = 'Платеж не может быть исполнен. Очередность платежей при действующих ограничениях должна быть не выше 3-ей', @for_client = 'Мы не можем провести данный платеж при действующих ограничениях.'
		if @Reason = 'дивиденды по проекту ДВ Модульбанк'
		and @dap_analis = 'ДВМодульбанк'
			select @for_ba = 'Платеж по выплате дивидендов будет исполнен после того, как по платежу НДФЛ придет успешный статус отправки. Повторите запрос в ТАСК через 1 час.', @for_client = 'Платеж по уплате дивидендов находится на дополнительной проверке, мы исполним его в течение часа.'
	end
	if @doc_status = 'На валютный контроль'
		select @for_ba = 'Платеж на проверке валютного контроля. Специалисты свяжутся с клиентом при наличии вопросов в течение суток.', @for_client = 'Ваш платеж находится на проверке валютного контроля, обычно это занимает не больше суток. Если у специалистов возникнут вопросы по документам, они свяжутся с вами в чате.'
	if @doc_status = 'Проведен'
		select @for_ba = 'Платеж проведен ' + @account_data + '.'
	if @doc_status = 'Возвратить клиенту'
	begin
		if  @errdesc = 'Отменен клиентом'
			select @for_ba = 'Платеж отменен клиентом через личный кабинет'	
		if  @errdesc in ('ВАШ ПЛАТЕЖ ОТКЛОНЕН И АННУЛИРОВАН ПО ПРИЧИНЕ:НЕВЕРНОЕ НАИМЕНОВАНИЕ ПОЛУЧАТЕЛЯ', 'ПЛАТЕЖ АННУЛИРОВАН ПО ПРИЧИНЕ: НАИМЕНОВАНИЕ ПОЛУЧАТЕЛЯ НЕ СООТВЕТСТВУЕТ Р/СЧЕТУ.', 'ПЛАТЕЖ АННУЛИРОВАН ПО ПРИЧИНЕ: НЕВЕРНОЕ НАИМЕНОВАНИЕ ПОЛУЧАТЕЛЯ', 'ПЛАТЕЖ АННУЛИРОВАН ПО ПРИЧИНЕ: НЕВЕРНЫЕ РЕКВИЗИТЫ ПОЛУЧАТЕЛЯ', 'ПП АННУЛИРОВАНО ПО ПРИЧИНЕ: НАИМЕНОВАНИЕ ПОЛУЧАТЕЛЯ НЕ СООТВЕТСТВУЕТ УКАЗАННОМУ В ДОКУМЕНТЕ.', 'ПП АННУЛИРОВАНО ПО ПРИЧИНЕ: ОРГАНИЗАЦИОННО-ПРАВОВАЯ ФОРМА ПОЛУЧАТЕЛЯ НЕ СОВПАДАЕТ С УКАЗАННОЙ В ДОКУМЕНТЕ.')
			select @for_ba = 'Платеж аннулирован по причине: неверное наименование получателя.',	 @for_client = 'Платеж был отклонен из-за неверного реквизита. Вы допустили ошибку в наименовании получателя. Проверьте реквизит и создайте новый платеж.'	
		if  @errdesc in ('ВАШ ПЛАТЕЖ ОТКЛОНЕН И АННУЛИРОВАН ПО ПРИЧИНЕ:НЕВЕРНЫЕ РЕКВИЗИТЫ ПОЛУЧАТЕЛЯ (НАИМЕНОВАНИЕ И ИНН)', 'ПЛАТЕЖ АННУЛИРОВАН ПО ПРИЧИНЕ: НАИМЕНОВАНИЕ И ИНН ПОЛУЧАТЕЛЯ НЕ СООТВЕТСТВУЮТ Р/СЧЕТУ.', 'ПЛАТЕЖ ОТКЛОНЕН И АННУЛИРОВАН ПО ПРИЧИНЕ:НЕВЕРНОЕ НАИМЕНОВАНИЕ ПОЛУЧАТЕЛЯ')
			select @for_ba = 'Платеж аннулирован по причине: неверное наименование получателя и ИНН', @for_client = 'Платеж был отклонен из-за неверных реквизитов. Вы допустили ошибку в наименовании получателя и ИНН. Проверьте реквизиты и создайте новый платеж.'
		if  @errdesc in ('ПЛАТЕЖ АННУЛИРОВАН ПО ПРИЧИНЕ: НЕВЕРНЫЙ ИНН ПОЛУЧАТЕЛЯ', 'ПЛАТЕЖ ОТКЛОНЕН И АННУЛИРОВАН ПО ПРИЧИНЕ: НЕВЕРНЫЙ ИНН ПОЛУЧАТЕЛЯ.', 'ПП АННУЛИРОВАНО ПО ПРИЧИНЕ: ИНН ПОЛУЧАТЕЛЯ НЕ СОВПАДАЕТ С ИНН УКАЗАННЫМ В ДОКУМЕНТЕ.')
			select @for_ba = 'Платеж аннулирован  по причине: неверный ИНН', @for_client = 'Платеж был отклонен из-за неверного реквизита. Вы допустили ошибку в ИНН получателя. Проверьте реквизит и создайте новый платеж.'
		if  @errdesc in ('ПЛАТЕЖ АННУЛИРОВАН ПО ПРИЧИНЕ: СЧЕТ ПОЛУЧАТЕЛЯ ЗАКРЫТ', 'ПЛАТЕЖ ОТКЛОНЕН И АННУЛИРОВАН ПО ПРИЧИНЕ : СЧЕТ ПОЛУЧАТЕЛЯ ЗАКРЫТ.')
			select @for_ba = 'Платеж аннулирован  по причине: счет получателя закрыт.', @for_client = 'Перевод был отклонен по причине закрытия счета получателя платежа. Уточните актуальные реквизиты у контрагента и создайте новый платеж.'
		if  @errdesc in ('ПЛАТЕЖ ОТКЛОНЕН И АННУЛИРОВАН ПО ПРИЧИНЕ:НЕВЕРНЫЙ СЧЕТ ПОЛУЧАТЕЛЯ', 'ПП АННУЛИРОВАНО ПО ПРИЧИНЕ НЕВЕРНО УКАЗАННЫХ РЕКВИЗИТОВ ПОЛУЧАТЕЛЯ', 'ПП АННУЛИРОВАНО ПО ПРИЧИНЕ: ЗАЧИСЛЕНИЕ ПО УКАЗАННЫМ РЕКВИЗИТАМ НЕВОЗМОЖНО.', 'Неверные реквизиты получателя. Уточните счет и БИК')
			select @for_ba = 'Платеж аннулирован  по причине: неверные реквизиты получателя.', @for_client = 'Платеж был отклонен из-за неверных реквизитов получателя. Уточните актуальные реквизиты у контрагента и создайте новый платеж.'
		if  @errdesc in ('ПП АННУЛИРОВАНО ПО ПРИЧИНЕ: ЗАЧИСЛЕНИЕ НА СКС ВОЗМОЖНО ТОЛЬКО С РАСЧЕТНОГО СЧЕТА ПАО БАНК "ФК ОТКРЫТИЕ".')
			select @for_ba = 'Ваш платёж аннулирован по причине: зачисление на скс возможно только с расчётного счёта банка ПАО БАНК "ФК ОТКРЫТИЕ"', @for_client = 'Ваш платёж аннулирован по причине: зачисление на скс возможно только с расчётного счёта банка ПАО БАНК "ФК ОТКРЫТИЕ"'
		if  @errdesc in ('Недопустимая операция по счету кредитной организации получателя')
			select @for_ba = 'Платеж вернулся клиенту по причине некорректных реквизитов.Уточнить информацию можно в банке-получателе', @for_client = 'Ваш платеж вернул банк-получатель по причине некорректных реквизитов. Рекомендуем обратиться к получателю платежа и уточнить актуальные реквизиты.'
		if  @errdesc in ('Дата создания документа раньше текущего опердня на 10+ дней', 'Истек срок действия платежа', 'Истек срок платежного поручения')
			select @for_ba = 'Срок платежного поручения истек. Платежное поручение действует в течение 10 дней после его составления.', @for_client = 'Срок вашего платежного поручения истек. Платежное поручение действует в течение 10 дней после его составления. Рекомендуем сделать новый платеж. '
		if  @errdesc in ('Недостаточно средств на счете')
			select @for_ba = 'Для проведения платежа не хватило денег на счете клиента. ', @for_client = 'Ваш платеж отменили, так как для его проведения не хватило денег на счете. Создайте новый платеж, учитывая остаток на счете, а также затраты на комиссию банка.'
		if  @errdesc in ('Остатка собственных средств не достаточно для проводки документа.', 'Документ не может быть проведен за счет кредитных средств.', 'Нецелевое использование кредитных средств.')
			select @for_ba = 'Платеж отклонен, так как клиент пытался провести нецелевой платеж за счет кредитных средств. ', @for_client = 'Мы отклонили платеж, так как он не входит в целевое использование кредитных средств.'
	end
if @dop_status = 'Исходящие платежи зависшие на обработке  в Расчетном центре'
	if @doc_status = 'РЦ' 
	begin
		if @Reason = 'очередь автоматической автопроводки 1 и 2'
		and @errdesc = 'очередь 1 и 2'
			select @for_ba = 'Платеж находится в обработке банком, повторите запрос в ТАСК через 15 минут.', @for_client = 'Ваш платеж нахоится в обработке, в течение 15-20 минут он пройдет.'
		if @Reason = 'очередь ошибок и ручного контроля, очередь 5,5/6и 6'
		and @errdesc in ('Недостаточность ЛА на счете клиента', 'не закрытый счетовой контракт')
			select @for_ba = 'По платежу клиента обнаружена ошибка (несоответствие) в процесинге. РКО уже поставили задачу на отдел пластиковых карт для разбора ситуации. Повторите запрос в ТАСК через 1 час. ', @for_client = 'По этому платежу наблюдаем техническую заминку, уточним информацию и напишем вам в течение 2-х часов.'
		if @Reason = 'очередь ошибок и ручного контроля, очередь 5,5/6и 6'
		and @errdesc = 'Недостаточность собственных средств для проведения платежа'
			select @for_ba = 'Платеж клиента на доп.проверке расходов по целевому назначению. РКО уже поставили задачу на отдел кредитов  для разбора ситуации. Повторите запрос в ТАСК через 1 час.', @for_client = 'Так как вы отправляете платеж за счет кредитных средств, нам нужно немного времени для его проверки. Сообщим по результату в течение 2-х часов.'
		if @Reason = 'очередь ошибок и ручного контроля, очередь 5,5/6и 6'
		and @errdesc = 'спишите картотеку'
			select @for_ba = 'На счете клиента есть неоплаченная картотека. Чтобы платеж прошел, ее нужно погасить.', @for_client = 'Мы не можем провести платеж, так как на вашем счете есть задолженность. После ее оплаты мы исполним платеж.'
		if @Reason = 'очередь ошибок и ручного контроля, очередь 5,5/6и 6'
		and @errdesc = 'Счет получ. - Неверный Контрольный ключ счета,Некорректное значение поля 108 (Номер документа основания платежа, Идентификатор сведений о физическом лице)'
			select @for_ba = 'Платеж отклонен из-за некорректных реквизитов', @for_client = 'Платеж отклонили, так как в нем некорректно заполнены реквизиты. Внимательно проверьте все поля и создайте новый платеж.'
		if @Reason = 'очередь ошибок и ручного контроля, очередь 5,5/6и 6,  ожидания средств 3 '
		and @errdesc = 'Недостаточность денежных средств на счете клиента'
			select @for_ba = 'На счете клиента недостаточно денежных средств, платеж будет исполнен после пополнения счета.', @for_client = 'Для проведения платежа не хватает денег на счете. Чтобы перевод прошел, пополните расчетный счет'
		if @Reason = 'очередь 5,5/6 и 6'
		and @errdesc = 'Иные причины'
			select @for_ba = 'Платеж на проверке сотрудника РКО. Обычно это занимает не более 15 минут.', @for_client = 'Ваш платеж находится на дополнительной проверке. Напишу вам по результату в течение 30 минут.'
	end
if @dop_status = 'Входящие платежи на 47416 (невыясненных сумм)'
	if @doc_status = 'Проведен' and @dap_analis = '47416' --найти кредитный док
	begin
		if @Reason = 'Платеж пришел на счет помеченный к открытию.'
		and @errdesc = 'Cчет кредита .................  в состоянии "Помечен к открытию"'
			select @for_ba = 'Счет еще не открыт. Деньги будут храниться 5 рабочих дней, если за это время счет не откроют - вернутся обратно.', @for_client = 'Платеж сейчас находится на счете банка, так как ваш расчетный счет еще не открыт. В банке они могут храниться до 5 рабочих дней, за это время нужно успеть открыть счет.'
		if @Reason = 'не совпадают реквизиты получателя'
		and @errdesc = 'ИНН получателя "........" не совпадает с ИНН, указанным в документе'
			select @for_ba = 'Во входящем платеже не совпадает ИНН получателя. На следующий рабочий день платеж будет отправлен обратно. (дата)', @for_client = 'В платеже была допущена ошибка в вашем ИНН. (дата) мы вернем деньги обратно отправителю.'
		if @Reason = 'не совпадают реквизиты получателя'
		and @errdesc = 'Наименование владельца счета не совпадает с наименованием получателя'
			select @for_ba = 'Во входящем платеже не совпадает наименование получателя средств. На следующий рабочий день платеж будет отправлен обратно. (дата)', @for_client = 'В платеже была допущена ошибка в наименовании вашей компании. (дата) мы вернем деньги обратно отправителю.'
		if @Reason = 'не совпадают реквизиты получателя'
		and @errdesc = 'Нулевой ИНН получателя,Пустой ИНН получателя'
			select @for_ba = 'Во входящем платеже не указан ИНН получателя. На следующий рабочий день платеж будет отправлен обратно.  (дата)', @for_client = 'В платеже не указан ИНН вашей компании. (дата) мы вернем деньги обратно отправителю.'
		if @Reason = 'Внутрений блок на зачисление вхоядщего платежа на счет клиента'
		and @errdesc = 'По счету ......... есть ограничение на кредитование. Основание: ФРОД Запрет кредитования. Счёт не закрывать. Контроль поступлений'
			select @for_ba = 'Платеж на дополнительной проверке. Банком будет принято решение о зачислении или возврате в течение 5 рабочих дней. Повторите запрос в ТАСК завтра.', @for_client = 'Платеж находится на дополнительной проверке банка. По результату мы сообщим вам завтра в течение дня.'
		if @Reason = 'Входящий платеж на закрытый счет получателя'
		and @errdesc = 'Счет кредита .......... закрыт, будет использован счет невыясненных сумм'
			select @for_ba = 'Счет получателя закрыт. На следующий рабочий день платеж будет отправлен обратно. (дата)', @for_client = 'Так как ваш счет закрыт, мы вернем деньги (дата) обратно отправителю.'
	end
if @dop_status = 'Входящий платеж, поставленный первоначально на счет невыясненных сумм, зачислен на счет клиента, согласно уточнения или идентификации'
	if @doc_status = 'Проведен'
		if @Reason = 'Входящий платеж, который встал на счет невыясненных сумм, может быть зачислен на счет клиента по поступившему уточнению или согласно проведенной идентификации Банком.'
		and @dap_analis = '47416' --проверка начислений с невыясненых сумм
			select @for_ba = 'Платеж, который ранее поступил на счет невыясненных сумм, зачислен на счет клиента ДАТА (дата проводки дока зачисления на счет клиента) согласно.... (основание зачисления платежа будет указана в назначении дока зачиления). ', @for_client = 'Мы зачислили этот платеж на ваш счет на основании...'
if @dop_status = 'Входящий платеж, поставленный первоначально на счет невыясненных сумм, возвращен в Банк плательщика'
	if @doc_status = 'Проведен'
		if @Reason = 'В случае не получения уточнения от Банка плательщика, в определенный период времени, платеж со счета невыясненных сумм подлежит возврату. '
		and @dap_analis = '47416' --проверка возврата в банк
			select @for_ba = 'Платеж, поступивший на счет невыясненных сумм, возвращен в Банк плательщика. ', @for_client = 'Мы не смогли зачислить этот платеж и вернули обратно отправителю из-за некорректных реквизитов. Сообщите контрагенту верные реквизиты вашего расчетного счета и попросите повторить платеж.'
if @doc_status = 'Исходящий платеж не найден'
	if @Reason = 'Причина - либо не правильно указаны параметры платежа, либо платеж не выгружен в АБС'
		select @for_ba = 'Указанный платеж не найден. Проверьте:1. Подписал ли клиент платеж через ЛК. 2. Корректность указанных данных платежа. 3. Повторите запрос. В случае правильности указания информации по платежу и не нахождения его через ТАСК - поставте задачу на CS, платеж не выгружен в АВС.', @for_client = 'Уточняю информацию по вашему платежу. Напишем по результату в течение 2-х часов.'
if @doc_status = 'Входящий платеж не найден'
	if @Reason = 'Причина - либо не правильно указаны параметры платежа, либо платеж не дошел до Банка.'
		select @for_ba = 'Указанный платеж не найден. Проверьте:1. Подписал ли клиент платеж через ЛК. 2. Корректность указанных данных платежа. 3. Повторите запрос. В случае правильности указания информации по платежу и не нахождения его через ТАСК - поставте задачу на CS, платеж не выгружен в АВС.', @for_client = 'Уточняю информацию по вашему платежу. Напишем по результату в течение 2-х часов.'


go















if 1 !< 1
select 3

1. Если свободных денежных средств достаточно: 
 - Зарплатный платеж на проверке сотрудника РКО. Обычно это занимает не более 15 минут. 

2. Если на счете недостаточно свободных денежных средств:
- На счете клиента недостаточно денежных средств, платеж будет исполнен после пополнения счета.



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
		from [operblock].[dbo].[v_clients] with(nolock)  --правильно или нет...
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
			begin 	--хайс
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
				set @for_ba = 'У клиента нет действующих тарифов' 
			end

			if (select top 1 1 from @tdoc_ids where [status] like '%жидает%') is null
			begin 
				set @for_ba = 'У клиента действует тариф  "' + select top 1 [name] from @tdoc_ids + '" дата подключения ' + select top 1 [data_start] from @tdoc_ids 
			end
			else
			begin
				set @for_ba = 'У клиента действует тариф "' + (select top 1 [name] from @tdoc_ids where [status]  like '%Работает%') + '". С ' + (select top 1 [data_start] from @tdoc_ids where [status]  like '%жидает%') + ' запланирован переход на тариф "' + (select top 1 [name] from @tdoc_ids where [status]  like '%жидает%') + '"'
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
			begin 	--хайс
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
			select json_value([value], '$.NAME'),null,json_value([value], '$.DATE_START'), iif(json_value([value], '$.DATE_END') is null, 'не указана', json_value([value], '$.DATE_END')) from openjson(@temprp, '$.response.response.CLIENT_ACTIAS_GET.ACTIA')
	
			if @tdoc_ids is null
				set @for_ba = 'У клиента не подключены дополнительные опции'
			else
			begin
				set @for_ba = 'У клиента подключены опции:' + CHAR(13)
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
					set @for_ba = '	' + @name + ' дата начала ' + @data_start + ', дата окончания ' + @data_end + CHAR(10)
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
	declare @rfrfr1 nvarchar(max) ='', @rfrfr nvarchar(max) = '{"status":"ok","response":{"response":{"CLIENT_ACTIAS_GET":{"ACTIA":[{"ID":"19110073433","ACTIA_ID":"19142563819","NAME":"ПЛАТНЫЕ_СМС_СОТРУДНИКУ","DATE_START":"01/03/2019 12:03:00","DATE_END":"19/06/2019 12:06:00","PAY_START":"01/06/2019","PAY_END":"30/06/2019"},{"ID":"19110073433","ACTIA_ID":"19798784200","NAME":"ОБМЕН_ВАЛЮТЫ_СО_СКИДКОЙ","DATE_START":"26/03/2019 12:03:00","DATE_END":"31/01/2020 11:01:59","PAY_START":"01/01/2020","PAY_END":"31/01/2020"},{"ID":"19110073433","ACTIA_ID":"19164209407","NAME":"ПОДФТ_ЛИМИТ_1","DATE_START":"02/03/2019 02:03:44","DATE_END":"26/03/2019 02:03:04"},{"ID":"19110073433","ACTIA_ID":"20751176995","NAME":"ЗАРПЛАТНЫЙ_ПРОЕКТ","DATE_START":"29/04/2019 12:04:00","DATE_END":"01/01/2199 11:01:59"},{"ID":"19110073433","ACTIA_ID":"21556211517","NAME":"ВАЛЮТНЫЙ_КОНТРОЛЬ","DATE_START":"27/05/2019 12:05:00"},{"ID":"19110073433","ACTIA_ID":"23752251633","NAME":"АБОНЕНТКА_ОПТИМАЛЬНЫЙ_12_М","DATE_START":"01/08/2019 12:08:00","PAY_START":"01/08/2021","PAY_END":"31/07/2022"},{"ID":"19110073433","ACTIA_ID":"22537274578","NAME":"BP_ACTIVE","DATE_START":"01/06/2019 12:06:00","DATE_END":"30/06/2022 12:06:00"},{"ID":"19110073433","ACTIA_ID":"30619400151","NAME":"ОБМЕН_ВАЛЮТЫ_СО_СКИДКОЙ_12_М","DATE_START":"01/02/2020 12:02:00","PAY_START":"01/02/2022","PAY_END":"31/01/2023"},{"ID":"19110073433","ACTIA_ID":"42061101240","NAME":"КОПИЛКА","DATE_START":"02/09/2020 09:09:12","DATE_END":"17/02/2021 11:02:59"},{"ID":"19110073433","ACTIA_ID":"52747219797","NAME":"НЕТ_КОМИСС_ВК","DATE_START":"11/03/2021 12:03:00","DATE_END":"31/03/2021 12:03:00"},{"ID":"19110073433","ACTIA_ID":"51606527956","NAME":"КОПИЛКА","DATE_START":"18/02/2021 12:02:00","DATE_END":"29/04/2021 11:04:59"},{"ID":"19110073433","ACTIA_ID":"55473288658","NAME":"КОПИЛКА","DATE_START":"30/04/2021 12:04:00"},{"ID":"19110073433","ACTIA_ID":"77271391144","NAME":"ПОДАРИ_БАНК","DATE_START":"01/05/2022 12:05:00","DATE_END":"31/12/2199 12:12:00"}]}}}}'
	if @rfrfr not like '%fe1r%'
	insert into @tdoc_ids
	select json_value([value], '$.NAME'),null,json_value([value], '$.DATE_START'),iif(json_value([value], '$.DATE_END') is null, 'не указана', json_value([value], '$.DATE_END')) from openjson(@rfrfr, '$.response.response.CLIENT_ACTIAS_GET.ACTIA')
	--while (1=1)
	select top 1 1 from @tdoc_ids  where [name] = 'gg'   --order by [name] offset 1 rows fetch next 1 rows only
	select *  from @tdoc_ids
	DELETE FROM @tdoc_ids 
	select *  from @tdoc_ids
	set @rfrfr1 += 'У клиента подключены опции:'+(select top 1 [name] from @tdoc_ids)+  CHAR(10)
	set @rfrfr1 += 'У клиента подключены опции:'+(select top 1 [name] from @tdoc_ids)+	CHAR(13)
	
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
									'ОТВЕТ БА' [label],
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


declare @temprp varchar (max) = '{"status":"ok","response":{"response":{"CLIENT_BP_GET":{"BP":[{"CLIENT_ID":"74319967506","BP_ID":"74574980346","NAME":"ПАКЕТ_ХАЙС_ФЛ_LARGE","DATE_START":"19/03/2022","STATUS":"Работает"},{"CLIENT_ID":"74144061298","BP_ID":"74572548839","NAME":"ПАКЕТ_ХАЙС_ИП_LARGE","DATE_START":"19/03/2022","STATUS":"Работает"}]}}}}'
	--select	
	if (select iif(json_query(@temprp,'$.response.response.CLIENT_BP_GET.BP') is null, '$.response.response.CLIENT_BP_GET', '$.response.response.CLIENT_BP_GET.BP')) = '$.response.response.CLIENT_BP_GET.BP'
		  select json_value([value], '$.NAME'),json_value([value], '$.STATUS'),json_value([value], '$.DATE_START'), null from openjson(@temprp, '$.response.response.CLIENT_BP_GET.BP')
	else  select json_value([value], '$.NAME'),json_value([value], '$.STATUS'),json_value([value], '$.DATE_START'), null from (select json_query(@temprp,'$.response.response.CLIENT_BP_GET') [value]) jj
		


