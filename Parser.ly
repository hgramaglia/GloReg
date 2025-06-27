% -*- mode: literate-haskell;-*-
%$Id: Grammar.ly,v 1.7 2006-05-24 14:37:16 mpagano Exp $
> {
> module Parser where
> import Data.Char
> import Aux
> import Alg
> import Exc
> --import Sig
> import Small
> }
 
> %tokentype {Token}
 
> %token 
>       int             { TIv $$ }
>       string          { TString $$}
>       true            { TTrue }
>       false           { TFalse }
>       let             { TLet }
>       in              { TIn }
>       inc             { TInc }
>       if              { TIf }
>       then            { TThen }
>       else            { TElse }
>       split           { TSplit}
>       as              { TAs}
>       null            { TNull}
>       case            { TCase}
>       of              { TOf}
>       '='             { TEq }
>       "||"            { TOr }
>       "&&"            { TAnd }
>       not             { TNot }
>       '+'             { TAdd }
>       '-'             { TMinus }
>       '*'             { TMult }
>       '%'             { TDiv }
>       '('             { TOB }
>       ')'             { TCB }
>       '['             { TOC }
>       ']'             { TCC }
>       '{'             { TOL }
>       '}'             { TCL }
>       '<'             { TMe }
>       "<="            { TMi }
>       '>'             { TMa }
>       "=="            { TEqual }
>       ','             { TComma }
>       ';'             { TPComma }
>       '.'             { TPunto }
>       hi              { THi }
>       su              { TSu }
>       un              { TUn }
>       "un!"             { TU_ }
>       "lo!"             { TL_ }
>       lo              { TLo }
>       ':'             { T2p }
>       "->"            { Tfl}
>       unit            { Tunit}
>       p1              { Tp1}
>       p2              { Tp2}
>       id              { Tid}
>       '\\'            { TLambda}
>       new             { TNew}
>       "<-"            { TAsig}
>       upd             { TUpd}
>       ent             { TEntry}
>       den             { TDEntry}
>       isNull          { TIsNull}
>       head            { THead}
>       tail            { TTail}
>       '@'             { TIF }
>       nod             { TNod }
>       inp             { TInp }
>       '^'             { TAt }




>
> %right as
> %right else
> %right then
> %right in
> %left BOP  "&&" "||"
> %left NOT 
> %nonassoc ROP  '<' "==" "<=" 
> %left IBOP '+' '-' ';'
> %left NEG
> %left FACT '*' '%' 
> %left APP
> %right FL 
> %nonassoc POR
> %nonassoc QUA
> %monad { IO } 
> %name pexc Exc
%name pqu Qu
> %name ptau Tau
> %name ptaus Taus
> %name ppat Pat
> %name ppi Pi
> %name pstr Str
> %name psigma Sigma
> %name pvalue Value
> %name pplace Exc
> %name peffs Effs
> %%
>

-- Signatura

>    Sig :: { Sig }
>    Sig : true                 { VbOp True  }
>        | false                { VbOp False }
>        | int                  { ViOp $1 }
>        | not                  { NotOp }
>        | "&&"                 { AndOp  }
>        | "||"                 { OrOp }
>        | "=="                 { EqualOp }
>        | "<="                 { MiOp  }
>        | '<'                  { MeOp }
>        | '+'                  { AddOp  }
>        | '-'                  { SustrOp }
>        | '*'                  { MultOp }
>        | '%'                  { DivOp  }
>        | new                  { NewOp }
>        | inc                  { IncOp }
>        | upd                  { UpdOp  }
>        | ent                  { EntryOp  }
>        | den                  { DEntryOp  }
>        | id                   { IdOp }
>        | p1                   {  P1Op }
>        | p2                   { P2Op }
>        | "==" int             { EqOp $2 }
>        | '+' int              { AdOp $2 }
>        | '-' int              { SuOp $2 }
>        | '%' int              { DiOp $2 }
>        | '*' int              { MuOp $2 }
>        | ':'                  { ConOp }
>        | '[' ']'              { NullOp }
>        | '[' ':' ']'          { DConOp }
>        | isNull               { IsNullOp  }
>        | head                 { HeadOp  }
>        | tail                 { TailOp  }
>        | nod int              { NOp $2 }
>        | inp int              { IOp $2 }


>    Sigma1 :: { Sigma }
    Sigma1 : int Sig ':' Tau                   { [($1,$2,$4)] }
           | int Sig ':' Tau ',' Sigma1        { ($1,$2,$4) : $6 }
>    Sigma1 : Sig ':' Tau                   { [(0,$1,$3)] }
>           | Sig ':' Tau ',' Sigma1        { (0,$1,$3) : $5 }

