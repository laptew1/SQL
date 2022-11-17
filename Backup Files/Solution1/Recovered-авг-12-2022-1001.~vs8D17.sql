



	if @action like 'state.ba_pi_%'
			begin
				declare 
					@ba_doc_id varchar(50),
					@liq_i int,
					@ba_inn varchar(20),
					@ba_num nvarchar(50)

				if @action in ('state.ba_pi_data_request')
				begin

					goto ok
				end
				{"state":"ba_pi_response"}
				if @action in ('state.ba_pi_response')
				begin
					select top 1 
						@liq_id = cls_org.[id] 
					from 
						[OPERBLOCK].[dbo].[closure_organization] cls_org with(nolock) 
						inner join [OPERBLOCK].[dbo].[object_map] map with(nolock) 
						on cls_org.[id] = map.[bid] 
						and map.[btype] = 'task/obj' 
						and map.[act] = 1
					where
						map.[oid] = @task_id


					--if object_id('tempdb..#inns') is not null
					--drop table #inns

					declare @liqTable_inns table ([inn] varchar(20))

					insert into @liqTable_inns 
						select [value] from 
							string_split((select [value] from [OPERBLOCK].[dbo].[object_key_values] where oid = @liq_id and kid = '83759CE6-7248-4C41-9448-A514E5382575' and act = '1'), char(10))
						where [value] <> ''

					set @liq_i = 0

					while 1 = 1
					begin
					  select distinct
						@liq_inn = [inn]
					  from
						@liqTable_inns
					  order by [inn] offset @liq_i rows fetch next 1 rows only

					  if @@rowcount = 0 break

					  set @tempjs = null
					  set @tempjs =
						(
						  select
							'D8B84E56-BB14-4CFA-8100-AE132040E791' [userid], --оперблок
							'liquid_close' [type],
							json_query((
							  select top 1
								json_query((
								select top 1
								  @liq_inn [client_inn]
								for json path, without_array_wrapper
								)) [client]
							  for json path, without_array_wrapper
							)) [form]
						  for json path, without_array_wrapper
						)

					  set @temprp = null
					  exec [tasks].[dbo].[ms_api] 'task.create',@tempjs,@temprp out

					  set @liq_code = json_value(@temprp,'$.response.task_id')

					  insert into [OPERBLOCK].[dbo].[cls_orgs_logs]
						values(newid(),getdate(),@liq_inn, @liq_code)

					  waitfor delay '00:00:02'

					  set @liq_i += 1
					end


				end

				if @action in ('state.ba_pi_response')
				begin

					--это последний шаг в карте - переводим в комплит				
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

			end


go


			declare @tempjs varchar(max), @temprp2 varchar(max), @client_id varchar(50), @temprp varchar(max)
--set @tempjs =
--(
--  select 
--    '82104615974' [id]
--  for json path, without_array_wrapper
--)           
--exec [operblock].[operblock].[ms_api] 'payment.docInfo',@tempjs,@temprp2 out
--select @temprp2

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


if @dop_status = 'пп' and @doc_status = 'необработан' and @Reason = '' and @errdesc = '' and @dap_analis = '' then @for_ba = '' @for_client = ''



declare @tempjs integer = 1
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
