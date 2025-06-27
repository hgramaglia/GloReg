
module Main

where
import Aux
import Alg
import Exc
import Parser
import Small
import TypeGlo
import TypeReg
import GloToReg
import Edit
import Control.Monad


pupath  = "Programas/" 
capath  = "Programas/"
 
main = putStr menuStr

{-
Definiciones básicas:

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

PP (Programa plus tipo):    (pi,str,e,t)   (no se muestran, siempre se muestra TEP o TEPT)
-}

menuStr =
  "\n" ++
  "\n" ++
  "sh \"pro.m\"           show pro.m (m=gl,rl)\n"++
  "tc \"ef\" \"pro\"        type checking of pro.m (m=gl,rl)\n"++
  "                       Example of \"ef\":  \"x,b,map\" (global),  \"0,1,l_x,l_2\" (regions)\n" ++  
  "ev \"pro.m\"           evaluate pro.m (m=gl.rl) \n"++
  "pev n \"pro.m\"        evaluate (n steps) of pro.m (m=gl,rl)\n"++
  "gtr \"pro.gl\"         translate global to regions\n"++
  "\n\n"

-------------------------------------------------------------------
-- Auxiliares -----------------------------------------------------

modo "un" = Irrestricto
modo "su" = Subestructural
modo "lo" = Local
modo "gl" = Global [] 
modo "rl" = Regiones 

ext s = if m==[] then error ("Debe ingresar el nombre del archivo con su extensión .m (m=rl,lo,gl)  " ++ s) 
        else tail m
 where m = dropWhile ((/=) '.') s       

nom s = takeWhile ((/=) '.') s

-- Lectura sin tipo
readTEP s      = do  tep       <- readFile (capath ++ s) 
                     sp        <- return (separar tep) 
                     putStr ("Leyendo modalidad " ++ ext s ++ "\n")
                     str       <- ((pstr . etalexer) (part 0 sp))
                     putStr "Store ok, "
                     e         <- ((pexc . lexer) (part 1 sp))
                     putStr "Expression ok, "
                     putStr "Signature ok, "
                     pi        <- ((ppi . taulexer) (part 3 sp))
                     putStr "Type Context ok.\n"
                     return (pi,str,e,[],[]) 

-- Lectura con tipo (en la parte 4)
readTEPT s     = do  tep       <- readFile (capath ++ s) 
                     sp        <- return (separar tep) 
                     putStr ("Leyendo modalidad " ++ ext s ++ "\n")
                     str       <- ((pstr . etalexer) (part 0 sp))
                     putStr "Store ok, "
                     e         <- ((pexc . lexer) (part 1 sp))
                     putStr "Expression ok, "
                     putStr "Signature ok, "
                     pi        <- ((ppi . taulexer) (part 3 sp))
                     putStr "Type context ok."
                     t         <-  ((ptau . lexer) (part 4 sp))
                     putStr "Expression type ok.\n"
                     return (pi,str,e,[],[],t) 

-- Lectura str y e solamente, de archivo .un y .lo: es para generar la signatura de base
readP    s     = do  tep    <- readFile (capath ++ s) 
                     sp        <- return (separar tep) 
                     str       <- ((pstr . etalexer) (part 0 sp))
                     e         <- ((pexc . lexer) (part 1 sp))
                     return (str,e) 
  
-- f_ = función f aplicada a un PP
red_ m xs (pi,str,e,t) = case m of
--                         "un" -> last (red Subestructural (str,[],e,new,(tamb str,tamb str,0,[],[])))
--                         "su" -> last (red Subestructural (str,[],e,new,(tamb str,tamb str,0,[],[])))
--                         "lo" -> last (red (Global []) (str,[],e,new,(tamb str,tamb str,0,[],[])))
                         "rl" -> last (red Regiones (str,[],e,new,(tamb str,tamb str,0,[],[])))
                                      where new = newNew [1..iniciales (str,e)] --([1..iniciales (str,e)] ++ codIni (str,e))
                         "gl" -> last (red (Global xs) (str,[],e,new,(tamb str,tamb str,0,[],[])))
                                      where new = [(0,1)]
pred_ k m xs (pi,str,e,t) = case m of
--                           "un" -> last (partialRed k Subestructural (str,[],e,new,(tamb str,tamb str,0,[],[])))
--                           "su" -> last (partialRed k Subestructural (str,[],e,new,(tamb str,tamb str,0,[],[])))
--                           "lo" -> last (partialRed k (Global []) (str,[],e,new,(tamb str,tamb str,0,[],[])))
                           "rl" -> last (partialRed k Regiones (str,[],e,new,(tamb str,tamb str,0,[],[])))
                                      where new = newNew [1..iniciales (str,e)]
                           "gl" -> last (partialRed k (Global xs) (str,[],e,new,(tamb str,tamb str,0,[],[])))
                                      where new = newNew [0]
sred_ m xs (pi,str,e,t) = case m of
--                         "un" -> (red Subestructural (str,[],e,new,(tamb str,tamb str,0,[],[])))
--                         "su" -> (red Subestructural (str,[],e,new,(tamb str,tamb str,0,[],[])))
--                         "lo" -> (red (Global []) (str,[],e,new,(tamb str,tamb str,0,[],[])))
                         "rl" -> (red Regiones (str,[],e,new,(tamb str,tamb str,0,[],[])))
                                      where new = newNew [1..iniciales (str,e)]
                         "gl" -> (red (Global xs) (str,[],e,new,(tamb str,tamb str,0,[],[])))
                                      where new = newNew [0]