>    Sigma :: { Sigma }
>    Sigma : {- empty -}                     { [] }
>          | Sigma1                          { $1 }


-- Secuencias

>
>    Pats1 :: { [Pat] }
>    Pats1 : Pat ',' Pat          { [$1,$3] }
>          | Pat ','  Pats1       { $1 : $3 }
>
>    Pats :: { [Pat] }
>    Pats : {- empty -}          { [] }
>         | Pats1                { $1 }
>
>    Pat  :: { Pat }
>    Pat  :  string                { VP $1 }
>         | '(' Pats ')'           { P $2 }
>

--    Calificadores, Value, contextos, state

>    Qu :: { Qu }
>    Qu    : un                          { Un  }
>          | "un!"                       { U_  }
>          | "lo!"                       { L_  }
>          | su                          { Su  }
>          | hi                          { Hi  }
>          | lo                          { Lo  }
>          | string                      { qvar $1 }
>          | int                         { Ef (Place $1) }

          | '<' Exc '>'                         { Gl $2 }
          | '<' Excs '>'                        { Gl (Tup $2) }


-- Secuencias de enteros

>    Ints1 :: { Array }
>    Ints1 : int                 { [$1] }
>          | int ','  Ints1      { $1 : $3 }

>    Ints :: { Array }
>    Ints : {- empty -}          { [] }
>         | Ints1                { $1 }


>    Value :: { Value }
>    Value : true                               { Vb True  }
>          | false                              { Vb False }
>          | int                                { Vi $1    }
>          | '-' int                            { Vi (-$2) }
>          | '\\' Pat '.' '\\' Pat '.' Exc                   { Vf $2 $5 $7 }
>          | '(' '\\' Pat '.' '\\' Pat '.' Exc ')'                   { Vf $3 $6 $8}
>          | '(' '\\' Pat '.' '(' '\\' Pat '.' Exc ')' ')'                   { Vf $3 $7 $9}
>          | '\\' Pat '.' '(' '\\' Pat '.' Exc ')'                    { Vf $2 $6 $8}
          | '(' Excs ')'                        { Vt Un $2 }
>          | '{' Ints '}'                       { Va $2 }
>          | '(' string ':' string ')'          { Vl $2 $4}
>          | '[' ']'                            { VN    }


       

>    Str1 :: { Str }
>    Str1 : string '=' Value               { [($1,$3)] }
>         | string '=' Value ',' Str1      { ($1,$3) : $5 }

>    Str :: { Str }
>    Str : {- empty -}                     { [] }
>        | Str1                            { $1 }


-- types


>    Tau :: { Tau }
>    Tau : Qu string                   %prec QUA    { Q $1 $2 }
>        | Tau "->"  Tau               %prec FL     { Fun $1 $3 }
>        | '(' Tau "->"  Tau ')'       %prec FL     { Fun $2 $4 }
>        | '(' Tau ')'                              { $2 }
>        | '(' Taus ')'                %prec POR    { Prod $2 }
>        | Qu '[' Tau ']'              %prec POR    { List $1 $3 }
>        | Qu '\\' Pat  ':' Tau '.' Tau   %prec POR    {  FO $1 $3 $5 (Eff []) $7 }
>        | Qu '\\' Pat  '.' Tau "->" '(' Effs ')' Tau   %prec POR    {  FO $1 $3 $5 (Eff $8) $10 }
>        | Qu '(' '\\' Pat  ':' Tau '.' Tau ')'  %prec POR    {  FO $1 $4 $6 (Eff []) $8 }
>        | Qu '(' '\\' Pat  '.' Tau "->" '(' Effs ')' Tau ')'  %prec POR    {  FO $1 $4 $6 (Eff $9) $11 }



-- Secuencias

>    String1 :: { [String] }
>    String1 : string                   { [$1] }
>            | string ','  String1      { $1 : $3 }

>    Strings :: { [String] }
>    Strings : {- empty -}          { [] }
>            | String1               { $1 }

>    Taus1 :: { [Tau] }
>    Taus1 : Tau                 { [$1] }
>          | Tau ','  Taus1      { $1 : $3 }

>    Taus :: { [Tau] }
>    Taus : {- empty -}          { [] }
>         | Taus1                { $1 }

-- Ltype context

>    Pi1 :: { Pi }
>    Pi1 : string ':' Tau               { [($1,$3)] }
>        | string ':' Tau ',' Pi1       { ($1,$3) : $5 }

>    Pi :: { Pi }
>    Pi : {- empty -}          { [] }
>       | Pi1                  { $1 }

>    Effs1  :: { [Eff] }
>    Effs1 : Eff                 { [$1] }
>          |  Eff ',' Effs1            { $1 : $3 }
>
>    Effs  :: { [Eff] }
>    Effs : {- empty -}                 { [] }
>         |  Effs1                      { $1  }

