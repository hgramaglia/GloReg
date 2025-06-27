

module Small
 (
  isCt, isVar, int,exc,
  Modo(Irrestricto,Subestructural,Local,Global,Regiones),isGl,
  Config,insec,cstr,caux,cexc,cnew,cinf,cn,ck,cc,
  correct, intconf,  
  Eval,
  red, partialRed,
  tamb              -- tamaño de memoria
 )
where

import Aux
import Alg
import Exc
--import Sig

-- Conversión entero-expresión calificada, para calificado entero

ent (O (i,ViOp k,t) []) = k
exc k = O (0,ViOp k,Q Lo "int") [] 

-- locación de una variable como expresión de parámetro RAL

locRal x = O (0,ViOp (codigo x),Q Lo "int") [] 

-- desalojo de store auxiliar: elimina la región k
dallocStr aux k = filter (\(x,v) -> codigo x /= k) aux

-------------------------------------------------------------------
-- Formas canónicas -----------------------------------------------

isCt (Var x)   = True
isCt (Tup cts) = and (map isCt cts)
isCt e         = False 

isVar (Var x)    = True
isVar _          = False
 
var (Var x)      = x
var e            = error ("Small/var: " ++ show e ++ " no es variable")

-------------------------------------------------------------------------
-- CONFIGURACIONES ------------------------------------------------------
-------------------------------------------------------------------------

data Modo         = Irrestricto | Subestructural | Local | Global [Var] | Regiones
 deriving (Eq)

isGl (Global xs) = True
isGl _ = False 

type Inf = (Int,Int,Int,[[Int]],[Int])  -- últimos campos: código+dependencias y sec. de inputs (1 o 2)
                                           -- head=código, resto las dependencias
icod (k,n,j,cs,is) = cs

setMmax (m,n,k,cs,is) n'  = (max m n',n,k,cs,is)
setM (m,n,k,cs,is) n' = (max m (n+n'),n+n',k,cs,is)
setP (m,n,k,cs,is) k'  = (m,n,k+k',cs,is)
setC (m,n,k,cs,is) k' ks = (m,n,k,cs++[k':ks],is)
setI (m,n,k,cs,is) k'  = (m,n,k,cs,is++[k'])
setIf (m,n,k,cs,is)    =  if is==[] then error ("setIf: lista de input vacía") else (m,n,k,cs,init is ++ [last is + 1])

-----------------------
-- CONFIGURACIONES
-----------------------

type Config    =  (Str,Str,Exc,New,Inf)   

insec (str,aux,e,new,(m,n,k,cs,is)) = if is==[] then [] else init is 

-------------------------------------------------------------------
-- EVALUACION -----------------------------------------------------
-------------------------------------------------------------------

type Eval     = [Config]

cstr (str,aux,e,new,inf) = str
caux (str,aux,e,new,inf) = aux
cexc (str,aux,e,new,inf) = e
cnew (str,aux,e,new,inf) = new
cinf (str,aux,e,new,inf) = inf

cm (str,aux,e,new,(m,n,k,cs,is)) = m
cn (str,aux,e,new,(m,n,k,cs,is)) = n
ck (str,aux,e,new,(m,n,k,cs,is)) = k
cc (str,aux,e,new,(m,n,k,cs,is)) = cs

red   :: Modo -> Config -> [Config]

red m (str,aux,e,new,inf) = if e==Var "v0_2" then error(show (isCt e)) else 
         if int e  then (str,aux,Var interrupcion,new,inf) : []
         else 
         case isCt e of 
           (True)  -> (str,aux,e,new,inf) : []
           (False) -> case m of 
                        Irrestricto     -> (str,aux,e,new,inf) : red m (sma [] (str,aux,e,new,inf))
                        Subestructural  -> (str,aux,e,new,inf) : red m (sma [] (str,aux,e,new,inf))
                        Regiones        -> (str,aux,e,new,inf) : red m (sma [] (str,aux,e,new,inf))
                        (Global xs )    -> (str,aux,e,new,inf) : red m (sma xs (str,aux,e,new,inf))

