-- RCP BMW Servie 0x22 Script
-- Version, 5.2.0
-- Copyright (c) 2023 The SECRET Ingredient!
-- GNU General Public License v3.0
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
local b=13.5;local c=0X6F1;local d=0x0FF;local e=0x600;local f=0xF00;local g=0;local h=100;local i=2;local j=true;setTickRate(1000)local k,l,m=0,0,0;local n=0;setCANfilter(g,0,0,e,f)for o,p in pairs(a)do p[12]=addChannel(string.sub(p[2],1,11),unpack(p,3,6),string.sub(p[7],1,7))p[13],p[14],p[15],p[16],p[17]=0,0,0,0,0;k=math.max(k,p[3])end;function _gQ()if getUptime()-l>h then if getUptime()-i>m then local q,r,s=nil,0,0;for o,p in pairs(a)do p[13]=p[13]+p[3]r=p[13]/p[3]if p[13]>k and r>s then q,s=o,r end end;if q~=nil then a[q][13]=0;return q end end end end;function _rM(t)local u,v,w=rxCAN(g,h)if u~=nil then if j==true then _lD(g,u,v,w)end;if bit.band(w[2],0xF0)==0x00 then return u,w else if bit.band(w[2],0xF0)==0x10 then local x={w[1],unpack(w,3)}local y=math.ceil((bit.lshift(bit.band(w[2],0x0F),8)+w[3]-(#w-3))/6)w={bit.band(u,d),0x30,y,i}if _sM(c,w)==1 then if t==nil then t=0 end;repeat t=t+1;u,w=_rM(t)if u~=nil then for z=1,#w do x[#x+1]=w[z]end;if t>=y then return u,x end end until u==nil end elseif bit.band(w[2],0xF0)==0x20 and bit.band(w[2],0x0F)==bit.band(t,0x0F)then return u,{unpack(w,3)}else w={bit.band(u,d),0x32,0x00,0x00}_sM(g,c,w)end end end end;function _lD(A,u,v,w)local B,C,D,E,F,G,H=getDateTime()local I=string.format("%04d-%02d-%02d %02d:%02d:%02d.%03d %9d",B,C,D,E,F,G,H,getUptime())I=I..string.format(" %1d "..(v==1 and"%10d 0x%08X"or"%4d 0x%03X").." %02d",A+1,u,u,#w)I=I..string.format(string.rep(" 0x%02X",#w),unpack(w))println(I)end;function _sQ()local o=_gQ()if o~=nil then if _sM(c,{a[o][1],0x03,0x22,bit.band(bit.rshift(o,8),0xFF),bit.band(o,0xFF)})==1 then l=getUptime()a[o][14]=a[o][14]+1;_rR()end end end;function _sM(u,x)local J=txCAN(g,u,0,x,h)if J==1 and j==true then _lD(g,u,nil,x)end;return J end;function _rR()local u,w=_rM()if u~=nil and l~=0 and bit.band(c,d)==w[1]and w[3]==0x62 then if _pD(u,w)==1 then l=0;m=getUptime()end end end;function _pD(u,w)local o=bit.lshift(w[4],8)+w[5]if a[o]then if bit.band(u,d)==a[o][1]then local K=0;for z=6,w[2]+2 do K=K+bit.lshift(w[z],8*(w[2]+2-z))end;if a[o][8]=='s'then K=_sI(K,w[2]-3)end;if a[o][5]~=nil then K=math.max(K,a[o][5])end;if a[o][6]~=nil then K=math.min(K,a[o][6])end;setChannel(a[o][12],K*a[o][9]/a[o][10]+a[o][11])if j==true then local L=getUptime()a[o][16]=a[o][15]~=0 and(a[o][14]*a[o][16]+L-a[o][15])/(a[o][14]+1)or 0;a[o][17]=a[o][15]~=0 and(a[o][14]*a[o][17]+L-l)/(a[o][14]+1)or 0;println(string.format("[0x%04X] - TS:[%d] QC:[%d] LU:[%d] AR:[%d] AL:[%d]",o,L,unpack(a[o],14)))a[o][15]=L end;return 1 end end end;function _sI(w,M)return w>=math.pow(2,M*8-1)and w-math.pow(2,M*8)or w end
function onTick()if getUptime()-n>=1000 then collectgarbage()n=getUptime()end;if getChannel("Battery")~=nil and getChannel("Battery")>=b then _sQ()end end
