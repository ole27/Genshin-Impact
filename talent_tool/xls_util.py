# coding=utf-8
import xlrd
import ast
# import os

class LuaMaker:

    @staticmethod
    def makeLuaTable(table):
        _tableMask = {}
        _keyMask = {}
        def analysisTable(_table, _indent, _parent):
            if isinstance(_table, tuple):
                _table = list(_table)
            if isinstance(_table, list):
                _table = dict(zip(range(1, len(_table) + 1), _table))
            if isinstance(_table, dict):

                if id(_table) in _tableMask:
                    print("error: LuaMaker.makeLuaTable() 成环: this = "+ _parent + "  oldP = " + _tableMask[id(_table)])
                    return

                _tableMask[id(_table)] = _parent
                cell = []
                thisIndent = _indent + "\t"
                for k in _table:
                    if not (isinstance(k, str) or isinstance(k, int) or isinstance(k, float)):
                        print("error: LuaMaker.makeLuaTable() key类型错误: parent = "+ _parent + "  key = " + k)
                        return
                    key = isinstance(k, int) and "[" + str(k) + "]" or "[\"" + str(k) + "\"]"
                    if (_parent + key) in _keyMask:
                        print("error: LuaMaker.makeLuaTable() 重复key: key = "+ _parent + key)
                        return
                    _keyMask[_parent + key] = True

                    var = None
                    v = _table[k]
                    if isinstance(v, str):
                        var = "\"" + v + "\""
                    elif isinstance(v, bool):
                        var = v and "true" or "false"
                    elif isinstance(v, int) or isinstance(v, float):
                        var = str(v)
                    else:
                        var = analysisTable(v, thisIndent, _parent + key)
                    cell.append(thisIndent + key + " = " + var)
                lineJoin = ",\n"
                return "{\n" + lineJoin.join(cell) + "\n" + _indent +"}"

            else:
                print("error: LuaMaker.makeLuaTable() table类型错误: "+ _parent)

        return analysisTable(table, "", "root")

class XlsUtil:

	sheets = {}

	def __init__(self, path):
		book = xlrd.open_workbook(path)

		for sheet_name in book.sheet_names():
			sheet = book.sheet_by_name(sheet_name)
			data = []
			keyCount = 0
			keyList = []
			typeList = []
			for i in range(sheet.nrows):
				lineData = sheet.row_values(i)
				if i == 0:
					try:
						keyCount = int(lineData[1])
					except ValueError:
						keyCount = 0
				elif i == 1:
					remarksList = lineData
				elif i == 2:
					for key in lineData:
						if key != "":
							keyList.append(key)
						else:
							break
				elif i == 3:
					typeList = lineData
				else:
					data.append(lineData)
			self.sheets[sheet_name] = {}
			self.sheets[sheet_name]["keyCount"] = keyCount
			self.sheets[sheet_name]["remarksList"] = remarksList
			self.sheets[sheet_name]["keyList"] = keyList
			self.sheets[sheet_name]["typeList"] = typeList
			self.sheets[sheet_name]["data"] = data

		self.savelua(path)

	def savelua(self, path):
		length = path.rfind(".")
		if length == -1:
			return
		path = path[:length] + ".lua"

		content = ""
		for name, sheet in self.sheets.items():
			content = content + self.tolua(name, sheet)

		f = open(path, 'w')
		f.write(content)
		f.close()
		print("ouput:", path)

	def tolua(self, name, sheet):
		keyCount = int(sheet["keyCount"])

		if keyCount > 0:
			return self.row_mode(name, sheet, keyCount)
		else:
			return self.column_mode(name, sheet, keyCount)

	def row_mode(self, name, sheet, keyCount):
		remarksList = sheet["remarksList"]
		keyList = sheet["keyList"]
		# print(len(keyList))
		typeList = sheet["typeList"]
		data = sheet["data"]

		tmp = {}
		for	oneLine in data:
			for x in range(0, keyCount):
				if oneLine[x] != "":
					tmp[x] = oneLine[x]
			for x in range(0, keyCount):
				oneLine[x] = tmp[x]

			for i in range(0, len(keyList)):
				if typeList[i] == "str":
					oneLine[i] = oneLine[i]
				elif typeList[i] == "int":
					if oneLine[i] == "":
						oneLine[i] = None
					else:
						oneLine[i] = int(oneLine[i])
				elif typeList[i] == "tab":
					oneLine[i] = ast.literal_eval(oneLine[i])
				elif typeList[i] == "list":
					oneLine[i] = ast.literal_eval(oneLine[i])
				elif typeList[i] == "float":
					oneLine[i] = oneLine[i]

		dataTable = {}
		ptr = dataTable
		for	oneLine in data:
			for x in range(0, keyCount):
				key = oneLine[x]
				if key in ptr:
					ptr = ptr[key]
				else:
					ptr[key] = {}
					ptr = ptr[key]

			for i in range(keyCount, len(keyList)):
				if oneLine[i] != None:
					ptr[keyList[i]] = oneLine[i]

			ptr = dataTable

		content = name + " = " + LuaMaker.makeLuaTable(dataTable) + "\n\n"

		dataTable = {}
		for i in range(0, len(keyList)):
			dataTable[keyList[i]] = remarksList[i]
		content = content + name + "_remark = " + LuaMaker.makeLuaTable(dataTable) + "\n\n"

		return content

	def column_mode(self, name, sheet, keyCount):
		# remarksList = sheet["remarksList"]
		keyList = sheet["keyList"]
		# print(len(keyList))
		typeList = sheet["typeList"]
		data = sheet["data"]
		oneLine = data[0]

		for i in range(0, len(keyList)):
			if typeList[i] == "str":
				oneLine[i] = oneLine[i]
			elif typeList[i] == "int":
				if oneLine[i] == "":
					oneLine[i] = None
				else:
					oneLine[i] = int(oneLine[i])
			elif typeList[i] == "tab":
				oneLine[i] = ast.literal_eval(oneLine[i])
			elif typeList[i] == "list":
				oneLine[i] = ast.literal_eval(oneLine[i])
			elif typeList[i] == "float":
				oneLine[i] = oneLine[i]

		dataTable = {}
		for i in range(0, len(keyList)):
			dataTable[keyList[i]] = oneLine[i]
		content = name + " = " + LuaMaker.makeLuaTable(dataTable) + "\n\n"

		return content