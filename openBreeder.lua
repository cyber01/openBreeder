-- (c) Max K https://github.com/asgmax


local component = require("component")
local computer = require("computer")
local term = require("term")
local event = require("event")
local gpu = component.gpu
local serialization = require("serialization")
local unicode = require("unicode")
--local chat = component.chat_box
--chat.setName("§fL§7")

-- getItems - ident, getAvailableItems - fingerprint(nbt)

local const = {
	strongPrincessCount = 3, -- >=
	strongCount = 10,
	strongCountRoof = 15,
	trashInterface = component.proxy("3292e570-c9b4-47b2-a943-33c79d7af1e4"),
	analyzerInterface = component.proxy("dd4b88b9-1baa-42c7-835a-02168c1b209e"),
	analyzerChestSide = "NORTH", -- relative to analyzerInterface
	exportSide = "WEST", -- side to export for test purposes
	houseSide = "SOUTH", -- side of apiary (relative to interface)
	trashSide = "WEST", -- side of chest (relative to intTrash (trashing interface)) to drop notNatural princesses
}

local int = {
	[1] = component.proxy("ce354e25-a660-409a-bb73-eacab2d0ba88"),
}

local apiary = {
	[1] = component.proxy("70b9944d-837c-462f-a438-965ec9a5ede9"),
}

--function say(text) component.chat_box.say("§bBee Master§7: " .. text) end

function isBee(table) if table.individual then return true else return false end end
function isNatural(table) if table.individual.isNatural == true then return true else return false end end
function isAnalyzed(table) if table.individual.isAnalyzed == true then return true else return false end end
function isDrone(table) if string.find(table.label,"Drone") then return true else return false end end
function isPrincess(table) if string.find(table.label,"Princess") then return true else return false end end
function isQueen(table) if string.find(table.label,"Queen") then return true else return false end end
function isPure(table) if table.individual.isAnalyzed and table.individual.active.species == table.individual.inactive.species then return true else return false end end
function isUnpure(table) if table.individual.isAnalyzed and table.individual.active.species ~= table.individual.inactive.species then return true else return false end end
function isSpecie(table,specie) if string.lower(specie) == string.lower(table.individual.displayName) then return true else return false end end
function isAl1(table,specie) if string.lower(specie) == string.lower(table.individual.active.species) then return true else return false end end
function isAl2(table,specie) if string.lower(specie) == string.lower(table.individual.inactive.species) then return true else return false end end

function isAlx(table,specie) if string.lower(specie) == string.lower(table.individual.active.species) or string.lower(specie) == string.lower(table.individual.inactive.species) then return true else return false end end
function isPureSpec(table,specie) if string.lower(specie) == string.lower(table.individual.active.species) and string.lower(specie) == string.lower(table.individual.inactive.species) then return true else return false end end

function isVanilla(table) if isSpecie(table,"meadows") or isSpecie(table,"forest") then return true else return false end end
function canFind(string1,string2) if string.find(string1,string2) then return true else return false end end

function totalBeesCount()
	local ti = int[1].getItemsInNetwork()
	local ta = int[1].getAvailableItems()
	local count = 0
	for i in ipairs(ti) do
		if isBee(ti[i]) then
			count = count + ti[i].size
		end
	end
	return count
end

function removeUnnatural()
	local ti = int[1].getItemsInNetwork()
	local ta = int[1].getAvailableItems()
	local totalExported = 0
	for i in ipairs(ti) do
		if isBee(ti[i]) and not isNatural(ti[i]) then
			local toexport = ti[i].size
			repeat
				local exported = const.trashInterface.exportItem(ta[i].fingerprint,const.trashSide,toexport)
				toexport = toexport - exported.size
				totalExported = totalExported + exported.size
			until toexport == 0
		end
	end
	io.write("removeUnnatural() - removed " .. totalExported .. " \n")
end

function clearNetwork()
	local ti = int[1].getItemsInNetwork()
	local ta = int[1].getAvailableItems()
	local totalExported = 0
	for i in ipairs(ti) do
		if isBee(ti[i]) then
			local toexport = ti[i].size
			repeat
				local exported = const.trashInterface.exportItem(ta[i].fingerprint,const.trashSide,toexport)
				toexport = toexport - exported.size
				totalExported = totalExported + exported.size
			until toexport == 0
		end
	end
	io.write("clearNetwork() - removed " .. totalExported .. " \n")
end

function isApiaryFree(num)
	for i = 1,9 do
		if apiary[num].getStackInSlot(i) then
			return false
		end
	end
	return true
end

