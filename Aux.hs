

module Aux
 ( 
  -- gestión de variables auxiliares
  isAux,codigo,orden,numero,germen,
  -- espacio de índices para evalación
  New,newNew,newvar,newreg,update,dalloc,
  -- OTRAS AUXILIARES
  -- manejo de secuencias y secuencias de pares
  dosec_,dosec, 
  -- auxiliares de edición
  editss,editsl,formatear,
  -- Operaciones sobre conjuntos (implementados como listas)
  quitar,esta,union,contenido,filtrar,igual,isFun,maximo,
  insert,insertar,ordenar,ordenarPar,
  editToken,num
 )

where

import Data.Char
 
----------------------------------------------------------------------------
-- Variable auxiliar: de la forma v23_786
-- codigo v23_879 = 23 (para las funciónes que no usan el autómata este número es el orden)
-- mumero v23_879 = 879
-- germen v23_879 = v23

isAux ('v' : []) = False
isAux ('v' : cs) = and (map (\c-> isDigit c || c=='_') cs)
isAux _          = False

--codigo y orden: el número después de 'v' (en variables auxiliares de cualquier formato)
--código refiere al número que otorga la gramática
--el orden es el número que corresponde con la linea de la secuencia de operaciones (en los archivos)
codigo ('v' : vs) = num (takeWhile isDigit vs)
codigo vs = 0
orden vs = codigo vs

--número: el número después del código, 
numero ('v' : vs) = num (tail (dropWhile (\c -> c/='_') vs))
numero vs = 0

-- germen v23_879 = v23
germen ('v' : vs) = 'v' : takeWhile (\c -> c/='_') vs
germen vs = vs ++ " es variable sin germen" 

-- Gestión de variables auxiliares: 
-- si (k,i) en new indica que la próxima variable requerida de código k será vk_i

-------------------------------------------------------------------------
-- ESPACIO EXCLUSIVO RAL
--Espacio de Índices
type New = [(Int,Int)] 
-- región, primera locación libre, desde 1 
-- discontinuado para ral, continuo para códigos

newreg new = newreg_ new 1 
 where newreg_ [] j = j
       newreg_ ((r,n):new) j = if j<r then j else newreg_ new (j+1) 

newvar new k = "v"++show k++"_"++show (newloc new k)  
 where newloc [] k = 1  
       newloc ((j,n):new) k = if k==j then n else newloc new k

update new k = update [] new k 
 where update new' [] k = new' ++ [(k,1)] 
       update new' ((j,n):new) k = if k>j then update (new'++[(j,n)]) new k 
                                          else if j == k then new' ++ ((j,n+1):new)
                                                         else new' ++ ((k,1):(j,n):new)                                                    

dalloc [] k = [] -- error ("Aux/dalloc: no existe la región: " ++ show k) 
dalloc ((j,n):new) k = if k==j then (j,n-1) : new else (j,n) : dalloc new k
-----------------------------------------------------------------------------

-- Nuevo espacio de índices
newNew ks = map (\k->(k,1)) (ord ks)
 where ord [] = []
       ord (k:ks) = ins k (ord ks)
       ins k [] = [k]
       ins k (j:ks) = if k<j then k:j:ks else j : ins k ks

---------------------------------------------------------------------------
--Auxiliares para manejo de secuencias de pares

-- dosec [[(1,'a'),(2,'b')],[(1,'c')],[(1,'d'),(2,'e'),(3,'f')]] = [ ([1,1,1],['a','c','d']) , ([1,1,2],['a','c','e']) ,...]
dosec = dopar . dosec_ 
-- dosec_ [[(1,'a'),(2,'b')],[(1,'c')],[(1,'d'),(2,'e'),(3,'f')]] =
--        [ [(1,'a'),(1,'c'),(1,'d')] , [(1,'a'),(1,'c'),(2,'e')] , [(1,'a'),(1,'c'),(3,'f')] , [(2,'b'),(1,'c'),(1,'d')] , ...]
dosec_ ((p:[]):[])  = [[p]]
dosec_ ((p:ps):[])  = [p] : dosec_ (ps:[])
dosec_ ((p:[]):pss) = map ((:) p) (dosec_ pss)
dosec_ ((p:ps):pss) = (map ((:) p) (dosec_ pss)) ++ dosec_ (ps:pss)
dosec_ ([]) = error ("\n Aux/dosec_: secuencia vacía\n\n")
dosec_ ([]:pss) = error ("\n Aux/dosec_: primera secuencia de pares vacía\n\n")
dosec_ pss = error ("\n Aux/dosec_ \n\n")
-- dopar [ [(1,'a'),(1,'c'),(1,'d')] , [(1,'a'),(1,'c'),(2,'e')] ,... ] = [ ([1,1,1],['a','c','d']) , ([1,1,2],['a','c','e']) ,...]
dopar pss = map (\ps -> (map fst ps , map snd ps)) pss

--------------------------------------------------------
-- Auxiliares de edición -------------------------------
-- secuencia
editss [] = ""
editss [s] = s
editss (s:ss) = s ++ "," ++ editss ss