>    Eff  :: { Eff }
>    Eff :  string                { EffVar $1 }
>        |  int                   { Place $1 }
        |  int '(' int ':' int ')'             { LPlace $1 $3 $5 }
        |  '(' int '(' int ':' int ')' ')'     { LPlace $2 $4 $6 }
>        |  '(' Effs ')'          { Eff $2 }


>    Excs1 :: { [Exc] }
>    Excs1 : Exc          { [$1] }
>          | Exc ','  Excs1       { $1 : $3 }
>
>    Excs :: { [Exc] }
>    Excs : {- empty -}          { [] }
>         | Excs1                { $1 }


-- Expresiones 




>
>    Exc :: { Exc  }
>        : string                                { Var $1 }
>        | int                                   { O (0,ViOp $1,Q Lo "int")  [] }
>        | nod int                               { O (0,NOp $2,Q Lo "int")  [] }
>        | inp int                               { O (0,IOp $2,Q Lo "bool")  [] }
>        | inc  Exc %prec NEG                    { O (0,IncOp,Fun (Q Lo "int") (Q Lo "int")) [$2] }
        | new '(' Exc ')'                       { O (0,NewOp,Fun (Q Lo "int") (Q Lo "array")) [$3] }
>        | id '(' Exc ')'                        { O (0,IdOp,Fun (Q Lo "int") (Q Lo "int")) [$3] }
>        | p1 '(' Excs ')'                       { O (0,P1Op,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q Lo "int")) $3 }
>        | p2 '(' Excs ')'                       { O (0,P2Op,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q Lo "int")) $3 }
>        | head  Exc %prec NEG                    { O (0,HeadOp,Fun (List Lo (Q Lo "int")) (Q Lo "int")) [$2] }
>        | tail  Exc %prec NEG                    { O (0,TailOp,Fun (List Lo (Q Lo "int")) (List Lo (Q Lo "int"))) [$2] }
>        | isNull  Exc %prec NEG                  { O (0,IsNullOp,Fun (List Lo (Q Lo "int")) (Q Lo "bool")) [$2] }
        | string int            %prec APP       { App $1 (O (0,ViOp $2,Q Lo "int")  []) }
        | string string         %prec APP       { App $1 (Var $2) }
        | string true           %prec APP       { App $1 (O (0,VbOp True,Q Lo "bool")  [] ) }
        | string false          %prec APP       { App $1 (O (0,VbOp False,Q Lo "bool")  [] )  }



