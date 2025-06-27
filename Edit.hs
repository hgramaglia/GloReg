
module Edit
( --L1
  editPP,meditPP,-- programa plus: (pi,str,e,t), se edita con formato TEPT   
  editCom,                           -- edición con forma de comando  
  editConfig,
  editPPTest,editTypeTest            -- edición de chequeo de tipos
  )
where
import Aux
import Alg
import Exc
import Parser
import Small
--import Type



--------------------------------------------------------------------------
-- Edición de programas --------------------------------------------------

{-PP Programa plus = (pi,str,e,t)

TEP Texto estandard de programa:
x=4,
y=1
-----
x +^q y
-----
-----
x:q int,
y:q int
-----
OJO!! : en str, las variables libres de v, aparecen declaradas antes de x=v

TEPT:
TEP
q int
-----
-}

--edición de PP en formato TEPT
editPP m (pi,str,e,t) =  "\n\n" ++
 editStr str                         ++ "\n" ++
 "------------------------------------" ++ "\n" ++
 show e                              ++ "\n" ++
 "------------------------------------" ++ "\n" ++
 " "                                    ++ "\n" ++ --  editSigma (sigma (str,e))              ++ "\n" ++
 "------------------------------------" ++ "\n" ++
-- editTaus (tcs (str,e))                 ++ "\n" ++  los tipos de los constructores se incorporaron a la signatura
-- "------------------------------------" ++ "\n" ++
 editPi  pi                             ++ "\n" ++
 "------------------------------------" ++ "\n" ++
 show t                              ++ "\n" ++
 "------------------------------------" ++ "\n"
 
 
--edición de secuencias de PP en formato TEPT
meditPP m pps=  concat (map (editPP m) pps) 
 

-- Edición de programa con forma de comando
 
editCom (pi,str,e,t)  =                
 editStrC (fv pi) str                   ++ 
 editcom (fv pi) e                        ++ "\n" 
 ++ "------------------------------------\n" 


-- EDICIÓN DE CONFIGURACIONES


editConfig  m (str,aux,e,new,inf) = editConfig_ m (str,aux,e,new,inf) ++ "\n" ++ editInfE inf
editConfigC m (str,aux,e,new,inf) = editConfig_ m (str,aux,e,new,inf) ++ "\n" ++ editInfE inf -- ++ editInfC inf
editCCod (str,aux,e,new,inf)    = editInfC inf

editConfig_ m (str,aux,e,new,inf) = 
 if isCt e then  
 case showResult (str++aux) e of
  [] -> 
   "---------------------------------------------------------------------------------\n" ++
   editMem aux ++ "\n" ++
   "---------------------------------------------------------------------------------\n" ++
   show e  ++ "\n" ++  
   "---------------------------------------------------------------------------------\n" 
  s  -> 
   "---------------------------------------------------------------------------------\n" ++
   editMem (str ++ aux) ++ "\n" ++
   "---------------------------------------------------------------------------------\n" ++
   show e ++ "\n" ++  
   "---------------------------------------------------------------------------------\n" ++
   s  ++ "\n" ++ 
   "---------------------------------------------------------------------------------\n" 
 else  
  "---------------------------------------------------------------------------------\n" ++
   editMem (str ++ aux) ++ "\n" ++
   "---------------------------------------------------------------------------------\n" ++
   show e ++ "\n" ++  
  "---------------------------------------------------------------------------------\n" 

editInfE (m,n,k,cs,is) = "Tamaño máximo de Memoria:         " ++ show m ++ "\n" ++
                            "Tamaño actual de Memoria:          " ++ show n ++ "\n" ++
                            "Cantidad de Pasajes de parámetros: " ++ show k ++ "\n"
                      
editInfC (n0,n,k,cs,is) =   "Inputs:  " ++ if is==[] then show is else show (init is) ++ "\n" ++
                              "Codigo:  " ++ show (  cs) ++ "\n"                                       -- <-- AQUI CODIGO


----------------------------------------------------------------------------------------
-- EDICIÓN de test de tipos
----------------------------------------------------------------------------------------

editPPTest m ((pi,str,e,t),txs) = editPP m (pi,str,e,t) ++ (if isGl m then editCom (pi,str,e,t) ++ editTypeTest m txs 
                                                               else editTypeTest m txs) 
                                
editTypeTest m txs =  "Test " ++ 
                       (if isGl m || m==Local then "global: " else if m==Regiones then "de regiones: " 
                                                                                  else "subestructural: ") ++
                       (if txs == [] then "CORRECTO\n" else "INCORRECTO: \n" ++ concat txs) 
 
-- Auxiliar: es tipo global/Ral
isravar x = (head x=='l')