function waitForApiary(num)
	
	io.write("waitForApiary(" .. num .. ") ")
	if isApiaryFree(num) ~= true then
		repeat
			io.write(". ")
			os.sleep(3)
		until isApiaryFree(num) == true
			io.write(" \n")
	else
		io.write("waitForApiary(" .. num .. ") - is free \n" )
	end
end

function waitForAnalyze()
	local count1 = totalBeesCount()
	local a = analyzeAll()
	if a ~= false then
		io.write("waitForAnalyze() - analyzing ")
		repeat
			io.write(" .")
			os.sleep(5)
		until totalBeesCount() == count1
		io.write("\nwaitForAnalyze() - analysis finished\n")
	else
		io.write("waitForAnalyze() - nothing to analyze\n")
	end
end

function analyze(table) -- ta[i]
	local toexport = const.analyzerInterface.getItemDetail(table.fingerprint).basic().qty
	local sent = 0
	repeat
		local exported = const.analyzerInterface.exportItem(table.fingerprint,const.analyzerChestSide,toexport)
		toexport = toexport - exported.size
		sent = sent + exported.size
	until toexport == 0
	return sent
end

function analyzeAll()
	local ti = int[1].getItemsInNetwork()
	local ta = int[1].getAvailableItems()
	local unknownStacks = 0
	local knownStacks = 0
	local beesSent = 0
	local knownBees = 0
	for i in ipairs(ti) do
		if isBee(ti[i]) then
			if not isAnalyzed(ti[i]) then
				unknownStacks = unknownStacks + 1
				beesSent = beesSent + analyze(ta[i])
			else
				knownStacks = knownStacks + 1
				knownBees = knownBees + ti[i].size
			end
		end
	end
	io.write("analyzeAll() - known: " .. knownBees .. " bees (" .. knownStacks .. " stacks), being analyzed: " .. beesSent .. " bees (" .. unknownStacks .. " stacks) \n")
	if unknownStacks == 0 then
		return false
	end
end

function isType(table,type) -- "drone" or "princess" or "queen"
	if string.lower(type) == "drone" then
		return isDrone(table)
	elseif string.lower(type) == "princess" then
		return isPrincess(table)
	elseif string.lower(type) == "queen" then
		return isQueen(table)
	else
		io.write("isType() - incorrect argument " .. tostring(type) .. " \n")
	end
end

function isPurity(table,purity)
	if string.lower(purity) == "pure" then
		return isPure(table)
	elseif string.lower(purity) == "unpure" then
		return isUnpure(table)
	else
		io.write("isPurity() - incorrect argument " .. tostring(purity) .. " \n")
	end
end

function countPrincess(al1,al2)
	local ti = int[1].getItemsInNetwork()
	local ta = int[1].getAvailableItems()
	local count = 0
	for i in ipairs(ti) do
		if isBee(ti[i]) and isAnalyzed(ti[i]) and isPrincess(ti[i]) then
			if al1check(ti[i],al1) and al2check(ti[i],al2) then
				count = count + ti[i].size
			end
		end
	end
	io.write("countPrincess() - " .. tostring(al1) .. "/" .. tostring(al2) .. " - " .. count .. "\n")
	return count
end

function countDrone(al1,al2)
	local ti = int[1].getItemsInNetwork()
	local ta = int[1].getAvailableItems()
	local count = 0
	for i in ipairs(ti) do
		if isBee(ti[i]) and isAnalyzed(ti[i]) and isDrone(ti[i]) then
			if al1check(ti[i],al1) and al2check(ti[i],al2) then
				count = count + ti[i].size
			end
		end
	end
	io.write("countDrone() - " .. tostring(al1) .. "/" .. tostring(al2) .. " - " .. count .. "\n")
	return count
end



function al1check(table,al1)
	if al1 then
		if string.lower(al1) == string.lower(table.individual.active.species) then
			return true
		else
			return false
		end
	else
		return true
	end
end

function al2check(table,al2)
	if al2 then
		if string.lower(al2) == string.lower(table.individual.inactive.species) then
			return true
		else
			return false
		end
	else
		return true
	end
end


function move(interface,side,table,number) -- table = ta[i] ONLY
	local toexport = math.min(number or 1,table.size)
	local totalExported = 0
	repeat
		local exported = int[interface].exportItem(table.fingerprint,side,toexport)
		toexport = toexport - exported.size
		totalExported = totalExported + exported.size
	until toexport == 0
	io.write("move() - moved:" .. totalExported .. ", int:" .. interface .. ", side:" .. side .. ", " .. table.fingerprint.id .. ":" .. table.fingerprint.dmg .. " \n")
	return totalExported 
end

function house1(table)
	move(1,const.houseSide,table,1)
