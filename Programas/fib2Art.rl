
fib = \(l_y,l_x,l_b).\x . if (==0)^l_b x then (0^l_y,1^l_y)
                                             else let (w,y) = fib (l_y,l_x,l_b) ((-1)^l_x x) in (y,(w +^l_y y))
------------------------------------
new l_x. new l_b.  fib (1,l_x,l_b) (8^l_x) 
------------------------------------
 
------------------------------------
fib : \(l_y,l_x,l_b):l_x int.(l_y int,l_y int)
------------------------------------
(1 int,1 int)
------------------------------------
fib2 del artículo, no tiene versión global de la cual provenga


