ESX = nil

TriggerEvent('esx:getSharedObject', function(obj)
    ESX = obj
end)

local vrijeme = 0
local provjera = {}
local cekanje = 60
local reportovi = {}
local statusAdmina = {}

SacuvajInfo = function() 
    SaveResourceFile(GetCurrentResourceName(), 'reportovi.json', json.encode(statusAdmina), -1)
end

UcitajInfo = function()
    local ucitan = LoadResourceFile(GetCurrentResourceName(), "reportovi.json")
    local decoded = json.decode(ucitan)
    statusAdmina = decoded
end

UcitajInfo()

ESX.RegisterServerCallback('Reportovi:izvuciListu', function(source, cb)
    cb(reportovi)
end)

ESX.RegisterServerCallback('Reportovi:izvuciRank', function(source, cb)
    local igrac = ESX.GetPlayerFromId(source)
    local grp = igrac.getGroup()
    if grp ~= 'user' then
        cb(true)
    else
        cb(false)
    end
end)

RegisterCommand(Cfg.Komande.TopLista, function()
    reportlogovi(Cfg.Webhookovi.ListaReportova, '**LISTA REPORTOVA**')
    for k,v in pairs(statusAdmina) do 
        reportlogovi(Cfg.Webhookovi.ListaReportova, '**Admin : **<@' .. k .. '> \n **Broj Reportova : **' .. v.reportovi)
    end
end, true)

RegisterCommand(Cfg.Komande.Report, function(source, args)
    if (not provjera[source] or provjera[source] <= os.time() - cekanje) then
        provjera[source] = os.time()
        TriggerClientEvent('chat:addMessage', source, {
          args = {"^2Vas report je poslan svim online adminima."}
        })
        vrijeme = 60*1000
        local xPlayers = ESX.GetPlayers()
            for i=1, #xPlayers, 1 do
                local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
                if xPlayer.getGroup() ~= "user" then
                    TriggerClientEvent('chat:addMessage', xPlayer.source, {
                        args = {"^4Igrac " .. GetPlayerName(source) .. ' [ID : ' .. source .. '] je poslao report /' .. Cfg.Komande.Meni}
                    })
                    reportlogovi(Cfg.Webhookovi.Reportovi, '**Igrac : ' .. GetPlayerName(source) .. ' je poslao report sa tekstom**\n**Tekst** : ' .. table.concat(args, " "))
                 for i = 0, #reportovi, 1 do
                    table.insert(reportovi, {ime = GetPlayerName(source),idigraca = source, poruka = table.concat(args, " "), idreporta = i + 1})
                 end
                 TriggerClientEvent('Reportovi:vratiListu', -1)
                end
            end
            while vrijeme ~= 0 do
            vrijeme = vrijeme - 1000
            Wait(1000)
            end
    else
        local format = vrijeme / 1000
        TriggerClientEvent('chat:addMessage', source, {
            args = {"^7Pricekaj ^1^*60 ^7^rsekundi prije slanja sledeceg reporta."}
          })
    end 
end)

RegisterServerEvent('Reportovi:posaljiOdgovor')
AddEventHandler('Reportovi:posaljiOdgovor', function(target, text)
    local igrac = ESX.GetPlayerFromId(source)
    if target ~= -1 and igrac.getGroup() ~= 'user' then
        TriggerClientEvent('chat:addMessage', tonumber(target), {
            args = {"^4ADMIN", " ^7(^4^*" .. GetPlayerName(source) .. "^7) ^7» ^0" .. text}
        })
        reportlogovi(Cfg.Webhookovi.Odgovori, '**Admin : ' .. GetPlayerName(source) .. '** je odgovorio igracu **' .. GetPlayerName(tonumber(target)) .. '**\n**Tekst** : ' .. text)  
    else
        DropPlayer(source, 'ae bezi')
    end
end)

RegisterServerEvent('Reportovi:obrisiReport')
AddEventHandler('Reportovi:obrisiReport', function(id)
    local igrac = ESX.GetPlayerFromId(source)
    if igrac.getGroup() ~= 'user' then
        reportlogovi(Cfg.Webhookovi.Brisanje, '**Admin : ' .. GetPlayerName(source) .. ' je obrisao report**\n**Poslao :** ' .. GetPlayerName(reportovi[id].idigraca) .. '\n**Tekst** : ' .. reportovi[id].poruka)
        reportovi[id] = nil
        TriggerClientEvent('Reportovi:vratiListu', -1)
        igrac.showNotification('Obrisao si report sa IDom : ' .. id)
    end
end)

RegisterServerEvent('Reportovi:baciIgraca')
AddEventHandler('Reportovi:baciIgraca', function(id, target)
    local ESXIgracS = ESX.GetPlayerFromId(source)
    if ESXIgracS.getGroup() ~= 'user' then
        local igracT = GetPlayerPed(tonumber(target))
        if igracT == 0 then
            return ESXIgracS.showNotification('Igrac je offline')
        end
        reportlogovi(Cfg.Webhookovi.Teleportovi, '**Admin : ' .. GetPlayerName(source) .. ' se teleportovao do igraca ' .. GetPlayerName(tonumber(target)) .. '**')
        local igracS = GetPlayerPed(source)
        SetEntityCoords(igracS, GetEntityCoords(igracT))
        TriggerClientEvent('chat:addMessage', tonumber(target), {
            args = {"^4ADMIN", " ^7(^4^*" .. GetPlayerName(source) .. "^7) ^7» ^0 se teleportovao do vas"}
        })
        reportovi[id] = nil
        TriggerClientEvent('Reportovi:vratiListu', -1)
        local DiscordID = "Nepoznat" 
        for i = 0, GetNumPlayerIdentifiers(source) - 1 do
            local id = GetPlayerIdentifier(source, i)	
            if string.find(id, "discord") then
                DiscordID = id:gsub("discord:", "")
            end
        end    

        if DiscordID == 'Nepoznat' then
            return ESXIgracS.showNotification('Povezi discord sa Fivemom, inace ti se reportovi nece racunati')
        end
        if statusAdmina[DiscordID] then
            statusAdmina[DiscordID] = {reportovi = statusAdmina[DiscordID].reportovi + 1}
            SacuvajInfo()
        else
            statusAdmina[DiscordID] = {reportovi = 1}
            SacuvajInfo()
        end 
    else
        DropPlayer(source, 'ae zibe')
    end
end)

function reportlogovi(huk, message)
	local vrijeme = os.date('*t')
	local poruka = {
		{
			["color"] = Cfg.Webhookovi.Boja,
			["title"] = "**Report System ( 📝 |**",
			["description"] = message,
			["footer"] = {
			["text"] = "Logovi\nVrijeme: " .. vrijeme.hour .. ":" .. vrijeme.min .. ":" .. vrijeme.sec,
			},
		}
	  }
	PerformHttpRequest(huk, function(err, text, headers) end, 'POST', json.encode({username = Cfg.Webhookovi.ImeLogova, embeds = poruka, avatar_url = Cfg.Webhookovi.Slika}), { ['Content-Type'] = 'application/json' })
  end
