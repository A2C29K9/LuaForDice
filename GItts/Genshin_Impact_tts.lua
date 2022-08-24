-- by 简律纯. For 阿尘 22/8/20
-- About API? View more at https://github.com/w4123/vits

write_file = function(path, text, mode)
    file = io.open(path, mode)
    file.write(file, text)
    io.close(file)
end

read_file = function(path, mode)
    local text = ""
    local file = io.open(path, mode)
    if (file ~= nil) then
        text = file.read(file, "*a")
        io.close(file)
    else
        return "没有该文件或文件内容为空哦"
    end
    return text
end

npcList = {
    "派蒙",
    "凯亚",
    "安柏",
    "丽莎",
    "琴",
    "香菱",
    "枫原万叶",
    "迪卢克",
    "温迪",
    "可莉",
    "早柚",
    "托马",
    "芭芭拉",
    "优菈",
    "云堇",
    "钟离",
    "魈",
    "凝光",
    "雷电将军",
    "北斗",
    "甘雨",
    "七七",
    "刻晴",
    "神里绫华",
    "戴因斯雷布",
    "雷泽",
    "神里绫人",
    "罗莎莉亚",
    "阿贝多",
    "八重神子",
    "宵宫",
    "荒泷一斗",
    "九条裟罗",
    "夜兰",
    "珊瑚宫心海",
    "五郎",
    "散兵",
    "女士",
    "达达利亚",
    "莫娜",
    "班尼特",
    "申鹤",
    "行秋",
    "烟绯",
    "久岐忍",
    "辛焱",
    "砂糖",
    "胡桃",
    "重云",
    "菲谢尔",
    "诺艾尔",
    "迪奥娜",
    "鹿野院平藏"
}

msg_order = {["让"] = "letSpeaker", ["说"] = "doSpeaker", [".GItts"] = "GItts"}

settings = {["noise"] = 0, ["noisew"] = 0, ["length"] = 0, ["format"] = "mp3"}

local dataFolder = getDiceDir() .. "\\plugin\\Genshin_Impact_tts\\data"
local dataPath = dataFolder .. "\\default.json"
local confPath = getDiceDir() .. "\\plugin\\Genshin_Impact_tts\\settings.ini"
local MasterQQ = tonumber(string.match(read_file(getDiceDir() .. "\\conf\\Console.xml"), "<master>(%d+)</master>", 0))

-------------------------------------------------------------------------
-- EDIT INI FILE
-- No unauthorized use without permission.
-- BY 简律纯.
-- 2022/6/10
-------------------------------------------------------------------------

-- 读全部
load_all = function(fileName)
    assert(type(fileName) == "string", "参数“fileName”必须是字符串哦")
    local file = assert(io.open(fileName, "r"), "加载文件时出错：" .. fileName)
    local data = {}
    local section
    for line in file:lines() do
        local tempSection = line:match("^%[([^%[%]]+)%]$")
        if (tempSection) then
            section = tonumber(tempSection) and tonumber(tempSection) or tempSection
            data[section] = data[section] or {}
        end
        local param, value = line:match("^([%w|_]+)%s-=%s-(.+)$")
        if (param and value ~= nil) then
            if (tonumber(value)) then
                value = tonumber(value)
            elseif (value == "true") then
                value = true
            elseif (value == "false") then
                value = false
            end
            if (tonumber(param)) then
                param = tonumber(param)
            end
            data[section][param] = value
        end
    end
    file:close()
    return data
end
-- 写全部
save_all = function(fileName, data)
    assert(type(fileName) == "string", "参数“fileName”必须是字符串哦")
    assert(type(data) == "table", "参数“data”必须是一个表！")
    local file = assert(io.open(fileName, "w+b"), "加载文件时出错：" .. fileName)
    local contents = ""
    for section, param in pairs(data) do
        contents = contents .. ("[%s]\n"):format(section)
        for key, value in pairs(param) do
            contents = contents .. ("%s=%s\n"):format(key, tostring(value))
        end
        contents = contents .. "\n"
    end
    file:write(contents)
    file:close()
end
-- 读单条
ReadIni = function(IniPath, Section, Key)
    local data = load_all(IniPath)
    return data[Section][Key]
end
-- 写单条
WriteIni = function(IniPath, Section, Key, Value)
    local data = load_all(IniPath)
    data[Section][Key] = Value
    save_all(IniPath, data)
end

--检测中文，如有则返回true
checkChinese = function(str)
    local tmpStr = str
    local _, sum = string.gsub(str, "[^\128-\193]", "")
    local _, countEn = string.gsub(tmpStr, "[%z\1-\127]", "")
    if sum - countEn ~= 0 then
        return true
    else
        return false
    end
end

ToStringEx = function(value)
    if type(value) == "table" then
        return table.list(value)
    elseif type(value) == "string" then
        return "'" .. value .. "'"
    else
        return tostring(value)
    end
end