end

function getParents(spec)
	if string.lower(spec) == "common" then
		return "forest","meadows"
	elseif string.lower(spec) == "cultivated" then
		return "common","forest"
	else
		local t = apiary[1].getBeeParents(spec)
		local par1 = t[1].allele1.name
		local par2 = t[1].allele2.name
		return par1, par2
	end
end

function GET(purity,type,spec) -- RETURNS ta[i], ("pure","princess","common") or ("unpure","drone","meadows"), pure means al1 == al2
	local ti = int[1].getItemsInNetwork()
	local ta = int[1].getAvailableItems()
	local count = 0
	local tai
	local speed = 0
	for i in ipairs(ti) do
		if isBee(ti[i]) and isAnalyzed(ti[i]) then
			if isType(ti[i],type) and isPurity(ti[i],purity) and isAlx(ti[i],spec) then
				count = count + ti[i].size
				if ti[i].individual.active.speed + ti[i].individual.inactive.speed > speed then
					speed = ti[i].individual.active.speed + ti[i].individual.inactive.speed
					tai = ta[i]
				end
			end
		end
	end
	io.write("GET() - " .. purity .. " " .. type .. " " .. spec .. " - found " .. count .. " (returned avg speed: " .. speed/2 .. ") \n")
	return count, tai
end

function GET1(type,spec1,spec2) -- RETURNS ta[i], gets only bees with BOTH spec genes present
	local ti = int[1].getItemsInNetwork()
	local ta = int[1].getAvailableItems()
	local count = 0
	local tai
	local speed = 0
	for i in ipairs(ti) do
		if isBee(ti[i]) and isAnalyzed(ti[i]) then
			if isType(ti[i],type) and isAlx(ti[i],spec1) and isAlx(ti[i],spec2) then
				count = count + ti[i].size
				if ti[i].individual.active.speed + ti[i].individual.inactive.speed > speed then
					speed = ti[i].individual.active.speed + ti[i].individual.inactive.speed
					tai = ta[i]
				end
			end
		end
	end
	io.write("GET1() - " .. type .. " " .. spec1 .. "+" .. spec2 .. " - found " .. count .. " (returned avg speed: " .. speed/2 .. ") \n")
	return count, tai
end

function GET3(type,spec) -- RETURNS ta[i], counts bees of TYPE and at least 1 of genes SPEC
	local ti = int[1].getItemsInNetwork()
	local ta = int[1].getAvailableItems()
	local count = 0
	local tai
	local speed = 0
	for i in ipairs(ti) do
		if isBee(ti[i]) and isAnalyzed(ti[i]) then
			if isType(ti[i],type) and isAlx(ti[i],spec) then
				count = count + ti[i].size
				if ti[i].individual.active.speed + ti[i].individual.inactive.speed > speed then
					speed = ti[i].individual.active.speed + ti[i].individual.inactive.speed
					tai = ta[i]
				end
			end
		end
	end
	io.write("GET3() - found " .. count .. " " .. spec .. " " .. type .. " \n")
	return count, tai
end

function GET4(purity,type) -- RETURNS ta[i],
	local ti = int[1].getItemsInNetwork()
	local ta = int[1].getAvailableItems()
	local count = 0
	local tai
	local speed = 0
	local reportedSpecs
	for i in ipairs(ti) do
		if isBee(ti[i]) and isAnalyzed(ti[i]) then
			if isType(ti[i],type) and isPurity(ti[i],purity) then
				count = count + ti[i].size
				if ti[i].individual.active.speed + ti[i].individual.inactive.speed > speed then
					speed = ti[i].individual.active.speed + ti[i].individual.inactive.speed
					reportedSpecs = ti[i].individual.active.species .. "/" .. ti[i].individual.inactive.species
					tai = ta[i]
				end
			end
		end
	end
	io.write("GET4() - " .. purity .. " " .. type .. " - found " .. tostring(reportedSpecs) .. " " .. count .. " (returned avg speed: " .. speed/2 .. ") \n")
	return count, tai
end