-- secuencia de lineas
editsl [] = ""
editsl [[]] = ""
editsl [s] = s
editsl ([]:ss) = editsl ss
editsl (s:ss) = s ++ "\n" ++ editsl ss

formatear n s = if n < length s then s else  s ++ esp (n-length s)
 where esp 0        = ""
       esp n = esp (n-1) ++ " "
 
---------------------------------------------------------------------------
-- operaciones basicas de Conjunto sobre strings --------------------------

esta v []       = False
esta v (u:w)    | v == u      = True
                | otherwise   = esta v w

union xss = depure (concat xss)
 where depure  s = dep [] s 
       dep s' []      = s'
       dep s' (x:s)   = if esta x s' then dep s' s else dep (s'++[x]) s


quitar [] z    = []
quitar w []    = w
quitar w (u:z) = quitar (q w u) z 
                  where q [] v = []
                        q (u:w) v   |u==v      = q w v
                                    |otherwise = u:(q w v)

contenido [] xs = True
contenido (z:zs) xs = esta z xs && contenido zs xs

igual xs ys = contenido xs ys && contenido ys xs

filtrar [] = []
filtrar (k:ks) = if esta k ks then filtrar ks else k : filtrar ks

maximo [] = 0
maximo (n:ns) = max n (maximo ns)

-- insertar con y sin repetición
insertar x [] = [x]
insertar x (y:ys) = if x <= y then x : y : ys else y : insertar x ys 

insert x [] = [x]
insert x (y:ys) |x == y  = y : ys 
                |x < y   = x : y : ys 
                |x > y   = y :  insert x ys 

ordenar [] = []
ordenar (x:xs) = insertar x (ordenar xs)


ordenarPar [] = []
ordenarPar ((k,a) : ps) = ins (k,a) (ordenarPar ps)
 where ins (k,a) [] = [(k,a)]
       ins (k,a) ((n,b):ps) = if k<=n then (k,a) : (n,b) : ps else (n,b) : ins (k,a) ps 

----------------------------------------------------------------------------
-- es función 1 a 1

isFun [] = []
isFun ((x,y):ps) = if ys==[] then isFun ps else "\n" ++ show (x,y) ++ "\n" ++ show (head ys) ++ "\n"
 where ys = filter (\(z,w) -> z==x && w/=y) ps

is1to1 [] = True
is1to1 ((x,y):ps) = if ys/=[] then False else is1to1 ps
 where ys = filter (\(z,w) -> w==y) ps

----------------------------------------------------------------------------
num :: String -> Int
num ('0':[]) = 0
num ('1':[]) = 1
num ('2':[]) = 2
num ('3':[]) = 3
num ('4':[]) = 4
num ('5':[]) = 5
num ('6':[]) = 6
num ('7':[]) = 7
num ('8':[]) = 8
num ('9':[]) = 9
num (d:cs)   = num (d:[]) * pot (length cs) + num cs
 where pot 0 = 1
       pot k = 10 * pot (k-1)

-------------------------------------------------------------------------------------
-- mensajes de error del parser

editToken ('T':'I':'v':s) = tail s   -- TIv k
editToken ('T':'S':'t':s) = filter ((/=) '\"') (drop 5 s) ++ " "-- TString s
editToken "TTrue" = "true"
editToken "TFalse" = "false"
editToken "TAdd" = "+"
editToken "TInc" = "inc"
editToken "TMinus" = "-"
editToken "TMult" = "*"
editToken "TDiv" = "/"
editToken "TOB" = "("
editToken "TCB" = ")"
editToken "TOr" = "||"
editToken "TAnd" = "&&" 
editToken "TNot" = "not" 
editToken "TMe" = "<"
editToken "TMa" = ">"
editToken "TMi" = "<="
editToken "TEqual" = "=="
editToken "TLet" = "let"
editToken "TIn" = "in"
editToken "TEq" = "="
editToken "TComma" = ","
editToken "TPunto" = "."
editToken "TPComma" = ";"
editToken "THi" = "hi"
editToken "TSu" = "su"
editToken "TUn" = "un"
editToken "TLo" = "lo"
editToken "T2p" = ":"
editToken "Tunit" = "unit"
editToken "Tfl" = "->"
editToken "Tid" = "id"
editToken "Tp1" = "p1"
editToken "Tp2" = "p2"
editToken "TLambda" = "\\"
editToken "TSplit" = "split"
editToken "TAs" = "as"
editToken "TIf" = "if"
editToken "TThen" = "then"
editToken "TElse" = "else"
editToken "TIF" = "@"
editToken "TNew" = "new"
editToken "TAsig" = ":="
editToken "TUpd" = "upd" 
editToken "TEntry" = "ent"
editToken "TDEntry" = "den"
editToken "TOC" = "["
editToken "TCC" = "]"
editToken "TOL" = "{"
editToken "TCL" = "}"
editToken "TCase" = "case"
editToken "TOf" = "of"
editToken "TNull" = "[]"
editToken "TIsNull" = "isnull"
editToken "THead" = "head"
editToken "TTail" = "tail"
editToken "TNod" = "nod"
editToken "TInp" = "inp"
editToken "TAt" = "^"
editToken t = "?"


