b = true,
x = 8,
w = 1,
y = 1,
fib = \(l_x,l_b,l_w,l_y).\(x,b,w,y) . if (==0)^l_b x then (x,w,y) else (let (x,w,y) = fib (l_x,l_b,l_w,l_y) ((-1)^l_x x,b,w,y) in (let z = id^0(w) in (x,p2^l_w(w,y),(z+^l_y y))))
------------------------------------
fib (2,1,3,4) (x,b,w,y)
------------------------------------
 
------------------------------------
b : 1 bool,
x : 2 int,
w : 3 int,
y : 4 int,
fib : 0 (\(l_x,l_b,l_w,l_y).(l_x int,l_b bool,l_w int,l_y int) ->(0,l_x,l_b,l_w,l_y) (l_x int,l_w int,l_y int))
------------------------------------
(2 int,3 int,4 int)
------------------------------------




