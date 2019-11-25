gpio.mode(5, gpio.INPUT, gpio.PULLUP)

--check if the jumper forces th apmode
if gpio.read(5) == 0 then
  print("Forcing AP MODE.")
  dofile("ap_mode.lua")
else
  local count = 0
  tmr.alarm(1, 1000, 1, function()
    ip = wifi.sta.getip()
    if ip==nil then
      count = count + 1
      print("No IP yet. Retrying.")
      if count > 5000 then
        tmr.stop(1)
        dofile("ap_mode.lua")
      end
    else
      tmr.stop(1)
      c=wifi.sta.getconfig(true)
      print("Connected to ", c.ssid)
      print('IP is ',ip)
      dofile("app.lua")
    end
  end)
end