table.list = function(t)
    if t == nil then
        return ""
    end
    local retstr = "{"

    local i = 1
    for key, value in pairs(t) do
        local signal = ","
        if i == 1 then
            signal = ""
        end

        if key == i then
            retstr = retstr .. signal .. ToStringEx(value)
        else
            if type(key) == "number" or type(key) == "string" then
                retstr = retstr .. signal .. "[" .. ToStringEx(key) .. "]=" .. ToStringEx(value)
            else
                if type(key) == "userdata" then
                    retstr =
                        retstr .. signal .. "*s" .. TableToStr(getmetatable(key)) .. "*e" .. "=" .. ToStringEx(value)
                else
                    retstr = retstr .. signal .. key .. "=" .. ToStringEx(value)
                end
            end
        end

        i = i + 1
    end

    retstr = retstr .. "}"
    return retstr
end

-- 空格占位符处理
spaceKiller = function(str)
    return string.gsub(str, "[%s]+", "+")
end

--作用：获取文件夹下的一级文件及文件夹table
--参数: path——>遍历文件的路径
getFileList = function(path)
    local a = io.popen("dir " .. path .. "/")
    local fileTable = {}

    if a == nil then
    else
        for l in a:lines() do
            table.insert(fileTable, l)
        end
    end
    return fileTable
end

--作用：判断文件夹是否存在
--参数: folderPath——>文件夹路径
--返回值：true/false ——>是否存在
isFolderExist = function(folderPath)
    return os.execute("cd " .. folderPath)
end

CER = function(fun, arg1, arg2, arg3, arg4, arg5)
    local i
    local ret, errMessage = pcall(fun, arg1, arg2, arg3, arg4, arg5)
    wrong = ret and "false" or "true"
    --return "是否错误:\n"..错误.." \n\n出错信息:\n" .. (errMessage or "无")
    if wrong == "true" then --错误提示
        --output[i]
        local ret, errMessage = pcall(fun, arg1, arg2, arg3, arg4, arg5)
        return "\n错误详情：\n" .. errMessage
    else --无错误正常执行
        ret, back = pcall(fun, arg1, arg2, arg3, arg4, arg5)
        return back
    end
end

--调用方法：
--local  str= "-6ciNeXFTlqy5Dcld8UPmsrcieJkmFJO4zDcaOP56YY$-$OPENTM207374570"
--local tab = str_split(str, "$-$")
--打印：["-6ciNeXFTlqy5Dcld8UPmsrcieJkmFJO4zDcaOP56YY","OPENTM207374570"]