function breed(spec)
	local par1, par2 = getParents(spec)
	local princess = nil
	local drone = nil
	local function getDrone(num) -- num is 1 for par1, 2 for par2, 3 for par1 AND par2
		if num == 2 then
			if GET("pure","drone",par2) > 0 then
				_,drone = GET("pure","drone",par2)
			elseif GET1("drone",par1,par2) > 0 then
					_,drone = GET1("drone",par1,par2)
			elseif GET("unpure","drone",par2) > 0 then
				_,drone = GET("unpure","drone",par2)
			end
		elseif num == 1 then
			if GET("pure","drone",par1) > 0 then
				_,drone = GET("pure","drone",par1)
			elseif GET1("drone",par1,par2) > 0 then
				_,drone = GET1("drone",par1,par2)
			elseif GET("unpure","drone",par1) > 0 then
				_,drone = GET("unpure","drone",par1)
			end
		elseif num == 3 then
			if GET1("drone",par1,par2) > 0 then
				_,drone = GET1("drone",par1,par2)
			elseif GET("pure","drone",par1) > 0 then
				_,drone = GET("pure","drone",par1)
			elseif GET("pure","drone",par2) > 0 then
				_,drone = GET("pure","drone",par2)
			elseif GET("unpure","drone",par1) > 0 then
				_,drone = GET("unpure","drone",par1)
			elseif GET("unpure","drone",par2) > 0 then
				_,drone = GET("unpure","drone",par2)
			end
		end
	end
-- new
	if not isStrong(par1) and par1 ~= "forest" and par1 ~= "meadows" then
		io.write("breed() - " .. par1 .. " is not Strong, calling multiply() for ".. par1 .. " \n")
		multiply(par1)
		return true
	elseif not isStrong(par2) and par1 ~= "forest" and par1 ~= "meadows" then
		io.write("breed() - " .. par2 .. " is not Strong, calling multiply() for ".. par2 .. " \n")
		multiply(par2)
		return true
	end




--new
	if GET("pure","princess",par1) > 2 then
		_,princess = GET("pure","princess",par1)
		getDrone(2)
	end

	if drone == nil then
		if GET("pure","princess",par2) > 2 then
			_,princess = GET("pure","princess",par2)
			getDrone(1)
		end
	end

	if drone == nil then
		if GET1("princess",par1,par2) > 0 then
			_,princess = GET1("princess",par1,par2)
			getDrone(3)
		end
	end

	if drone == nil then
		if GET("unpure","princess",par1) > 0 then
			_,princess = GET("unpure","princess",par1)
			getDrone(2)
		end
	end

	if drone == nil then
		if GET("unpure","princess",par2) > 0 then
			_,princess = GET("unpure","princess",par2)
			getDrone(1)
		end
	end

	if princess and drone then
		io.write("breed(".. spec ..") - housing \n")
		house1(princess)
		house1(drone)
	else
		local missingSpecGene = nil
		local isPrincessMissing = nil
		local isDroneMissing = nil
		io.write("breed() - cant find (enough) princesses OR a drone to breed " .. spec .. " \n")
		if GET3("drone",par1) < 1 then
			io.write("breed(".. spec ..") - missing drone with at least 1 gene of spec " .. par1 .. " \n")
			missingSpecGene = par1
			isDroneMissing = true
		end
		if	GET3("drone",par2) < 1 then
			io.write("breed(".. spec ..") - missing drone with at least 1 gene of spec " .. par2 .. " \n")
			if missingSpecGene == nil then
				missingSpecGene = par2
			end
			isDroneMissing = true
		end
		if GET3("princess",par1) < 3 then
			io.write("breed(".. spec ..") - missing princess (or not enough pures) with at least 1 gene of spec " .. par1 .. " \n")
			if missingSpecGene == nil then
				missingSpecGene = par1
			end
			isPrincessMissing = true
		end
		if	GET3("drone",par2) < 3 then
			io.write("breed(".. spec ..") - missing princess (or not enough pures) with at least 1 gene of spec " .. par2 .. " \n")
			if missingSpecGene == nil then
				missingSpecGene = par2
			end
			isPrincessMissing = true
		end
		gpu.setForeground(0x00FF00)
		io.write("breed(".. spec ..") - calling multiply for species " .. missingSpecGene .. " \n")
		gpu.setForeground(0xFFFFFF)
		multiply(missingSpecGene)
	end
end



function isStrong(spec)
	if GET("pure","princess",spec) >= const.strongPrincessCount and GET("pure","drone",spec) >= const.strongCount then
		return true
	else
		return false
	end
end



function multiply(spec)
	local princess = nil
	local drone = nil

	local function getPrincessAndDrone()
		if GET("pure","princess",spec) > 0 then
			_,princess = GET("pure","princess",spec)
		else
			if
				GET("unpure","princess",spec) > 0 then
				_,princess = GET("unpure","princess",spec)
			end
		end

		if GET("pure","drone",spec) > 0 then
			_,drone = GET("pure","drone",spec)
		else
			if
				GET("unpure","drone",spec) > 0 then
				_,drone = GET("unpure","drone",spec)
			end
		end
	end

	local function makePrincess()
		local princess1 = nil
		local drone1 = nil
