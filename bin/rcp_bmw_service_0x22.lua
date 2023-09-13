-- RCP BMW Servie 0x22 Script
-- Version, 5.2.0
-- Copyright (c) 2023 The SECRET Ingredient!
-- GNU General Public License v3.0
--
-- Select BMW OBD Service 0x22 PID Maps Available at
-- https://thesecretingredient.neocities.org
--
local a={
[0x4205]={0x12,'Boost',50,2,0,30,'psi','u',1,8825.26,0},
[0x4650]={0x12,'TFT',1,1,0,300,'F','u',1.35,1,-54.4},
[0x56D7]={0x12,'FRP',1,1,0,50,'MPa','u',1,500,0},
[0x580F]={0x12,'IAT',1,1,0,200,'F','u',1.35,1,-54.4},
[0x586F]={0x12,'EOP',2,1,0,100,'psi','s',14.696,1013.25,0},
[0x5889]={0x12,'Lambda',50,2,0,2,'','u',16,65535,0},
[0x5890]={0x12,'CRT',1,1,0,300,'F','u',1.35,1,-54.4},
[0x59FA]={0x12,'Spark',25,1,nil,nil,'*','s',0.75,1,0}}
local b=13.5;local c=0X6F1;local d=0x0FF;local e=0x600;local f=0xF00;local g=0;local h=100;local i=2;local j=false;local k=true;setTickRate(1000)local l,m,n=0,0,0;local o=0;setCANfilter(g,0,0,e,f)for p,q in pairs(a)do q[12]=addChannel(string.sub(q[2],1,11),unpack(q,3,6),string.sub(q[7],1,7))q[13],q[14],q[15],q[16],q[17]=0,0,0,0,0;l=math.max(l,q[3])end;function _sQ()local p=_gQ()if p~=nil then if _sM(c,{a[p][1],0x03,0x22,bit.band(bit.rshift(p,8),0xFF),bit.band(p,0xFF)})==1 then m=getUptime()a[p][14]=a[p][14]+1;_rR()end end end;function _gQ()if getUptime()-m>h then if getUptime()-i>n then local r,s,t=nil,0,0;for p,q in pairs(a)do q[13]=q[13]+q[3]s=q[13]/q[3]if q[13]>l and s>t then r,t=p,s end end;if r~=nil then a[r][13]=0;return r end end end end;function _sM(u,v)local w=txCAN(g,u,0,v,h)if w==1 and j==true then _lD(g,u,v)end;return w end;function _rR()local u,v=_rM()if u~=nil and m~=0 and bit.band(c,d)==v[1]and v[3]==0x62 then if _pD(u,v)==1 then m=0;n=getUptime()end end end;function _rM(x)local u,y,v=rxCAN(g,h)if u~=nil then if j==true then _lD(g,u,v)end;if bit.band(v[2],0xF0)==0x00 then return u,v else if bit.band(v[2],0xF0)==0x10 then local z={v[1],unpack(v,3)}local A=math.ceil((bit.lshift(bit.band(v[2],0x0F),8)+v[3]-(#v-3))/6)v={bit.band(u,d),0x30,A,i}if _sM(c,v)==1 then if x==nil then x=0 end;repeat x=x+1;u,v=_rM(x)if u~=nil then for B=1,#v do z[#z+1]=v[B]end;if x>=A then return u,z end end until u==nil end elseif bit.band(v[2],0xF0)==0x20 and bit.band(v[2],0x0F)==bit.band(x,0x0F)then return u,{unpack(v,3)}else v={bit.band(u,d),0x32,0x00,0x00}_sM(g,c,v)end end end end;function _pD(u,v)local p=bit.lshift(v[4],8)+v[5]if a[p]then if bit.band(u,d)==a[p][1]then local C=0;for B=6,v[2]+2 do C=C+bit.lshift(v[B],8*(v[2]+2-B))end;if a[p][8]=='s'then C=_sI(C,v[2]-3)end;if a[p][5]~=nil then C=math.max(C,a[p][5])end;if a[p][6]~=nil then C=math.min(C,a[p][6])end;setChannel(a[p][12],C*a[p][9]/a[p][10]+a[p][11])if k==true then local D=getUptime()a[p][16]=a[p][15]~=0 and(a[p][14]*a[p][16]+D-a[p][15])/(a[p][14]+1)or 0;a[p][17]=a[p][15]~=0 and(a[p][14]*a[p][17]+D-m)/(a[p][14]+1)or 0;println(string.format("[0x%04X] - TS:[%d] QC:[%d] LU:[%d] AR:[%d] AL:[%d]",p,D,unpack(a[p],14)))a[p][15]=D end;return 1 end end end;function _sI(v,E)return v>=math.pow(2,E*8-1)and v-math.pow(2,E*8)or v end;function _lD(F,u,v)local G,H,I,J,K,L,M=getDateTime()local N=string.format("%04d-%02d-%02d %02d:%02d:%02d.%03d %9d",G,H,I,J,K,L,M,getUptime())N=N..string.format(" %1d %4d 0x%03X %02d",F+1,u,u,#v)N=N..string.format(string.rep(" 0x%02X",#v),unpack(v))println(N)end
function onTick()if getUptime()-o>=1000 then collectgarbage()o=getUptime()end;if getChannel("Battery")~=nil and getChannel("Battery")>=b then _sQ()end end
