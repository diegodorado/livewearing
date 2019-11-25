--begin to connect
wifi.setmode(wifi.STATION)

function startup()
    if file.open("init.lua") == nil then
        print("init.lua deleted or renamed")
    else
        print("Running")
        file.close("init.lua")

        if file.open("init.lua") ~= nil then
          print ("---------------------")
          print('Starting Wifi Manager')
          dofile('wifi.lua')
          print ("---------------------")
        end

    end
end

-- you have 3 seconds to delete/rename init.lua
-- if something goes wrong
tmr.create():alarm(3000, tmr.ALARM_SINGLE, startup)
