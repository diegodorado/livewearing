-- init the ws2812 module
ws2812.init(ws2812.MODE_SINGLE)
-- create a buffer, 10 LEDs with 3 color bytes
buffer = ws2812.newBuffer(40, 3)

local h,s,v = 0,255,255

sck = net.createUDPSocket()
sck:listen(8000)
sck:on("receive", function(socket, packet, port, ip)
  if string.len (packet) == 12 then
    addr = tostring(string.sub (packet, 2, 2))
    data = tonumber(string.byte (packet, 12))

    if addr == 'h' then h = (data*360/255) end
    if addr == 's' then s = data end
    if addr == 'v' then v = data end

    for i=1,buffer:size() do
      buffer:set(i, color_utils.hsv2grb(h,s,v))
    end
    ws2812.write(buffer)

  end
  if string.len (packet) == 28 then
    i = tonumber(string.byte (packet, 16))
    local h = (tonumber(string.byte (packet, 20))*360/255)
    local s = tonumber(string.byte (packet, 24))
    local v = tonumber(string.byte (packet, 28))

    if i>0 and i < buffer:size() then
      buffer:set(i, color_utils.hsv2grb(h,s,v))
    end
    ws2812.write(buffer)

  end
end)


--tmr.create():alarm(33, tmr.ALARM_AUTO, function()
--  ws2812.write(buffer)
--end)