>        | int '^' lo                            { O (0,ViOp $1,Q Lo "int")  [] }
>        | true '^' lo                           { O (0,VbOp True,Q Lo "bool")  [] }
>        | false '^' lo                          { O (0,VbOp False,Q Lo "bool") [] }
>        | not '^' lo Exc %prec NOT              { O (0,NotOp,Fun (Q Lo "bool") (Q Lo "bool")) [$4] }
>        | '-' '^' lo Exc  %prec NEG             { O (0,AddInvOp,Fun (Q Lo "int") (Q Lo "int")) [$4] }
>        | '(' "==" int ')' '^' lo Exc %prec NEG        { O (0,EqOp $3,Fun (Q Lo "int") (Q Lo "bool")) [$7] }
>        | '(' '+' int ')' '^' lo Exc %prec NEG         { O (0,AdOp $3,Fun (Q Lo "int") (Q Lo "int")) [$7] }
>        | '(' '-' int ')' '^' lo Exc %prec NEG         { O (0,SuOp $3,Fun (Q Lo "int") (Q Lo "int")) [$7] }
>        | '(' '*' int ')' '^' lo Exc %prec NEG         { O (0,MuOp $3,Fun (Q Lo "int") (Q Lo "int")) [$7] }
>        | '(' '%' int ')' '^' lo Exc %prec NEG         { O (0,DiOp $3,Fun (Q Lo "int") (Q Lo "int")) [$7] }
>        | Exc "&&" '^' lo Exc %prec BOP         { O (0,AndOp,Fun (Prod [(Q Lo "bool"),(Q Lo "bool")]) (Q Lo "bool")) [$1,$5] }
>        | Exc "||" '^' lo Exc %prec BOP         { O (0,OrOp,Fun (Prod [(Q Lo "bool"),(Q Lo "bool")]) (Q Lo "bool")) [$1,$5] }
>        | Exc "==" '^' lo Exc %prec ROP                { O (0,EqualOp,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q Lo "bool")) [$1,$5] }
>        | Exc "<=" '^' lo Exc %prec ROP                { O (0,MiOp,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q Lo "bool")) [$1,$5] }
>        | Exc '<' '^' lo Exc  %prec ROP                { O (0,MeOp,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q Lo "bool")) [$1,$5] }
>        | Exc '+' '^' lo Exc %prec IBOP                { O (0,AddOp,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q Lo "int")) [$1,$5] }
>        | Exc '-' '^' lo Exc %prec IBOP                { O (0,SustrOp,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q Lo "int")) [$1,$5] }
>        | Exc '*' '^' lo Exc %prec FACT                { O (0,MultOp,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q Lo "int")) [$1,$5] }
>        | Exc '%' '^' lo Exc %prec FACT                { O (0,DivOp,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q Lo "int")) [$1,$5] }
>        | Exc '[' Exc ']' '^' lo                { O (0,EntryOp,Fun (Prod [(Q Lo "array"),(Q Lo "int")]) (Q Lo "int")) [$1,$3] }
>        | Exc '[' Exc ',' Exc ']' '^' lo        { O (0,DEntryOp,Fun (Prod [(Q Lo "array"),(Q Lo "int"),(Q Lo "int")]) (Q Lo "int")) [$1,$3,$5] }
>        | Exc '[' Exc "<-" Exc ']' '^' lo       { O (0,UpdOp,Fun (Prod [(Q Lo "array"),(Q Lo "int"),(Q Lo "int")]) (Q Lo "array")) [$1,$3,$5] }
>        | Exc '[' Exc ':' Exc ']' '^' lo { O (0,DConOp,Fun (Prod [(List Lo (Q Lo "int")),(Q Lo "int"),(List Lo (Q Lo "int"))]) (List Lo (Q Lo "int"))) [$1,$3,$5] }
>        | '(' Exc ':'  Exc ')' '^' lo             { O (0,ConOp,Fun (Prod [(Q Lo "int"),List Lo (Q Lo "int")]) (List Lo (Q Lo "int"))) [$2,$4] }
>        | '[' ']' '^' lo                         { O (0,NullOp,List Lo (Q Lo "int"))  [] }    
>        | p1 '^' lo '(' Excs ')'                       { O (0,P1Op,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q Lo "int")) $5 }
>        | p2 '^' lo '(' Excs ')'                       { O (0,P2Op,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q Lo "int")) $5 }
>        | id '^' lo '(' Exc ')'                        { O (0,IdOp,Fun (Q Lo "int") (Q Lo "int")) [$5] }


