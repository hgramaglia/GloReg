

g = \l_.\x. new l_1. let z = (+1)^l_1 x in  (\l_.\w:1 int.w +^l_ z)^1  
------------------------------------
let f = g 1 (2^1) in f 1 (3^1)
------------------------------------

------------------------------------
g : 1 \l_. 1 int ->[1] 1 (\l_.l_ int ->[1,l_] l_ int)
------------------------------------
1 int
------------------------------------
se rompe
let f = g 1 (2^1) in f 1 (3^1)
let f = g 1 x1_1 in f 1 (3^1)     x1_1=2
let f = new a. let z = (+1)^a x1_1 in \l.\w.w +^l z in f 1 (3^1)     x1_1=2
let f = new 2. let z = (+1)^2 x1_1 in \l.\w.w +^l z in f 1 (3^1)     x1_1=2
let f = new 2. let z = x2_1 in \l.\w.w +^l z in f 1 (3^1)            x1_1=2, x2_1 = 3
let f = new 2. \l.\w.w +^l x2_1 in f 1 (3^1)                         x1_1=2, x2_1 = 3
let f = \l.\w.w +^l x2_1 in f 1 (3^1)                                x1_1=2
(\l.\w.w +^l x2_1) 1 (3^1)                                           x1_1=2
x1_2 +^1 x2_1                                                        x1_1=2, x1_2=3