partialRed   :: Int -> Modo -> Config -> [Config]
partialRed 0 m (str,aux,e,new,inf)     = [(str,aux,e,new,inf)]
partialRed l m (str,aux,e,new,inf) = 
      case isCt e of 
           (True)  -> (str,aux,e,new,inf) : []
           (False) -> case m of 
                        Irrestricto    -> (str,aux,e,new,inf) : partialRed (l-1) m (sma [] (str,aux,e,new,inf))
                        Subestructural -> (str,aux,e,new,inf) : partialRed (l-1) m (sma [] (str,aux,e,new,inf))
                        Regiones       -> (str,aux,e,new,inf) : partialRed (l-1) m (sma [] (str,aux,e,new,inf))
                        Global   xs    -> (str,aux,e,new,inf) : partialRed (l-1) m (sma xs (str,aux,e,new,inf))

---------------------------------------------------------------------------------
-- Terminación de la ejecución subestructural

interrupcion = "ejecución interrumpida"

intconf (str,aux,e,new,inf) = int e

int (Var x ) = (x == interrupcion)
int (Tup es) = or (map int es) 
int (O (k,o,t) es) = or (map int es)
int (App f ep e) =  int e
int (If e a0 a1) = or (map int [e,a0,a1]) 
int (IF ess) = or (map (\(e,e') -> int e || int e') ess) 
int (Let p a0 a1) =  or (map int [a0,a1])
int (Spl q a0 p a1) =  or (map int [a0,a1])
int (Lam q pe p tr a) =  int a
int (Case q e  a0 pp p a1) =  or (map int [e,a0,a1])
int (Sec a0 a1) =  or (map int [a0,a1])
int (New l a1) =  int a1


---------------------------------------------------------------------------------
-- correccción de la ejecución global respecto del Irrestricto

correct (str,aux,Var x,new,inf) (str',aux',Var x',new',inf') = eqValue (str++aux) (value (str++aux) x) (str'++aux') (value (str'++aux') x') 
correct (str,aux,Tup es,new,inf) (str',aux',Tup es',new',inf') =  
         and (map (\(e,e') -> correct (str,aux,e,new,inf) (str',aux',e',new',inf')) (zip es es'))
correct (str,aux,e,new,inf) (str',aux',e',new',inf') = error ("correct: patrones no compatibles\n" ++ show e ++ "\n" ++ show e')

-------------------------------------------------------------------------------
-- test de continuación

ctest str [] = []
ctest str (x:xs) = if esta x (map fst str) then ctest str xs else x

-------------------------------------------------------------------------------
-- Small Step Semantic --------------------------------------------------------
-------------------------------------------------------------------------------

sma xs (str,aux,Var x,new,inf)         =  (str,aux, Var x,new,inf)

sma xs (str,aux, New (EffVar l) e,new,inf)  = --if k == 1  then error (show new ++ show (update new k)) else 
          (str,aux,New (Place k) (sust [(l,O (k,ViOp k,Q Lo "int") [])] e),update new k,inf)  
    where k = newreg new 

sma xs (str,aux, New (Place k) e,new,inf)  = 
 if isCt e then (str,aux',e,dalloc new k,setM inf (-tamReg aux k)) 
           else  (str1,aux1,New (Place k) e1,new1,inf1) 
 where  aux' = dallocStr aux k
        (str1,aux1,e1,new1,inf1) = sma xs (str,aux,e,new,inf) 

sma xs (str,aux, Lam (Ef (Place k)) pe p t e,new,inf)  = (str,comaStr aux [(x,v)],Var x,update new k,setM inf (tamv (x,v)))
                                        where x = newvar new k
                                              v = Vf pe p e
sma xs (str,aux, Lam Lo pe p t e,new,inf)  = (str,comaStr aux [(x,v)],Var x,update new 0,setM inf (tamv (x,v)))
                                        where x = newvar new 0
                                              v = Vf pe p e
sma xs (str,aux, Lam (Gl (Var x)) pe p t e,new,inf)  = (str',aux',Var x,new,inf)
                where k'  = tkcod str x
                      v = Vf pe p e
                      (str',aux') = if isAux x then (str,comaStr aux [(x,v)]) else (comaStr str [(x,v)],aux)

sma xs (str,aux, Lam q pe p t e,new,inf)  = 
 error ("Small/sma : calificador inapropiado para lambda: " ++ show q) 

sma xs (str,aux, O (k,o,t) es ,new,inf)  = case and (map isCt es)  of
   (True)  ->  
      case qTau (iop t) of
        Ef (Place k')  -> --if o == AddOp && k'==3  then error (show new ++ show (update new k')++show k'++show x') else
                          (str',aux',Var x',update new k',setI (setC (setM inf (tamv (x',v))) k' ks) 1) 
                                        where vs  = map ((value (str++aux)).var) es
                                              x'   = newvar new k' 
                                              ks  = map ((tkcod str).var) es
                                              es' = map (\(Var x) -> x) es
                                              v   = appoc o vs str es'
                                              (str',aux') = if isAux x' then (str,comaStr aux [(x',v)]) 
                                                                        else (comaStr str [(x',v)],aux) 
        Ef (Eff [Place k'])  ->  --if o == ViOp 0 then error (show new ++ show (update new k')++show k'++show x') else
                                      (str',aux',Var x',update new k',setI (setC (setM inf (tamv (x',v))) k' ks) 1) 
                                        where vs  = map ((value (str++aux)).var) es
                                              x'  = newvar new k' 
                                              ks  = map ((tkcod str).var) es
                                              es' = map (\(Var x) -> x) es
                                              v   = appoc o vs str es'
                                              (str',aux') = if isAux x' then (str,comaStr aux [(x',v)]) 
                                                                        else (comaStr str [(x',v)],aux) 
        Ef (LPlace n i j)  ->  (str',aux',Var x',update new j,setI (setC (setM inf (tamv (x',v))) j ks) 1) 
                                        where vs  = map ((value (str++aux)).var) es
                                              x'   = if o==NullOp then newvar new n else newvar new j 
                                              ks  = map ((tkcod str).var) es
                                              es' = map (\(Var x) -> x) es
                                              v   = if length es < 2 
                                                    then VN
                                                    else Vl (head es') (head (tail es'))
                                              (str',aux') = if isAux x' then (str,comaStr aux [(x',v)]) 
                                                                        else (comaStr str [(x',v)],aux) 
        Gl (Var x) ->  (str',aux',Var x',update new k',setI (setC inf k' ks) 1) 
                                        where k'  = tkcod str x
                                              vs  = map ((value (str++aux)).var) es
                                              x'  = x -- newvar new k' 
                                              ks  = map ((tkcod str).var) es
                                              es' = map (\(Var x) -> x) es
                                              v   = appoc o vs str es'
                                              (str',aux') = if isAux x' then (str,comaStr aux [(x',v)]) 
                                                                        else (comaStr str [(x',v)],aux) 
        Lo  -> --if o==ViOp 2 then error (show new ++ show k'++ show (update new k')) else
               (str,comaStr aux [(x,v)],Var x,update new k',setI (setC (setM inf (tamv (x,v))) k' ks) 1)
                          where x   = newvar new 0
                                k'  = codigo x
                                ks  = map ((tkcod str).var) es
                                vs  = map ((value (str++aux)).var) es
                                es' = map (\(Var x) -> x) es
                                v   = appoc o vs str es'
        q  -> error ("Small/sma : calificador inapropiado para el operador  " ++ codop o ++ ": " ++ show q) 

   (False) -> (str',aux',O (k,o,t) (esct ++ (e0': tail esnct)),new',inf') 
                where (str',aux',e0',new',inf') = sma xs (str,aux,e0,new,inf)
                      esct  = takeWhile isCt es
                      esnct = dropWhile isCt es 
                      e0    = head esnct

sma xs (str,aux,App f ep e,new,inf) = 
  case isCt e of
     (False) ->  (str1,aux1,App f ep e1,new1,inf1) 
                    where (str1,aux1,e1,new1,inf1) = sma xs (str,aux,e,new,inf)
     (True)  ->  if ep /= Eff [] then (str,aux,sust mst (sust mstp e0),new,setP inf (length mstp+length mst))
                                 else (str,aux,sust mst e0,new,setP inf (length mst))
                   where vf    = value (str++aux) f
                         mst   = msust xs p0 e
                         mstp  = msustEff pp0 ep
                         p0    = (\(Vf pp p e) -> p) vf
                         pp0   = (\(Vf pp p e) -> pp) vf
                         e0    = case vf of 
                                   Vf pp p e -> e
                                   v -> error ("Small/sma: no es valor: " ++  show v ++ show (str++aux))
                                                          
sma xs (str,aux,Tup es,new,inf) = case and (map isCt es) of
                                    (True)  ->  (str,aux,Tup es,new,inf)
                                    (False) ->  (str',aux',Tup (esct ++ (e': tail esnct)),new',inf') 
                                  where (str',aux',e',new',inf') = sma xs (str,aux, head esnct ,new,inf)
                                        esct  = takeWhile isCt es
                                        esnct = dropWhile isCt es 

sma xs (str,aux, If (Var b) e' e'' ,new,inf)  = 
  if ctest (str++aux) [b] == [] then case value (str++aux) b  of 
                                      (Vb True)  -> (str,aux,e',new,inf) 
                                      (Vb False) -> (str,aux,e'',new,setIf inf)
                                      v          -> error ("sma/If\n " ++ b ++ "==" ++ show v )
                                             else (str,aux, Var ("ejecución interrumpida"),new,inf)
                                  
sma xs (str,aux,If e0 e' e'',new,inf)  = (str',aux',If e0' e' e'',new',inf')   
                                       where (str',aux',e0',new',inf') = sma xs (str,aux,e0,new,inf)
sma xs (str,aux, IF [(Var b,e'),(g2,e'')],new,inf)  = if ctest (str++aux) [b] == [] then case value (str++aux) b  of 
                                                                             (Vb True)  -> (str,aux,e',new,inf) 
                                                                             (Vb False) -> (str,aux,e'',new,setIf inf)
                                                      else (str,aux, Var ("ejecución interrumpida"),new,inf)
sma xs (str,aux, IF ((Var b,e'):ess),new,inf)  = 
    if ctest (str++aux) [b] == [] then case value (str++aux) b  of 
                                         (Vb True)  -> (str,aux,e',new,inf) 
                                         (Vb False) -> (str,aux,IF ess,new,setIf inf)
                                  else (str,aux, Var ("ejecución interrumpida"),new,inf)
sma xs (str,aux, IF ((e,e1):ess),new,inf)  = 
   (str',aux',IF ((e',e1):ess),new',inf')  where (str',aux',e',new',inf') = sma xs (str,aux,e,new,inf)

sma xs (str,aux,Let p e e',new,inf)  = 
      case isCt e of
           (False) ->  (str1,aux1,Let p e1 e',new1,inf1) where (str1,aux1,e1,new1,inf1) = sma xs (str,aux,e,new,inf)
           (True)  ->  --(str,aux,sustExc mst e',new,setP inf (length mst))  
                       (str,aux,sust mst e',new,setP inf (length mst))     where mst   = msust xs p e

sma xs (str,aux,Case q e e' pp p e'',new,inf)  = 
      case e of
         Var x    ->  case value (str++aux) x of  
                      VN      -> (str,aux,e',new,inf)
                      Vl z zs -> --(str,aux,sustExc mst (sustEff mstp e''),new,setIf (setP inf (length mst)))
                                 (str,aux,sust mst (sust mstp e''),new,setIf (setP inf (length mst))) 
                                  where mst = msust xs p (Tup [Var z,Var zs])
                                        mstp = msust [] pp (Tup [O (0,ViOp k,Q Lo "int") [],O (0,ViOp l,Q Lo "int") []])
                                        k    = codigo z
                                        l    = codigo zs
         _  ->  (str1,aux1,Case q e1 e' pp p e'',new1,inf1) where (str1,aux1,e1,new1,inf1) = sma xs (str,aux,e,new,inf)
sma xs (str,aux,Spl q e p e',new,inf)  = 
 case (e,q) of
  (Var x,Su) ->  case value (str++aux) x of  
                  VN      -> error "Small/sma : split con lista vacía"
                  Vl z zs -> (str',aux',sust mst e',new,setIf (setMmax (setP inf (length mst)) (tamb (str'++aux')))) 
                                         where mst = msust [] p (Tup [Var z,Var zs])
                        where str' = filt [x] str
                              aux' = filt [x] aux
  (Var x,_)    ->  case value (str++aux) x of  
                             VN      -> error "Small/sma : split con lista vacía"
                             Vl z zs -> --(str,aux,sustExc mst e',new,setIf (setP inf (length mst))) 
                                        (str,aux,sust mst e',new,setIf (setP inf (length mst))) 
                                         where mst = msust xs p (Tup [Var z,Var zs])
  _       ->  (str1,aux1,Spl q e1 p e',new1,inf1) where (str1,aux1,e1,new1,inf1) = sma xs (str,aux,e,new,inf)
sma xs (str,aux,Sec e e',new,inf)  = 
      case isCt e of
           (False) ->  (str1,aux1,Sec e1 e',new1,inf1) where (str1,aux1,e1,new1,inf1) = sma xs (str,aux,e,new,inf)
           (True)  ->  (str,aux,e',new,inf)


sma xs (str,aux,e,new,inf) = error ("Small sma : no esta implementada la sem. small step para " ++ show e)

-----------------------------------------------------------------------
-- Funciones de tamaño de memoria

-- tam, tamb : Refleja sólo la cantidad de "unidades" de tipos básicos
tamv (x,Vb b)      = 1
tamv (x,Vi i)      = 1 
tamv (x,Vf p ep e) = 1
tamv (x,Va a)      = length a    
tamv (x,VN)        = 1
tamv (x,Vl z zs)   = 1

tamb [] = 0
tamb ((x,Vb b): str)      = 1 + tamb  str
tamb ((x,Vi i): str)      = 1 + tamb  str
tamb ((x,Vl a b): str)    = 1 + tamb  str
tamb ((x,VN): str)        = 1 + tamb  str
tamb ((x,Vf p ep e): str) = 1 + tamb  str               
tamb ((x,Va a): str)      = length a  + tamb  str  

tamReg aux k = tamb (filter (\(x,v) -> codigo x == k) aux)

--maxStr cs = maxL 0 cs
-- where maxL k [] = k
--       maxL k (c:cs) = maxL (max k (length (c str c))) cs 
--       max i j = if i < j then j else i 
                        
-------------------------------------------------------------------------------
-- Aplicar operadores usuales vistos como operadores estandard

appop :: Sig -> [Value] -> Value
appop (VbOp b) vs = Vb b
appop (ViOp i) vs = Vi i
appop IdOp (v:vs) = v
appop AddOp ((Vi n) : ((Vi m) : vs)) = Vi (n+m)
appop IncOp ((Vi n) : vs) = Vi (n+1)
appop AddInvOp ((Vi n) : vs) = Vi (-n)
appop MeOp ((Vi i) : ((Vi i') : vs)) = Vb (i<i')
appop MiOp ((Vi i) : ((Vi i') : vs)) = Vb (i<=i')
appop EqualOp (v : (v' : vs)) = Vb (v==v')
appop MultOp ((Vi n) : ((Vi m) : vs)) = Vi (n*m)
appop SustrOp ((Vi n) : ((Vi m) : vs)) = Vi (n-m)
appop DivOp ((Vi n) : ((Vi m) : vs)) = Vi (div n m)
appop ModOp ((Vi n) : (( Vi m) : vs)) = Vi (mod n m)
appop OrOp ((Vb b) : ((Vb b') : vs)) = Vb (b||b')
appop AndOp ((Vb b) : ((Vb b') : vs)) = Vb (b&&b')
appop P1Op (v1 : (v2 : vs)) = v1
appop P2Op (v1 : (v2 : vs)) = v2
appop NewOp ((Vi n) : vs) = Va (new n)
appop EntryOp ((Va a) : ((Vi i) : vs)) = Vi (entry a i)
appop DEntryOp ((Va a) : ((Vi i) : ((Vi n) : vs))) = Vi (entry a i)
appop UpdOp ((Va a) : ((Vi i) : ((Vi k) : vs))) = Va (upd a i k)
appop (EqOp k) ((Vi n) : vs) = Vb (k==n)
appop (AdOp k) ((Vi n) : vs) = Vi (k+n)
appop (MuOp k) ((Vi n) : vs) = Vi (k*n)
appop (DiOp k) ((Vi n) : vs) = Vi (div n k)
appop (SuOp k) ((Vi n) : vs) = Vi (n-k)
appop NullOp vs = VN
appop IsNullOp ((Vl x xs):vs) = Vb False
appop IsNullOp (VN:vs) = Vb True
appop ConOp vs = error "Small appop: ConOp"
appop HeadOp vs = error "Small appop: HeadOp"
appop TailOp vs = error "Small appop: TailOp"
appop o vs = error ("appop: no esta definida o faltan argumentos para la operación: " ++ (codop o) ++ "   " ++ show vs) 

-- aplicar operador o constructor
appoc o vs str es = case o of
  ConOp  -> if length es < 2 then error "Small appoc : operador (:) con menos de dos argumentos"
                             else Vl (head es) (head (tail es))
  DConOp -> if length es < 3 then error "Small appoc : operador [:] con menos de tres argumentos"
                             else Vl (head (tail es)) (head (tail (tail es)))
  HeadOp  -> if length es < 1 then error "Small appoc : operador head con menos de un argumentos"
                              else valueHead str (head vs)
  TailOp  -> if length es < 1 then error "Small appoc : operador tail con menos de un argumentos"
                              else valueTail str (head vs)                               
  _       -> appop o vs
 where
  valueHead str (Vl x xs) = value str x
  valueHead str v = error ("Small/valueHead: " ++ show v)
  valueTail str (Vl x xs) = value str xs
  valueTail str v = error ("Small/valueTail: " ++ show v)


---------------------------------------------------------------------------------
-- NO EXPORTABLES ---------------------------------------------------------------
---------------------------------------------------------------------------------
-- Funciones auxiliares----------------------------------------------------------

tkcod str x = if isAux x then codigo x else codinicial x (map fst str) 
 where codinicial x [] = 0
       codinicial x (y:ys)  = if x==y then 1 else 1 + codinicial x ys  
---------------------------------------------------------------------
-- Operaciones sobre valores de los tipos primitivos ----------------

fs []      =   error "fs: tupla o array vacio"
fs (x:xs)  = x
sn []      =   error "sn: tupla o array vacio"
sn (x:[])  =   error "sn: tupla o array con sólo un elemento"
sn (x:xs)  = fs xs
th []      =   error "th: tupla o array vacio"
th (x:[])  =   error "th: tupla o array con sólo un elemento"
th (x:(y:[])) =   error "th: tupla o array con sólo dos elemento"
th (x:xs)  = sn xs

--  elimina variables de un store


filt :: [Var] -> Str ->  Str
filt []  str        =  str
filt (x:xs)  str    = filt xs (f x  str)
  where f x [] = []
        f x (p:ps)  = if x == fst p  then f x ps else p : f x ps


