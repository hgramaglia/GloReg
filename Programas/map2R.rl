A = {0,1,2,3,2,1,0,1},
i = 0,
n = 8,
map = \(l_f,l_mapf).\f .(\(l_A,l_i,l_n).\(A,i,n) : (l_A array,l_i int,l_n int). 
 new l_b. new l_z. if (i==^l_b n) then (A,i,n) 
              else (let mapf = map (l_f,l_mapf) (f) in mapf (l_A,l_i,l_n) (A[i<-f l_z (A[i]^l_z)]^l_A,(+1)^l_i i,n)))^l_mapf
------------------------------------
new l_f. new l_mapf. let f = (\l_z.\z : l_z int. (+1)^l_z z)^l_f in (let mapf = map (l_f,l_mapf) (f) 
                                                                     in mapf (1,2,3) (A,0^2,8^3))
------------------------------------
 
------------------------------------
A : 1 array,
i : 2 int,
n : 3 int,
map : 4 (\(l_f,l_mapf).l_f (\l_z.l_z int ->(l_z) l_z int) ->(l_mapf) 
      l_mapf (\(l_A,l_i,l_n).(l_A array,l_i int,l_n int) ->(l_mapf,l_A,l_i,l_n) (l_A array,l_i int,l_n int)))
------------------------------------
(1 array,2 int,3 int)
------------------------------------


MEMORIA
A = {1,2,3,4,3,2,1,2},
i = 8,
n = 8,
b = true,
z = 2,
f = \().\z . (+1) z,
mapf = \().\(A,i,n) . if (i==n) then (A,i,n) else (let mapf = map () (f) in mapf () (A[i<-f () (A[i])],(+1) i,n)),
map = \().\f . (\(A,i,n) : (A array,i int,n int). if (i==n) then (A,i,n) else (let mapf = map () (f) in mapf () (A[i<-f () (A[i])],(+1) i,n)))^mapf

Reg1  v1 = {1,2,3,4,3,2,1,2}
Reg2  v2 = 8
Reg3  v3 = 8
Reg4  v4 = true
Reg5  v5 = 2
Reg6  v6 = \l_z.\z . (+1)^l_z z
Reg7  v7 = \(l_A,l_i,l_n).\(A,i,n) . if (i==^1 n) then (A,i,n) else (let mapf = map 3 (v3_1) in mapf (l_A,l_i,l_n) (A[i<-v3_1 2 (A[i]^2)]^l_A,(+1)^l_i i,n))


