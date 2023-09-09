# RCP BMW Servie 0x22 Script
# Copyright (c) 2023 The SECRET Ingredient!
# GNU General Public License v3.0

# function minification
s/sendQuery(/sQ(/g ; 
s/getQuery(/gQ(/g ;
s/sendMessage(/sM(/g ; 
s/recvResponse(/rR(/g ; 
s/recvMessage(/rM(/g ; 
s/processData(/pD(/g ; 
s/signedInteger(/sI(/g ; 
s/logCANData(/lC(/g ; 

# format for presentation
s/{\[/{\n\[/ ;
s/},\[/},\n\[/g ;
s/}}local/}}\nlocal/ ;
s/;function onTick/\nfunction onTick/ 
