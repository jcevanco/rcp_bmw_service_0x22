# RCP BMW Servie 0x22 Script
# Copyright (c) 2023 The SECRET Ingredient!
# GNU General Public License v3.0

# format for presentation
# s/{\[/{\n\[/ ;
# s/},\[/},\n\[/g ;
s/}}local/}}\nlocal/ ;
s/;function onTick/\nfunction onTick/ 
