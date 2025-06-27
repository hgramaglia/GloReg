
module TypeReg
 (
  testReg,tkTauReg
 )

where

import Aux
import Alg
import Exc

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- AUXILIARES PARA TIPADO RAL 
-------------------------------------------------------------------------
 
-- (<=) multiple
mleq ts ts' = and (map (\(t,t') -> t <= t') (zip ts ts'))  -- se usa????

---------------------------------------------------------------------------------
-- TIPO DE UNA EXPRESIÓN
---------------------------------------------------------------------------------
tkTauReg :: Pi -> Exc -> Tau
tkTauReg pi (Var x) =  if esta x (map fst pi) then tau pi x 
                       else error ("Exc/tkTauReg: la variable " ++ x ++ " no esta en:\n" ++ editPi pi )
tkTauReg pi (New (EffVar l) e) = sust [(l,Tup [])] (tkTauReg pi e) 
tkTauReg pi (O (k,ConOp,t) es) = List (qTau (iop t)) (tkTauReg pi (head es))
tkTauReg pi (O (k,o,t) es) =  iop t
tkTauReg pi (Tup es)  =  Prod (map (tkTauReg pi) es) 
tkTauReg pi (If e e' e'') = tkTauReg pi e''     
tkTauReg pi (Let p e e')  = tkTauReg (comaPip pi p lt0) e' where lt0 = tkTauReg pi e 
tkTauReg pi (Lam q pe p t e)  = --error (show (effects e))
                              FO q pe t (Eff (effects e)) (tkTauReg (comaPip pi p t) e) 
tkTauReg pi (App f ep e) = --if f=="fact" then error ("||"++ show pi ++ show (App f ep e)) else 
                case tau pi f of
                        FO q p t ef t' ->  sust dta t'  where dta = msustEff p ep 
                        Fun t t'  -> t'
                        a         -> error ("Exc tkTauReg: " ++ f ++ " no es función: " ++ show a)
tkTauReg pi (Case q e e' pp p e'')  = case tkTauReg pi e of
               List q t   -> tkTauReg (comaPip pi p (Prod [t,List q t])) e' 
               _          -> error ("Exc tkTauReg en case: el tipo no es lista " ++ show (tkTauReg pi e) ) 
tkTauReg pi (Sec e e')  = tkTauReg pi e' 
tkTauReg pi e  =  error ("\nExc tkTauReg sin ecuaciones: " ++ show e ) 

-- tkTauReg múltiple
mtkTauReg pi es = map (tkTauReg pi) es 

---------------------------------------------------------------------------------

patExc (Var x) = VP x
patExc (Tup es) = P (map patExc es)
patExc e = P []

patTau (Q (Ef (EffVar x)) a) = VP x
patTau (List (Ef (EffVar x)) a) = VP x
patTau (Prod ts) = P (map patTau ts)
patTau t = P []

---------------------------
-- TEST DE TIPOS : REGIONES
---------------------------
-- Las funciones devuelven secuencias de string
-- [] = True

testReg pi (str,e) phi t = tStr str phi pi ++ tExc pi e phi t

--Tipado de tuplas
mtExc [] [] phi [] = []
mtExc (pi:pis) (e:es) phi (t:ts) = (tExc pi e phi t) ++ (mtExc pis es phi ts)
mtExc pis es phi ts = ["mtExc: distintas long. de secuencias: \n" ++ show es ++ "   " ++ show ts ++ "\n"]

tExc :: Pi -> Exc -> [Eff] -> Tau -> [String]

tExc pi (New s e) phi t =  if esta s (effects t ++ effects pi) 
                                    then [show (New s e) ++ "\n" ++ "la locación  " ++ show s ++ 
                                           " forma parte del tipo o el contexto\n" ++ show t ++ "\n" ++ show pi ++ "\n"] 
                                    else tExc pi e (phi++[s]) t  

tExc pi (Var x) phi t = if esta x (map fst pi) then 
                             if tx==t then []
                             else ["en el contexto\n" ++ editPi pi ++ "\nla variable " 
                                   ++ x ++ " no tiene tipo el tipo solicitado "++ show t ++ "\n"]
                       else ["la variable " ++ x ++ " no esta en el contexto " ++  editPi pi ++ "\n"]
  where tx  = tau pi x  


tExc pi (Lam (Ef a) pp p t e) phi (FO (Ef a') p' td ef ti) =  
  if a == a' then
  if contenido [a] phi then 
                  if and (map (\z -> not (esta z (effects pi))) (effects p')) 
                  then if  p' == pp then tExc (comaPip [] p td) (tkexc p) [] td ++ tExc (comaPip pi p t) e (effects ef) ti 
                                    else ["Lambda: tipo con patrones incompatibles\n" 
                                                 ++ show pp ++ "    " ++ show p' ++ "\n"]      
                       else ["Lambda: los parámetros de reg. no deben estar en el contexto:\n" 
                                                         ++ show pp ++ "    " ++ show (effects pi) ++ "\n"]
  else ["Lambda: region " ++ show a ++ " no está en phi = " ++  show phi ++ "\n"]
  else ["Lambda: las reg. de tipo y lambda: lambda: " ++ show a' ++ "    tipos: " ++ show a ++ "\n"]
 where  tkexc (VP x) = Var x
        tkexc (P ps) = Tup (map tkexc ps) 


tExc pi (App f ep e) phi lt = 
  case tf of
   Fun d i     ->  ["App: la función no es de tipo \\q.T ->[...] T'): " ++ show  (Fun d i) ++ "\n"]
   FO q p d ef i -> if not (contenido (effects (sust dta ef)) phi) 
                    then ["App: patrones de place en " ++ show  (sust dta ef) 
                           ++ " no contenidos en: " ++ show phi ++ "\n"
                            ++ show (App f ep e) ++ "\n"]
                    else if i'==lt &&  td == d' then tExc pi e phi td 
                                         else [show (App f ep e) ++ "\n" ++ 
                                                              "for all con output o input no compatible:\n" ++
                                                              "Tipo de la función en el contexto: " ++  show tf ++ "\n" ++ 
                                                              "Tipo esperado: " ++  show lt ++ "\n"++ 
                                                              "Tipo de la imagen: " ++ show i' ++ "\n" ++
                                                              "Tipo del dominio: " ++  show d' ++ "\n" ++
                                                              "Tipo de la expresión: " ++  show td  ++"\n"]
                                           where dta =  msustEff p ep  
                                                 i'  =  sust dta i
                                                 d'  =  sust dta d
                                                 td  =  tkTauReg pi e
   _       ->  [f ++ " su tipo no es función ni for all\n"]
 where tf  =  tau pi f 


tExc pi (O (k,o,t) es) phi t0 = --if o==IdOp  then error (show phi)  else
 --if contenido (concat (map effects ts) ++ effects t) phi then 
 if contenido (effects t) phi then 
 if tkTauReg pi (O (k,o,t) es) == t0 then 
  case length (dop t) of
   0     -> []
   j     -> if mleq (dop t) ts then mtExc pis es phi ts 
                               else ["operador " ++ show (O (k,o,t) es) ++ 
                                     " con input de tipo incorrecto:\ntipo calculado: " 
                                      ++ editTaus ts ++ "\ntipo del operador: "++ show (dop t) ++ "\n"] 
              where pis = [pi | i <- [1..j]]
 else [codop o ++ ": el tipo de output esperado -" ++ show t0 ++  
       "- no es compatible con el del operador: " ++ show  (tkTauReg pi (O (k,o,t) es) ) ++ "\n" ++ show (O (k,o,t) es) ++ "\n"]
 else [codop o ++ ": las locaciones " ++ show (concat (map effects ts) ++ effects t) ++ 
       " deberían ser locaciones activas. Activas:" ++ show phi ++ "\n"] 
 where ts  = mtkTauReg pi es
 
tExc pi (O (k,o,t) es) phi lt = ["operador " ++ codop o ++ ": los tipos no son válidos para un operador\n"]
tExc pi (Tup []) phi t = []
tExc pi (Tup es) phi (Prod ts) =  if length ts == length es then mtExc [pi | i <- [1..length es]] es phi ts
                                                            else ["tupla: las longitudes tupla y tipo no coinciden\n"]
tExc pi (If e e' e'') phi lt = mtExc [pi,pi,pi] [e,e',e''] phi [tkTauReg pi e,lt,lt] 
tExc pi (IF ((e,e'):[])) phi lt = tExc pi e' phi lt
tExc pi (IF ((e,e'):ps)) phi lt =  mtExc [pi,pi,pi] [e,e',IF ps] phi [tkTauReg pi e,lt,lt] 
tExc pi (Let p e e' ) phi lt    = 
  stPat p phi lt0 ++ mtExc [pi,comaPip pi p lt0] [e,e'] phi [lt0,lt] where lt0 = tkTauReg pi e
tExc pi (Sec e e') phi lt    = tExc pi e' phi lt
tExc pi e phi t = error ("TypeReg/tExc: sin ecuaciones: " ++ show e ++ " : " ++ show t) 

---------------------------------------------------------------------------------------
-- Test de mapa sustitución para tipos (si cambia Gl x debe ser por Gl w)

tmsust xs [] = []
tmsust xs ((x,Var y) : dta) = tmsust xs dta
tmsust xs ((x,e) : dta) = if esta x xs 
                          then ["No se puede sustituir la referencia " ++ x ++ " por una refencia indefinida: " ++ show e ++ "\n"]
                          else tmsust xs dta


----------------------------------------------------------------------------------------
-- tipado de patrones

stPat p phi t = tExc (comaPip [] p t) (excPat p) phi t
 where excPat (VP x) = Var x
       excPat (P ps) = Tup (map excPat ps)
       
----------------------------------------------------------------------------------------
-- TIPADO DE STORE

tStr str phi pi = tStr_ (reverse pi) (reverse str) phi (reverse pi)

tStr_ pi0 [] phi [] = []
tStr_ pi0 ((x,Vi i) : str) phi ((y,Q q' "int") : pi) =  
  if x==y then tStr_ pi0 str phi pi else ["tStr_: store y contexto no coordinados: " ++ x ++ " /= " ++ y ++ "\n"] 
tStr_ pi0 ((x,Vb b) : str) phi ((y,Q q' "bool") : pi) =  
  if x==y then tStr_ pi0 str phi pi else ["tStr_: store y contexto no coordinados: " ++ x ++ " /= " ++ y ++ "\n"] 
tStr_ pi0 ((x,Va a) : str) phi ((y,Q q' "array") : pi) =  
  if x==y then tStr_ pi0 str phi pi else ["tStr_: store y contexto no coordinados: " ++ x ++ " /= " ++ y ++ "\n"] 
tStr_ pi0 ((x,Vf pp p e) : str) phi ((y,Fun td ti) : pi) = 
     ["Str/valor función: la función no es de tipo \\q.T ->[...] T'): " ++ show  (Fun td ti) ++ "\n"]
tStr_ pi0 ((x,Vf pp p e) : str) phi ((y,FO q p' td ef ti) : pi) = 
 if x==y then tStr_ pi0 str phi pi ++ tExc ((y,FO q p' td ef ti):pi) (Lam q pp p td e) phi (FO q p' td ef ti)
         else ["tStr_: store y contexto no coordinados: " ++ x ++ " /= " ++ y ++ "\n"] 
{-
 where tRec f tf pi (Lam pp p t e) phi (FO p' td ef ti) 
        =  if and (map (\z -> not (esta z (effects pi))) (effects p')) 
           then if  p' == pp 
                then tExc (comaPip [] p td) (tkexc p) [] td ++ tExc ((f,tf):comaPip pi p t) e (effects ef) ti 
                else ["Lambda: tipo con patrones incompatibles\n"  ++ show pp ++ "    " ++ show p' ++ "\n"]      
           else ["Lambda: los parámetros de reg. no deben estar en el contexto:\n" 
                                                         ++ show pp ++ "    " ++ show (effects pi) ++ "\n"]
       tkexc (VP x) = Var x
       tkexc (P ps) = Tup (map tkexc ps)                  
-}
tStr_ pi0 ((x,v) : str) phi ((y,t) : pi) =  
  if x==y then ["tStr_: el valor\n" ++ show v ++ "\ny el tipo\n" ++ show t ++ " no responden a ningún patrón" ++ "\n"] 
          else ["tStr_: store y contexto no coordinados: " ++ x ++ " /= " ++ y ++ "\n"] 


tStr_ pi0 [] phi ((y,t) : pi) =  ["tStr_: store y contexto de distinta longitud" ++ "\n"]


