local os = require"os"


local out_log = ""
function Log(log)
	print(log)
	out_log = out_log .. log .. "\n"
end

os.execute([[.\data.exe]])
Log("data.xls转data.lua")
require "data"

local cur_time = os.time()

local cur_ti = player_data.tili
local rest_time = player_data.sleep
local getup_time = player_data.getup
local buy_tili = player_data.buytili

local max_ti = 160
local cur_ti_ext = 0
local max_ti_ext = 5
local add_ti_interval = 480
local is_rest = false

function LogTime(log)
	log = string.format("%s %s\t剩余体力:%d\t剩余大体力:%d", os.date("%Y/%m/%d %a %H:%M:%S", cur_time), log, cur_ti, cur_ti_ext)
	print(log)
	out_log = out_log .. log .. "\n"
end

local function print_r(t)
	local print_r_cache={}
	local function sub_print_r(t,indent)
		if (print_r_cache[tostring(t)]) then
			print(indent.."*"..tostring(t))
		else
			print_r_cache[tostring(t)]=true
			if (type(t)=="table") then
				for pos,val in pairs(t) do
					if (type(val)=="table") then
						print(indent.."["..pos.."] => "..tostring(t).." {")
						sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
						print(indent..string.rep(" ",string.len(pos)+6).."}")
					elseif (type(val)=="string") then
						print(indent.."["..pos..'] => "'..val..'"')
					else
						print(indent.."["..pos.."] => "..tostring(val))
					end
				end
			else
				print(indent..tostring(t))
			end
		end
	end
	if (type(t)=="table") then
		print(tostring(t).." {")
		sub_print_r(t,"  ")
		print("}")
	else
		sub_print_r(t,"  ")
	end
	print()
end

local mat_table = {}
for name, v in pairs(player_role) do
	local tab = game_role_tabe[name]
	for skill_name, skill in pairs(v) do
		for i = skill.cur_lv, skill.tar_lv - 1 do
			mat = tab[skill_name][i]
			for k,v in pairs(mat) do
				mat_table[k] = mat_table[k] or 0
				mat_table[k] = mat_table[k] + v
			end
		end
	end
end

local tar_log = "提升角色:\n"
local talent_name = {
	[1] = "普攻",
	[2] = "技能",
	[3] = "大招",
}
for name, v in pairs(player_role) do
	tar_log = tar_log .. string.format("%.8s", name)
	for skill_name, skill in ipairs(v) do
		tar_log = tar_log .. "\t" .. talent_name[skill_name] .. ":" .. skill.cur_lv .. "->" .. skill.tar_lv
	end
	tar_log = tar_log .. "\n"
end
Log(tar_log)

tar_log = "需要材料:"
for k, v in pairs(mat_table) do
	local mat_name = game_role_tabe_remark[k]
	tar_log = tar_log .. "\n" .. mat_name .. ":" .. v
end
tar_log = tar_log .. "\n"
Log(tar_log)

for k, v in pairs(mat_table) do
	local min_mat = game_met_table[k]
	if min_mat then
		mat_table[k] = v * min_mat.mat_num
	else
		mat_table[k] = nil
	end
end

for k, v in pairs(mat_table) do
	local min_mat = game_met_table[k]
	if player_bag[k] then
		local base_num = player_bag[k].num * min_mat.mat_num
		if base_num > v then
			mat_table[k] = nil
		else
			mat_table[k] = v - base_num
		end
	end
end

local weekTaskList = {}
for key, num in pairs(mat_table) do
	if game_dun_table[key] then
		game_dun = game_dun_table[key].week
		for _, day in ipairs(game_dun) do
			weekTaskList[day] = weekTaskList[day] or {}
			table.insert(weekTaskList[day], key)
		end
	end
end

--print_r(mat_table)
--print_r(weekTaskList)

function GetNextAddTiTime()
	cur_year = os.date("%Y", cur_time)
	cur_mon = os.date("%m", cur_time)
	cur_day = os.date("%d", cur_time)
	cur_hour = os.date("%H", cur_time)
	cur_min = os.date("%M", cur_time)
	cur_sec = os.date("%S", cur_time)
	next_time = os.time{year=cur_year, month=cur_mon, day=cur_day, hour=4}
	if tonumber(cur_hour) < 4 then
		next_time = next_time - 24 * 60 * 60
	end
	interval = cur_time - next_time

	return cur_time + add_ti_interval - interval % add_ti_interval
end

function GetRestAddTi()
	local interval = getup_time - rest_time
	if getup_time < rest_time then
		interval = interval + 24
	end
	return math.ceil(interval * 15 / 2)
end

local next_add_ti_time = GetNextAddTiTime()
local rest_add_ti = GetRestAddTi()