>        | int '^' string                        { O (0,ViOp $1,Q (qvar $3) "int")  [] }
>        | true '^' string                       { O (0,VbOp True,Q (qvar $3) "bool")  [] }
>        | false '^' string                      { O (0,VbOp False,Q (qvar $3) "bool")  [] }
>        | not '^' string Exc %prec NOT          { O (0,NotOp,Fun (Q Lo "bool") (Q (qvar $3) "bool")) [$4] }
>        | '-' '^' string Exc  %prec NEG         { O (0,AddInvOp,Fun (Q Lo "int") (Q (qvar $3) "int")) [$4] }
>        | id '^' string '('  Exc ')'  %prec NEG { O (0,IdOp,Fun (Q Lo "int") (Q (qvar $3) "int")) [$5] }
>        | Exc "&&" '^' string Exc %prec BOP   {O (0,AndOp,Fun (Prod [(Q Lo "bool"),(Q Lo "bool")]) (Q (qvar $4) "bool")) [$1,$5] }
>        | Exc "||" '^' string Exc %prec BOP                { O (0,OrOp,Fun (Prod [(Q Lo "bool"),(Q Lo "bool")]) (Q (qvar $4) "bool")) [$1,$5] }
>        | '(' "==" int ')' '^' string Exc %prec NEG   { O (0,EqOp $3,Fun (Q Lo "int") (Q (qvar $6) "bool")) [$7] }
>        | '(' '+' int ')' '^' string Exc %prec NEG  { O (0,AdOp $3,Fun (Q Lo "int") (Q (qvar $6) "int")) [$7] }
>        | '(' '-'  int ')' '^' string Exc %prec NEG  { O (0,SuOp $3,Fun (Q Lo "int") (Q (qvar $6) "int")) [$7] }
>        | '(' '*' int ')' '^' string Exc %prec NEG  { O (0,MuOp $3,Fun (Q Lo "int") (Q (qvar $6) "int")) [$7] }
>        | '(' '%' int ')' '^' string  Exc %prec NEG  { O (0,DiOp $3,Fun (Q Lo "int") (Q (qvar $6) "int")) [$7] }
>        | Exc "==" '^' string Exc %prec ROP  { O (0,EqualOp,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q (qvar $4) "bool")) [$1,$5] }
>        | Exc "<=" '^' string Exc %prec ROP  { O (0,MiOp,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q (qvar $4) "bool")) [$1,$5] }
>        | Exc '<' '^' string Exc %prec ROP  { O (0,MeOp,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q (qvar $4) "bool")) [$1,$5] }
>        | Exc '+' '^' string Exc %prec ROP  { O (0,AddOp,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q (qvar $4) "int")) [$1,$5] }
>        | Exc '-' '^' string Exc %prec ROP  { O (0,SustrOp,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q (qvar $4) "int")) [$1,$5] }
>        | Exc '*' '^' string Exc %prec ROP  { O (0,MultOp,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q (qvar $4) "int")) [$1,$5] }
>        | Exc '%' '^' string Exc %prec ROP  { O (0,DivOp,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q (qvar $4) "int")) [$1,$5] }
>        | Exc '[' Exc ']' '^' string     { O (0,EntryOp,Fun (Prod [(Q Lo "array"),(Q Lo "int")]) (Q (qvar $6) "int")) [$1,$3] }
>        | Exc '[' Exc ',' Exc ']' '^' string   { O (0,DEntryOp,Fun (Prod [(Q Lo "array"),(Q Lo "int"),(Q Lo "int")]) (Q (qvar $8) "int")) [$1,$3,$5] }
>        | Exc '[' Exc "<-" Exc ']' '^' string   { O (0,UpdOp,Fun (Prod [(Q Lo "array"),(Q Lo "int"),(Q Lo "int")]) (Q (qvar $8) "array")) [$1,$3,$5] }
>        | '(' Exc ':'  Exc ')' '^' string        { O (0,ConOp,Fun (Prod [(Q Lo "int"),List Lo (Q Lo "int")]) (List (qvar $7) (Q Lo "int"))) [$2,$4] }
>        | '[' ']' '^' string                      { O (0,NullOp,List (qvar $4) (Q Lo "int"))  [] }    
>        | p1 '^' string '(' Excs ')'                       { O (0,P1Op,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q (qvar $3) "int")) $5 }
>        | p2 '^' string '(' Excs ')'                       { O (0,P2Op,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q (qvar $3) "int")) $5 }
       | id '^' string '(' Exc ')'                        { O (0,IdOp,Fun (Q Lo "int") (Q (qvar $3) "int")) [$5] }


>        | int '^' int                           { O (0,ViOp $1,Q (Ef (Place $3)) "int")  [] }
>        | true '^' int                          { O (0,VbOp True,Q (Ef (Place $3)) "bool")  [] }
>        | false '^' int                         { O (0,VbOp False,Q (Ef (Place $3)) "bool")  [] }
>        | not '^' int    Exc %prec NOT  { O (0,NotOp,Fun (Q Lo "bool") (Q (Ef (Place $3)) "bool")) [$4] }
>        | '-' '^' int Exc  %prec NEG            { O (0,AddInvOp,Fun (Q Lo "int") (Q (Ef (Place $3)) "int")) [$4] }
>        | id '^' int '('  Exc ')'  %prec NEG    { O (0,IdOp,Fun (Q Lo "int") (Q (Ef (Place $3)) "int")) [$5] }
>        | Exc "&&" '^' int Exc %prec BOP  {O (0,AndOp,Fun (Prod [(Q Lo "bool"),(Q Lo "bool")]) (Q (Ef (Place $4)) "bool")) [$1,$5] }
>        | Exc "||" '^' int Exc %prec BOP                { O (0,OrOp,Fun (Prod [(Q Lo "bool"),(Q Lo "bool")]) (Q (Ef (Place $4)) "bool")) [$1,$5] }
>        | '(' "==" int ')' '^' int Exc %prec NEG   { O (0,EqOp $3,Fun (Q Lo "int") (Q (Ef (Place $6)) "bool")) [$7] }
>        | '(' '+' int ')' '^' int Exc %prec NEG  { O (0,AdOp $3,Fun (Q Lo "int") (Q (Ef (Place $6)) "int")) [$7] }
>        | '(' '-' int ')' '^' int Exc %prec NEG  { O (0,SuOp $3,Fun (Q Lo "int") (Q (Ef (Place $6)) "int")) [$7] }
>        | '(' '*' int ')' '^' int Exc %prec NEG  { O (0,MuOp $3,Fun (Q Lo "int") (Q (Ef (Place $6)) "int")) [$7] }
>        | '(' '%' int ')' '^' int Exc %prec NEG  { O (0,DiOp $3,Fun (Q Lo "int") (Q (Ef (Place $6)) "int")) [$7] }
>        | Exc "==" '^' int Exc %prec ROP  { O (0,EqualOp,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q (Ef (Place $4)) "bool")) [$1,$5] }
>        | Exc "<=" '^' int Exc %prec ROP  { O (0,MiOp,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q (Ef (Place $4)) "bool")) [$1,$5] }
>        | Exc '<' '^' int Exc %prec ROP  { O (0,MeOp,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q (Ef (Place $4)) "bool")) [$1,$5] }
>        | Exc '+' '^' int Exc %prec ROP  { O (0,AddOp,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q (Ef (Place $4)) "int")) [$1,$5] }
>        | Exc '-' '^' int Exc %prec ROP  { O (0,SustrOp,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q (Ef (Place $4)) "int")) [$1,$5] }
>        | Exc '*' '^' int Exc %prec ROP  { O (0,MultOp,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q (Ef (Place $4)) "int")) [$1,$5] }
>        | Exc '%' '^' int Exc %prec ROP  { O (0,DivOp,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q (Ef (Place $4)) "int")) [$1,$5] }
>        | Exc '[' Exc ']' '^' int { O (0,EntryOp,Fun (Prod [(Q Lo "array"),(Q Lo "int")]) (Q (Ef (Place $6)) "int")) [$1,$3] }
>        | Exc '[' Exc ',' Exc ']' '^' int  { O (0,DEntryOp,Fun (Prod [(Q Lo "array"),(Q Lo "int"),(Q Lo "int")]) (Q (Ef (Place $8)) "int")) [$1,$3,$5] }
>        | Exc '[' Exc "<-" Exc ']' '^' int   { O (0,UpdOp,Fun (Prod [(Q Lo "array"),(Q Lo "int"),(Q Lo "int")]) (Q (Ef (Place $8)) "array")) [$1,$3,$5] }
        | '(' Exc ':'  Exc ')' '^' '(' int ':' int ')' { O (0,ConOp,Fun (Prod [(Q Lo "int"),List Lo (Q Lo "int")]) (List (Ef (Places $8 $10)) (Q Lo "int"))) [$2,$4] }