spred_ k m xs (pi,str,e,t) = case m of
--                             "un" -> (partialRed k Subestructural (str,[],e,new,(tamb str,tamb str,0,[],[])))
--                             "su" -> (partialRed k Subestructural (str,[],e,new,(tamb str,tamb str,0,[],[])))
--                             "lo" -> (partialRed k (Global []) (str,[],e,new,(tamb str,tamb str,0,[],[])))
                             "rl" -> (partialRed k Regiones (str,[],e,new,(tamb str,tamb str,0,[],[])))
                                      where new = newNew [1..iniciales (str,e)]
                             "gl" -> (partialRed k (Global xs) (str,[],e,new,(tamb str,tamb str,0,[],[])))                          
                                      where new = newNew [0]
test_ m phi (pi,str,e,t) = ((pi,str,e,t),if m == "gl" then testGlo pi (str,e) phi t 
                                                      else testReg pi (str,e) phi t)
editTest_ m ((pi,str,e,t),txs) = editPPTest (modo m) ((pi,str,e,t),txs)

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Funciones principales
--------------------------------------------------------------------------------------


-- muestra region - global
sh s =  
         if null s then return()
         else do m <- return (ext s)
                 (pi,str,e,tc,sig,t) <- readTEPT s
                 com                 <- if ext s == "gl" then return (editCom (pi,str,e,t)) else return []
                 putStr ("\n" ++  editPP (modo m) (pi,str,e,t) ++ "\n" ++ com)
                 


-- Evaluación region - local/global
ev s = 
          if null s then return()
          else do (pi,str,e,tc,sig,t) <- readTEPT s 
                  m                   <- return (ext s)
                  c                   <- return (if isRal t then red_ m [] (pi,str,e,t) 
                                                            else red_ m (globals pi) (pi,str,e,t))
                  string0             <- return ("\n" ++  editConfig (modo m) c) 
                  putStr (string0 ++ "\n" ++ "\n") 

pev k s = 
          if null s then return()
          else do (pi,str,e,tc,sig,t) <- readTEPT s 
                  m                   <- return (ext s)
                  c                   <- return (pred_ k m [] (pi,str,e,t))
                  string0             <- return ("\n" ++ editConfig (modo m) c )
                  putStr (string0 ++ "\n" ++ "\n") 

tc es s = 
          if null s then return()
          else do (pi,str,e,ts,sig,t) <- readTEPT (s)
                  m                   <- return (ext s)
                  efs                 <- (peffs.lexer) es
                  putStr (editTest_ m  (test_ m efs (pi,str,e,t)))
                  
-- conversión global to regiones
gtr s = 
          if null s then return()
          else do (pi,str,e,ts,sig,t)     <- readTEPT s 
                  (pi',str',e',t') <- return (gToR (pi,str,e,t))
                  text             <- return (editPP Regiones (pi',str',e',t')) 
                  --writeFile (capath ++  s ++ ".rl") text
                  putStr text

-------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
-- auxiliares

tkpi (pi,str,e,t,ts)  = pi
tktau (pi,str,e,t,ts) = t
tkstr (pi,str,e,t,ts) = str
tkexc (pi,str,e,t,ts) = e
tktaus (pi,str,e,t,ts) = ts

------------------------------------------------------------------------------------
--Otras funciones

----------------------------------------------------------------------------------------
-- Procesamiento de archivos .su y .gl -------------------------------------------------
-- TEXTO ESTANDARD DE PROGRAMA (TEP)
-- En el se encuentra, en este orden:
-- part 0: store
-- part 1: expresión
-- part 2: signautra
-- part 3: entorno de tipos
-- part 4: tipo (se parsea sólo en archivos .gl, o para test en .su)
-- SEPARADOR: 
-- __________________________________
--
-- PRODUCCIÓN DE ALGORITMOS DE SUBESTRUCTURALIZACIÓN O GLOBALIZACIÓN:
-- Secuencia donde cada uno responde a la estructura TEP, de manera
-- que se puede leer con sho, sho, dotc, etc.
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- Auxiliar para procesar archivos 

-- separar el archivo que contiene toda la información. Separador: "\n"++"--"
separar s = secP (secR s)

part k [] = []
part 0 (p:ps) = concatren p
                where concatren [] = []
                      concatren (r:rs) = r ++ "\n" ++ concatren rs
part k (p:ps) = part (k-1) ps  
-- tomar parte, quitar parte
takeP sr = takeWhile norsep sr
dropP sr = dropWhile norsep sr
secP_ sp []  = sp
secP_ sp sr   = if sr' == [] then sp ++ [p] else secP_ (sp ++ [p]) (tail sr')
                where p = takeP sr
                      sr' = dropP sr 
secP s = secP_ [] s
-- tomar y quitar renglón, secuencia de renglones
takeR s = takeWhile nofsep s
dropR s = dropWhile nofsep s
secR_ sr []  = sr
secR_ sr s   = if s == r then sr ++ [r] else secR_ (sr ++ [r]) (tail (dropR s))
               where r = takeR s 
secR s = secR_ [] s
-- separador de renglón
fsep c = (c == '\n') 
nofsep c = not (fsep c)
-- separador de parte
rsep ren =  if length ren' >= 2 then  (head ren' == '-') && (head (tail ren') == '-') else False
            where ren' = dropWhile (\c->(c==' ')) ren
norsep ren = not (rsep ren)

-- mini-parser de secuencias de variables

parsevar s = (if s'==[] then [] else [s']) ++ (if s''==[] then [] else parsevar (tail s'')) 
               where s'' = dropWhile (\a -> a/=' ' && a/=',') s 
                     s'  = takeWhile (\a -> a/=' ' && a/=',') s