--new

		if GET("unpure","princess",spec) > 0 then
			_,princess1 = GET("unpure","princess",spec)
--new
		--[[elseif GET1("princess","rocky",spec) > 0 then
			_,princess1 = GET1("princess","rocky",spec)]] -- changed to whats below. (take any unpure princess to make princess of spec. can cause problems taking higher tier princesses)
		elseif GET4("unpure","princess") > 0 then
			_,princess1 =  GET4("unpure","princess")
--
		elseif GET("pure","princess","rocky") > 0 then
			_,princess1 = GET("pure","princess","rocky")
		else
			gpu.setForeground(0x00FF00)
			io.write("makePrincess() - ERROR#2 - no princesses with Rocky gene available \n")
			gpu.setForeground(0xFFFFFF)
			error("ERROR#2")
		end
		_,drone1 = GET("pure","drone",spec)
		house1(princess1)
		house1(drone1)
		
	end


	if isStrong(spec) then
		gpu.setForeground(0x00FF00)
		io.write("multiply() - called to multiply " .. spec .. " - strong species (" .. const.strongCount .. " drones and ".. const.strongPrincessCount .. " pure princesses) achieved! \n")
		gpu.setForeground(0xFFFFFF)
	else
		getPrincessAndDrone()
		if princess and drone then
			if GET("pure","princess",spec) < const.strongPrincessCount and GET("pure","drone",spec) >= const.strongCount then
				gpu.setForeground(0x00FF00)
				io.write("multiply() - found <" .. const.strongPrincessCount .. " pure princesses of " .. spec .. " and >=" .. const.strongCount .." drones, calling makePrincess() " .. spec .. " \n")
				gpu.setForeground(0xFFFFFF)
				makePrincess()
			elseif GET("pure","princess",spec) > 0 and GET("pure","drone",spec) < const.strongCount then
				gpu.setForeground(0xff9933)
				io.write("multiply() - forming strong specie of " .. spec .. " \n")
				gpu.setForeground(0xFFFFFF)
				
				house1(princess)
				house1(drone)

			else
			
				gpu.setForeground(0x00FF00)
				io.write("multiply() - attempting to multiply specie of " .. spec .. " \n")
				gpu.setForeground(0xFFFFFF)
				
				house1(princess)
				house1(drone)
			end
				
		elseif not princess and not drone then
			io.write("multiply() - cant find princess NOR drone of species " .. spec .. " \n")
			gpu.setForeground(0x00FF00)
			io.write("multiply() - calling breed() " .. spec .. " \n")
			gpu.setForeground(0xFFFFFF)
			breed(spec)
		elseif princess == nil and GET("pure","drone",spec) > 0 then
			io.write("multiply() - cant find princess (have pure drone) of species " .. spec .. " \n")
			gpu.setForeground(0x00FF00)
			io.write("multiply() - calling makePrincess() " .. spec .. " \n")
			gpu.setForeground(0xFFFFFF)
			makePrincess()


		else
			io.write("multiply() - cant find princess AND drone of species " .. spec .. " \n")
			gpu.setForeground(0x00FF00)
			io.write("multiply() - calling breed() " .. spec .. " \n")
			gpu.setForeground(0xFFFFFF)
			breed(spec)
		end
	end
end


function houseBee(interface,type,al1,al2)
	local ti = int[interface].getItemsInNetwork()
	local ta = int[interface].getAvailableItems()
	for i in ipairs(ti) do
		if isBee(ti[i]) and isAnalyzed(ti[i]) and isType(ti[i],type) then
			if al1check(ti[i],al1) and al2check(ti[i],al2) then
				house1(ta[i])
				io.write("houseBee() - " .. tostring(al1) .. "/" .. tostring(al2) .. " " .. tostring(type) .. " housed \n")
				return true
			end
		end
	end
	io.write("houseBee() - nothing found \n")
end

function console()
	while true do
		gpu.setForeground(0x00FF00)
		io.write("Console >> ")
		gpu.setForeground(0x99ccff)
		local command = io.read()
		gpu.setForeground(0xFFFFFF)
		if command == "close" then
			return true
		else
			local a,err = pcall((load(command)))
			if a == false then
				gpu.setForeground(0xFF0000)
				io.write("failed: ")
				gpu.setForeground(0xFFFFFF)
				io.write(tostring(err))
			else
				io.write("success ")
			end
			io.write("\n")
		end
	end
end

function achieve(spec)
	while true do
		if isStrong(spec) then
			break
		else
			waitForAnalyze()
			multiply(spec)
			waitForApiary(1)
		end
	end
end

--
term.clear()
removeUnnatural()
console()





