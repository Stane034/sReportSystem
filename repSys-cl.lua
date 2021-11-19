local repovi = {}

ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do 
        TriggerEvent('esx:getSharedObject', function(obj)
            ESX = obj
        end)
        Wait(1000)
        SkiniListu()
    end
end)

RegisterNetEvent('Reportovi:vratiListu')
AddEventHandler('Reportovi:vratiListu', function()
    SkiniListu()
end)

function SkiniListu()
    ESX.TriggerServerCallback('Reportovi:izvuciListu', function(data)
        repovi = data
    end)
end

RegisterCommand(Cfg.Komande.Meni, function()
    ESX.TriggerServerCallback('Reportovi:izvuciRank', function(br)
        if br then
            OtvoriMeniRepova()
        else
            ESX.ShowNotification('Nisi Autorizovan')
        end
    end)
end)

function OtvoriMeniRepova()
            local elementi = {
            }

         for i = 1, #repovi, 1 do
            table.insert(elementi, {label = 'Ime : ' .. repovi[i].ime.. ' Tekst : ' .. repovi[i].poruka .. '.', value = repovi[i].idreporta})   
         end
            ESX.UI.Menu.CloseAll()
              ESX.UI.Menu.Open(
              'default', GetCurrentResourceName(), 'admin_meni',
              {
                css      = 'meni',
                title    = '👨‍💼 Reportovi 👨‍💼',
                align    = 'top-left',
                elements = elementi
              },
                
                function(data, menu)
                 for i = 1, #repovi, 1 do
                    if data.current.value == i then
                        OtvoriMeniAdmina(i)
                    end
                end
              end,
              function(data, menu)
                menu.close()
              end
            )
end

function OtvoriMeniAdmina(id)
    local elementi = {
    }
    table.insert(elementi, {label = '👨‍💼 Pitanje : ' .. repovi[id].poruka .. '.', value = 'pitanje'})
    table.insert(elementi, {label = '👨‍💼 Odgovori', value = 'odgovor'})
    table.insert(elementi, {label = '🌀 Port do igraca', value = 'port'})
    table.insert(elementi, {label = '❌ Obrisi Report', value = 'brisanje'})
    ESX.UI.Menu.CloseAll()
      ESX.UI.Menu.Open(
      'default', GetCurrentResourceName(), 'admin_meni',
      {
        css      = 'meni',
        title    = '👨‍💼 ' .. repovi[id].ime .. ' 👨‍💼',
        align    = 'top-left',
        elements = elementi
      },
        
        function(data, menu)
         for i = 1, #repovi, 1 do
            if data.current.value == 'odgovor' then
                menu.close()
                local unos = UnosTastatura('Upisi Odgovor', '', 120)
                if unos ~= nil then
                    TriggerServerEvent('Reportovi:posaljiOdgovor', repovi[id].idigraca, unos)
                end
            elseif data.current.value == 'port' then
                menu.close()
                local unos = UnosTastatura('Da li si siguran da zelis da se portas do igraca ' .. repovi[id].ime, 'DA/NE', 120)
                if unos == 'DA' then
                    TriggerServerEvent('Reportovi:baciIgraca', id, repovi[id].idigraca)
                else
                    ESX.ShowNotification('Odustao si od teleportovanja do igraca ' .. repovi[id].ime)
                end
            elseif data.current.value == 'brisanje' then
                menu.close()
                local unos = UnosTastatura('Da li si siguran da zelis da obrises report od' .. repovi[id].ime, 'DA/NE', 120)
                if unos == 'DA' then  
                  TriggerServerEvent('Reportovi:obrisiReport', id)
                else
                  ESX.ShowNotification('Odustao si od brisanja reporta')
                end
            end
        end
      end,
      function(data, menu)
        menu.close()
      end
    )
end

UnosTastatura = function(TextEntry, ExampleText, MaxStringLength)
    AddTextEntry("FMMC_KEY_TIP1", TextEntry .. ":")
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", ExampleText, "", "", "", MaxStringLength)
    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        DisableAllControlActions(0)
        if IsDisabledControlPressed(0, 322) then return "" end
        Wait(0)
    end
    if (GetOnscreenKeyboardResult()) then
      print(GetOnscreenKeyboardResult())
      return GetOnscreenKeyboardResult()
    end
end
