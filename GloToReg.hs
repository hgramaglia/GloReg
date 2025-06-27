
module GloToReg
 (
  gToR,gToRTau,gToRPi
 )

where

import Aux
import Alg
import Exc
import TypeGlo

-------------------------------------------------------------------------------------------------
-- Conversión Global to Regiones
-------------------------------------------------------------------------------------------------
-- Rergiones de variables iniciales
type Reg = [(Var,Int)] 

reg [] x = 0 -- error ("GloToReg:vreg: no existe la región correspondiente a " ++ x)
reg ((y,k):rs) x = if y==x then k else reg rs x

doloc pi = map fst (doreg pi)
doreg pi = numerar 1 pi
 where numerar k [] = []
       numerar k ((x,Q Lo s):pi) = (x,0) : numerar k pi
       numerar k ((x,Q (Gl (Var y)) s):pi) = if x==y then (x,k) : numerar (k+1) pi 
                                                     else error ("GloToReg:numerar en doreg: pi incorrecto")
       numerar k ((x,FO Lo p t ef t'):pi) = (x,0) : numerar k pi
       numerar k ((x,FO (Gl (Var y)) p t ef t'):pi) = if x==y then (x,k) : numerar (k+1) pi 
                                                              else error ("GloToReg:numerar en doreg: pi incorrecto")
       numerar k ((x,t):pi) = numerar k pi

globales rs p = filter(\x -> reg rs x /= 0) (fv p)
locales (VP x) (Q Lo s) = [x]
locales (VP x) (Q (Gl (Var y)) s) = []
locales (VP x) (FO Lo p t ef t') = [x]
locales (VP x) (FO (Gl (Var y)) p t ef t') = []
locales (P ps) (Prod ts) = concat (map (\(p,t) -> locales p t) (zip ps ts))

mapq :: Reg -> [Var] -> Tau -> Exc -> Eff
-- sólo expresiones que devuelve mapp (patrones)
mapq rs xs (Q Lo s) (Var x) = Place 0 
mapq rs xs (Q (Gl (Var y)) s) (Var x)  = if esta x xs then Place (reg rs x) 
                                                      else EffVar ("l_" ++ x) 
mapq rs xs (FO Lo p t e t') (Var x) = Place 0 
mapq rs xs (FO (Gl (Var y)) p t e t') (Var x)  = if esta x xs then Place (reg rs x) 
                                                               else EffVar ("l_" ++ x) 
mapq rs xs t (Tup []) = Place 0
mapq rs xs (Prod ts) (Tup es) = Eff (map (\(t,e) -> mapq rs xs t e) (zip ts es))
mapq rs xs t e = error ("GloToReg:mapq: " ++ show e)

alpha (Q Lo s) (VP x) = P []
alpha (FO Lo p t ef t') (VP x) = P []
alpha (Q q s) (VP x) = VP ("l_"++x)
alpha (FO q p t ef t') (VP x) = VP ("l_"++x)
alpha (Prod ts) (P ps) = P (map (\(t,p) -> alpha t p) (zip ts ps))
alpha t p = error ("GloToReg: alpha in gToRFunValue: " ++ show t ++ "   " ++ show p)

---------------------------------------------------------------------------------------------

gToR (pi,str,e,t) = (gToRPi rs xs pi,gToRStr rs xs pi str,gToRExc rs xs pi e,gToRTau rs xs pi t) 
 where rs = doreg pi
       xs = doloc pi
 
gToRExc rs xs pi (Var x)  = Var x 
gToRExc rs xs pi (New (EffVar x) e)  =  error ("no debe haber new") 
                                        -- New (EffVar ("l_"++x)) (gToRExc (as++[x]) (quitar xs [x]) pi e) 
gToRExc rs xs pi (O (k,o,t) es) =  
    case qTau (iop t) of
     Lo         -> O (k,o,sustOut t (Place 0)) (map (gToRExc rs xs pi) es)                  
     Gl (Var x) -> if esta x xs 
                      then O (k,o,sustOut t (Place (reg rs x))) (map (gToRExc rs xs pi) es)     
                      else O (k,o,sustOut t (EffVar ("l_"++x))) (map (gToRExc rs xs pi) es) 
     _             -> error ("GloToReg:gToRExc: " ++ show (O (k,o,t) es)) 
  where sustOut (Q q s) e = Q (Ef e) s
        sustOut (Fun t t') e = Fun (sustOut t (Eff [])) (sustOut t' e)
        sustOut (List Lo s) e = List (Ef e) (sustOut s (Eff []))
        sustOut (Prod ts) e = Prod (map (\t-> sustOut t (Eff [])) ts)
        sustOut t e = error ("TypeReg/sustLo en gToRExc: no es tipo de operador:\n" 
                             ++ show t ++ "\n" ++ show (O (k,o,t) es))
       --isLoc x = take 2 x == "l_"
gToRExc rs xs pi (Lam q pp p t e) = 
  case q of
    Lo            -> Lam (Ef (Place 0)) (alpha t p) p (gToRTau rs' xs' pi' t) (gToRExc rs' xs' pi' e)
    Gl (Var x)    -> if esta x xs 
                     then Lam (Ef (Place (reg rs x))) (alpha t p) p (gToRTau rs' xs' pi' t) (gToRExc rs' xs' pi' e)
                     else Lam (Ef (EffVar ("l_"++x))) (alpha t p) p (gToRTau rs' xs' pi' t) (gToRExc rs' xs' pi' e)
    _             -> error ("GloToReg:gToRExc: " ++ show (Lam q pp p t e)) 
 where pi' = comaPip pi p t
       rs' = rs
       xs' = union [quitar xs (globales rs' p),locales p t]
gToRExc rs xs pi (App f e e') = App f ep (gToRExc rs xs pi e')  
 where ep = case tau pi f of
             FO q p t e t' -> mapq rs xs t (mapp pi e') 
             t             -> error ("GloToReg:gToRExc: aplicación: tipo incorrecto")
gToRExc rs xs pi (Tup es) = Tup (map (gToRExc rs xs pi) es)
gToRExc rs xs pi (If e e' e'') = If (gToRExc rs xs pi e) (gToRExc rs xs pi e') (gToRExc rs xs pi e'')
gToRExc rs xs pi (IF ees) = IF (map (\(e,e') -> (gToRExc rs xs pi e,gToRExc rs xs pi e')) ees)
gToRExc rs xs pi (Let p e e') = Let p (gToRExc rs xs pi e) (gToRExc rs xs pi' e')
 where pi' = comaPip pi p (tkTauGlo pi e)
gToRExc rs xs pi (Spl q e p e') = Spl q (gToRExc rs xs pi e)  p (gToRExc rs xs pi e')
gToRExc rs xs pi (Sec e e') = Sec (gToRExc rs xs pi e) (gToRExc rs xs pi e') 
gToRExc rs xs pi e = error ("Type.gToRExc: no definida para\n" ++ show e)

gToRFunValue rs xs pi (f,Vf pp p e) = (f,Vf (alpha (dom (tau pi f)) p) p (gToRExc rs' xs' pi' e)) 
 where pi' = comaPip pi p (dom (tau pi f))
       rs' = rs
       xs' = union [quitar xs (globales rs' p),locales p (dom (tau pi f))]
gToRFunValue rs xs pi (x,v) = (x,v)

gToRStr rs xs pi str = map (gToRFunValue rs xs pi) str

gToRTau rs xs pi (Q (Gl (Var x)) a) = if esta x xs then Q (Ef (Place (reg rs x))) a else Q (Ef (EffVar ("l_"++x))) a
gToRTau rs xs pi (Q Lo a) =  Q (Ef (Place 0)) a
gToRTau rs xs pi (List (Gl (Var x)) t) = List (Ef (EffVar ("l_"++x))) (gToRTau rs xs pi t)
gToRTau rs xs pi (List Lo t) = List (Ef (Place 0)) (gToRTau rs xs pi t)
gToRTau rs xs pi (Fun t1 t2) = Fun (gToRTau rs xs pi t1) (gToRTau rs xs pi t2)
gToRTau rs xs pi (FO q p t e t') = 
  case q of 
   Lo -> FO (Ef (Place 0)) p' (gToRTau rs' xs' pi' t) (doEff e) (gToRTau rs' xs' pi' t')
   Gl (Var x) -> FO (Ef (Place (reg rs x))) p' (gToRTau rs' xs' pi' t) (doEff e) (gToRTau rs' xs' pi' t')
   q  -> error (show q)
 where pi' = comaPip pi p t
       rs' = rs
       xs' = union [quitar xs (globales rs' p),locales p t]
       p'  = alpha t p 
       doEff (EffVar x) = if esta x xs' then Place (reg rs x) else EffVar ("l_" ++ x) 
       doEff (Eff es) = Eff (map doEff es)
       doEff e = error ("GloToReg:doEff en gToRTau " ++ show e)
gToRTau rs xs pi (Prod ts) = Prod (map (gToRTau rs xs pi) ts)

gToRPi :: Reg -> [Var]  -> Pi -> Pi
gToRPi rs xs pi = map (\(x,t) -> (x,gToRTau rs xs pi t)) pi
                  --map (\(es,(x,t)) -> (x,putEff es (gToRTau rs xs pi t))) (zip (map (effects.snd) str) pi)
{-
 where putEff es (FO q pp t (Eff ef) t') = FO q pp t (Eff (union [es,ef])) (putEff (union [es,ef]) t')
       putEff es (FO q pp t e t') = FO q pp t (Eff (union [es,[e]])) (putEff (union [es,[e]]) t')
       putEff es (Prod ts) = Prod (map (putEff es) ts)
       putEff es t = t
-}       
-- AUXILIAR gTorTau

effs f [] = error ("GloToReg/effs: no está la función " ++ f)
effs f ((x,Vf pp p e):str) = if x==f then filter isPlace (effects e) else effs f str
 where isPlace (Place j) = True
       isPlace e = False
effs f ((x,v):str) = effs f str

