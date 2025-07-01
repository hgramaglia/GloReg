
module TypeGlo
 (
  testGlo,tkTauGlo,mapp 
 )

where

import Aux
import Alg
import Exc

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- AUXILIARES PARA TIPADO GLOBAL
-------------------------------------------------------------------------
 
-- (<=) multiple
mleq ts ts' = and (map (\(t,t') -> t <= t') (zip ts ts'))

---------------------------------------------------------------------------------
-- TIPO DE UNA EXPRESIÓN
---------------------------------------------------------------------------------
tkTauGlo = tkTau
tkTau :: Pi -> Exc -> Tau
tkTau pi (Var x) =  if esta x (map fst pi) then tau pi x else error ("Exc/tkTau: la variable " ++ x ++ " no esta en:\n" ++ editPi pi )
tkTau pi (O (k,o,t) es) =  iop t
tkTau pi (Tup es)  =  Prod (map (tkTau pi) es) 
tkTau pi (If e e' e'') = if (tkTau pi e')==(tkTau pi e'') then (tkTau pi e') else 
                         if (tkTauf pi e')==(tkTauf pi e'') then (tkTauf pi e') else  
                         error ("Exc tkTau en if: tipos no coincidentes:\n" ++ 
                                       show (tkTau pi e') ++ "  " ++ show (tkTau pi e'') )     
tkTau pi (Let p e e')  = sust dta (tkTau (comaPip pi p lt0) e') -- sustitución inútil: el tipado impide let y = e ... con e: x B
                          where lt0 = tkTau pi e
                                dta = msust [] p (glExcTau lt0) 
tkTau pi (Lam q pe p t e) = --if p==VP "z" then error (show e ++ show (Eff (effects e))) else 
                            FO q p t (Eff (effects e)) (tkTau (comaPip pi p t) e) 
                          --(sust dta (tkTau (comaPip pi p t) e))  
                          where dta = msust [] p (glExcTau t) 
tkTau pi (App f ep e) = case tau pi f of
                        FO q p t ef t' -> sust dta t'  where dta = msust [] p (mapp pi e) 
                        Fun t t'  -> t'
                        a         -> error ("Exc tkTau: " ++ f ++ " no es función: " ++ show a)
tkTau pi (Case q e e' pp p e'')  = case tkTau pi e of
                                 List q t   -> tkTau (comaPip pi p (Prod [t,List q t])) e' 
                                 _          -> error ("Exc tkTau en case: el tipo no es lista " ++ show (tkTau pi e) ) 
tkTau pi (Sec e e')  = tkTau pi e' 
tkTau pi (New e e')  = tkTau pi e' 
tkTau pi (e)  = error ("TypeGlo/tkTau: " ++ show e)

-- tkTau múltiple
mtkTau pi es = map (tkTau pi) es 
---------------------------------------------------------------------------------
-- Obtener el tipo mas informativo de un expresión
tkTauf pi (Var x) =  if esta x (map fst pi) then case tau pi x of
                                                  Q q s     -> Q (Gl (Var x)) s 
                                                  List q s  -> List (Gl (Var x)) s 
                                                  t         -> t 
                     else error ("Exc/tkTauf: la variable " ++ x ++ " no esta en:\n" ++ editPi pi )
tkTauf pi (O (k,o,t) es) =  iop t
tkTauf pi (Tup es)  =  Prod (map (tkTauf pi) es) 
tkTauf pi (If e e' e'') = if (tkTauf pi e')==(tkTauf pi e') then (tkTauf pi e') 
                         else error ("Exc tkTauf en if: tipos no coincidentes:\n" ++ 
                                      show (tkTauf pi e') ++ "  " ++ show (tkTauf pi e'') )     
tkTauf pi (Let p e e') = sust dta (tkTauf (comaPip pi p lt0) e')  
                          where lt0 = tkTauf pi e
                                dta = msust [] p (glExcTau lt0) 
tkTauf pi (Lam q pe p t e) = FO q p t (Eff (effects e)) (sust dta (tkTauf (comaPip pi p t) e))  
                          where dta = msust [] p (glExcTau t) 
tkTauf pi (App f ep e) = case tau pi f of
                       FO q p t ef t' -> sust dta t'  where dta = msust [] p (glExcTau (tkTauf pi e))  
                       Fun t t'  -> t'
                       a         -> error ("Exc tkTauf: " ++ f ++ " no es función: " ++ show a)
tkTauf pi (Case q e e' pp p e'')   = case tkTauf pi e of
                                 List q t   -> tkTauf (comaPip pi  p (Prod [t,List q t])) e' 
                                 _          -> error ("Exc tkTauf en case: el tipo no es lista " ++ show (tkTauf pi e) ) 
tkTauf pi (Sec e e')  = tkTauf pi e'
tkTauf pi (New e e')  = tkTauf pi e' 

-- tkTauf múltiple
mtkTauf pi es = map (tkTauf pi) es 

-- mapa T -> p_T del artículo pero devuelve el patrón con fomormato de expresión, lo = ()
glExcTau (Q (Gl (Var x)) a) = Var x
glExcTau (Q q a) = Tup []
glExcTau (List (Gl (Var x)) a) = Var x
glExcTau (List q a) = Tup []
glExcTau (Prod ts) = Tup (map glExcTau ts)
glExcTau (Fun t1 t2) = Tup []
glExcTau (FO (Gl (Var x)) p t ef t') = Var x
glExcTau (FO q p t ef t') = Tup []
glExcTau t = error ("Exc:glExcTau: " ++ show t)

-- mapa p^\Gamma e
-- para usar mapa sustitución devuelve expresión en lugar de patrón
mapp pi (Var x) =  Var x
mapp pi (O (k,o,t) es) = glExcTau (iop t)
mapp pi (Tup es)  =  Tup (map (mapp pi) es) 
mapp pi (Lam (Gl (Var x)) pe p t e) =  Var x
mapp pi (Lam q pe p t e) =  Tup []
mapp pi (If e e' e'') = if (mapp pi e')==(mapp pi e'') then (mapp pi e') 
                         else error ("Exc:mapp en if: exc. no coincidentes:\n" ++ show (mapp pi e') 
                                      ++ "  " ++ show (mapp pi e'') )     
mapp pi (Let p e e') =  mapp pi (sust dta e')  where dta = msust [] p (mapp pi e) 
mapp pi (App f ep e) = case tau pi f of
                       FO q p t ef t' -> glExcTau (sust dta t')  where dta = msust [] p (mapp pi e)  
                       Fun t t'  -> glExcTau t'
                       a         -> error ("Exc mapp: " ++ f ++ " no es función: " ++ show a)
mapp pi (Case q e e' p pp e'')  = case tkTau pi e of
                                 List q t -> if (mapp pi e')==(mapp ( comaPip pi p (Prod [t,List q t])) e'')
                                             then (mapp pi e')
                                             else error ("Exc:mapp en case: exc. no coincidentes:\n" ++ show (mapp pi e') 
                                                          ++ "  " ++ show (mapp (comaPip pi p (Prod [t,List q t])) e''))  
                                 _          -> error ("Exc:mapp en case: el tipo no es lista " ++ show (tkTau pi e) )
mapp pi (Sec e e') =  mapp pi e' 
                                  
mmapp pi es = map (mapp pi) es 

-----------------------------------------------
-- RELACIÓN CON LOS OPERADORES TEÓRICOS: 
-- si T = tkTauf pi e , entonces p_T = p^pi e
-- O sea p^pi e es el patrón del tipo mas 
-- informativo que se le puede dar a e
-----------------------------------------------

------------------------------------------------------------------------------------------
-- TEST DE TIPOS GLOBAL 
------------------------------------------------------------------------------------------
-- Las funciones devuelven secuencias de string
-- [] = True

testGlo pi (str,e) phi t = tStr str phi pi ++ tExc pi e phi t

--Tipado de tuplas
mtExc [] [] phi [] = []
mtExc (pi:pis) (e:es) phi (t:ts) = (tExc pi e phi t) ++ (mtExc pis es phi ts)
mtExc pis es phi ts = ["mtExc: distintas long. de secuencias\n"]



tExc :: Pi -> Exc -> [Eff] -> Tau -> [String]

 
tExc pi (Var x) phi t = if esta x (map fst pi) then 
                           if t==tx then []
                           else if tx <= t && (qTau t)==(Gl (Var x)) then []
                                else ["en el contexto\n" ++ editPi pi ++ "\nla variable " 
                                        ++ x ++ " no tiene tipo <= que  "++ show t ++ "\n"]
                    else ["la variable " ++ x ++ " no esta en el contexto " ++  editPi pi ++ "\n"]
  where tx  = tau pi x  

-- diferencia con reg: los inputs no se testean, el efcto refiere solo a la escritura, no al uso
tExc pi (O (k,o,t) es) phi t0 = 
 if contenido (effects t) phi then -- contenido (concat (map effects ts) ++ effects t) phi then 
 if (iop t)==t0 then
  case length (dop t) of
   0     -> []
   k     -> if mleq (dop t) ts then mtExc pis es phi ts  
            -- if  o==ConOp then error (editTaus (ts++[t])) else mtExc pis es ts 
            else ["operador " ++ show (O (k,o,t) es) ++ " con input de tipo incorrecto:\ntipo calculado: " 
                                      ++ editTaus ts ++ "\ntipo del operador: "++ show (dop t) ++ "\n"] 
             where pis = [pi | i <- [1..length es]]
 else [codop o ++ ": el tipo de output esperado -" ++ show t0 ++  
       "- no coincide con el del operador: " ++ show  (iop t) ++ "\n" ++ show (O (k,o,t) es) ++ "\n"]
 else [codop o ++ ": las variables " ++ show (concat (map globals ts) ++ globals t) ++ 
       " deberían ser variables globales activas. Activas:" ++ show phi ++ "\n"] 
 where ts = mtkTauf pi es

-- con mtkTau se tipa incorrectamentetiene (==0) x, con (==0) : x int->lo bool (pi x = lo int) (ver fact3, fib1, etc.)
-- con esta modificación muygl.gl lograría tipar con el algoritmo (todo local)
-- IMPLEMENTACIÓN: se usa p_{tkTauf pi e} = mapp pi e (como patrón)  


-- a diferencia de regiones no se testea que p sea disjunto con pi
tExc pi (Lam Lo pp p t e) phi (FO Lo p' td ef ti) =  
  if  p' == p then if  pycTest pi p t == [] 
                   then tExc (comaPip [] p td) (tkexc p) [] td ++ tExc (comaPip pi p t) e (effects ef) ti 
                   else pycTest pi p t
              else ["Lambda: tipo con patrones incompatibles\n" ++ show pp ++ "    " ++ show p' ++ "\n"]      
 where  tkexc (VP x) = Var x
        tkexc (P ps) = Tup (map tkexc ps)

tExc pi (Lam (Gl (Var x)) pp p t e) phi (FO (Gl (Var x')) p' td ef ti) =  
   if x == x' then 
   if contenido [EffVar x] phi then 
   if p' == p then if pycTest pi p t == [] 
                   then --if x=="f" then error (show (fv ef)) else 
                        tExc (comaPip [] p td) (tkexc p) [] td ++ tExc (comaPip pi p t) e (effects ef) ti 
                   else pycTest pi p t
              else ["Lambda: tipo con patrones incompatibles\n" ++ show pp ++ "    " ++ show p' ++ "\n"]      
   else ["Lambda: variable global " ++ x ++ " no está en phi = " ++  show phi ++ "\n"]
   else ["Lambda: variables globales incompatibles\n" ++ show x ++ "    " ++ show x' ++ "\n"]      
 where  tkexc (VP x) = Var x
        tkexc (P ps) = Tup (map tkexc ps)
       
tExc pi (Tup []) phi t = []

tExc pi (Tup es) phi (Prod ts) =  if length ts == length es 
                                  then mtExc [pi | i <- [1..length es]] es phi ts
                                  else ["tupla: las longitudes tupla y tipo no coinciden\n"  ++ 
                                        show (Tup es) ++ "\n"  ++ show (Prod ts) ++"\n"]
 where
  editseq  []           = []
  editseq [pi] =  "[" ++ editPi pi ++ "]"
  editseq  (pi:pis) =  "[" ++ editPi pi ++ "] " ++ editseq pis

tExc pi (If e e' e'') phi lt =  --error (editPi (head (tail pis)))
                            mtExc pis [e,e',e''] phi [lt0,lt,lt] 
 where lt0 = tkTau pi e
       pis = [pi,pi,pi]
       editseq  []           = []
       editseq [pi] =  "[" ++ editPi pi ++ "]"
       editseq  (pi:pis) =  "[" ++ editPi pi ++ "] " ++ editseq pis


tExc pi (IF ((e,e'):[])) phi lt = tExc pi e' phi lt

tExc pi (IF ((e,e'):ps)) phi lt =  mtExc pis [e,e',IF ps] phi [lt0,lt,lt] 
 where lt0 = tkTau pi e
       pis = [pi,pi,pi]

tExc pi (Let p e e' ) phi lt = if lt==lt1 
                               then if pycTest pi p lt0 == [] 
                                    then --if p==VP "f" then error (show e ++ show lt0) else 
                                         stPat p lt0 ++ mtExc [pi,comaPip pi p lt0] [e,e'] phi [lt0,lt1]
                                    else pycTest pi p lt0
                                   --else ["No se puede borrar globalidad con la localidad:\n" ++ 
                                   --       editPi (filter (\(x,t) -> esta x (fv p)) pi2) ++ "\n" ++ 
                                   --       show p  ++ "\n" ++ show lt0 ++ "\n"]
                               else  [show (Let p e e') ++ "\n" ++
                                     "Tipo esperado: " ++  show lt ++ "\n" ++ 
                                     "Tipo calculado de " ++ show e' ++ ":  " ++  show lt1 ++ "\n"]
 where
  lt0 = tkTau pi e -- sust dta (tkTau pi e)      
  dta = msust [] p (mapp pi e)      
  lt1 = lt -- sust dta lt
  editseq  []           = []
  editseq [pi] =  "[" ++ editPi pi ++ "]"
  editseq  (pi:pis) =  "[" ++ editPi pi ++ "] " ++ editseq pis

tExc pi (App f ep e) phi lt =  -- if f=="f" then error (editPi pi) else
  case tf of
    Fun d i ->  if i==lt && d==td then tExc pi e phi d
                else [f ++ " función y argumento compatibles: " ++ show tf ++ "\n" ++ show e ++ " : " ++ show td ++ 
                       "\n" ++  "Tipo del resultado : " ++ show lt ++ "\n"] 
                   where  td  =  tkTau pi e
    FO q p d ef i -> if not (contenido (effects (sust dta ef)) phi) 
                     then ["App: globales de función " ++ f ++ " aplicada " ++ show (effects (sust dta ef)) 
                           ++ " no contenidos en: " ++ show phi ++ "\n"
                            ++ show (App f ep e) ++ "\n"]
                     else if i'==lt  
                      -- si se pone d en lugar de tkTau entonces el paréntesis sobra
                     then if d' <= te then tExc pi e phi te
                                      else [show (App f ep e) ++ "\n el tipo esperado " ++ show d' ++ 
                                                              " no es <= que el tipo del input " ++ show te ++ "\n"]
                     else [show (App f ep e) ++ "\n" ++ f ++ " for all con output o input no compatible:\n" ++
                           "Tipo de la función en el contexto: " ++  show tf ++ "\n" ++ 
                           "Tipo esperado: " ++  show lt ++ "\n"++ "Tipo de la imagen: " ++ show i' ++ "\n" ]
                        where dta =  msust [] p (mapp pi e)  
                              i'  =  sust dta i
                              d' =  sust dta d
                                                                                          
    _       ->  [f ++ " su tipo no es función ni for all\n"]
 where tf  = tau pi f 
       te  = tkTau pi e

tExc pi (Case q e e' pp p e'' ) phi lt  = ["Case con patrón incorrecto"] 

tExc pi (Sec e e') phi lt    = tExc pi e' phi lt

tExc pi (New e e') phi lt = tExc pi e' phi lt 

tExc pi e phi t = error ("TypeGlo/tExc: sin ecuaciones: " ++ show e ++ " : " ++ show t) 

----------------------------------------------------------------------------------------
-- Test de mapa sustitución para tipos (si cambia Gl x debe ser por Gl w)

tmsust xs [] = []
tmsust xs ((x,Var y) : dta) = tmsust xs dta
tmsust xs ((x,e) : dta) = if esta x xs 
                          then ["No se puede sustituir la referencia " ++ 
                                 x ++ " por una refencia indefinida: " ++ show e ++ "\n"]
                          else tmsust xs dta


----------------------------------------------------------------------------------------
-- tipado de patrones

stPat p t = tExc (comaPip [] p t) (excPat p) [] t
 where excPat (VP x) = Var x
       excPat (P ps) = Tup (map excPat ps)
       
----------------------------------------------------------------------------------------
-- TIPADO DE STORE

tStr str phi pi = tStr_  (reverse str) phi (reverse pi)

tStr_ [] phi pi = []
tStr_ ((x,Vi i) : str) phi ((y,Q (Gl (Var z)) "int") : pi) =
  if not (esta (EffVar y) phi) then ["tStr_: la variable " ++ y ++ " no está en " ++ show phi ++ "\n"] 
  else if x==y then tStr_ str phi pi else ["tStr_: store y contexto no coordinados: " ++ x ++ " /= " ++ y ++ "\n"] 
tStr_ ((x,Vi i) : str) phi ((y,Q q' "int") : pi) =  
  if x==y then tStr_ str phi pi else ["tStr_: store y contexto no coordinados: " ++ x ++ " /= " ++ y ++ "\n"] 
tStr_ ((x,Vb b) : str) phi ((y,Q (Gl (Var z)) "bool") : pi) =
  if not (esta (EffVar y) phi) then ["tStr_: la variable " ++ y ++ " no está en " ++ show phi ++ "\n"] 
  else if x==y then tStr_ str phi pi else ["tStr_: store y contexto no coordinados: " ++ x ++ " /= " ++ y ++ "\n"] 
tStr_ ((x,Vb b) : str) phi ((y,Q q' "bool") : pi) =  
  if x==y then tStr_ str phi pi else ["tStr_: store y contexto no coordinados: " ++ x ++ " /= " ++ y ++ "\n"] 
tStr_ ((x,Va a) : str) phi ((y,Q (Gl (Var z)) "array") : pi) =
  if not (esta (EffVar y) phi) then ["tStr_: la variable " ++ y ++ " no está en " ++ show phi ++ "\n"] 
  else if x==y then tStr_ str phi pi else ["tStr_: store y contexto no coordinados: " ++ x ++ " /= " ++ y ++ "\n"] 
tStr_ ((x,Va a) : str) phi ((y,Q q' "array") : pi) =  
  if x==y then tStr_ str phi pi else ["tStr_: store y contexto no coordinados: " ++ x ++ " /= " ++ y ++ "\n"] 
tStr_ ((x,Vf pp p e) : str) phi ((y,FO q p' td ef ti) : pi) = 
 if x==y then tStr_ str phi pi ++ tExc ((y,FO q p' td ef ti):pi) (Lam q pp p td e) phi (FO q p' td ef ti)
         else ["tStr_: store y contexto no coordinados: " ++ x ++ " /= " ++ y ++ "\n"] 
tStr_ ((x,v) : str) phi ((y,t) : pi) =  
  if x==y then ["tStr_: el valor\n" ++ show v ++ "\ny el tipo\n" ++ show t ++ " no responden a ningún patrón" ++ "\n"] 
          else ["tStr_: store y contexto no coordinados: " ++ x ++ " /= " ++ y ++ "\n"] 

tStr_ ((x,v) : str)  phi [] =  ["tStr_: store y contexto de distinta longitud" ++ "\n"] 


--- PUNTO Y COMA
-- test de punto y coma para global: se aplica comaPip pero se testea primero si es un (;)
pycTest pi (VP x) (Q Lo s) = if not (esta x (map fst pi)) then [] else 
  case qTau (tau pi x) of
   Gl (Var y) -> ["Punto y coma indefinido para " ++ x ++ ": " ++ 
                           show (tau pi x) ++ "<-" ++ show (Q Lo s)++"\n"]
   _  -> []
pycTest pi (VP x) (FO Lo pp p t t') = if not (esta x (map fst pi)) then [] else 
  case qTau (tau pi x) of
   (Gl (Var y)) -> ["Punto y coma indefinido para " ++ x ++ ": " ++ show (tau pi x) ++ "<-" ++ 
                                                          show (FO Lo pp p t t')++"\n"]
   _  -> []
pycTest pi (VP x) (Q q s) = []
pycTest pi (VP x) (FO q pp p t t') = []
pycTest pi (P ps) (Prod ts) = concat (map (\(p,t) -> pycTest pi p t) (zip ps ts))
pycTest pi p t = error ("TypeGlo:pycTest")
