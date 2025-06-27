
module Exc
 (
  FV(fv),Effects(effects),Sust(sust),Globals(globals),IsRal(isRal),
  Var,Pat(VP,P),
  Qu(Un,Hi,Su,U_,Lo,L_,Gl,Pu,Ef),qvar,
  Tau(Q,Prod,Fun,List,FO,ApT),dom,im,qTau,
  Taus,editTaus,
  Sigma, editSigma,iop,dop,
  Exc(Var,O,Tup,Lam,App,If,Let,Case,Spl,IF,Sec,New),editcom,fl,
  Eff(EffVar,Place,LPlace,Eff),Effs,
  Value(Vi,Vb,Vf,Va,VN,Vl),eqValue,
  Delta,msust,msustEff,editDelta,delta,
  Pi,editPi,editPis,tau,comaPip,
  Str,editStr,editStrC,editMem,editFun,value,showResult,comaStr,bvVar,
    -- gestión de regiones iniciales
  iniciales 
 )

where

import Aux
import Alg

-- CLASES PROPIAS
class FV a where 
 fv :: a -> [Var]
class Sust a where
 sust :: Delta -> a -> a
class Effects a where
 effects :: a -> [Eff]
class Globals a where
 globals :: a -> [Var]
class IsRal a where
 isRal :: a -> Bool
--------------------------------------------------------------------------
-- Variables, Patrones ---------------------------------------------------

type Var         = String

data Pat         = VP Var  | P [Pat]
 deriving (Eq)
instance Show Pat where 
 show (VP x) = x
 show (P ps) = "(" ++ editss (map show ps) ++ ")"
