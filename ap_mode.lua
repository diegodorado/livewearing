wifi.setmode(wifi.STATIONAP)
print("ESP8266 mode is: " .. wifi.getmode())

local ssids = {}

--- Call Get AP Method ---
wifi.sta.getap({},0, function (nets)
 for ssid,v in pairs(nets) do
   local _, rssi, _, _ = string.match(v, "([^,]+),([^,]+),([^,]+),([^,]+)")
   local quality = 2 * (rssi + 100)
   table.insert(ssids, {ssid = ssid, quality = quality})
 end
 print("Starting server")

 cfg={}
 cfg.ssid="ceiborg_Wifi_Config"
 wifi.ap.config(cfg)

 srv = net.createServer(net.TCP)
 srv:listen(80, function(conn)
   conn:on("receive", receiver)
 end)

 print("HTTP Server is now listening. Free Heap:", node.heap())
end)





function send_status(sck)
  local header = "HTTP/1.0 200 OK\r\nContent-Type: application/json\r\n\r\n"
  local data = {}

  print("Getting IP")
  ip = wifi.sta.getip()

  if ip==nil then
    data["up"] = 0
  else
    local sta_config=wifi.sta.getconfig(true)
    data["up"] = 1
    data["ip"] = ip
    data["ssid"] = sta_config.ssid
  end

  ok, json = pcall(sjson.encode, data )
  if ok then
    sck:send(header..json,function(c) c:close() end)
  else
    print("failed to encode!")
  end

end

function send_ssids(sck)
  local header = "HTTP/1.0 200 OK\r\nContent-Type: application/json\r\n\r\n"

  ok, json = pcall(sjson.encode, ssids)
  if ok then
    sck:send(header..json,function(c) c:close() end)
  else
    print("failed to encode!")
  end

end

function forget(sck)
  sck:send("HTTP/1.1 200 OK\r\n\r\n",function(c) c:close() end)
  wifi.sta.clearconfig()
end


function receiver(sck, data)

  _, _, _, url, _ = string.find(data, "([A-Z]+) /([^?]*)%??(.*) HTTP")
  _, _, json = string.find(data, "({.*})")

  if url=="setup" then
    sck:send("HTTP/1.1 200 OK\r\n\r\n",function(c) c:close() end)
    local cfg = {}

    local decoder = sjson.decoder()
    decoder:write(json)
    local result = decoder:result()
    local i = tonumber(result["ssid"])

    cfg.ssid = ssids[i]["ssid"]
    cfg.pwd= result["pwd"]
    wifi.sta.config(cfg)
    return
  end

  if url=="status" then
    send_status(sck)
    return
  end

  if url=="forget" then
    forget(sck)
    return
  end

  if url=="restart" then
    node.restart()
    return
  end

  if url=="ssids" then
    send_ssids(sck)
    return
  end

  if url=="favicon.ico" then
    sck:send("HTTP/1.1 404 OK\r\n\r\n",function(c) c:close() end)
    return
  end

  sck:send("HTTP/1.1 200 OK\r\n\r\n",function(c) send_it_all(c,0) end)

end

--recursive send function
function send_it_all(c,p)
  if file.open("app.html", "r") then
      file.seek("set", p)
      local chunk = file.read(512)
      file.close()
      if chunk then
          if (string.len(chunk) == 512) then
              c:send(chunk,function(c)
                send_it_all(c,p+512) end)
              return
          else
            c:send(chunk,function(c)
              c:close() end)
            return
          end
      end
  end
  c:close()
end