----------------------------------------
-- @description 拆分字符串的方法
-- @param str   传入的元字符串
-- @param split_char  以什么符号拆分
-- @return str_tab 返回拆分之后的字符串table
-----------------------------------------
function str_split(str, split_char)
    local str_tab = {}
    while (true) do
        --问题在这里  local findstart,findend = string.find(str, split_char)
        --这里第4个参数一定要给，第4个参数表示把要find的字符串，split_char当成一个整体字符串看。
        --string.find返回找到匹配字符串的起始位置和结束位置
        local findstart, findend = string.find(str, split_char, 1, true)
        if not (findstart and findend) then
            str_tab[#str_tab + 1] = str
            break
        end
        local sub_str = string.sub(str, 1, findstart - 1)
        str_tab[#str_tab + 1] = sub_str
        str = string.sub(str, findend + 1, #str)
    end

    return str_tab
end

getFileList = function(path, exp)
    local a = io.popen("dir " .. path .. exp .. " /b")
    local fileTable = {}
    local str = ""

    if a == nil then
    else
        for l in a:lines() do
            table.insert(fileTable, l)
        end

        for i = 1, #fileTable do
            str = fileTable[i] .. "\n" .. str
        end

        return fileTable
    end
end

-------------------------------------------------------------------------
-- 接下来的才是脚本主体
-- No unauthorized use without permission.
-- BY 简律纯.
-- 2022/08/22
-------------------------------------------------------------------------

local settings_text =
    [[
[MasterConfig]
nick=nil
QQ=nil

[UserConfig]
noise=0.667
noisew=0.8
length=1.2 
DefaultNpc=*
format=mp3

[AutoUpdate]
Version=v1.2.2]]

if not getUserConf(getDiceQQ(), "GI_tts") then
    mkDirs(getDiceDir() .. "\\plugin\\Genshin_Impact_tts")
    write_file(confPath, settings_text, "w+")
    WriteIni(confPath, "MasterConfig", "QQ", MasterQQ)
    WriteIni(confPath, "MasterConfig", "nick", getUserConf(MasterQQ, "name"))
    WriteIni(confPath, "UserConfig", "noisew", "0.8")
    WriteIni(confPath, "UserConfig", "length", "1.2")
    WriteIni(confPath, "UserConfig", "format", "mp3")
    WriteIni(confPath, "AutoUpdate", "Version", "v1.2.2 ;laset version")
    if not isFolderExist(getDiceDir() .. "\\SelfData\\GItts") then
        expansion, state = 0, "失败，疑似没有SelfData/GItts文件夹 "
    else
        enable = 0
        files = getFileList(getDiceDir() .. "\\SelfData\\GItts", "\\*.json")
        state = "成功 共" .. #files .. "个拓展可用，已启用" .. enable .. "个"
    end
    setUserConf(getDiceQQ(), "GI_tts", true)
    log(os.date("%X") .. "\n> 原神tts:初始化完成~\n> 读取情绪拓展" .. state, 1)
end

function letSpeaker(msg)
    local npc = string.match(msg.fromMsg, "让(.-)说")

    settings.noise = ReadIni(confPath, "UserConfig", "noise")
    settings.noisew = ReadIni(confPath, "UserConfig", "noisew")
    settings.length = ReadIni(confPath, "UserConfig", "length")
    settings.format = ReadIni(confPath, "UserConfig", "format")

    if npc then
        --return #npcList
        local prefix = "让" .. npc .. "说"
        local text = string.sub(msg.fromMsg, #prefix + 1)
        for i = 1, #npcList do
            if npcList[i] == npc then
                return "[CQ:record,file=http://233366.proxy.nscc-gz.cn:8888?speaker=" ..
                    npcList[i] ..
                        "&text=" ..
                            spaceKiller(text) ..
                                "&noise=" ..
                                    settings.noise ..
                                        "&noisew=" ..
                                            settings.noisew ..
                                                "&length=" .. settings.length .. "&format=" .. ettings.format .. "]"
            end
        end
    else
        return
    end
end

function doSpeaker(msg)
    local p, b

    settings.noise = ReadIni(confPath, "UserConfig", "noise")
    settings.noisew = ReadIni(confPath, "UserConfig", "noisew")
    settings.length = ReadIni(confPath, "UserConfig", "length")
    settings.format = ReadIni(confPath, "UserConfig", "format")

    for i = 1, #npcList do
        p, b = string.find(msg.fromMsg, npcList[i])
        if p or b then
            break
        end
    end
    if p or b then
        return "[CQ:record,file=http://233366.proxy.nscc-gz.cn:8888?speaker=" ..
            string.sub(msg.fromMsg, p, b) ..
                "&text=" ..
                    string.sub(msg.fromMsg, #"说" + 1) ..
                        "&noise=" ..
                            settings.noise ..
                                "&noisew=" ..
                                    settings.noisew ..
                                        "&length=" .. settings.length .. "&format=" .. ettings.format .. "]"
    else
        return "[CQ:record,file=http://233366.proxy.nscc-gz.cn:8888?speaker=神里绫华&text=" ..
            spaceKiller(string.sub(msg.fromMsg, #"说" + 1)) ..
                "&noise=" ..
                    settings.noise ..
                        "&noisew=" ..
                            settings.noisew .. "&length=" .. settings.length .. "&format=" .. settings.format .. "]"
    end
end

function GItts(msg)
    command = str_split(msg.fromMsg, " ")

    settings.noise = ReadIni(confPath, "UserConfig", "noise")
    settings.noisew = ReadIni(confPath, "UserConfig", "noisew")
    settings.length = ReadIni(confPath, "UserConfig", "length")
    settings.format = ReadIni(confPath, "UserConfig", "format")

    if command[2] == "reload" then
        setUserConf(getDiceQQ(), "GI_tts", false)
        eventMsg(".system load", 0, msg.fromQQ)
    elseif command[2] == "ini" then
        items = str_split(msg.fromMsg, " ")
        if #items == 2 then
            return read_file(confPath)
        elseif items[3] == "set" then
            WriteIni(confPath, items[4], items[5], items[6])
            return "节点" .. items[4] .. "的key" .. items[5] .. "值已修改为" .. items[6]
        end
    elseif checkChinese(command[2]) then
        local npc = ReadIni(confPath, "UserConfig", "DefaultNpc")
        if npc == "*" then
            npc = npcList[ranint(1, #npcList)]
        end
        return "[CQ:record,file=http://233366.proxy.nscc-gz.cn:8888?speaker=" ..
            npc ..
                "&text=" ..
                    spaceKiller(string.sub(msg.fromMsg, #".GItts " + 1)) ..
                        "_&noise=" ..
                            settings.noise ..
                                "&noisew=" ..
                                    settings.noisew ..
                                        "&length=" .. settings.length .. "&format=" .. ettings.format .. "]"
    elseif command[2] == "npcList" then
        return table.list(npcList)
    else
        return [[
		原神tts·GItts
			【.GItts reload】重新配置ini文件并重载
			【.GItts ini (set) (section) (key) (value)】ini配置文件操作
			【.GItts (文本)】调用key:DefaultNpc说一句话
			【.GItts whiteList (add|remove|clr) (word1[,word2[,word3]...])】添加语句白名单
			【.GItts npcList】查看可以使用的人物]]
    end
end

-- Plan:
--  > 情感要素
--  > 转义要素
