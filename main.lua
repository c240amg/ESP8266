print("Running main")
gpio.mode(2,gpio.OUTPUT)
BLUE=1
gpio.mode(BLUE,gpio.OUTPUT)
gpio.write(BLUE,gpio.HIGH)
-- Set the LED to flash
pwm.stop(2)
pwm.setup(2,1,10)
pwm.start(2)
-- Load library

sda_pin = 5
scl_pin = 6
dht_pin = 4
oled_addr = 0x3c
-- Counter for heartbeat
cnt = 1
state = 0
-- global for display/read dht
humidtwo = 0
temptwo = 0
-- Heap limit
heap_limit= 22000

function init_OLED(sda,scl)
     sla = 0x3c
     i2c.setup(0, sda, scl, i2c.SLOW)
     disp = u8g.ssd1306_128x64_i2c(sla)
     disp:setFont(u8g.font_6x12)
     disp:setFontRefHeightExtendedText()
     disp:setDefaultForegroundColor()
     disp:setFontPosTop()
end
function read_sensor_values()
  local varh,vart
  dht22.read(dht_pin)
  varh = dht22.getHumidity()
  vart = dht22.getTemperature()
  if varh ~= nil then
    humidtwo = (varh/10).."."..(varh%10)
  else
    print ("Previous H : " ..humidtwo)
  end
  if vart ~= nil then
    temptwo = (vart/10).."."..(vart%10)
  else
    print ("Previous T : " ..temptwo)
  end
end

function display_sensor_values(vvar)
  disp:firstPage()
  disp:setFont(u8g.font_6x10)
  disp:setFontRefHeightExtendedText()
  disp:setDefaultForegroundColor()
  disp:setFontPosTop()
  local x,y,ip,nm,st,deg,result
  if state==1 then
    st=string.char(176)
  else
    st=" "
  end
  deg=string.char(176)
  repeat
    disp:drawRFrame(0, 0, 128-1, 64-1, 1)
    x=4
    y=8
    disp:drawStr(x, y, 'T:' .. (temptwo) .. deg ..'C   H:' .. (humidtwo) .. '%RH' )
    y = y+14
    disp:drawStr(x, y,  st .. ' H:' .. (node.heap()) .. ' C:' .. (cnt) )
    y = y+14
    if wifi.sta.status()==0 then result='STA_IDLE' end
    if wifi.sta.status()==1 then node.restart() end
    if wifi.sta.status()==2 then result='STA_WRONG PASSWD' end
    if wifi.sta.status()==3 then result='STA_NO AP FOUND' end
    if wifi.sta.status()==4 then result='STA_CONNECT FAILED' end
    if wifi.sta.status()==5 then result='STA_GOT_IP' end
    if vvar==1 then
      ssid,password,bssid_set,bssid=wifi.sta.getconfig()
      result= ssid
      ssid,password,bssid_set,bssid=nil,nil,nil,nil
    end
    disp:drawStr(x, y, result  )
    y = y+14
    ip,nm=wifi.sta.getip()
    if ip ~= nil then
        disp:drawStr(x, y, 'IP:' .. (ip)  )
    else
        disp:drawStr(x, y, 'IP: Cannot get IP')
        node.restart()
    end

  until disp:nextPage() == false

  cnt = cnt + 1
  if cnt > 999 then
     cnt=1
  end
end

init_OLED(5,6)

i2c.setup(0, sda_pin, scl_pin, i2c.SLOW)
disp = u8g.ssd1306_128x64_i2c(oled_addr)

  sv=net.createServer(net.TCP, 2)
  sv:listen(80,function(c)
      c:on("receive", function(c, pl)
         print(pl)
         if pl=="1" then
            print ("gpio1 low")
            gpio.write(1,gpio.LOW)
         end
         if pl=="2" then
            print ("gpio1 high")
            gpio.write(1,gpio.HIGH)
         end
      end)
        dht22 = require("dht22")
        gpio.mode(BLUE,gpio.OUTPUT)
        gpio.write(BLUE,gpio.HIGH)
        read_sensor_values()
        display_sensor_values()
        dht22=nil
        print("Humidity:    "..humidtwo.." %")
        print("Temperature: "..temptwo.." deg C")
        c:send("H:"..humidtwo.." ; T:"..temptwo.."\r\n")
        c:close()
        gpio.write(BLUE,gpio.LOW)
      
        hp=node.heap()
        if hp<5000 then
            node.restart()
        end
  
        collectgarbage()
       end)
     
tmr.alarm( 2, 1000, 1, function()
  if state == 0 then
    display_sensor_values(1)
  end
  if state == 1 then
    display_sensor_values(0)
  end
  state = (state + 1) %2
  collectgarbage()
end)
