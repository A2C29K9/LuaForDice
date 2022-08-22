-- by 简律纯. For 阿尘 22/8/20

write_file = function(path, text, mode)
    file = io.open(getDiceDir() .. "\\" .. path, mode)
    file.write(file, text)
    io.close(file)
end

read_file = function(path, mode)
    local text = ""
    local file = io.open(getDiceDir() .. "\\" .. path, mode)
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

settings = {["noise"] = 0, ["noisew"] = 0, ["length"] = 0}

local dataPath = getDiceDir() .. "//GI_tts.default.data"
local confPath = getDiceDir() .. "//GI_tts.settings.ini"
local MasterQQ = tonumber(string.match(read_file("conf//Console.xml"), "<master>(%d+)</master>", 0))

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
  local tmpStr=str
  local _,sum=string.gsub(str,"[^\128-\193]","")
  local _,countEn=string.gsub(tmpStr,"[%z\1-\127]","")
  if sum-countEn ~= 0 then return true else return false end
end

ToStringEx = function(value)
    if type(value)=='table' then
       return table.list(value)
    elseif type(value)=='string' then
        return "\'"..value.."\'"
    else
       return tostring(value)
    end
end

table.list = function(t)
    if t == nil then return "" end
    local retstr= "{"

    local i = 1
    for key,value in pairs(t) do
        local signal = ","
        if i==1 then
          signal = ""
        end

        if key == i then
            retstr = retstr..signal..ToStringEx(value)
        else
            if type(key)=='number' or type(key) == 'string' then
                retstr = retstr..signal..'['..ToStringEx(key).."]="..ToStringEx(value)
            else
                if type(key)=='userdata' then
                    retstr = retstr..signal.."*s"..TableToStr(getmetatable(key)).."*e".."="..ToStringEx(value)
                else
                    retstr = retstr..signal..key.."="..ToStringEx(value)
                end
            end
        end

        i = i+1
    end

     retstr = retstr.."}"
     return retstr
end

spaceKiller = function(str)
    return string.gsub(str, "[%s]+", "")
  end
  
-------------------------------------------------------------------------
-- 接下来的才是脚本主体
-- No unauthorized use without permission.
-- BY 简律纯.
-- 2022/08/22
-------------------------------------------------------------------------
local settings_text =
    [[
[Master]
nick=nil
QQ=nil

[UserConfig]
noise=0.667
noisew=0.8
length=1.2 
DefaultNpc=*

[AutoUpdate]
Version=v1.2.2
]]

if not getUserConf(getDiceQQ(), "GI_tts") then
    write_file("GI_tts.settings.ini", settings_text, "w+")
	WriteIni(confPath,"Master","QQ",MasterQQ)
    WriteIni(confPath,"Master","nick",getUserConf(MasterQQ,"name"))
    WriteIni(confPath,"UserConfig","noisew","0.8")
    WriteIni(confPath,"UserConfig","length","1.2")
    WriteIni(confPath,"AutoUpdate","Version","v1.2.2 ;laset version")
    setUserConf(getDiceQQ(), "GI_tts", true)
    log(os.date("%X") .. "\n> 原神tts:初始化完成~", 1)
end

--[[
	settings["noise"] = ReadIni(confPath,"default settings","noise")
	settings["noisew"] = ReadIni(confPath,"default settings","noisew")
	settings["length"] = ReadIni(confPath,"default settings","length")

	WriteIni(confPath,"Master","QQ",MasterQQ)
    WriteIni(confPath,"Master","nick",getUserConf(MasterQQ,"name"))
    WriteIni(confPath,"UserConfig","noisew","0.8")
    WriteIni(confPath,"UserConfig","length","1.2")
    WriteIni(confPath,"AutoUpdate","Version","v1.0.2 ;laset version")

]]
function letSpeaker(msg)
    local npc = string.match(msg.fromMsg, "让(.-)说")
    if npc then
        local prefix = "让" .. npc .. "说"
        local text = string.sub(msg.fromMsg, #prefix + 1)
        for i = 1, #npcList do
            if npcList[i] == npc then
                return "[CQ:record,file=http://233366.proxy.nscc-gz.cn:8888?speaker=" ..
                    npcList[i] .. "&text=" .. text .. "]"
            end
        end
        --return #npcList
    else
        return
    end
end

function doSpeaker(msg)
    local p, b
    for i = 1, #npcList do
        p, b = string.find(msg.fromMsg, npcList[i])
        if p or b then
            break
        end
    end
    if p or b then
        return "[CQ:record,file=http://233366.proxy.nscc-gz.cn:8888?speaker=" ..string.sub(msg.fromMsg, p, b) .. "&text=" .. string.sub(msg.fromMsg, #"说" + 1) .. "]"
    else
        return "[CQ:record,file=http://233366.proxy.nscc-gz.cn:8888?speaker=神里绫华&text=" ..string.sub(msg.fromMsg, #"说" + 1) .. "]"
    end
end

function GItts(msg)
    command = string.sub(msg.fromMsg, #".GItts" + 2)

    if command == "reload" then
        setUserConf(getDiceQQ(), "GI_tts", false)
        eventMsg(".system load", msg.fromGroup, msg.fromQQ)
    elseif command == "ini" then
        return read_file("GI_tts.settings.ini")
	elseif checkChinese(command) then
		local npc = ReadIni(confPath,"UserConfig","DefaultNpc")
		if npc == "*" then npc = npcList[ranint(1,#npcList)] end
		return "[CQ:record,file=http://233366.proxy.nscc-gz.cn:8888?speaker="..npc.."&text=" ..string.sub(msg.fromMsg, #".GItts " + 1) .. "]"
	elseif command == "npcList" then
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