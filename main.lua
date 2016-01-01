--Я СКАЗАЛА СТАРТУЕМ
local install = {}
print(" ")
print("Check the analysis of the required data...")

-----ПРОВЕРЯЕМ НУЖНЫЕ ФАЙЛЫ-----

--Если плохое GPU, то...
if gpu.maxResolution() < 150 then table.insert(install, "ERR: Bad GPU. It takes less than 3 GB of memory.") end

--Если экран не поставлен в 3 блока, то...
if gpu.getDepth() < 8 and gpu.maxResolution() < 150 then table.insert(install, "ERR: Bad Screen.  It takes less than 3 blocks of screen.") end

--Если оперативка не поставлена, то...
if math.floor(computer.totalMemory() / 1024 ) < 2048 then table.insert(install, "ERR: Not enough RAM. It takes at least 2048 KB RAM.") end

--Наконец мы проверяем систему OpenOS.
if fs.get("bin/edit.lua") == nil or fs.get("bin/edit.lua").isReadOnly() then table.insert(install, "FATAL_ERR: You can not set WicopeeOS due to the fact that you have not set OpenOS. Write to /install/ in the system , write the recommended option 1. Then install WicopeeOS.") end


if #install > 0 then
  print(" ")
  for i = 1, #install do
    print(install[i])
  end
  print(" ")
  return
else
  print("Done. All checked. Be prepared to boot...")
  print(" ")
end

-----------------------

local lang
 
local applications
 
local padColor = 0x262626
local installerScale = 1
 
local timing = 0.2

-----------------------
-----------------------------СТАДИЯ ПОДГОТОВКИ-------------------------------------------
 
 
--ЗАГРУЗОЧКА С ГИТХАБА
local function getFromGitHub(url, path)
  local sContent = ""
  local result, response = pcall(internet.request, url)
  if not result then
    return nil
  end
 
  if fs.exists(path) then fs.remove(path) end
  fs.makeDirectory(fs.path(path))
  local file = io.open(path, "w")
 
  for chunk in response do
    file:write(chunk)
    sContent = sContent .. chunk
  end
 
  file:close()
 
  return sContent
end
 
--БЕЗОПАСНАЯ ЗАГРУЗОЧКА
local function getFromGitHubSafely(url, path)
  local success, sRepos = pcall(getFromGitHub, url, path)
  if not success then
    io.stderr:write("Can't download \"" .. url .. "\"!\n")
    return -1
  end
  return sRepos
end
 
--ЗАГРУЗОЧКА С ПАСТЕБИНА
local function getFromPastebin(paste, filename)
  local cyka = ""
  local f, reason = io.open(filename, "w")
  if not f then
    io.stderr:write("Failed opening file for writing: " .. reason)
    return
  end
  --io.write("Downloading from pastebin.com... ")
  local url = "http://pastebin.com/raw.php?i=" .. paste
  local result, response = pcall(internet.request, url)
  if result then
    --io.write("success.\n")
    for chunk in response do
      --if not options.k then
        --string.gsub(chunk, "\r\n", "\n")
      --end
      f:write(chunk)
      cyka = cyka .. chunk
    end
    f:close()
    --io.write("Saved data to " .. filename .. "\n")
  else
    f:close()
    fs.remove(filename)
    io.stderr:write("HTTP request failed: " .. response .. "\n")
  end
 
  return cyka
end
 
local GitHubUserUrl = "https://raw.githubusercontent.com/"
 
 
--------------------------------- Стадия стартовой загрузки всего необходимого ---------------------------------
 
 
local preLoadApi = {
  { paste = "Wicopee/OpenComputers/master/MineOS/Icons/Languages.pic", path = "MineOS/System/OS/Icons/Languages.pic" },
  { paste = "Wicopee/OpenComputers/master/MineOS/Icons/OK.pic", path = "MineOS/System/OS/Icons/OK.pic" },
  { paste = "Wicopee/OpenComputers/master/MineOS/Icons/Downloading.pic", path = "MineOS/System/OS/Icons/Downloading.pic" },
  { paste = "Wicopee/OpenComputers/master/MineOS/Icons/OS_Logo.pic", path = "MineOS/System/OS/Icons/OS_Logo.pic" },
}
 
