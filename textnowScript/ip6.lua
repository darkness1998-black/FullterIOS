-- version 3 update ngay 29.11.2021
local Helper = {}

local json = require("json")
local http = require("socket.http")
local plist = require("plist")

---- Config const values --------------------------------
local fakeData = "/Library/PreferenceLoader/Preferences/lunaspoofer/data.plist"

-- math.randomseed(os.time())
function split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end
function file_exists(file)
    local f = io.open(file, "rb")
    if f then
        f:close()
    end
    return f ~= nil
end
function lines_from(file)
    if not file_exists(file) then
        return {}
    end
    lines = {}
    for line in io.lines(file) do
        lines[#lines + 1] = line
    end
    return lines
end
function linesNumber_from(file)
    local counter = 0;
    for line in io.lines(file) do
        print(line)
        counter = counter + 1;
    end
    return counter;
end
function string.replace(input, before, after, limit)
    if input == nil or input == "" then
        error("Input must not be nil or an empty string; Aborting.")
    end
    if before == nil or before == "" then
        error("Before parameter must not be nil or an empty string; Aborting.")
    end
    if after == nil then
        after = ""
    end
    if limit == nil then
        limit = 0
    end

    input = input:gsub(before, after, limit)

    return input
end
function readFile(path)
    T = {}
    if io.open(path, "r") then
        for i in io.open(path, "r"):lines() do
            table.insert(T, i)
        end
        io.open(path, "r"):close()
        return T
    else
        return {""}
    end
end
function tablelength(file)
    local count = 0
    for _ in pairs(file) do
        count = count + 1
    end
    return count
end
function parseRandomIp(randomIP)
    local replaceString = split(randomIP, ".")[2]
    local number = tonumber(replaceString);
    if (number > 244) then
        number = number - 1
    else
        number = number + math.random(1, 10)
    end

    local insertString = tostring(number)
    return string.replace(randomIP, replaceString, insertString, 1)
end

function randomIPFromFile(file)
    local data = readFile(file);
    local randomIndex = math.random(1, tablelength(data));
    local selectedIP = data[randomIndex];
    local selectedIPTbl = split(selectedIP, ".");
    -- local headIp = selectedIPTbl[1] .. "." .. selectedIPTbl[2];
    local headIp = selectedIPTbl[1] .. "." .. math.random(3, 244) .. "." .. selectedIPTbl[3];
    -- local randomIp = parseRandomIp(headIp) .. "." .. math.random(3, 244) .. "." .. math.random(3, 244);
    local randomIp = tostring(parseRandomIp(headIp)) .. "." .. tostring(math.random(3, 244));
    return randomIp;
end

function Helper.fakeDevice1(file) -- ghichu
    local body = nil;
    repeat
        local ipaddress = Helper.randomIPFromFile(file);
        body = http.request("http://localhost:3004/device/changefull?ip=" .. ipaddress)
        if body ~= nil and string.find(body, "Error") ~= nil then
            toast("Fake ERROR", 1);
        end
        if body ~= nil and string.find(body, "Fail") ~= nil then
            toast("Fake ERROR", 1);
        end
        if body ~= nil and string.find(body, "HardwarePlatform") ~= nil then
            toast("Fake OK", 1);
            usleep(1000000);
            break
        end
    until body ~= nil and string.find(body, "HardwarePlatform") ~= nil
end

function wipe(bundleName)
    local url = "http://localhost:3004/app/wipe?bundleName=" .. bundleName;
    local body = http.request(url);
end

function fakeDevice(country)
    local url = "http://localhost:3004/app/fake";
    local output = http.request(url);
    if (output == "true|US") then
        return 1
    else
        fakeDevice(country)
        usleep(1000000);
    end
end

function getFullInfo(info)
    local body = nil;
    while body == nil do
        body = http.request("https://randomuser.me/api/?inc=gender,name,nat,email,dob,login&nat=us")
    end

    local decode = json.decode(body)
    local tblInfo = {}
    local tblBirthDate = ParseBirthDate(decode["results"][1]["dob"]["date"])
    -- get email
    local exampleEmail = decode["results"][1]["email"]
    local headEmail = split(exampleEmail, "@")[1]

    tblInfo["firstName"] = decode["results"][1]["name"]["first"];
    tblInfo["lastName"] = decode["results"][1]["name"]["last"];
    tblInfo["gender"] = decode["results"][1]["gender"]
    tblInfo["gmail"] = "huy@gmail.com";
    tblInfo["dd"] = tblBirthDate["dd"];
    tblInfo["mm"] = tblBirthDate["mm"];
    tblInfo["yy"] = tblBirthDate["yy"];
    tblInfo["email"] = headEmail .. tblBirthDate["dd"] .. tblBirthDate["mm"] .. tblBirthDate["yy"]
    tblInfo["password"] = decode["results"][1]["login"]["username"]
    if (tblInfo["mm"] == "04" or tblInfo["mm"] == "06" or tblInfo["mm"] == "09" or tblInfo["mm"] == "11") then
        if (tonumber(tblInfo["dd"]) > 30) then
            tblInfo["dd"] = "29"
        end
    end

    if (tblInfo["mm"] == "02") then
        if (tonumber(tblInfo["dd"]) > 28) then
            tblInfo["dd"] = "27"
        end
    end

    return tblInfo[info];

end
function pTouchDown(x, y)
    executeCommands("/usr/bin/LinhVu touch down " .. x .. " " .. y)
end
function pTouchUp(x, y)
    executeCommands("/usr/bin/LinhVu touch up " .. x .. " " .. y)
end

function pTouchMove(x, y)
    executeCommands("/usr/bin/LinhVu touch move " .. x .. " " .. y)
end

function ParseBirthDate(date)
    local tblDate = {}
    local fullDateString = split(date, "T")
    local tblBirthDate = split(fullDateString[1], "-")
    tblDate["dd"] = tblBirthDate[3];
    tblDate["mm"] = tblBirthDate[2];
    tblDate["yy"] = tblBirthDate[1];
    return tblDate
end
----------------------------------------------------------------
--------------------------------------------------
-----------------------------------------
Pixel = {};

function Pixel.new(x, y, color)
    local o = {};
    o.x = x;
    o.y = y;
    o.color = color;
    return o;
end
-- returns new pixel that has offset from the original pixel
function Pixel.withOffset(pixel, offsetx, offsety)
    local o = {};
    o.x = pixel.x + offsetx;
    o.y = pixel.y + offsety;
    o.color = pixel.color;
    return o;
end

Location = {};

function Location.new(x, y)
    local o = {};
    o.x = x;
    o.y = y;
    return o;
end

Rect = {}

function Rect.new(x1, y1, x2, y2)
    local o = {};
    o.x1 = x1;
    o.x2 = x2;
    o.y1 = y1;
    o.y2 = y2;
    return o;
end

local Keys = {}
-- key char
Keys.q = Rect.new(14, 923, 61, 990)
Keys.w = Rect.new(90, 921, 101, 988)
Keys.e = Rect.new(164, 927, 213, 986)
Keys.r = Rect.new(246, 935, 285, 991)
Keys.t = Rect.new(317, 931, 359, 986)
Keys.y = Rect.new(395, 933, 437, 986)
Keys.u = Rect.new(467, 936, 505, 986)
Keys.i = Rect.new(544, 932, 581, 984)
Keys.o = Rect.new(616, 935, 658, 985)
Keys.p = Rect.new(691, 934, 734, 984)
Keys.a = Rect.new(50, 1030, 93, 1099)
Keys.s = Rect.new(128, 1042, 171, 1094)
Keys.d = Rect.new(203, 1045, 243, 1096)
Keys.f = Rect.new(279, 1040, 321, 1094)
Keys.g = Rect.new(355, 1043, 400, 1095)
Keys.h = Rect.new(429, 1043, 467, 1088)
Keys.j = Rect.new(508, 1038, 547, 1095)
Keys.k = Rect.new(582, 1037, 619, 1095)
Keys.l = Rect.new(659, 1042, 693, 1093)
Keys.z = Rect.new(131, 1152, 173, 1195)
Keys.x = Rect.new(207, 1147, 245, 1196)
Keys.c = Rect.new(278, 1150, 319, 1197)
Keys.v = Rect.new(355, 1146, 395, 1199)
Keys.b = Rect.new(431, 1149, 473, 1196)
Keys.n = Rect.new(502, 1148, 543, 1199)
Keys.m = Rect.new(578, 1154, 617, 1198)
Keys.space = Rect.new(239, 1260, 517, 1306)
Keys.shift = Rect.new(15, 1153, 75, 1201)
Keys.enter = Rect.new(581, 1255, 726, 1304)
Keys.number = Rect.new(15, 1252, 80, 1310)
Keys.emoji = Rect.new(112, 1250, 173, 1314)

Keys.number1 = Rect.new(28, 930, 217, 986)
Keys.number2 = Rect.new(285, 933, 471, 987)
Keys.number3 = Rect.new(536, 933, 711, 989)
Keys.number4 = Rect.new(30, 1044, 212, 1093)
Keys.number5 = Rect.new(275, 1039, 473, 1093)
Keys.number6 = Rect.new(543, 1035, 704, 1097)
Keys.number7 = Rect.new(24, 1040, 219, 1204)
Keys.number8 = Rect.new(279, 1148, 471, 1202)
Keys.number9 = Rect.new(529, 1153, 715, 1204)
Keys.number0 = Rect.new(281, 1251, 472, 1310)

-- Keys.a = Rect.new(9)
-- Keys.a = Rect.new(0,1030,93,1099)
-- Keys.a = Rect.new(50,1030,93,1099)
-- Keys.a = Rect.new(50,1030,93,1099)
-- Keys.a = Rect.new(50,1030,93,1099)
-- Keys.a = Rect.new(50,1030,93,1099)
function isInteger(str)
    return not (str == "" or str:find("%D")) -- str:match("%D") also works

end

-- function convertInputString(string)
-- 	--"Huy123" -> "Huy,123,"
-- 	local result = "";
-- 	for chacracter in string:gmatch"." do
-- 			if (string.sub(result,#result) == ",") then
-- 			result = result:sub(1,#result-1)
-- 		end
-- 		if (isInteger(chacracter) == true) then
-- 			result = result .. "," .. chacracter .. ","
-- 		else result = result .. chacracter end
-- 	end
-- 	return result;
-- end
function tapString(string)
    string = string:gsub("%W", "")

    for chacracter in string:gmatch "." do
        if chacracter == "a" then
            tapR(Keys.a)
        end
        if chacracter == "b" then
            tapR(Keys.b)
        end
        if chacracter == "c" then
            tapR(Keys.c)
        end
        if chacracter == "d" then
            tapR(Keys.d)
        end
        if chacracter == "e" or chacracter == "3" then
            tapR(Keys.e)
        end
        if chacracter == "f" then
            tapR(Keys.f)
        end
        if chacracter == "g" then
            tapR(Keys.g)
        end
        if chacracter == "h" then
            tapR(Keys.h)
        end
        if chacracter == "i" or chacracter == "8" then
            tapR(Keys.i)
        end
        if chacracter == "j" then
            tapR(Keys.j)
        end
        if chacracter == "k" then
            tapR(Keys.k)
        end
        if chacracter == "l" then
            tapR(Keys.l)
        end
        if chacracter == "m" then
            tapR(Keys.m)
        end
        if chacracter == "n" then
            tapR(Keys.n)
        end
        if chacracter == "o" or chacracter == "9" then
            tapR(Keys.o)
        end
        if chacracter == "p" or chacracter == "0" then
            tapR(Keys.p)
        end
        if chacracter == "q" or chacracter == "1" then
            tapR(Keys.q)
        end
        if chacracter == "r" or chacracter == "4" then
            tapR(Keys.r)
        end
        if chacracter == "s" then
            tapR(Keys.s)
        end
        if chacracter == "t" or chacracter == "5" then
            tapR(Keys.t)
        end
        if chacracter == "u" or chacracter == "7" then
            tapR(Keys.u)
        end
        if chacracter == "v" then
            tapR(Keys.v)
        end
        if chacracter == "w" or chacracter == "2" then
            tapR(Keys.w)
        end
        if chacracter == "x" then
            tapR(Keys.x)
        end
        if chacracter == "y" or chacracter == "6" then
            tapR(Keys.y)
        end
        if chacracter == "z" then
            tapR(Keys.z)
        end
        if chacracter == " " then
            tapR(Keys.space)
        end
        if chacracter == "/" then
            tapR(Keys.enter)
        end
        if chacracter == ":" then
            tapR(Keys.shift)
        end
        if chacracter == "," then
            tapR(Keys.number)
        end

    end
end
function tapNumber(string)
    for chacracter in string:gmatch "." do
        if chacracter == "1" then
            tapR(Keys.number1)
        end
        if chacracter == "2" then
            tapR(Keys.number2)
        end
        if chacracter == "3" then
            tapR(Keys.number3)
        end
        if chacracter == "4" then
            tapR(Keys.number4)
        end
        if chacracter == "5" then
            tapR(Keys.number5)
        end
        if chacracter == "6" then
            tapR(Keys.number6)
        end
        if chacracter == "7" then
            tapR(Keys.number7)
        end
        if chacracter == "8" then
            tapR(Keys.number8)
        end
        if chacracter == "9" then
            tapR(Keys.number9)
        end
        if chacracter == "0" then
            tapR(Keys.number0)
        end
    end
end

local Config = {}

-- Scroll size, represents height of the item in game scroll list
Config.scrollSize = 86;

-- Delays

-- The in-game animation delay in microseconds, should be the same on all devices
-- Don't relay on animations, because sometime it may be laggy, rather check if pixel
-- is presented
Config.animationDelay = 500000;
-- Scrolling touch delay
Config.scrollTouchDelay = 150000;
-- Delay for button tap
Config.tapDelay = 150000;
-- Delat for action that generates experience points
Config.XPAnimationDelay = 2000000;
-- Delay for tap tapButton
Config.tapDelayRandom = math.random(150000, 1000000)
----------------------------------------------- Config.btn*
-- Config.btnSignIn = Pixel.new(350, 1201, 1733608)
-- Config.btnChooseGoogleMail = Pixel.new(178, 420, 2105636)
-- Config.btnContinueEmail = Pixel.new(507, 786, 31487)
-- Config.btnCreateAccount = Pixel.new(68, 840, 1733608)
-- Config.btnForMyself = Pixel.new(126, 940, 8947848)
-- Config.btnTapFirstName = Pixel.new(147, 571, 6251368)
-- Config.btnTapLastName = Pixel.new(76, 627, 6251368)
-- Config.btnNextName = Pixel.new(629, 626, 1733608)
-- Config.btnTapMonth = Pixel.new(95, 572, 6251368)
-- Config.scrollMonth = Location.new(360, 1222)
-- Config.btnTapDate = Pixel.new(326, 564, 6251368)
-- Config.btnTapYear = Pixel.new(551, 507, 6711919)
-- Config.btnTapGender = Pixel.new(93, 650, 6251368)
-- Config.btnTapDoneGender = Pixel.new(686,863,31487)
-- Config.btnTapth1Mail = Pixel.new(310,924,6251368)
-- Config.btnTapNext = Pixel.new(631, 877, 1733608)
-- Config.btnTapDonePassword = Pixel.new(686,775,31487)
-- Config.btnTapNextFinishPassword = Pixel.new(619, 850, 1733608)

-- ---------------------------------------------

-- Config.btnCreateMail1 = Pixel.new(80, 774, 6251368)
-- Config.btnCreateMail2 = Pixel.new(132, 616, 6251368)

-- Config.btnNextNameMail = Pixel.new(575, 651, 1733608)
-- Config.btnTapPassword = Pixel.new(96, 617, 6317161)

---------------------------------------------------
------------------------------------------------------------
---------------------------------------------------------------------------
--- Scrolls the screen in a certain direction at some speed, with the option to repeat the scrolling 
function scroll(dir, speed, repeats)
    if repeats <= 0 then
        return
    end

    wid, hyt = getScreenSize()

    if speed == nil then
        speed = 3
    elseif speed > 5 then
        speed = 5
    elseif speed < 1 then
        speed = 1
    end

    if dir:sub(1, 1):lower() == "d" then
        dir = "d"
    elseif dir:sub(1, 1):lower() == "u" then
        dir = "u"
    elseif dir:sub(1, 1):lower() == "l" then
        dir = "l"
    elseif dir:sub(1, 1):lower() == "r" then
        dir = "r"
    else
        alert("Cant parse your inputted direction of: " .. dir .. ". Aborting.")
        return
    end

    startX = wid / 2;
    startY = hyt / 2;
    finX = wid / 2;
    finY = hyt / 2;
    step = 0;

    if dir == "d" then
        startY = hyt * 0.9
        finY = hyt * 0.1
        step = -1
    elseif dir == "u" then
        startY = hyt * 0.1
        finY = hyt * 0.9
        step = 1
    elseif dir == "l" then
        startX = wid * 0.1
        finX = wid * 0.9
        step = 1
    else
        startX = wid * 0.9
        finX = wid * 0.1
        step = -1
    end

    local modSpeed = speed ^ 2
    step = step * modSpeed

    touchDown(0, startX, startY)
    usleep(60000)
    if dir == "u" or dir == "d" then
        for p = startY, finY, step do
            touchMove(0, startX, p)
            usleep(16000)
        end
    else
        for p = startX, finX, step do
            touchMove(0, p, startY)
            usleep(16000)
        end
    end
    touchUp(0, finX, finY)
    if repeats > 1 then
        usleep(250000)
        scroll(dir, speed, repeats - 1)
    end
end

Config.isTimedout = 0

function waitForPixel(timeout, pixel)
    local wait = 1;
    local waitingTime = 0;
    local result = 1;

    while (wait == 1) do
        if (hasPixel(pixel) == 1) then
            wait = 0;
            usleep(100000); -- 0.1
        else
            waitingTime = waitingTime + 1;
            if (timeout > 0 and waitingTime > timeout * 10) then
                wait = 0;
                main();
                --                error("Timedout")
            else
                usleep(100000); -- 0.1
            end
        end
    end
    return result;
end

function waitForPixels(timeout, ...)
    local wait = 1;
    local waitingTime = 0;
    local result = 1;

    -- if (hasPixels(...) == 1) then
    --     alert("Founded")
    -- end
    while (wait == 1) do
        if (hasPixels(...) == 1) then
            wait = 0;
            usleep(100000); -- 0.1
        else
            waitingTime = waitingTime + 1;
            if (timeout > 0 and waitingTime > timeout * 10) then
                wait = 0;
                main();
                --               error("Timedout")
            else
                usleep(100000); -- 0.1
            end
        end
    end
    return result;
end

function tapR(rect)
    local width = rect.x2 - rect.x1;
    local height = rect.y2 - rect.y1;
    if (width < 0 or height < 0) then
        return nil
    end
    local location = Location.new(rect.x1 + math.random(0, width), rect.y1 + math.random(0, height));
    tapButton(location)
    -- alert(location.x .. " and " .. location.y);
    -- return location;
end

function tapWR(rect, timeout, ...)
    if (waitForPixels(timeout, ...) == 1) then
        tapR(rect);
    end
end

function hasPixel(pixel)
    if (getColor(pixel.x, pixel.y) == pixel.color) then
        return 1;
    else
        return 0;
    end
end
function hasPixels(...)
    local result = 1;
    local pixels = {...}
    for i = 1, #pixels, 1 do
        local isFound = hasPixel(pixels[i]);
        if isFound == 1 then
            return result;
        end
    end
    return 0;
end

-- Tap button and wait for animation
function tapButton(location)
    if (location == nil) then
        return
    end
    touchDown(4, location.x, location.y);
    usleep(Config.tapDelay);
    touchUp(4, location.x, location.y);
    usleep(Config.animationDelay);
end

function ssleep(time, message)

    local message = string.format("Waiting %ds for\n%s\nsince\n%s", time, message, os.date());
    for i = 1, time do
        if (time > 9 and i == 3) then
            alert(message);
        end
        usleep(1000000);
        if (time > 9 and i == time - 5) then
            tapButton(Config.ssleepDialogCloseButtonLocation);
        end
    end

end

-- Scroll the list up
function scrollUp(location, x)
    for i = 1, x, 1 do
        touchDown(7, location.x, location.y);
        usleep(Config.scrollTouchDelay);
        touchMove(7, location.x, location.y + Config.scrollSize);
        usleep(Config.scrollTouchDelay);
        touchUp(7, location.x, location.y + Config.scrollSize);
        usleep(Config.scrollTouchDelay);
        touchDown(7, location.x, location.y);
        usleep(Config.scrollTouchDelay);
        touchUp(7, location.x, location.y);
        usleep(Config.scrollTouchDelay);
    end

end

-- Scroll the list down
function scrollDown(location, x)
    for i = 1, x, 1 do
        touchDown(3, location.x, location.y);
        usleep(Config.scrollTouchDelay);
        touchMove(3, location.x, location.y - Config.scrollSize);
        usleep(Config.scrollTouchDelay);
        touchUp(3, location.x, location.y - Config.scrollSize);
        usleep(Config.scrollTouchDelay);
        touchDown(7, location.x, location.y);
        usleep(Config.scrollTouchDelay);
        touchUp(7, location.x, location.y);
        usleep(Config.scrollTouchDelay);
    end
end

function testError()
    local i = 9;
    if (i > 10) then
        error("errorz")
    end
end

function executeCommands(command)
    local process = io.popen(command)
    local lastline
    for line in process:lines() do
        lastline = line
    end
end
function touchDownR(rect)
    local width = rect.x2 - rect.x1;
    local height = rect.y2 - rect.y1;
    if (width < 0 or height < 0) then
        return nil
    end
    local location = Location.new(rect.x1 + math.random(0, width), rect.y1 + math.random(0, height));
    touchDown(3, location.x, location.y)

end
local offset = {};
offset.x = 10;
offset.y = 5;

function randomLocationWithOffset(location)
    return Location.new(location.x + math.random(0, offset.x), location.y + math.random(0, offset.y));
end
function randomSleep()
    return math.random(10000, 300000)
end
function touchRandomMove(randomLocation)
    local newLocation = randomLocationWithOffset(randomLocation);
    touchMove(1, newLocation.x, newLocation.y)
    usleep(randomSleep());
end

function pxTouchDown(rect)
    local width = rect.x2 - rect.x1;
    local height = rect.y2 - rect.y1;
    if (width < 0 or height < 0) then
        return nil
    end
    local randomLocation = Location.new(rect.x1 + math.random(0, width), rect.y1 + math.random(0, height));
    touchDown(1, randomLocation.x, randomLocation.y);
    usleep(randomSleep());

    while (waitForPixel(7, Pixel.new(659, 545, 3750201)) ~= 1) do
        touchRandomMove(randomLocation);
        usleep(randomSleep());
    end

    usleep(math.random(1500000, 1800000));
    touchUp(1, randomLocation.x, randomLocation.y)
    usleep(randomSleep())
    tap(1, randomLocation.x + 3, randomLocation.y + 4)
    -- touchUp(1,randomLocation.x + 3,randomLocation.y+4)

end
function tap(x, y)
    touchDown(0, x, y);
    usleep(16000);
    touchUp(0, x, y);
end

function isReachable()
    local body = http.request("https://randomuser.me/api/?inc=gender,name,nat,email,dob,login&nat=us")
    if (body == nil) then
        return false
    else
        return true
    end
end

function waitUntilReachable()
    local a = 1;
    while isReachable() == false do
        usleep(1000000)
        a = a + 1;
        if (a > 30) then
            main();
        end
    end
end

function randomIPUS()
    local ipus1 = (readFile(rootDir() .. "/ListIPUS.txt")[math.random(1, tablelength(
        readFile(rootDir() .. "/ListIPUS.txt")))])
    local ipus2 = ipus1 .. "." .. tostring(math.random(2, 245));
    return ipus2

end
function printTable(list, i)

    local listString = ''
    -- ~ begin of the list so write the {
    if not i then
        listString = listString .. '{'
    end

    i = i or 1
    local element = list[i]

    -- ~ it may be the end of the list
    if not element then
        return listString .. '}'
    end
    -- ~ if the element is a list too call it recursively
    if (type(element) == 'table') then
        listString = listString .. printTable(element)
    else
        listString = listString .. element
    end

    return listString .. ', ' .. printTable(list, i + 1)

end

-- function fakeDevice(country)
--     local file = assert(io.popen('/usr/bin/LinhVu fake device', 'r'))
--     local output = file:read('*all')
--     file:close()
--     local tblOutput = split(output, "|")
--     if (tblOutput[2] == country) then
--         return 1
--     else
--         fakeDevice(country)
--     end

-- end
-------------codemoi------------------
-----------------------------------

function pTouchDown(x, y)
    executeCommands("/usr/bin/LinhVu touch down " .. math.floor(x / 2) .. " " .. math.floor(y / 2))
end
function pTouchUp(x, y)
    executeCommands("/usr/bin/LinhVu touch up " .. math.floor(x / 2) .. " " .. math.floor(y / 2))
end

function pTouchMove(x, y)
    executeCommands("/usr/bin/LinhVu touch move " .. math.floor(x / 2) .. " " .. math.floor(y / 2))
end
function pTapButton(location)
    if (location == nil) then
        return
    end
    pTouchDown(location.x, location.y);
    usleep(Config.tapDelay);
    pTouchUp(location.x, location.y);
    usleep(Config.animationDelay);
end

function pTapR(rect)
    local width = rect.x2 - rect.x1;
    local height = rect.y2 - rect.y1;
    if (width < 0 or height < 0) then
        return nil
    end
    local location = Location.new(rect.x1 + math.random(0, width), rect.y1 + math.random(0, height));
    pTapButton(location)
end

function pTouchDownR(rect)
    local width = rect.x2 - rect.x1;
    local height = rect.y2 - rect.y1;
    if (width < 0 or height < 0) then
        return nil
    end
    local location = Location.new(rect.x1 + math.random(0, width), rect.y1 + math.random(0, height));
    -- pTouchDown(location.x, location.y)
end

function pTouchMoveR(rect)
    local width = rect.x2 - rect.x1;
    local height = rect.y2 - rect.y1;
    if (width < 0 or height < 0) then
        return nil
    end
    local location = Location.new(rect.x1 + math.random(0, width), rect.y1 + math.random(0, height));
    pTouchMove(location.x, location.y)
    usleep(math.random(300000, 1200000));
    pTouchMove(location.x, location.y)
    return location;

end

function pCaptCha()
    waitForPixel(7, Pixel.new(384, 541, 5197647))
    -- pTouchDownR(Rect.new(150, 467, 625, 603))
    -- pTouchMoveR(Rect.new(150, 467, 625, 603))
    -- waitForPixel(7, Pixel.new(340, 549, 7303023))
    -- usleep(math.random(300000, 1200000))
    -- local upPosition = pTouchMoveR(Rect.new(150, 467, 625, 603))
    -- pTouchUp(upPosition.x, upPosition.y);
    pTouchDownR(Rect.new(150, 467, 625, 603))
    pTouchMoveR(Rect.new(150, 467, 625, 603))
    pTouchDownR(Rect.new(150, 467, 625, 603))
    pTouchMoveR(Rect.new(150, 467, 625, 603))
    pTouchDownR(Rect.new(150, 467, 625, 603))
    pTouchMoveR(Rect.new(150, 467, 625, 603))
    pTouchDownR(Rect.new(150, 467, 625, 603))
    pTouchDownR(Rect.new(150, 467, 625, 603))
    pTouchMoveR(Rect.new(150, 467, 625, 603))
    pTouchDownR(Rect.new(150, 467, 625, 603))
    pTouchMoveR(Rect.new(150, 467, 625, 603))
    pTouchDownR(Rect.new(150, 467, 625, 603))
    pTouchMoveR(Rect.new(150, 467, 625, 603))
    pTouchDownR(Rect.new(150, 467, 625, 603))
    pTouchMoveR(Rect.new(150, 467, 625, 603))
    pTouchDownR(Rect.new(150, 467, 625, 603))
    pTouchMoveR(Rect.new(150, 467, 625, 603))
    -- pTouchMoveR(Rect.new(150,467,625,603))
    -- pTouchDownR(Rect.new(150,467,625,603))
    -- pTouchMoveR(Rect.new(150,467,625,603))
    -- pTouchMoveR(Rect.new(150,467,625,603))
    -- pTouchDownR(Rect.new(150,467,625,603))
    -- pTouchMoveR(Rect.new(150,467,625,603))
    -- pTouchDownR(Rect.new(150,467,625,603))
    -- pTouchDownR(Rect.new(150,467,625,603))  
    -- pTouchMoveR(Rect.new(150,467,625,603))
    -- pTouchDownR(Rect.new(150,467,625,603))
    -- pTouchMoveR(Rect.new(150,467,625,603))
    waitForPixel(20, Pixel.new(659, 547, 3750201))
    usleep(math.random(300000, 1200000))
    local upPosition = pTouchMoveR(Rect.new(150, 467, 625, 603))
    pTouchUp(upPosition.x, upPosition.y);

end
------------------------------- TEXTNOW FUNCTION

function goso(text)
    local chuoi_ky_tu = text
    local chuoi_ky_tu_len = string.len(chuoi_ky_tu) + 1
    repeat
        local ky_tu = tostring(string.sub(chuoi_ky_tu, 1, 1))
        if ky_tu == ("1") then
            usleep(150000)
            tap(129, 959)
            usleep(150000)
        end
        -- Check_Message_Error();
        if ky_tu == ("2") then
            usleep(150000)
            tap(373, 959)
            usleep(150000)
        end
        -- Check_Message_Error();
        if ky_tu == ("3") then
            usleep(150000)
            tap(627, 959)
            usleep(150000)
        end
        -- Check_Message_Error();
        if ky_tu == ("4") then
            usleep(150000)
            tap(129, 1065)
            usleep(150000)
        end
        -- Check_Message_Error();
        if ky_tu == ("5") then
            usleep(150000)
            tap(373, 1065)
            usleep(150000)
        end
        -- Check_Message_Error();
        if ky_tu == ("6") then
            usleep(150000)
            tap(627, 1065)
            usleep(150000)
        end
        -- Check_Message_Error();
        if ky_tu == ("7") then
            usleep(150000)
            tap(129, 1170)
            usleep(150000)
        end
        -- Check_Message_Error();
        if ky_tu == ("8") then
            usleep(150000)
            tap(373, 1170)
            usleep(150000)
        end
        -- Check_Message_Error();
        if ky_tu == ("9") then
            usleep(150000)
            tap(627, 1170)
            usleep(150000)
        end
        -- Check_Message_Error();
        if ky_tu == ("0") then
            usleep(150000)
            tap(377, 1285)
            usleep(150000)
        end
        -- Check_Message_Error();
        if ky_tu == ("") then
            break
        end
        usleep(100000)
        chuoi_ky_tu_len = chuoi_ky_tu_len - 1
        chuoi_ky_tu = string.sub(chuoi_ky_tu, 2, chuoi_ky_tu_len)
        -- Check_Message_Error();
        if chuoi_ky_tu_len == 0 then
            break
        end
    until 1 == 2
end

function Check_Message_Error()
    if (getColor(224, 807) == 31487 and getColor(269, 802) == 31487) then
        usleep(500000);
        tap(237, 804);
        usleep(1000);
    else
        usleep(1000);
    end

    if (getColor(339, 606) == 0 and getColor(405, 605) == 0 and getColor(381, 785) == 31487) then
        tap(381, 785)
    else
        usleep(100);
    end

end
local areaCodes = {201, 202, 203, 205, 206, 207, 208, 209, 210, 212, 213, 214, 215, 216, 217, 218, 219, 220, 223, 224,
                   201, 202, 203, 205, 206, 207, 208, 209, 210, 212, 213, 214, 215, 216, 217, 218, 219, 220, 223, 224,
                   225, 228, 229, 231, 234, 239, 240, 248, 251, 252, 253, 254, 256, 260, 262, 267, 269, 270, 272, 276,
                   279, 281, 301, 302, 303, 304, 305, 307, 308, 309, 310, 312, 313, 314, 315, 316, 317, 318, 319, 320,
                   321, 323, 325, 330, 331, 332, 334, 336, 337, 339, 346, 347, 351, 352, 360, 361, 364, 380, 385, 386,
                   401, 402, 404, 405, 406, 407, 408, 409, 410, 412, 413, 414, 415, 417, 419, 423, 424, 425, 430, 432,
                   434, 435, 440, 442, 443, 445, 458, 463, 469, 470, 475, 478, 479, 480, 484, 501, 502, 503, 504, 505,
                   507, 508, 509, 510, 512, 513, 515, 516, 517, 518, 520, 530, 531, 539, 540, 541, 551, 559, 561, 562,
                   563, 564, 567, 570, 571, 573, 574, 575, 580, 585, 586, 601, 602, 603, 605, 606, 607, 608, 609, 610,
                   612, 614, 615, 616, 617, 618, 619, 620, 623, 626, 628, 629, 630, 631, 636, 640, 641, 646, 650, 651,
                   657, 660, 661, 662, 667, 669, 678, 680, 681, 682, 701, 702, 703, 704, 706, 707, 708, 712, 713, 714,
                   715, 716, 717, 718, 719, 720, 724, 725, 726, 727, 731, 732, 734, 737, 740, 743, 747, 754, 757, 760,
                   762, 763, 765, 769, 770, 772, 773, 774, 775, 779, 781, 785, 786, 801, 802, 803, 804, 805, 806, 808,
                   810, 812, 813, 814, 815, 816, 817, 818, 820, 828, 830, 831, 832, 838, 843, 845, 847, 848, 850, 854,
                   856, 857, 858, 859, 860, 862, 863, 864, 865, 870, 872, 878, 901, 903, 904, 906, 907, 908, 909, 910,
                   912, 913, 914, 915, 916, 917, 918, 919, 920, 925, 928, 929, 930, 931, 934, 936, 937, 938, 940, 941,
                   947, 949, 951, 952, 954, 956, 970, 971, 972, 973, 978, 979, 980, 984, 985, 986, 989}
function getRandomAreaCodeUS()
    return areaCodes[math.random(1, #areaCodes)];
end

----------------------------------------------Config.*

Config.btnSignTextNow = Pixel.new(329, 989, 10979308)

Config.rectSignTextNow = Rect.new(289, 953, 448, 1025);

Config.btnTapUpMail = Pixel.new(365, 1043, 11447982)

Config.rectTapUpMail = Rect.new(238, 1016, 554, 1070)

Config.btnTapNameEmail = Pixel.new(82, 325, 13882325)

Config.rectTapNameEmail = Rect.new(40, 300, 108, 338)

Config.btnTapPassMail = Pixel.new(94, 401, 14408668)

Config.rectTapPassMail = Rect.new(39, 327, 152, 344)

Config.btnTapSignUp = Pixel.new(354, 675, 12165360)

Config.rectTapSignUp = Rect.new(230, 631, 512, 691)

Config.rectTapLogInTN = Rect.new(303, 565, 461, 627)

Config.rectTapLogin2 = Rect.new(330, 519, 419, 544)

Config.btnSomething = Rect.new(373, 784, 294143)

Config.rectTapSomething = Rect.new(314, 758, 448, 816)

Config.rectTapEndLogIn = Rect.new(260, 559, 517, 629)

Config.btnContinueEnd = Pixel.new(325, 1154, 7289568)

Config.rectTapContinueEnd = Rect.new(301, 1129, 449, 1133)

Config.rectTapContinuenNumberPhone = Rect.new(222, 629, 534, 701)

Config.rectTapQuanhcapcha = Rect.new(284, 787, 475, 856)
Config.rectTapQuanhcapcha2 = Rect.new(355, 830, 528, 864)
Config.btnContinueGetNumber = Pixel.new(397, 706, 6630622)

Config.rectContinueGetNumber = Rect.new(291, 680, 473, 773)

Config.btnTouchDown = Pixel.new(392, 553, 4276545)
Config.btnChosePhonemunber1 = Pixel.new(555, 656, 7961217)
Config.btnChosePhonemunber2 = Pixel.new(542, 737, 10855850)
Config.btnChosePhonemunber3 = Pixel.new(564, 828, 8421767)
Config.rectChosePhonemunber3 = Rect.new(160, 817, 185, 852)
Config.btnChosePhonemunber4 = Pixel.new(577, 923, 7105909)
Config.btnContinueTextNow = Pixel.new(325, 1173, 9068518)

Config.btnLogin = Pixel.new(549, 1110, 16711678)
Config.btnLoginWithEmail = Pixel.new(421, 1042, 0)
Config.inputEmail = Pixel.new(82, 326, 13882324)
Config.btnLoginTN = Pixel.new(363, 595, 9068518)

Config.rectBtnLogin = Rect.new(497, 1089, 599, 1125)
Config.rectLogin = Rect.new(549, 1110, 549, 1110)
Config.rectLoginWithEmail = Rect.new(228, 1020, 583, 1067)
Config.rectInputEmail = Rect.new(41, 301, 172, 336)
Config.rectBtnLogin = Rect.new(277, 561, 502, 635)
Config.SignUp2 = Rect.new(475, 727, 582, 761)
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Config.btnConversations = Pixel.new(427, 74, 4934475)
Config.btnConversations = Pixel.new(592, 85, 15856113) -- ghichu
Config.rectConversations = Rect.new(38, 71, 73, 94)
Config.btnSettingTextNow = Pixel.new(433, 258, 16603522)
Config.rectSettingTextNow = Rect.new(103, 888, 230, 926)
Config.btnLogOutTextNow = Pixel.new(380, 830, 6630622)
Config.rectLogOutTextNow = Rect.new(312, 836, 437, 878)
-- Config.btnConfirm = Pixel.new(421, 604, 2697513)
Config.btnConfirm = Pixel.new(515, 779, 31487)
-- Config.btnNotNow = Pixel.new(354, 1256, 31487)
Config.rectConfirm = Rect.new(448, 769, 573, 798)
-- elseif (getColor(515,779) == 31487 
-- and getColor(533,782) == 31487) 
-- getColor(354,1256) == 31487 
----------------------
------------------------
Config.btnSignUpTextnow = Pixel.new(355, 994, 8014050)
Config.rectSignUpTextnow = Rect.new(288, 955, 471, 1021)
Config.btnSignUpEmail = Pixel.new(91, 851, 3450963)
Config.rectSignUpEmail = Rect.new(246, 1012, 562, 1071)
Config.btnSignUpTextNow1 = Pixel.new(329, 664, 8080355)
Config.rectSignUpTextNow1 = Rect.new(282, 630, 463, 695)
Config.btnLogInTN2 = Pixel.new(375, 742, 13092807)
Config.rectLogInTN2 = Rect.new(521, 796, 587, 821)
Config.btnLogInTN3 = Pixel.new(373, 603, 9002470)
Config.rectLogInTN3 = Rect.new(318, 567, 453, 636)
----------------------

function getNewNumber()
    usleep(2000000)
    executeCommands("/usr/bin/LinhVu airplane YES");
    usleep(2000000)
    executeCommands("/usr/bin/LinhVu airplane NO");
    waitUntilReachable();
    usleep(3000000)
    tapR(Rect.new(605, 1259, 653, 1299))
    tapR(Rect.new(605, 1259, 653, 1299))
    tapR(Rect.new(605, 1259, 653, 1299))
    tapNumber(tostring(getRandomAreaCodeUS()));

end
function wCaptcha()
    usleep(math.random(4000000, 5000000))
    waitForPixel(20, Pixel.new(80, 552, 3750201))
    pTouchDownR(Rect.new(192, 532, 552, 555))
    pTouchMoveR(Rect.new(192, 532, 552, 555))
    waitForPixel(20, Pixel.new(659, 547, 3750201))
    usleep(math.random(300000, 1200000))
    local upPosition = pTouchMoveR(Rect.new(192, 532, 552, 555))
    pTouchUp(upPosition.x, upPosition.y);

end

function logout()
    waitForPixel(10, Config.btnConversations);
    tapR(Config.rectConversations)
    usleep(math.random(50000, 1000000))
    waitForPixel(10, Config.btnSettingTextNow);
    tapR(Config.rectSettingTextNow)
    usleep(2000000)
    scroll("d", 5, 3)
    usleep(2000000)
    waitForPixel(10, Config.btnLogOutTextNow);
    tapR(Config.rectLogOutTextNow)
    usleep(math.random(50000, 1000000))
    waitForPixel(15, Config.btnConfirm)
    tapR(Config.rectConfirm)
    usleep(2000000)

end
function pickNumber()
    usleep(2000000);
    if (getColor(354, 1256) == 31487 and getColor(438, 1257) == 31487) then
        usleep(500000);
        tap(365, 1263);
        usleep(500000);
    end
    if (waitForPixels(40, Pixel.new(495, 1177, 13087731), Pixel.new(568, 825, 10724520), Pixel.new(382, 799, 31487),
        Pixel.new(568, 825, 10855850)) == 1) then
        if (hasPixel(Pixel.new(495, 1177, 13087731)) == 1) then
            toast("TH1_nocode", 2);
            usleep(2000000);
            tapR(Rect.new(162, 733, 179, 746))
            usleep(1000000)
            waitForPixel(5, Pixel.new(338, 1164, 9595367));
            tapR(Rect.new(209, 1129, 500, 1185))
        elseif (hasPixel(Pixel.new(382, 799, 31487)) == 1) then
            toast("TH2", 2);
            tapR(Rect.new(213, 777, 494, 822));
            getNewNumber();
            usleep(1000000);
            tapR(Rect.new(163, 694, 567, 751))
            usleep(1000000);
            waitForPixel(10, Pixel.new(536, 830, 7105909))
            tapR(Rect.new(162, 733, 179, 746))
            usleep(1000000)
            waitForPixel(5, Pixel.new(338, 1164, 9595367));
            tapR(Rect.new(209, 1129, 500, 1185))
        elseif (hasPixel(Pixel.new(568, 825, 10724520)) == 1) then
            toast("TH3ak", 2);
            usleep(1000000);
            tapR(Rect.new(159, 819, 183, 841))
            usleep(1000000);
            waitForPixel(10, Pixel.new(352, 1183, 6630622));
            tapR(Rect.new(311, 1150, 439, 1183))
        elseif (hasPixel(Pixel.new(568, 825, 10855850)) == 1) then
            toast("TH4ak", 2);
            usleep(1000000);
            tapR(Rect.new(159, 819, 183, 841))
            usleep(1000000);
            waitForPixel(10, Pixel.new(352, 1183, 6630622));
            tapR(Rect.new(311, 1150, 439, 1183))
        end

    end

end
function postCookie()
    alert("Reg Ok ...>>> up server")
    stop()
end

function resign()
    logout();
    toast("Founded btnSignUpEmail");
    usleep(10000000)
    tapR(Config.rectSignUpEmail)
    toast("Tapped signup", 3)
    usleep(math.random(500000, 2000000))
    tapR(Rect.new(57, 304, 113, 342));
    usleep(math.random(50000, 1000000))
    inputText(getFullInfo("email") .. "@xtgem.com")
    tapString("/")
    usleep(math.random(50000, 1000000))
    tapR(Config.rectTapPassMail)
    usleep(math.random(50000, 1000000))
    tapString(getFullInfo("password"));
    usleep(math.random(50000, 1000000))
    waitForPixel(7, Pixel.new(353, 662, 6630622))
    tapR(Config.rectTapSignUp)
    usleep(math.random(9000000, 12000000))
    if (getColor(230, 154) == 4858019 and getColor(334, 133) == 4858019) then
        CaptCha_Cuchi()
        usleep(math.random(8000000, 12000000))
    end
    if (getColor(354, 1256) == 31487 and getColor(438, 1257) == 31487) then
        usleep(500000);
        tap(365, 1263);
        usleep(500000);
    end
    if (waitForPixels(20, Pixel.new(81, 548, 3750201), Pixel.new(374, 767, 31487), Pixel.new(495, 1177, 13087731),
        Pixel.new(568, 825, 10724520), Pixel.new(382, 799, 31487)) == 1) then
        if (hasPixel(Pixel.new(81, 548, 3750201)) == 1) then
            toast("Captcha 1");
            CaptCha_Cuchi()
            usleep(math.random(8000000, 12000000))
        elseif (hasPixel(Pixel.new(374, 767, 31487)) == 1) then
            toast("Catpcha 2");
            main()
        else

            toast("Go Next");
        end
    end
    usleep(math.random(2000000, 4000000))

    pickNumber();
    postCookie();
    resign();
end
function readall(file)

    f = io.open("/var/mobile/" .. file, "r");
    local line = f:read("all");
    f:close()
    return line
end

function tap_random(x, y)
    tap(x + math.random(1, 5), y + math.random(1, 5))
end
function CaptCha_Cuchi()
    usleep(math.random(2000000, 3000000))
    tap_random(704, 34)
    usleep(math.random(1000000, 2000000))
    tap_random(547, 231)
    usleep(math.random(2000000, 3000000))
    tap_random(385, 542)
    usleep(math.random(8000000, 10000000))
end
function main()
    -- waitUntilReachable();   -- check connect network
    --------------------------Begin wipe and fake
    toast("Wait Wipe", 1)
    appKill("com.tinginteractive.usms"); -- skill app
    usleep(3000000)
    toast("start Wipe")
    executeCommands("/usr/bin/LinhVu wipe com.tinginteractive.usms");
    toast("Wipe OK", 1)
    executeCommands("/usr/bin/LinhVu airplane YES"); -- of network
    usleep(2000000)
    executeCommands("/usr/bin/LinhVu airplane NO"); -- on network
    waitUntilReachable(); -- check connect network
    usleep(5000000)
    fakeDevice("US") -- fake ip
    usleep(3000000)
    appRun("com.tinginteractive.usms") -- open app text now
    --------------------------end wipe and fake
    --------------------------Begin REGTN
    usleep(3000000)
    tx_ran_tb = {"@smuvaj.com", "@yahoo.com", "@wawue.com", "@xtgem.com", "@orange.fr"} --
    domain = (tx_ran_tb[math.random(#tx_ran_tb)])
    local serial_may = getSN()
    phoneNumber = tostring(serial_may)

    userName = getFullInfo("email")

    email = userName .. domain

    passw = getFullInfo("password")

    toast("open app, --> tap login", 2)
    usleep(9000000) -- tgc 2
    -- tapWR(Config.rectLogin, 5, Config.btnLogin); -- tap login bi_sai_diem_mau
    toast("tap login", 2)
    usleep(math.random(1000000, 2000000))
    tap_random(532, 1106)
    -- tapWR(Config.rectLoginWithEmail, 5, Config.btnLoginWithEmail); -- tap id login
    toast("tap login with email", 2)
    usleep(math.random(1000000, 2000000))
    tap_random(448, 1043)
    usleep(math.random(1000000, 2000000))

    inputText(email) -- nhap ip login
    -- inputText("zenobiemitch1487515@xtgem.com") -- testing
    tapString("/")
    usleep(math.random(50000, 1000000))
    tapR(Config.rectTapPassMail)
    usleep(math.random(50000, 1000000))
    -- tapString(passw);
    tapString(passw)
    waitForPixel(10, Pixel.new(291, 537, 6630622))
    usleep(math.random(50000, 1000000))
    tapR(Config.rectTapLogin2)
    usleep(math.random(5000000, 7000000))
    wCaptcha();

    usleep(500000);

    usleep(math.random(8000000, 12000000))
    usleep(math.random(5000000, 10000000))

    tap_random(525, 676) -- tap singin
    usleep(math.random(1000000, 2000000))
    tap_random(40, 255) -- tap email
    usleep(math.random(1000000, 2000000))
    inputText(email)
    usleep(math.random(1000000, 2000000))
    tap_random(46, 355) -- tap passw
    usleep(math.random(1000000, 2000000))
    inputText(passw)
    usleep(math.random(1000000, 2000000))
    tap_random(318, 610) -- tap signup
    usleep(math.random(5000000, 7000000))
    if (getColor(230, 154) == 4858019 and getColor(334, 133) == 4858019) then

        CaptCha_Cuchi()
        usleep(math.random(1000000, 2000000))
    end

    toast("check script...", 10)
    usleep(10000000)
    -- waitForPixel(15, Pixel.new(373, 784, 294143))
    -- tapR(Config.rectTapSomething);
    -- tap_random(533,744) -- tap signup
    -- usleep(math.random(1000000, 2000000))
    -- --usleep(math.random(50000, 1000000))
    -- tapR(Config.rectLogInTN2)
    -- usleep(math.random(50000, 1000000))
    -- -- inputText(getFullInfo("password"))
    -- --tapString(passw);
    -- inputText(passw)
    -- usleep(math.random(50000, 1000000))
    -- --tapWR(Config.rectLogInTN3, 5, Config.btnLogInTN3);
    -- --wCaptcha(); -- bam capcha L2
    -- tap_random(380,600) -- tap oki login
    -- usleep(math.random(10000000, 15000000))
    -- CaptCha_Cuchi()

    -- usleep(math.random(500000, 1000000))  --- REGTN
    -- --waitForPixel(7, Pixel.new(373, 784, 294143))
    -- --tapR(Config.rectTapSomething);
    -- --tap_random(533,744) -- tap singinup L2
    -- usleep(math.random(50000, 1000000))
    -- --tapR(Config.rectLogInTN2)
    -- usleep(math.random(50000, 1000000))
    -- -- inputText(getFullInfo("password"))
    -- --tapString(passw);
    -- inputText(passw)
    -- --tapWR(Config.rectLogInTN3, 5, Config.btnLogInTN3);
    -- --wCaptcha();
    -- --waitForPixel(15, Pixel.new(274, 482, 16741741))
    -- --tapR(Config.SignUp2)
    -- usleep(math.random(50000, 1000000))
    -- inputText(email)
    -- tapString("/")
    -- usleep(math.random(50000, 1000000))
    -- --tapR(Config.rectTapPassMail)
    -- usleep(math.random(50000, 1000000))
    -- inputText(passw)
    -- usleep(math.random(50000, 1000000))
    -- --waitForPixel(7, Pixel.new(353, 662, 6630622))
    -- --tapR(Config.rectTapSignUp)
    -- usleep(math.random(1000000, 4000000))
    --------------------------End REGTN -> pick_number
    pickNumber();
    for i = 10, 1, -1 do
        toast("Wait Post Cookie " .. i);
        executeCommands("/usr/bin/LinhVu getCookieTN")
        if file_exists("/var/mobile/apiv2") then
            local f = io.popen("mv var/mobile/apiv2 var/mobile/apiv2.txt", "r")
            f:close()
            dataget = readall("apiv2.txt");
            toast(dataget, 3)
            usleep(3000000)
            toast(
                "Men:" .. phoneNumber .. "|id:" .. userName .. "|mail:" .. email .. "|Pass:" .. passw .. "|Cookie:" ..
                    dataget, 3)
            usleep(3000000);
            local data = {
                phoneNumber = phoneNumber,
                userName = userName,
                email = email,
                password = passw,
                cookie = dataget
            }
            local cURL = require "cURL"
            local ltn12 = require("ltn12")
            local http = require("socket.http")
            http.TIMEOUT = 15;
            local json = require "json"
            reqbody = json.encode(data)
            local respbody = {}

            -- Testing so luong account tren thoi gian
            local result, respcode, respheaders, respstatus = http.request {
                url = "https://api-textnow.otp123.com/public-api/v1/text-now/create", -- server post ok
                method = "POST",
                source = ltn12.source.string(reqbody),
                headers = {
                    ["content-type"] = "application/json",
                    ["content-length"] = tostring(#reqbody)
                },
                sink = ltn12.sink.table(respbody)
            }
            toast(respbody[1], 3);
            local cURL = require "cURL"
            -- local json = require "json"
            if (respbody[1]) == '{"status":200,"msg":"success"}' then
                TG = os.date("%H") .. ':' .. os.date("%M") .. ' ' .. os.date("%d") .. '/' .. os.date("%m")
                file = io.open(rootDir() .. "/TextNow.txt", "a+"); -- mở 1 thư mục với quyền ghi file.
                -- file:write(string.format("%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n",TG,Time_over_Sig,dausous,testrefresh,sophone,zonetime,usernameIOS,mail,passw,dataget)) -- viêt vào file vừa mở trước đó
                file:write(string.format("%s|%s|%s|%s|%s|%s\n", TG, phoneNumber, userName, email, passw, dataget)) -- viêt vào file vừa mở trước đó
                file:close() -- đóng file
                toast("Post Ok", 3)
                usleep(3000000)
                -- solanpost = solanpost + 1
                -- solanerror = 0
                -- testREGTN = "Post OK"..email
                -- toast("R_"..solanreg.." E_"..solanerror.." P_"..solanpost.." C_"..solancookie.." Z_"..string.sub(zonetime,1,6).." ..."..Time_over_Sig.."    "..iptaget);
                -- toast("R_"..solanreg.." E_"..solanerror.." P_"..solanpost.." C_"..solancookie.." TZ_"..zonetime.."_4G "..testrefresh.." Air: "..testairplane.." "..testIP.." : "..iptaget.." Area : "..dausous.."  Post OK... "..dataget,10) 
                usleep(1000000)
                break
                i = 1
            else
                -- playAudio(rootDir()..'/LGHA.mp3', 0) 
                -- for j=1,10 do
                --   toast("POST NO "..testupserver.." reload : "..j.." Cookie : "..mail) 
                toast("Post No", 3)
                usleep(3000000)
                -- end
            end
            usleep(1000000)
        end
        --------------------------Begin Post

        -- resign();
        main()
    end
end
main();