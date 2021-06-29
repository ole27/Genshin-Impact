
data.xls
	game_role_tabe
		版本1.6除万叶外所有角色, 需要添加新角色的话按格式在此sheet添加即可
	game_met_table
		材料合成的比例表, 程序时会将高级材料转成最低级材料进行计算, 此sheet基本不用修改
	game_dun_table
		天赋本时间, 此sheet基本不用修改

	player_role
		玩家需要培养的角色, 角色名需要与game_role_tabe中的正确对上, 顺序可以乱, 但角色名要一样
	player_bag
		玩家背包现有的天赋材料
	player_dun_reward
		玩家打本掉落期望, 需要转换成最低等级的材料个数, 例如: 2蓝+2绿就是8
	player_data
		玩家的现有体力, 作息时间(只支持整点时间, 大概一下就好), 每天原石购买体力的次数

data.py
xls_util.py
	xls转lua的代码, 摸鱼摸出来的东西, 有些写死, 不会很灵活
pack_py.bat
	py打包exe脚本, 运行需要安装py环境
data.exe
	xls转lua的,双击运行就行
data.lua
	data.exe的最终产物, main.lua会用到, 不要手动改

lua5.1.dll
lua51.dll
	lua的库, 忽略吧
main.lua
	主代码, 推算的逻辑就在里面, 摸鱼摸出来的东西, 能实现就行
pack_lua.bat
	lua打包exe脚本, 运行需要安装lua环境
tool
	lua打包exe的工具
main.exe
	双击运行就行, 运行后也会调用data.exe
repo.txt
	main.exe的最终产物, 也就是你需要的体力安排, 误差会有, 但不大, 大也没办法


1. 在player_role中填上想培养的角色们和她们对应的当前天赋等级和想要达到的等级
2. 在player_bag中填上天赋材料数量
3. 在player_dun_reward中填上平时打天赋本的期望值, 本人就是20体出2蓝2绿的8绿欧洲人
4. 在player_data填上当前的体力, 和平时的作息时间, 24小时在线的请都填0
5. 双击main.exe
6. repo.txt就是结果了