function Init()
	Log("start")
	local hour = tonumber(os.date("%H", cur_time))
	if rest_time >= 24 then
		rest_time = 0
	end
	if getup_time >= 24 then
		getup_time = 0
	end
	if rest_time < getup_time then
		if rest_time <= hour and hour <= getup_time then
			is_rest = true
		end
	else
		if rest_time <= hour or hour <= getup_time then
			is_rest = true
		end
	end
	LogTime("")
end

--
function Update()
	cur_time = cur_time + 1

	if os.date("%H%M%S", cur_time) == "040000" then
		buy_tili = player_data.buytili
	end

	if os.date("%H%M%S", cur_time) == string.format("%02d0000", rest_time) then
		is_rest = true
		BeforeSleep()
	end

	if os.date("%H%M%S", cur_time) == string.format("%02d0000", getup_time) then
		is_rest = false
	end

	if cur_time >= next_add_ti_time then
		next_add_ti_time = GetNextAddTiTime()
		AddTi()
	end
end

--
function BeforeSleep()
	while cur_ti + rest_add_ti >= max_ti do
		local old_cur_ti = cur_ti
		local old_cur_ti_ext = cur_ti_ext
		if cur_ti >= 20 or cur_ti_ext > 0 then
			PlayDun()
		end
		if cur_ti_ext == old_cur_ti_ext and cur_ti == old_cur_ti then
			ComposeTi()
		end
	end
end

--
function AddTi()
	if cur_ti < max_ti then
		cur_ti = cur_ti + 1
	end

	if not is_rest then
		BuyTili()

		if cur_ti >= 20 or cur_ti_ext > 0 then
			PlayDun()
		end

		if cur_ti >= max_ti then
			ComposeTi()
		end
	end
end

--
function ComposeTi()
	if cur_ti_ext < max_ti_ext then
		cur_ti = cur_ti - 40
		cur_ti_ext = cur_ti_ext + 1
		LogTime("合成大体力")
	else
		PlaySomeDun()
	end
end

--
function BuyTili()
	if buy_tili <= 0 then
		return
	end

	local hour = tonumber(os.date("%H", cur_time))
	if hour < 4 then
		return
	end

	local taskList = HasDun()
	if not taskList then
		return
	end

	if cur_ti >= 100 then
		return
	end

	cur_ti = cur_ti + 60
	buy_tili = buy_tili - 1
	LogTime("购买一次体力")
end

--
function PlaySomeDun()
	cur_ti = cur_ti - 20
	LogTime("随便消耗20体力")
end

--
function PlayDun()
	local ret

	local taskList = HasDun()
	if not taskList then
		return
	end

	for _, mat_key in pairs(taskList) do
		local min_mat = game_met_table[mat_key]
		local mat_base_key = min_mat.mat_min
		local tar_num = mat_table[mat_key] or 0
		local reward = player_dun_reward[mat_base_key] or {}
		local out = reward.out or 0
		while tar_num > 0 and out > 0 do
			if (tar_num > out and cur_ti_ext > 0) or (cur_ti < 20 and cur_ti_ext > 0) then
				cur_ti_ext = cur_ti_ext - 1
				tar_num = tar_num - out * 2
				if tar_num <= 0 then
					mat_table[mat_key] = nil
					tar_num = 0
				else
					mat_table[mat_key] = tar_num
				end
				LogTime("使用大体力刷取[" .. game_role_tabe_remark[mat_base_key] .. "*" .. out .. "], 还需要" .. tar_num)
				ret = true
			elseif cur_ti >= 20 then
				cur_ti = cur_ti - 20
				tar_num = tar_num - out
				if tar_num <= 0 then
					mat_table[mat_key] = nil
					tar_num = 0
				else
					mat_table[mat_key] = tar_num
				end
				LogTime("使用体力刷取[" .. game_role_tabe_remark[mat_base_key] .. "*" .. out .. "], 还需要" .. tar_num)
				ret = true
			else
				break
			end
		end
	end

	return ret
end

function HasDun()
	if not next(mat_table) then
		return
	end

	cur_weekday = tonumber(os.date("%w", cur_time))
	if cur_weekday == 0 then
		cur_weekday = 7
	end

	cur_hour = tonumber(os.date("%H", cur_time))
	if cur_hour < 4 then
		cur_weekday = cur_weekday - 1
		if cur_weekday == 0 then
			cur_weekday = 7
		end
	end

	taskList = weekTaskList[cur_weekday]
	if not taskList then
		return
	end

	return taskList
end

Init()

while true do
	if not next(mat_table) then
		break
	end

	Update()
end

Log("end")

file = io.open("repo.txt", "w")
file:write(out_log)
file:close()
