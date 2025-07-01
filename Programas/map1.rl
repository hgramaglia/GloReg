A = {0,1,2,3,2,1,0,1},
i = 0,
n = 8,
map = \().\f . (\(l_A,l_i,l_n).\(A,i,n) : (l_A array,l_i int,l_n int). if (i==^0 n) then (A,i,n) else (let mapf = map 0 (f) in mapf (l_A,l_i,l_n) (A[i<-f 0 (A[i]^0)]^l_A,(+1)^l_i i,n)))^0
------------------------------------
(let f = (\().\z : 0 int. (+1)^0 z)^0 in (let mapf = map 0 (f) in mapf (1,2,3) (A,0^2,8^3)))
------------------------------------
 
------------------------------------
A : 1 array,
i : 2 int,
n : 3 int,
map : 0 (\().0 (\().0 int ->(0) 0 int) ->(0) 0 (\(l_A,l_i,l_n).(l_A array,l_i int,l_n int) ->(0,l_A,l_i,l_n) (l_A array,l_i int,l_n int)))
------------------------------------
(1 array,2 int,3 int)
------------------------------------
version 1, z colapsa parte de la region 0, pero colapsa menos que la versión 2





A = {0,1,2,3,2,1,0,1},
i = 0,
n = 8,
z = 0,
map = \().\f . (\(l_A,l_i,l_n).\(A,i,n) : (l_A array,l_i int,l_n int). if (i==^0 n) then (A,i,n) else (let mapf = map 0 (f) in mapf (l_A,l_i,l_n) (A[i<-f 0 (A[i]^0)]^l_A,(+1)^l_i i,n)))^0
------------------------------------
(let f = (\l_x.\x : l_x int. (+1)^l_x x)^0 in (let mapf = map 0 (f) in mapf (1,2,3) (A,0^2,8^3)))
------------------------------------
 
------------------------------------
A : 1 array,
i : 2 int,
n : 3 int,
z : 0 int,
map : 0 (\().0 (\l_x.l_x int ->(l_x) l_x int) ->(0) 0 (\(l_A,l_i,l_n).(l_A array,l_i int,l_n int) ->(l_A,l_i,l_n,0) (l_A array,l_i int,l_n int)))
------------------------------------
(1 array,2 int,3 int)
------------------------------------
version 2, z local, colapsa totalmente la intervención de z en la region 0, da lo mismo poner z en lugar de x

A = {0,1,2,3,2,1,0,1},
i = 0,
n = 8,
z = 0,
map = \().\f . (\(l_A,l_i,l_n).\(A,i,n) : (l_A array,l_i int,l_n int). if (i==^0 n) then (A,i,n) else (let mapf = map 0 (f) in mapf (l_A,l_i,l_n) (A[i<-f 4 (A[i]^4)]^l_A,(+1)^l_i i,n)))^0
------------------------------------
(let f = (\l_x.\x : l_x int. (+1)^l_x x)^0 in (let mapf = map 0 (f) in mapf (1,2,3) (A,0^2,8^3)))
------------------------------------
 
------------------------------------
A : 1 array,
i : 2 int,
n : 3 int,
z : 4 int,
map : 0 (\().0 (\l_x.l_x int ->(l_x) l_x int) ->(0,4) 0 (\(l_A,l_i,l_n).(l_A array,l_i int,l_n int) ->(0,l_A,l_i,l_n,4) (l_A array,l_i int,l_n int)))
------------------------------------
(1 array,2 int,3 int)
------------------------------------
version 3, con x en lugar de z

A = {0,1,2,3,2,1,0,1},
i = 0,
n = 8,
z = 0,
map = \().\f . (\(l_A,l_i,l_n).\(A,i,n) : (l_A array,l_i int,l_n int). if (i==^0 n) then (A,i,n) else (let mapf = map 0 (f) in mapf (l_A,l_i,l_n) (A[i<-f 4 (A[i]^4)]^l_A,(+1)^l_i i,n)))^0
------------------------------------
(let f = (\l_z.\z : l_z int. (+1)^l_z z)^0 in (let mapf = map 0 (f) in mapf (1,2,3) (A,0^2,8^3)))
------------------------------------
 
------------------------------------
A : 1 array,
i : 2 int,
n : 3 int,
z : 4 int,
map : 0 (\().0 (\l_z.l_z int ->(l_z) l_z int) ->(0,4) 0 (\(l_A,l_i,l_n).(l_A array,l_i int,l_n int) ->(0,l_A,l_i,l_n,4) (l_A array,l_i int,l_n int)))
------------------------------------
(1 array,2 int,3 int)
------------------------------------
version 3 sin reemplazar z por x




