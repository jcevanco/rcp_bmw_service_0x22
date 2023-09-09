-- BMW OBD Servie 0x22 Script
-- Version, 5.2.0,
-- Copyright (c) 2023 The SECRET Ingredient!
-- MIT License
--
-- Select BMW OBD Service 0x22 PID Maps Available at
-- https://thesecretingredient.neocities.org
--
local a={
[0x5512]={0x12,'AmbientTemp',1,1,0,200,'F','u',0.9,1,-40},
[0x59FA]={0x12,'Ign_Angle',25,1,nil,nil,'*','s',0.75,1,0},
[0x4205]={0x12,'Boost_Press',25,2,0,30,'kPa','u',20,2560,0},
[0x4300]={0x12,'Engine_Temp',1,1,0,300,'F','s',1.35,1,-54.4},
[0x558F]={0x12,'FPDM_Hours',1,1,nil,nil,'hours','u',0.5,1,0},
[0x558E]={0x12,'FPDM_Miles',1,1,nil,nil,'miles','s',0.62,1,0}}
local b=13.5;local c=0X6F1;local d=0x0FF;local e=0x600;local f=0xF00;local g=0;local h=100;local i=2;local j=true;setTickRate(1000)local k,l,m=0,0,0;local n=0;setCANfilter(g,0,0,e,f)for o,p in pairs(a)do p[12]=addChannel(string.sub(p[2],1,11),unpack(p,3,6),string.sub(p[7],1,7))p[13],p[14],p[15],p[16],p[17]=0,0,0,0,0;k=math.max(k,p[3])end;function sQ()local o=gQ()if o~=nil then if sM(c,{a[o][1],0x03,0x22,bit.band(bit.rshift(o,8),0xFF),bit.band(o,0xFF)})==1 then l=getUptime()a[o][14]=a[o][14]+1;rR()end end end;require"get_query"function sM(q,r)local s=txCAN(g,q,0,r,h)if s==1 and j==true then lC(g,q,r)end;return s end;function rR()local q,t=rM()if q~=nil and l~=0 and bit.band(c,d)==t[1]and t[3]==0x62 then if pD(q,t)==1 then l=0;m=getUptime()end end end;require"recv_message"function pD(q,t)local o=bit.lshift(t[4],8)+t[5]if a[o]then if bit.band(q,d)==a[o][1]then local u=0;for v=6,t[2]+2 do u=u+bit.lshift(t[v],8*(t[2]+2-v))end;if a[o][8]=='s'then u=sI(u,t[2]-3)end;if a[o][5]~=nil then u=math.max(u,a[o][5])end;if a[o][6]~=nil then u=math.min(u,a[o][6])end;setChannel(a[o][12],u*a[o][9]/a[o][10]+a[o][11])if j==true then local w=getUptime()a[o][16]=a[o][15]~=0 and(a[o][14]*a[o][16]+w-a[o][15])/(a[o][14]+1)or 0;a[o][17]=a[o][15]~=0 and(a[o][14]*a[o][17]+w-l)/(a[o][14]+1)or 0;println(string.format("[0x%04X] - TS:[%d] QC:[%d] LU:[%d] AR:[%d] AL:[%d]",o,w,unpack(a[o],14)))a[o][15]=w end;return 1 end end end;function sI(t,x)return t>=math.pow(2,x*8-1)and t-math.pow(2,x*8)or t end;function lC(y,q,t)local z,A,B,C,D,E,F=getDateTime()local G=string.format("%04d-%02d-%02d %02d:%02d:%02d.%03d %9d",z,A,B,C,D,E,F,getUptime())G=G..string.format(" %1d "..(ext==1 and"%10d 0x%08X"or"%4d 0x%03X").." %02d",y+1,q,q,#t)G=G..string.format(string.rep(" 0x%02X",#t),unpack(t))println(G)end
function onTick()if getUptime()-n>=1000 then collectgarbage()n=getUptime()end;if getChannel("Battery")~=nil and getChannel("Battery")>=b then sQ()end end