instance Ord Pat where
-- Pat implementa a Pat del artículo haciendo P [] = Lo
 (<=) (P []) (VP x) = True
 (<=) (VP z) (VP x) = (x==z)
 (<=) (P ps) (P ps') = length ps == length ps' && and (map (\(p,p') -> (<=) p p') (zip ps ps'))
 (<=) p p' = False --error ("Exc/(<=) patrones: " ++ show p ++ "     " ++ show p' ++ "\n")
instance FV Pat where
 fv (VP x) = [x]
 fv (P ps) = union (map fv ps)
instance Effects Pat where
 effects (VP x) = [EffVar x]
 effects (P ps) = union (map effects ps)
-------------------------------------------------------------------------
-- Types ----------------------------------------------------------------

data Qu  = Un  | Hi | Su | Pu |  U_ | Lo | L_ | Gl Exc | Ef Eff
-- U_ representación interna de un! (se fija en subestructuralización)    
-- L_ representación interna de lo! (se fija en globalización)    
instance Show Qu where
 show Su  = "su"
 show Hi  = "hi"
 show Un  = "un"
 show U_  = "un!"
 show Lo  = "lo"
 show L_  = "lo!"
 show Pu  = "pu"  
 show (Gl e) = show e
 show (Ef e) = show e
instance Eq Qu where
  (==) Su Su  = True
  (==) Un Un = True
-- Tipado Global: Orden representa cantidad de información
  (==) Lo Lo          = True
  (==) (Gl e) (Gl e') = e == e'    
--  Ral 
  (==) (Ef e) (Ef e') = igual (effects e) (effects e')
  (==) q q' = False
instance FV Qu where
 fv (Gl e) = fv e
 fv (Ef e) = fv e
 fv q = []
  -- Tipado Subestructural: Orden representa posibilidades de uso (se testea en tipos no en pseudotipos)
instance Ord Qu where
  (<=) Su q  = True
  (<=) Un Un = True
-- Tipado Global: Orden representa cantidad de información
  (<=) Lo q'          = True
  (<=) (Gl e) (Gl e') = e == e'   -- NO SE USA: SUBSUMIDO EN Ef  
--  Ral 
  (<=) (Ef e) (Ef e') = contenido (effects e) (effects e')
-- resto de los casos
  (<=) q q'           = if q == q' then True else False
instance IsRal Qu where
 isRal (Ef e) = True
 isRal _      = False
-- HACER CALIFICAGOR (GLOBAL O DE REGIONES) DESDE UNA VARIABLE
qvar ('l' : '_' : s) = Ef (EffVar ('l' : '_' : s)) 
qvar s = Gl (Var s) 
 
data Tau = Q Qu String 
         | Prod [Tau]   -- no se alojan en memoria
         | Fun Tau Tau  -- son siempre irrestrictas
         | List Qu Tau  
         | FO Qu Pat Tau Eff Tau -- forall, aplicación para tipado global y regiones
                                 -- para global se toma EffVar = Gl
         | ApT Tau Exc
instance Eq Tau where  
 (==) (List q t) (List q' t') =  q == q' && t == t' 
 (==) (Q q s) (Q q' s') = q == q' && s==s'
 (==) (Prod ts) (Prod ts') = and (map (\(t,t') -> t == t') (zip ts ts'))
 (==) (FO q p t e t1) (FO q' p' t' e' t1') = q==q' && p==p' && t==t' && e==e' && t1==t1'
 (==) t t' = False -- error ("Exc/== de Tau")
instance Show Tau where  
 show (Q q s) = show q ++ " " ++ s
 show (Prod lts) = "(" ++ editProd lts ++ ")"
                      where editProd [] = ""
                            editProd  [lt] =  show lt 
                            editProd  (lt:lts) = show lt ++ "," ++ editProd lts
 show (Fun lt lt') =  show lt ++ "-> " ++ show lt'
 show (List q t) =  show q ++ " " ++ "[" ++ show t ++ "]"
 show (FO q p t e t') =  show q ++" "++ --if isRal t' then
                                         "(\\" ++ show p ++ "." ++  show t ++ " ->" ++ show e ++ " " ++  show t'++")"
                                         --else "(\\" ++ show p ++ ":" ++  show t ++ "." ++  show t'++ ")"
 show (ApT t e) =  "(" ++ show t ++ ")[ " ++  show e ++ "]"
instance FV Tau where  -- para global
 fv (Q q s) = fv q
 fv (Prod lts) = union (map fv lts) 
 fv (Fun lt1 lt2) = union [fv lt1,fv lt2] 
 fv (List q t) = union [fv q,fv t]
 fv (FO q p t e t1) = union [fv q,quitar (union (fv e : [fv t,fv t1])) (fv p)] 
 fv (ApT a b) = union [fv a,fv b]
instance Ord Tau where
 (<=) (List q t) (List q' t') =  q <= q' && t <= t' 
 (<=) (Q q s) (Q q' s') = q <= q' && s==s'
 (<=) (Prod ts) (Prod ts') = and (map (\(t,t') -> t <= t') (zip ts ts'))
 (<=) (FO q p t e t1) (FO q' p' t' e' t1') = q <= q'
 (<=) t t' = t==t'
instance Effects Tau where
 effects (Q (Ef e) s) = effects e
 effects (List (Ef e) s) = filtrar (effects e ++ effects s)
 effects (Q (Gl (Var x)) s) = [EffVar x]
 effects (List (Gl (Var x)) s) = filtrar ([EffVar x] ++ effects s)
 effects (Q q s) = []
 effects (List q s) = []
 effects (Prod ts) = (filtrar.concat) (map effects ts)
 effects (Fun t t') = effects t'                           -- sólo se usa para el tipo de los operadores
 effects (FO q p t e t') = quitar (effects e) (eff p)
   where eff (VP x) = [EffVar x]
         eff (P ps) = concat (map eff ps)
 effects t = error ("Exc/effects: " ++ show t)
instance Globals Tau where
 globals (Q (Gl e) s) = fv e
 globals (List (Gl e) s) = filtrar (fv e ++ globals s)
 globals (Q q s) = []
 globals (List q s) = []
 globals (Prod ts) = (filtrar.concat) (map globals ts)
 globals (Fun t t') = globals t'                           -- sólo se usa para el tipo de los operadores
 globals (FO q p t e t') = quitar (toVarList e) (fv p)
  where toVarList (EffVar x) = [x]
        toVarList e = []
        toVarList (Eff efs) = concat (map toVarList efs)
 globals t = error ("Exc/globals: " ++ show t)
instance IsRal Tau where
 isRal (Q q s) = isRal q
 isRal (List q s) = isRal q
 isRal (Prod ts) = and (map isRal ts)
 isRal (Fun t t') = isRal t'  -- los operadores pueden ser lo int -> x int
 isRal (FO q p t e t') = isRal t && isRal t'
 isRal t = error ("Exc/isRal: " ++ show t)

dom (Fun t0 t1) = t0
dom (FO q p t0 e t1) = t0
dom _ = error ("dom: no tiene tipo funcional")

im (Fun lt0 lt1) = lt1
im (FO q p t0 e t1) = t1
im (Q q s) = error ("im: no tiene tipo funcional: es tipo básico")
im t = error ("im: no tiene tipo funcional: " ++ show t)

qTau :: Tau -> Qu
qTau (Q q a) = q
qTau (List q t) = q
qTau (Fun t1 t2) = Un
qTau (FO q x t e t') = q
qTau (Prod ts) = error ("qTau: el tipo producto no tiene calificación: " ++ show (Prod ts))
qTau (ApT t e) = error ("qTau: el tipo \"aplicación\" no tiene calificación: " ++ show (ApT t e))
-- Secuencias de tipos 
type Taus = [Tau]
editTaus []  = []
editTaus  [t] =  show t 
editTaus (t:ts) = show t ++ ", " ++ editTaus ts
-----------------------------------------------------------------------------
-- Signatura ----------------------------------------------------------------
type Sigma = [(Int,Sig,Tau)]
editSigma []      = []
editSigma [(k,o,t)] =  formatear 3 (codop o) ++ " : " ++ show t 
editSigma ((k,o,t):sig)  = formatear 3 (codop o) ++ " : " ++ show t ++ ",\n" ++ editSigma sig

-- FUNCIONES PARA TIPOS DE OPERADORES DE SIGMA
dop (Q q s) = []
dop (List q s) = []
dop (Fun (Q q s) i) = [(Q q s)]
dop (Fun (List q s) i) = [(List q s)]
dop (Fun (Prod ds) i) = ds
dop (FO q p (Q q' s) e i) = [(Q q' s)]
dop (FO q p (List q' s) e i) = [(List q' s)]
dop (FO q p (Prod ds) e i) = ds
dop t = error ("dop: no es tipo de operador k-ario: " ++ show t)
-- tipo de la imagen                                      
iop (Q q s) = Q q s
iop (List q s) = List q s
iop (Fun d i) = i
iop (FO q p d e i) = i
iop t  = error ("iop: no es tipo de función ni de un operador: " ++  show t)
-----------------------------------------------------------------------------
-- Expresiones del lenguaje (con operadores calificados)

data Exc =   Var Var 
         |   O (Int,Sig,Tau) [Exc]   
         |   Tup [Exc]               
         |   Lam Qu Pat Pat Tau Exc
         |   App Var Eff Exc              
         |   If Exc Exc Exc
         |   IF [(Exc,Exc)]
         |   Let Pat Exc Exc
         |   Spl Qu Exc Pat Exc
         |   Case Qu Exc Exc Pat Pat Exc
         |   Sec Exc Exc
         |   New Eff Exc -- primer Exc es variable o código entero de locación
 deriving (Eq)

instance Show Exc where
 show (Var x) = x
 show (O (k,o,t) es) = --if o==EqOp 0 then error (show t) else 
                       if isRal t then editOpRa o (map show es) ((show.qTau.iop) t)
                                  else editOpRa o (map show es) ((show.qTau.iop) t) -- editOp [] o (map show es) 
 show (Tup []) = "()"
 show (Tup es) = "(" ++ editss (map show es) ++ ")"
 show (App f e e') =  f ++  " "  ++ (if isRal e then show e ++ " " else []) 
                        ++   case e' of
                                      Tup es ->  show e'
                                      _      -> "(" ++ show e' ++ ")"
 show (Lam q p p' t e) = "(" ++ (if isRal e then "\\" ++ show p ++ "." else []) 
                           ++ "\\" ++ show p' ++  " : " ++ show t ++ ". "  ++ show e ++ ")^" ++ show q
 show (Let p e e') = "(let " ++  show p ++  " = "  ++ show e ++ " in " ++ show e'++ ")"
 show (Spl q e p e') = "(split " ++ show q ++  " " ++ show e ++  " as " ++ show p  ++ " in " ++ show e'++ ")"
 show (If e e' e'') = "if " ++ show e ++ " then " ++ show e' ++ " else " ++ show e''
 show (IF ((e,e'):ess)) = "\n   if " ++ show e ++ " -> " ++ show e' ++ "\n" ++ editIF ess
  where editIF [] = []
        editIF [(e,e')] = "   @ " ++ show e ++ " -> " ++ show e' 
        editIF ((e,e'):ess) = "   @ " ++ show e ++ " -> " ++ show e' ++ "\n" ++ editIF ess
 show (Case q e e' (P [VP l,VP ls]) (P [VP x,VP xs]) e'') = 
  "case " ++ show q ++ " " ++ show e ++ " of (" ++ show e' ++ ",(" ++ l ++ ":" ++ ls ++ ")" ++
                                                                "(" ++ x ++ ":" ++ xs ++ ")->" ++ show e''++ ")"
 show (Case q e e' (P []) (P [VP x,VP xs]) e'') = 
  "case " ++ show q ++ " " ++ show e ++ " of (" ++ show e' ++ ",(" ++ x ++ ":" ++ xs ++ ")->" ++ show e''++ ")"
 show (Sec e e') = show e ++ ";" ++ show e'
 show (New ef e)  = "new " ++ show ef ++ ". " ++ show e 
instance FV Exc where
 fv (Var x) = [x]
 fv (O (k,o,t) es) = union (map fv es) -- union (fv t : map fv es)
 fv (Tup es) = union (map fv es)
 fv (Lam q pe p t a0) =  quitar (fv a0) (fv p)
 fv (App f e e') =  f : fv e'
 fv (If e a0 a1) = union [fv e, fv a0, fv a1] 
 fv (IF ees) = union (map (fv.fst) ees ++ map (fv.snd) ees)
 fv (Let p a0 a1) =  union [(fv a0) , (quitar (fv a1) (fv p))]
 fv (Spl q a0 p a1) =  union [(fv a0) , (quitar (fv a1) (fv p))]
 fv (Case q e a0 pp p a1) =  union [fv e,fv a0,quitar (quitar (fv a1) (fv p)) (fv pp)]
 fv (Sec e e') = union [fv e, fv e'] 
 fv (New l e) = fv e 
instance IsRal Exc where  -- si se usa isRal para discriminar no puede haber diferencia en el caso variable!!
 isRal (Var x) = True
 isRal (O (k,o,t) es) = isRal t 
 isRal (Tup es) = and (map isRal es)
 isRal (Lam q p p' t a0) =  isRal a0
 isRal (App f e e') =  isRal e && isRal e'
 isRal (If e a0 a1) = and [isRal e, isRal a0, isRal a1] 
 isRal (IF ees) = and (map (isRal.fst) ees ++ map (isRal.snd) ees)
 isRal (Let p a0 a1) =  and [(isRal a0) , (isRal a1)]
 isRal (Spl q a0 p a1) = and [(isRal a0) , (isRal a1) ]
 isRal (Case q e a0 pp p a1) =  and [isRal e,isRal a0,isRal a1]
 isRal (Sec e e') = and [isRal e, isRal e'] 
 isRal (New l e) = True  
instance Effects Exc where  
 effects (Var x) = []
 effects (O (k,o,t) es) = --error (show t ++ show (O (k,o,t) es) ++ "\n" ++ show (effects t))
                           union (effects t : map  effects es) 
 effects (Tup es) = union (map  effects es)
 effects (App f e e') =  union [effects e,effects e']
 effects (Lam (Ef ef) p p' t e) =  union [effects ef,quitar (effects e) (effects p)]
 effects (Lam q p p' t e) =  quitar (effects e) (effects p)
 effects (If e a0 a1) = union [ effects e, effects a0, effects a1] 
 effects (IF ees) = union (map ( effects.fst) ees ++ map ( effects.snd) ees)
 effects (Let p a0 a1) =  union [ effects a0, effects a1]
 effects (Spl q a0 p a1) =  union [ effects a0, effects a1]
 effects (Case q e a0 pp p a1) =  union [ effects e, effects a0,quitar ( effects a1) (effects pp)]
 effects (Sec e e') = union [ effects e, effects e'] 
 effects (New el e) = quitar ( effects e) (effects el)   
--VARIABLES LIBRES DE LOCACIÓN
fl e = map var (filter f (effects e))
 where var (EffVar x) = x
       f (EffVar x) = True
       f ef = False
       
-------------------------------------------------------------------------------------------------
-- Edición de comando: pone asignación (operador con tipo Q (Gl x) s) y elimina var. de patrones

editcom xs (Var x) = x
editcom xs  (O (k,o,t) es) = editOpc x o (map (editcom xs) es)
 where x = case (qTau (iop t)) of
             Gl (Var x)    -> x
             Ef (EffVar x) -> x
             _             -> []
editcom xs (Tup []) = "()"
editcom xs (Tup es) = "(" ++ editss (map (editcom xs) es) ++ ")"
editcom xs (App f e e') =  f ++ " (" ++ editcom xs e' ++ ")"
editcom xs (Lam (Gl (Var x)) pe p t e) = x ++ ":=(" ++ "\\" ++ show p' ++  " . "  ++ editcom xs e ++ ")"
                             where p' = localpat p xs
editcom xs (Lam q pe p t e) = "(" ++ "\\" ++ show p' ++  " . "  ++ editcom xs e ++ ")"
                             where p' = localpat p xs
editcom xs (Let p e e') = "(let " ++  show p' ++  " = "  ++ editcom xs e ++ " in " ++ editcom xs e'++ ")"
                            where  p' = localpat p xs
editcom xs (Spl q e p e') = "(split " ++ editcom xs e ++ " as " ++  show p' ++  " in " ++ editcom xs e'++ ")"
                            where  p' = localpat p xs
editcom xs (If e e' e'') = "(if " ++ editcom xs e ++ " then " ++ editcom xs e' ++ " else " ++ editcom xs e''++ ")"
editcom xs (IF ((e,e'):ess)) = "\n   if " ++ editcom xs e ++ " -> " ++ editcom xs e' ++ "\n" ++ editIF ess
  where editIF [] = []
        editIF [(e,e')] = "   @ " ++ editcom xs e ++ " -> " ++ editcom xs e' 
        editIF ((e,e'):ess) = "   @ " ++ editcom xs e ++ " -> " ++ editcom xs e' ++ "\n" ++ editIF ess
editcom xs (Case q e e' pp p e'') = 
 "(case " ++ editcom xs e ++ " of (" ++ editcom xs e' ++ "," ++ localcase pp xs ++ localcase p xs ++ "->" ++ editcom xs e''++ "))"
  where localcase (P [VP z,VP zs]) xs = "("++z++":"++zs++")" 
  
editcom xs (Sec e e') = editcom xs e ++ ";" ++ editcom xs e'
editcom xs (New l e) =  editcom xs e 

-- auxiliar de edición de comandos
localpat (VP r) xs = if esta r xs then P [] else VP r
localpat (P []) xs = P [] 
localpat (P ps) xs = P (map (\q -> localpat q xs) ps)


--------------------------------------------------------------------------------
-- Effect ----------------------------------------------------------------------


data Eff = EffVar Var | Place Int | LPlace Int Int Int | Eff [Eff]
instance Eq Eff where
 (==) (Place k) (Place j) = k==j
 (==) (LPlace k i n) (LPlace k' i' n') = k==k' && i==i' && n==n'
 (==) (EffVar x) (EffVar y) = x==y
 (==) (Eff efs) (Eff efs') = igual efs efs'
 (==) ef ef' = False
instance Ord Eff where
-- (<=) (LPlace n i j) (LPlace n' i' j') = n==n' && i==i' & j==j'
-- (<=) (LPlace n i j) (LPlace n' i' j') = n==n' && i==i' & j==j'
 (<=) ef ef' = contenido (effects ef) (effects ef')
instance Show Eff where
 show (EffVar x) = x
 show (Place i)  = show i
 show (LPlace n i j)  = show n ++ "(" ++ show i ++ ":" ++ show j ++ ")" 
 show (Eff efs)  = "(" ++ editss (map show efs) ++ ")"
instance Effects Eff where
 effects (Place j) = [Place j]
 effects (LPlace n i j) = [Place n,Place i,Place j]
 effects (EffVar x) = [EffVar x]
 effects (Eff efs)  = (filtrar.concat) (map effects efs)
instance FV Eff where
 fv (EffVar x) = [x]
 fv (Place j)  = []
 fv (LPlace n i j)  = []
 fv (Eff efs)  = union (map fv efs)
instance IsRal Eff where
 isRal (EffVar ('l' : '_' : s)) = True
 isRal (Place k) = True
 isRal (Eff es)  = and (map isRal es)
 isRal _ = False

type Effs = [Eff]
instance FV Effs where
 fv efs = fv (Eff efs)

--------------------------------------------------------------------------------
-- Values -----------------------------------------------------------------------

data Value = Vb Bool | Vi Int | Va Array | Vf Pat Pat Exc | VN | Vl Var Var 
                                           -- Patrón de place
 deriving (Eq)

instance Show Value where
 show  (Vi x) = show x
 show  (Vb True) = "true"
 show  (Vb False) = "false"
 show  (Va a) =  showArray a
 show  (VN)   =  "[]"
 show  (Vl x xs) =  "(" ++ x ++  ":"  ++ xs ++ ")"
 show  (Vf pp p e) =   "\\" ++ show pp ++ ".\\" ++ show p ++  " . "  ++ show e 
instance Effects Value where
 effects  (Vf pp p e) = quitar (effects e) (effects pp)
 effects v = []
instance IsRal Value where
 isRal  (Vf pp p e) = case pp of
                       P [] -> isRal e 
                       _    -> True
 
eqValue str (Vb v) str' (Vb v') = v == v'
eqValue str (Vi v) str' (Vi v') = v == v'
eqValue str (Va a) str' (Va a') = a == a'
eqValue str (VN) str' (VN)      = True
eqValue str (Vl x xs) str' (Vl x' xs') = eqValue str (value str x) str' (value str' x') && eqValue str (value str xs) str' (value str' xs')
eqValue str (Vf pp p e) str' (Vf pp' p' e') =  (Lam Lo pp p (Prod []) e)==(Lam Lo pp' p' (Prod []) e')
eqValue str _ str' _ = False

---------------------------------------------------------------------------------
-- SUSTITUCIÓN ------------------------------------------------------------------
--------------------------------------------------------------------------
type Delta = [(Var,Exc)]

delta :: Delta -> Var -> Exc
delta [] x         = Var x
delta ((y,z):d) x  = if x==y then z else delta d x

editDelta [] = []
editDelta ((y,z):[]) = y ++ "->" ++ show z ++ " | "
editDelta ((y,z):d) = y ++ "->" ++ show z ++ "," ++ editDelta d

--------------------------------------------------------------------------
-- Mapa sustitución ------------------------------------------------------
-- Para ejecución

msust xs (P []) e = []
msust xs (VP x) e = if esta x xs then [] else [(x,e)]
msust xs (P ps) (Tup es) = concat (map (\(p,e) -> msust xs p e) (zip ps es))
msust xs p e = error ("msust: no se puede construir el mapa sustitución: " ++ show p ++ "  " ++ show e)

msustEff (P []) e = []
msustEff (VP x) e =  [(x,effToExc e)]
 where effToExc (EffVar x) = Var x
       effToExc (Place j)  = O (0,ViOp j,Q Lo "int") []
       effToExc (LPlace n i j)  = O (0,UpdOp,Q Lo "int") 
                                  [O (0,ViOp n,Q Lo "int") [],O (0,ViOp i,Q Lo "int") [],O (0,ViOp j,Q Lo "int") []]
       effToExc (Eff efs)  = Tup (map effToExc efs)
msustEff (P ps) (Eff es) = concat (map (\(p,e) -> msustEff p e) (zip ps es))
msustEff p e = error ("msustEff: no se puede construir el mapa sustitución: " ++ show p ++ "  " ++ show e)

--------------------------------------------------------------------------
-- Sustitución : definición ----------------------------------------------

instance Sust Qu where
 sust d (Ef (EffVar x)) = case delta d x of
                           Var w             -> Ef (EffVar w)
                           O (k,ViOp j,t) [] -> Ef (Place j)
                           _                 -> Lo 
                           
 sust d (Gl x) = case sust d x of
                   Var w          -> Gl (Var w)
                   O (k,o,t) []   -> error ("Exc/sust: no se puede sustitutir Gl " ++ show x 
                                              ++ " por " ++ show (sust d x))  
                   _              -> Lo
 sust d q      = q

instance Sust Tau where
 sust d (Q Lo a) = Q Lo a  
 sust d (Q q a) = Q (sust d q) a
 sust d (List Lo t) = List Lo (sust d t)
 sust d (List q t) = List (sust d q) (sust d t)
 sust d (Prod ts) = Prod (map (sust d) ts)
 sust d (Fun t1 t2) = Fun (sust d t1) (sust d t2)
 sust d (FO q p t1 e t2) =  FO (sust d q) p' (sust d' t1) (sust d' e) (sust d' t2)
                     where d' = componer d dren
                           p'  = sust dren p
                           dren = map (\x -> (x,Var (fresh x cap))) (fv p)
                           cap =  filterVar (map (delta d) (quitar (fv (Prod [t1,t2])) (fv p)))
 sust d t = error ("sust: no definido en " ++ show t)

instance Sust Pat where
 sust d (VP x)  = case delta d x of
                     Var y  -> VP y
                     e      -> error ("Pat.sust: a la variable " ++ x  ++ " de un patrón se la quiere sustituir por " ++ show e)
 sust d (P ps) = P (map (sust d) ps)

instance Sust Eff where
 sust d (EffVar x)  = excToEff (delta d x)
  where 
   excToEff (Var x) = EffVar x
   excToEff (O (k,ViOp j,t) []) = Place j
   excToEff (O (k,UpdOp,t) [O (k',ViOp n,t') [],O (k'',ViOp i,t'') [],O (k''',ViOp j,t''') []]) = LPlace n i j
   excToEff (Tup es) =  Eff (map excToEff es)
   excToEff e = error ("Exc/excToEff en sust: " ++ show e)
 sust d (Place j)   = Place j
 sust d (LPlace n i j)   = LPlace n i j
 sust d (Eff efs)   = Eff (map (sust d) efs)
  
instance Sust Exc where
 sust d (Var x)  = delta d x
 sust d (O (k,o,t) es) =  O (k,o,(sust d t)) (map (sust d) es)
 sust d (Tup es) = Tup (map (sust d) es)
 sust d (App f e e') = App (var (sust d (Var f))) (sust d e) (sust d e')
                        where var (Var x) = x
                              var _ = error ("Exc/sust: se quiere sustituir una var. de func. por no var. : " ++ f )
 sust d (If e e' e'') = If (sust d e) (sust d e') (sust d e'')
 sust d (IF ees) = IF (map (\(e,e') -> (sust d e,sust d e')) ees)
 sust d (Lam q pe p t e) = Lam (sust d q) pe p' t (sust d' e)
                     where d' = componer d dren
                           p'  = sust dren p
                           dren = map (\x -> (x,Var (fresh x cap))) (fv p)
                           cap =  filterVar (map (delta d) (quitar (fv e) (fv p)))
 sust d (Let p e e') = Let p' (sust d e) (sust d' e') -- no se contempla captura de var de locación !!!
                     where d' = componer d dren
                           p'  = sust dren p
                           dren = map (\x -> (x,Var (fresh x cap))) (fv p)
                           cap =  filterVar (map (delta d) (quitar (fv e') (fv p)))
 sust d (Spl q e p e') = Spl (sust d q) (sust d e)  p' (sust d' e')
                     where d' = componer d dren
                           p'  = sust dren p
                           dren = map (\x -> (x,Var (fresh x cap))) (fv p)
                           cap =  filterVar (map (delta d) (quitar (fv e') (fv p)))
 sust d (Case q e e' pp p e'') = Case (sust d q) (sust d e) (sust d e') pp' p' (sust d' e'')  
                     where d' = componer d dren
                           p'  = sust dren p
                           pp' = sust dren pp
                           dren = map (\x -> (x,Var (fresh x cap))) (fv pp ++ fv p)
                           cap =  filterVar (map (delta d) (quitar (fv e'') (fv pp ++ fv p)))
 sust d (Sec e e') = Sec (sust d e) (sust d e') 
 sust d (New ef e) =  New (sust dren ef) (sust d' e) 
                     where d'  = componer d dren
                           dren = map (\x -> (x,Var (fresh x cap))) (fv ef)
                           cap =  filterVar (map (delta d) (quitar (fl e) (fv ef)))
 sust d e = error ("Exc/sust: "++ show e)
--------------------------------------------------------------------------
-- Auxiliares ------------------------------------------------------------

-- composición de sustituciones 
componer d [] = d
componer d ((y,e):d') = componer ((filter f d)++[(y,e)]) d' 
				where f (x,e') = not (x==y)
-- elección de variable fresca que reemplace a x 
fresh x cap = primado x cap
  where primado x cap = if not (esta x cap) then x else primado (x++"'") cap
-- siempre se sustituye por variables, no tiene efecto
filterVar [] = []
filterVar (Var x : es) = x : filterVar es
filterVar (e : es) =  filterVar es
---------------------------------------------------------------------------------
-- Contextos de tipos -----------------------------------------------------------
type Pi = [(Var,Tau)]
instance IsRal Pi where
  isRal pi = and (map (isRal.snd) pi)
instance FV Pi where
 fv [] = []
 fv ((x,t):pi) = filtrar (fv t ++ fv pi)
instance Effects Pi where 
 effects pi = concat (map (effects.snd) pi)
instance Globals Pi where
 globals pi = concat (map (globals.snd) pi)

editPi [] = []
editPi [(x,t)] = x ++ " : " ++ show t
editPi ((x,t):pi) = x ++ " : " ++ show t ++ ",\n" ++ editPi pi

editPis []  = []
editPis [pi] =  "[" ++ editPi pi ++ "]"
editPis (pi:pis) =  "[" ++ editPi pi ++ "]\n\n" ++ editPis pis

-- Entorno modificado por patrón

comaPip pi p t = limpiar pi (fv p) ++ flat (p,t)
 where limpiar pi xs = filter (\(x,t) -> not (esta x xs)) pi  

--------------------------------------------------------------------------
-- Valor de un contexto en una variable  -----------------------
tau :: Pi -> Var -> Tau
tau pi x = if esta x (map fst pi) then tau_ pi x else error ("Exc/tau: " ++ x ++ " no esta en el entorno:\n" ++ show pi) 
 where tau_ [] x      =   error ("tau: no esta en el entorno: " ++ x ) 
       tau_ ((x,lt):pi) y = if x==y then lt else tau_ pi y
------------------
--Auxiliares Pi
------------------
flat (VP x,lt) = [(x,lt)]
flat (P [],lt) = []
flat (P ps,Prod lts) = concat (map flat (zip ps lts))
flat (p,t) = error ("flat: " ++ show p ++ "   " ++ show t)
--------------------------------------------------------------------------
-- Stores ----------------------------------------------------------------

type Str  = [(Var, Value)]
instance IsRal Str where
 isRal str = and (map (isRal.snd) str)
 
 
editStr [] = []
editStr [(x,v)] =  x ++ " = " ++ show v
editStr ((x,v):str) =  x ++ " = " ++ show v ++ ",\n" ++ editStr str


-- variables de valor básico en store
bvVar [] = []
bvVar ((y,Vf pp p e):str)  = bvVar str
bvVar ((y,v):str) = y : bvVar str  

-- Edit Funciones ---------------------------------------------------------

editFun [] = []
editFun ((x,Vf pp p e):[])   = x ++ " = " ++ show (Vf pp p e) 
editFun ((x,v):[])   =  [] 
editFun ((x,Vf pp p e):str)  = x ++ " = " ++ show (Vf pp p e) ++ ", " ++ editFun str
editFun ((x,v):str)   =  editFun str 

-- Edicion de stores en comandos ----------------------------------------

editStrC xs [] = []
editStrC xs ((x,Vb b):str) =  x ++ " = " ++ show (Vb b) ++ ",\n" ++ editStrC xs str
editStrC xs ((x,Vi b):str) =  x ++ " = " ++ show (Vi b) ++ ",\n" ++ editStrC xs str
editStrC xs ((x,Va b):str) =  x ++ " = " ++ show (Va b) ++ ",\n" ++ editStrC xs str
editStrC xs ((x,VN):str)   =  x ++ " = " ++ show (VN) ++ ",\n" ++ editStrC xs str
editStrC xs ((x,Vl a b):str) =  x ++ " = " ++ show (Vl a b) ++ ",\n" ++ editStrC xs str
editStrC xs ((x,Vf pp p e):str) = --if x=="map" then error (editcom xs e++"\n"++show xs) else
                                  x ++ " = " ++  "(" ++ "\\" ++ show (localpat p xs) ++  " . "  
                                  ++ editcom xs e ++ ")" ++ ",\n" ++ editStrC xs str

-- Edicion de memoria  ----------------------------------------------------

editMem ::  Str -> String
editMem str = editStr pstr  ++ "\n" ++ editReg paux ++ "\n"  -- ++ editReg paux
 where pstr = filter (not.isAux.fst) str--filter (not.isAux.fst) (filter (not.isFun.snd) str)
       paux = partir (ordenv codigo (filter (isAux.fst) str))     
       -- AUXILIARES       
       isFun (Vf pp p e) = True
       isFun _ = False
       -- partir [v1_1= ,v1_2=, v2_1= ] = [ (1,[v1_1= ,v1_2= ]) , (2,[v2_1= ]) ]
       partir [] = []
       partir ((x,v):ps) = (codigo x,[(x,v)] ++ takeWhile (\(y,w) -> codigo x == codigo y) ps) : 
                                              partir (dropWhile (\(y,w) -> codigo x == codigo y) ps) 
       ordenv numvar [] = []
       ordenv numvar (p:ps) = ins numvar p (ordenv numvar ps)
         where
          ins numvar (x,v) [] = [(x,v)]
          ins numvar (x,v) ((y,w):ps) = if numvar x > numvar y then (y,w) : ins numvar (x,v) ps else (x,v) : ((y,w) : ps)
       indexar k [] = []
       indexar k ((x,v):str) = (k,[(x,v)]) : indexar (k+1) str
       -- MUESTRA EL ULTIMO DE LAS REGIONES /= 0
       editR [] = []
       editR ((0,aux):[]) = "Reg 0"  ++ "  v_0" ++ " = " ++  editss (map (show.snd) aux)
       editR ((0,aux):paux) = "Reg 0" ++ "  v_0" ++ " = " ++  editss (map (show.snd) aux)
                                 ++ "\n" ++ editR paux
       editR ((k,aux):[]) = "Reg" ++ show k ++ "  v" ++ show k ++ " = " ++ last (map (show.snd) aux)
       editR ((k,aux):paux) = "Reg" ++ show k ++ "  v" ++ show k ++ " = " ++ last (map (show.snd) aux)
                                 ++ "\n" ++ editR paux
       -- MUESTRA TODO EL STORE
       editReg [] = []
       editReg ((k,aux):[]) = "Reg" ++ show k ++ "  v" ++ show k ++ " = " ++ editss (map (show.snd) aux)
       editReg ((k,aux):paux) = "Reg" ++ show k ++ "  v" ++ show k ++ " = " ++ editss (map (show.snd) aux)
                                 ++ "\n" ++ editReg paux

-- mostrar resultado

showResult str (Var x) =
 case value str x of
   (Vl z zs) -> x ++ "=[" ++ showL str (Vl z zs) ++ "]"
                    where showL str VN = []
                          showL str (Vl z zs) =  if ls==[] then show (value str z) else show (value str z) ++ "," ++ ls  
                                                     where ls = showL str (value str zs)
   (VN)      -> x ++ "=[]"
   v         -> x ++ "=" ++  show v

showResult str (Tup es) = "(" ++ mshowResult str es ++ ")"
                          where mshowResult str [] = []
                                mshowResult str [v] = showResult str v                 
                                mshowResult str (v:vs) = showResult str v ++ "," ++ mshowResult str vs                 


-- operadores coma: str,x->v
{-comaStr str [] = str
comaStr str ((y,v):str') = comaStr ((filter f str)++[(y,v)]) str' 
				where f (x,v) = not (x==y)
-}

comaStr str [] = str
comaStr [] [(y,v)] = [(y,v)]
comaStr ((x1,v1):str) [(x2,v2)] = if x1==x2 then (x2,v2):str else (x1,v1) : comaStr str [(x2,v2)]
comaStr str ((y,v):str') = comaStr (comaStr str [(y,v)]) str' 

limpiarStr str xs = map (limpiar str) xs
 where limpiar [] x = []
       limpiar ((x,v):str) y = if x==y then str else (x,v) : limpiar str y       
       
eliminar [] r = error ("eliminar una var del str: no existe la var " ++ r)
eliminar ((x,v):str) r =  if x==r then str else (x,v) : eliminar str r

--------------------------------------------------------------------------
-- Valor de un environment en una variable  ------------------------------

value :: Str -> Var -> Value

value [] x         =  error ("value: la variable "++x++" no está en el ambiente") 
value ((y,v):str) x = if x==y then v else value str x


----------------------------------------------------------------------------
-- REGIONES DEL STORE Y EL PROGRAMA
----------------------------------------------------------------------------

-- variables iniciales que no son funciones (determinan regiones de memoria)
iniciales (str,e) = max (length str) (maximo 0 (effects e))
 where maximo k [] = k
       maximo k ((Place n):efs) = maximo (max k n) efs
       maximo k (e : efs) = maximo k efs
       
-- longitud
long (str,e) = longS str + longE e

longS str = sum (map longV str)
 where longV (x,Vf pp p e) = longE e
       longV (x,v) = 0
       
longE (New x e) = longE e
longE (Var x) = 0
longE (O (n,o,t) es) = 1 + mlongE es
longE (Tup es) = mlongE es
longE (App f ep e) = longE e
longE (Lam q p p' t e) = longE e
longE (If e a0 a1) = mlongE [e,a0,a1]
longE (IF [(e,e')]) = longE e'
longE (IF ((e,e'):ps)) = mlongE [e,e',IF ps] 
longE (Let p a0 a1) = mlongE [a0,a1]
longE (Case q e eb pp p er) = mlongE [e,eb,er]
longE e = error ("Exc/longE: " ++ show e)
mlongE es = sum (map longE es)