>        | '(' Exc ':'  Exc ')' '^'  int  { O (0,ConOp,Fun (Prod [(Q Lo "int"),List Lo (Q Lo "int")]) (List (Ef (Place $7)) (Q Lo "int"))) [$2,$4] }
>        | '[' ']' '^' int                      { O (0,NullOp,List (Ef (Place $4)) (Q Lo "int"))  [] }    
       | p1 '^' int '(' Excs ')'            { O (0,P1Op,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q (Ef (Place $3)) "int")) $5 }
>        | p2 '^' int '(' Excs ')'            { O (0,P2Op,Fun (Prod [(Q Lo "int"),(Q Lo "int")]) (Q (Ef (Place $3)) "int")) $5 }
        | id '^' int '(' Exc ')'             { O (0,IdOp,Fun (Q Lo "int") (Q (Ef (Place $3)) "int")) [$5] }


        | '(' ')'                          { Tup [] }
>        | '(' Exc  ')'                          { $2 }
>        | '(' Excs ')'                          { Tup $2 }

>        | string  string  '(' string ')'        %prec APP        { App $1 (EffVar $2) (Var $4) }
>        | string  string   string                %prec APP       { App $1 (EffVar $2) (Var $3) }
>        | string  string  '(' Exc ')'            %prec APP       { App $1 (EffVar $2) $4 }
>        | string  string '(' Excs ')'            %prec APP       { App $1 (EffVar $2) (Tup $4) }
>        | string  int  '(' string ')'        %prec APP        { App $1 (Place $2) (Var $4) }
>        | string  int   string                %prec APP       { App $1 (Place $2) (Var $3) }
>        | string  int  '(' Exc ')'            %prec APP       { App $1 (Place $2) $4 }
>        | string  int '(' Excs ')'            %prec APP       { App $1 (Place $2) (Tup $4) }
>        | string  '(' Effs ')' '(' string ')'        %prec APP       { App $1 (Eff $3) (Var $6) }
>        | string  '(' Effs ')' string             %prec APP       { App $1 (Eff $3) (Var $5) }
>        | string  '(' Effs ')' '(' Exc ')'        %prec APP       { App $1 (Eff $3) $6 }
>        | string  '(' Effs ')' '(' Excs ')'        %prec APP       { App $1 (Eff $3) (Tup $6) }