print("Downloading file list")
applications = seri.unserialize(getFromGitHubSafely(GitHubUserUrl .. "Wicopee/OpenComputers/master/Applications.txt", "MineOS/System/OS/Applications.txt"))
print(" ")
 
for i = 1, #preLoadApi do
  print("Downloading must-have files (" .. fs.name(preLoadApi[i].path) .. ")")
  getFromGitHubSafely(GitHubUserUrl .. preLoadApi[i].paste, preLoadApi[i].path)
end
 
print(" ")
 
_G.ecs = require("ECSAPI")
_G.image = require("image")
_G.config = require("config")

local imageOK = image.load("photos/OK.pic")

ecs.setScale(installerScale)
 
local xSize, ySize = gpu.getResolution()
local windowWidth = 80
local windowHeight = 2 + 16 + 2 + 3 + 2
local xWindow, yWindow = math.floor(xSize / 2 - windowWidth / 2), math.ceil(ySize / 2 - windowHeight / 2)
local xWindowEnd, yWindowEnd = xWindow + windowWidth - 1, yWindow + windowHeight - 1
 
 
-----------------------
 
local function clear()
  ecs.blankWindow(xWindow, yWindow, windowWidth, windowHeight)
end
 
--ОБЪЕКТЫ
local obj = {}
local function newObj(class, name, ...)
  obj[class] = obj[class] or {}
  obj[class][name] = {...}
end
 
local function drawButton(name, isPressed)
  local buttonColor = 0x888888
  if isPressed then buttonColor = ecs.colors.blue end
  local d = { ecs.drawAdaptiveButton("auto", yWindowEnd - 3, 2, 1, name, buttonColor, 0xffffff) }
  newObj("buttons", name, d[1], d[2], d[3], d[4])
end
 
local function waitForClickOnButton(buttonName)
  while true do
    local e = { event.pull() }
    if e[1] == "touch" then
      if ecs.clickedAtArea(e[3], e[4], obj["buttons"][buttonName][1], obj["buttons"][buttonName][2], obj["buttons"][buttonName][3], obj["buttons"][buttonName][4]) then
        drawButton(buttonName, true)
        os.sleep(timing)
        break
      end
    end
  end
end
 
--Создаём окно.

local downloadWallpapers, showHelpTips = false, false
 
do
 
  clear()
 
  image.draw(math.ceil(xSize / 2 - 30), yWindow + 2, imageLanguages)
 
  --кнопа
  drawButton("Select language",false)
 
  waitForClickOnButton("Select language")
 
  local data = ecs.universalWindow("auto", "auto", 36, 0x262626, true, {"EmptyLine"}, {"CenterText", ecs.colors.orange, "Select language"}, {"EmptyLine"}, {"Select", 0xFFFFFF, ecs.colors.green, "Russian", "English"}, {"EmptyLine"}, {"CenterText", ecs.colors.orange, "Change some OS properties"}, {"EmptyLine"}, {"Switch", 0xF2B233, 0xffffff, 0xFFFFFF, "Download wallpapers", true}, {"EmptyLine"}, {"Switch", 0xF2B233, 0xffffff, 0xFFFFFF, "Show help tips in OS", true}, {"EmptyLine"}, {"Button", {ecs.colors.green, 0xffffff, "OK"}})
  downloadWallpapers, showHelpTips = data[2], data[3]
 
  --УСТАНАВЛИВАЕМ НУЖНЫЙ ЯЗЫК
  _G.OSSettings = { showHelpOnApplicationStart = showHelpTips, language = data[1] }
  ecs.saveOSSettings()
end