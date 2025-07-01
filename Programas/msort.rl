A = {15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0},
B = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
C = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
D = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
b = true,
d = true,
z = 0,
zk = 0,
zi = 0,
copy = \(l_D,(),l_K,(),()).\(D,i,K,j,n) . if (j==^4 n) then K else copy (l_D,0,l_K,0,0) (D,i,K[j<-D[j]^6]^l_K,(+1)^0 j,n),
merge = \(l_B,(),(),l_C,(),(),l_D,()).\(B,k,mk,C,i,mi,D,j) . 
   if ((k==^4 mk)&&^4 (i==^5 mi)) -> D
   @ ((k==^4 mk)&&^4 (i<=^5 mi)) -> merge (l_B,0,0,l_C,0,0,l_D,0) (B,k,mk,C,(+1)^0 i,mi,D[j<-C[i]^8]^l_D,(+1)^0 j)
   @ ((k<=^4 mk)&&^4 (i==^5 mi)) -> merge (l_B,0,0,l_C,0,0,l_D,0) (B,(+1)^0 k,mk,C,i,mi,D[j<-B[k]^7]^l_D,(+1)^0 j)
   @ () -> (let (zk,zi) = (B[k]^7,C[i]^8) in 
   if (zk<=^4 zi) -> merge (l_B,0,0,l_C,0,0,l_D,0) (B,(+1)^0 k,mk,C,i,mi,D[j<-zk]^l_D,(+1)^0 j)
   @ () -> merge (l_B,0,0,l_C,0,0,l_D,0) (B,k,mk,C,(+1)^0 i,mi,D[j<-zi]^l_D,(+1)^0 j)),
msort = \((),l_B,l_C,l_D,(),()).\(A,B,C,D,k,n) . if (==1)^4 n then D[k<-A[k]^6]^l_D else (let m = (%2)^0 n in (let (mk,i,mi) = ((k+^0 m),(k+^0 m),(k+^0 n)) in (let D = msort (0,l_B,l_C,l_D,0,0) (A,B,C,D,k,(%2)^0 n) in (let D = msort (0,l_B,l_C,l_D,0,0) (A,B,C,D,i,(%2)^0 n) in (let (B,C) = (copy (l_D,0,l_B,0,0) (D,k,B,k,mk),copy (l_D,0,l_C,0,0) (D,i,C,i,mi)) in merge (l_B,0,0,l_C,0,0,l_D,0) (B,k,mk,C,i,mi,D,k))))))
------------------------------------
msort (0,1,2,3,0,0) (A,B,C,D,0^0,16^0)
------------------------------------
 
------------------------------------
A : 0 array,
B : 1 array,
C : 2 array,
D : 3 array,
b : 4 bool,
d : 5 bool,
z : 6 int,
zk : 7 int,
zi : 8 int,
copy : 0 (\(l_D,(),l_K,(),()).(l_D array,0 int,l_K array,0 int,0 int) ->(0,4,6,l_D,l_K) l_K array),
merge : 0 (\(l_B,(),(),l_C,(),(),l_D,()).(l_B array,0 int,0 int,l_C array,0 int,0 int,l_D array,0 int) ->(0,4,5,7,8,l_D,l_B,l_C) l_D array),
msort : 0 (\((),l_B,l_C,l_D,(),()).(0 array,l_B array,l_C array,l_D array,0 int,0 int) ->(0,4,5,6,8,7,l_D,l_B,l_C) l_D array)
------------------------------------
3 array
------------------------------------
al no ser lineal lo que queda en C y B no cincide con el global

