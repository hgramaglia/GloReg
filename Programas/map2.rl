
b = 0,
z = 0,
f = 0,
mapf = 0,
A = {0,1,2,3,2,1,0,1},
i = 0,
n = 8,
map = \l_f.\f . (\(l_A,l_i,l_n).\(A,i,n) : (l_A array,l_i int,l_n int). if (i==^1 n) then (A,i,n) else (let mapf = map l_f (f) in mapf (l_A,l_i,l_n) (A[i<-f 2 (A[i]^2)]^l_A,(+1)^l_i i,n)))^4
------------------------------------
(let f = (\l_x.\x : l_x int. (+1)^l_x x)^3 in (let mapf = map 3 (f) in mapf (5,6,7) (A,0^6,8^7)))
------------------------------------
 
------------------------------------
b : 1 int,
z : 2 int,
f : 3 int,
mapf : 4 int,
A : 5 array,
i : 6 int,
n : 7 int,
map : 8 (\l_f.3 (\l_x.l_x int ->(l_x) l_x int) ->(1,2,l_f,4) 4 (\(l_A,l_i,l_n).(l_A array,l_i int,l_n int) ->(1,2,l_f,4,l_A,l_i,l_n) (l_A array,l_i int,l_n int)))
------------------------------------
(5 array,6 int,7 int)
------------------------------------



b = 0,
z = 0,
f = 0,
mapf = 0,
A = {0,1,2,3,2,1,0,1},
i = 0,
n = 8,
map = \l_f.\f . (\(l_A,l_i,l_n).\(A,i,n) : (l_A array,l_i int,l_n int). if (i==^1 n) then (A,i,n) else (let mapf = map l_f (f) in mapf (l_A,l_i,l_n) (A[i<-f 2 (A[i]^2)]^l_A,(+1)^l_i i,n)))^4
------------------------------------
(let f = (\l_z.\z : l_z int. (+1)^l_z z)^3 in (let mapf = map 3 (f) in mapf (5,6,7) (A,0^6,8^7)))
------------------------------------
 
------------------------------------
b : 1 int,
z : 2 int,
f : 3 int,
mapf : 4 int,
A : 5 array,
i : 6 int,
n : 7 int,
map : 8 (\l_f.3 (\l_z.l_z int ->(l_z) l_z int) ->(1,2,l_f,4) 4 (\(l_A,l_i,l_n).(l_A array,l_i int,l_n int) ->(1,2,l_f,4,l_A,l_i,l_n) (l_A array,l_i int,l_n int)))
------------------------------------
(5 array,6 int,7 int)
------------------------------------

