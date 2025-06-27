# GloReg

Load  module Main in a Haskell interpreter. Call 'main' to see the main prototype functions.

MAIN FUNCTIONS:

sh "pro.m"           show pro.m (m = gl,rl)
tc "ef" "pro"        type checking of pro.m (m = gl,rl). 
                     Example of "ef":  "x,b,map" (global),  "0,1,l_x,l_2" (regiones)  
ev "pro.m"           evaluate pro.m (m = gl.rl) 
pev n "pro.m"        evaluate (n steps) of pro.m (m = gl,rl)
gtr "pro.gl"         translate global to regions

1) In "Programas" folder there are numerous developed examples (some of them reported in [1]).

2) '.gl' and '.rl' files are displayed by the 'sh' function. Region variables must begin with "l_".
   
3) The parser was built with Happy (Version 1.19.12).
   
[1] Globality and Regions (2025), Héctor Gramaglia