>        | new Eff '.' Exc                         { New $2 $4 }
>        | split Qu Exc as Pat in Exc              { Spl $2 $3 $5 $7 }
>        | let  Pat '=' Exc in Exc                 { Let $2 $4 $6 }
>        | if Exc then Exc else Exc                { If $2 $4 $6  }   
>        | '(' '\\' Pat '.' '\\' Pat ':' Tau '.' Exc ')' '^' int  { Lam  (Ef (Place $13)) $3 $6 $8 $10}   
>        | '(' '\\' Pat '.' '\\' Pat ':' Tau '.' Exc ')' '^' string  { Lam  (qvar $13) $3 $6 $8 $10}   
>        | '(' '\\' Pat '.' '\\' Pat ':' Tau '.' Exc ')' '^' lo  { Lam  Lo $3 $6 $8 $10}   
>        | case Qu Exc of '(' Exc ',' '(' string ':' string ')' '(' string ':' string ')'  "->" Exc ')' { Case $2 $3 $6 (P [VP $9,VP $11]) (P [VP $14,VP $16]) $19 }
>        | if Exc "->" Exc '@' Exc "->" Exc           { IF [($2,$4),(Tup [],$8)]  }   
>        | if Exc "->" Exc '@'     "->" Exc           { IF [($2,$4),(Tup [],$7)]  }   
>        | if Exc "->" Exc '@' Exc "->" Exc '@' Exc "->" Exc  { IF [($2,$4),($6,$8),(Tup [],$12)]  }   
>        | if Exc "->" Exc '@' Exc "->" Exc '@'   "->" Exc  { IF [($2,$4),($6,$8),(Tup [],$11)]  }   
>        | if Exc "->" Exc '@' Exc "->" Exc '@' Exc "->" Exc '@' Exc "->" Exc  { IF [($2,$4),($6,$8),($10,$12),(Tup [],$16)]  }   
>        | if Exc "->" Exc '@' Exc "->" Exc '@' Exc "->" Exc '@'   "->" Exc  { IF [($2,$4),($6,$8),($10,$12),(Tup [],$15)]  }   
>        | if Exc "->" Exc '@' Exc "->" Exc '@' Exc "->" Exc '@' Exc "->" Exc '@' Exc "->" Exc  { IF [($2,$4),($6,$8),($10,$12),($14,$16),(Tup [],$20)]  }   
>        | if Exc "->" Exc '@' Exc "->" Exc '@' Exc "->" Exc '@' Exc "->" Exc '@'   "->" Exc  { IF [($2,$4),($6,$8),($10,$12),($14,$16),(Tup [],$19)]  }   
>        | Exc ';' Exc %prec IBOP                { Sec $1 $3 }




> {
> 
> data Token = TIv Int | TString String | TTrue | TFalse 
>            | TAdd | TInc
>            | TMinus 
>            | TMult | TDiv
>            | TOB | TCB | TOP | TCP 
>            | TOr 
>            | TAnd 
>            | TNot 
>            | TMe | TMa
>            | TMi 
>            | TEqual 
>            | TLet | TIn | TEq 
>            | TComma | TPunto | TPComma 
>            | THi | TSu | TUn | TU_ | TLo | TL_
>            | T2p | Tunit | Tfl 
>            | Tid | Tp1 | Tp2 | TLambda 
>            | TSplit | TAs 
>            | TIf | TThen | TElse | TIF
>            | TNew | TAsig | TUpd | TEntry | TDEntry | TOC | TCC | TOL | TCL 
>            | TCase | TOf | TNull | TIsNull | THead | TTail 
>            | TNod | TInp | TAt
>            deriving Show 
>
> happyError tokens = error ("Parse error\n" ++  (concat (map (editToken.show) (take 20 tokens)))) 
>
>
> symbols :: [Char]
> symbols = ['|', '&',  '=', '+', 
>            '-', '*','%', '(', ')' , '<', '>' , ':', '.',
>            ' ', ',', '\\', '\n','\t','{','}','[',']', '@',';','^']

> lexer :: String -> [Token]
> lexer [] = []
> lexer ('\n':cs) = lexer cs
> lexer ('\t':cs) = lexer cs
> lexer ('|':cs) = if cs!!0 == '|' then TOr :lexer (tail cs) else error "Malformed sequence"
> lexer ('&':cs) = if cs!!0 == '&' then TAnd :lexer (tail cs) else error "Malformed sequence"
> lexer ('<':cs) = if cs!!0 == '=' then TMi : lexer (tail cs) else  if cs!!0 == '-' then TAsig : lexer (tail cs) else TMe : lexer cs 
> lexer ('=':cs) = if cs!!0 == '=' then TEqual : lexer (tail cs) else TEq : lexer cs
> lexer ('+':cs) = TAdd : lexer cs
> lexer ('-':cs) = if cs!!0 == '>' then Tfl : lexer (tail cs) else TMinus : lexer cs
> lexer ('*':cs) = TMult : lexer cs
> lexer ('%':cs) = TDiv : lexer cs
> lexer ('@':cs) = TIF : lexer cs
> lexer ('>':cs) = TMa : lexer cs
> lexer ('<':cs) = TMe : lexer cs
> lexer ('(':cs) = TOB : lexer cs
> lexer (')':cs) = TCB : lexer cs
> lexer ('[':cs) = TOC : lexer cs
> lexer (']':cs) = TCC : lexer cs
> lexer ('{':cs) = TOL : lexer cs
> lexer ('}':cs) = TCL : lexer cs
> lexer (',':cs) = TComma : lexer cs
> lexer (';':cs) = TPComma : lexer cs
> lexer (':':cs) = T2p : lexer cs 
if cs!!0 == '=' then TAsig : lexer (tail cs) else T2p : lexer cs
> lexer ('\\':cs) = TLambda : lexer cs
> lexer ('.':cs)  = TPunto : lexer cs
> lexer ('^':cs)  = TAt : lexer cs


> lexer w@(c:cs) 
>       | isSpace c = lexer cs
>       | isDigit c = lexNum w
>       | isAlpha c = lexString w
>       | otherwise = error ("lexer: Not recognized symbol: " ++ [c])


> taulexer :: String -> [Token]
> taulexer [] = []
> taulexer ('\n':cs) = taulexer cs
> taulexer ('\t':cs) = taulexer cs
> taulexer ('-':cs) = if cs!!0 == '>' 
>                   then Tfl :taulexer (tail cs) 
>                   else error "Malformed sequence"
> taulexer (':':cs) = T2p :taulexer cs
> taulexer (',':cs) = TComma :taulexer cs  
> taulexer ('(':cs) = TOB : taulexer cs
> taulexer (')':cs) = TCB : taulexer cs
> taulexer ('>':cs) = TMa : taulexer cs
> taulexer ('<':cs) = TMe : taulexer cs
> taulexer ('[':cs) = TOC : taulexer cs
> taulexer (']':cs) = TCC : taulexer cs
> taulexer ('{':cs) = TOL : taulexer cs
> taulexer ('}':cs) = TCL : taulexer cs

> taulexer w@(c:cs) 
>       | isSpace c = taulexer cs
>       | isAlpha c = lexString w
>       | otherwise = error ("taulexer: Not recognized symbol: " ++ [c])


> etalexer :: String -> [Token]
> etalexer [] = []
> etalexer ('\n':cs) = etalexer cs
> etalexer ('\t':cs) = etalexer cs
> etalexer ('=':cs) = if cs!!0 == '=' 
>                   then TEq :etalexer (tail cs) 
>                   else TEq : etalexer cs
> etalexer ('(':cs) = TOB : etalexer cs
> etalexer (')':cs) = TCB : etalexer cs
> etalexer (',':cs) = TComma : etalexer cs
> etalexer ('.':cs) = TPunto : etalexer cs
> etalexer ('\\':cs) = TLambda : etalexer cs
> etalexer ('[':cs) = TOC : etalexer cs
> etalexer (']':cs) = TCC : etalexer cs
> etalexer ('{':cs) = TOL : etalexer cs
> etalexer ('}':cs) = TCL : etalexer cs

> etalexer w@(c:cs) 
>       | isSpace c = etalexer cs
>       | isDigit c = lexNum w
>       | isAlpha c = lexString w
>       | otherwise = error ("etalexer: Not recognized symbol: " ++ [c])

> lexString cs = case lookup w keywords of
>                  Nothing -> TString w: lexer rest
>                  (Just tok) -> tok : lexer rest
>     where (w,rest) = span (\x -> not (elem x symbols)) cs

> lexNum cs = TIv (read num) : lexer rest
>       where (num,rest) = span isDigit cs
> 
> keywords :: [(String,Token)]
> keywords = [("true",TTrue),
>             ("false",TFalse),
>             ("not",TNot),
>             ("su",TSu),
>             ("hi",THi),
>             ("un",TUn),
>             ("un!",TU_),
>             ("lo",TLo),
>             ("lo!",TL_),
>             ("unit",Tunit),
>             ("id",Tid),
>             ("p1",Tp1),
>             ("p2",Tp2),
>             ("let", TLet),
>             ("in", TIn),
>             ("if", TIf),
>             ("then", TThen),
>             ("else", TElse),
>             ("split", TSplit),
>             ("as", TAs),
>             ("new", TNew),
>             ("upd", TUpd),
>             ("ent", TEntry),
>             ("den", TDEntry),
>             ("inc", TInc),
>             ("null", TNull),
>             ("isNull", TIsNull),
>             ("case", TCase),
>             ("of", TOf),
>             ("tail", TTail),
>             ("head", THead),
>             ("nod",TNod),
>             ("inp",TInp)
>            ]
>
> }




