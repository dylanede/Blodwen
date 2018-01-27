module Core.Primitives

import Core.Core
import Core.Context
import Core.TT

import Data.Vect

%default covering

record Prim where
  constructor MkPrim
  fn : PrimFn arity
  type : ClosedTerm
  totality : Totality

binOp : (Constant -> Constant -> Maybe Constant) ->
        {vars : _} -> Vect 2 (NF vars) -> Maybe (NF vars)
binOp fn [NPrimVal x, NPrimVal y]
    = map NPrimVal (fn x y)
binOp _ _ = Nothing

strLength : Vect 1 (NF vars) -> Maybe (NF vars)
strLength [NPrimVal (Str s)] = Just (NPrimVal (I (cast (length s))))
strLength _ = Nothing

strHead : Vect 1 (NF vars) -> Maybe (NF vars)
strHead [NPrimVal (Str "")] = Nothing
strHead [NPrimVal (Str str)] 
    = Just (NPrimVal (Ch (assert_total (strHead str))))
strHead _ = Nothing

strTail : Vect 1 (NF vars) -> Maybe (NF vars)
strTail [NPrimVal (Str "")] = Nothing
strTail [NPrimVal (Str str)] 
    = Just (NPrimVal (Str (assert_total (strTail str))))
strTail _ = Nothing

add : Constant -> Constant -> Maybe Constant
add (BI x) (BI y) = pure $ BI (x + y)
add (I x) (I y) = pure $ I (x + y)
add (Ch x) (Ch y) = pure $ Ch (cast (cast {to=Int} x + cast y))
add (Db x) (Db y) = pure $ Db (x + y)
add _ _ = Nothing

sub : Constant -> Constant -> Maybe Constant
sub (BI x) (BI y) = pure $ BI (x - y)
sub (I x) (I y) = pure $ I (x - y)
sub (Ch x) (Ch y) = pure $ Ch (cast (cast {to=Int} x - cast y))
sub (Db x) (Db y) = pure $ Db (x + y)
sub _ _ = Nothing

mul : Constant -> Constant -> Maybe Constant
mul (BI x) (BI y) = pure $ BI (x * y)
mul (I x) (I y) = pure $ I (x * y)
mul (Db x) (Db y) = pure $ Db (x * y)
mul _ _ = Nothing

div : Constant -> Constant -> Maybe Constant
div (BI x) (BI 0) = Nothing
div (BI x) (BI y) = pure $ BI (assert_total (x `div` y))
div (I x) (I 0) = Nothing
div (I x) (I y) = pure $ I (assert_total (x `div` y))
div (Db x) (Db y) = pure $ Db (x / y)
div _ _ = Nothing

mod : Constant -> Constant -> Maybe Constant
mod (BI x) (BI 0) = Nothing
mod (BI x) (BI y) = pure $ BI (assert_total (x `mod` y))
mod (I x) (I 0) = Nothing
mod (I x) (I y) = pure $ I (assert_total (x `mod` y))
mod _ _ = Nothing

toInt : Bool -> Constant
toInt True = I 1
toInt False = I 0

lt : Constant -> Constant -> Maybe Constant
lt (I x) (I y) = pure $ toInt (x < y)
lt (BI x) (BI y) = pure $ toInt (x < y)
lt (Str x) (Str y) = pure $ toInt (x < y)
lt (Ch x) (Ch y) = pure $ toInt (x < y)
lt (Db x) (Db y) = pure $ toInt (x < y)
lt _ _ = Nothing

lte : Constant -> Constant -> Maybe Constant
lte (I x) (I y) = pure $ toInt (x <= y)
lte (BI x) (BI y) = pure $ toInt (x <= y)
lte (Str x) (Str y) = pure $ toInt (x <= y)
lte (Ch x) (Ch y) = pure $ toInt (x <= y)
lte (Db x) (Db y) = pure $ toInt (x <= y)
lte _ _ = Nothing

eq : Constant -> Constant -> Maybe Constant
eq (I x) (I y) = pure $ toInt (x == y)
eq (BI x) (BI y) = pure $ toInt (x == y)
eq (Str x) (Str y) = pure $ toInt (x == y)
eq (Ch x) (Ch y) = pure $ toInt (x == y)
eq (Db x) (Db y) = pure $ toInt (x == y)
eq _ _ = Nothing

gte : Constant -> Constant -> Maybe Constant
gte (I x) (I y) = pure $ toInt (x >= y)
gte (BI x) (BI y) = pure $ toInt (x >= y)
gte (Str x) (Str y) = pure $ toInt (x >= y)
gte (Ch x) (Ch y) = pure $ toInt (x >= y)
gte (Db x) (Db y) = pure $ toInt (x >= y)
gte _ _ = Nothing

gt : Constant -> Constant -> Maybe Constant
gt (I x) (I y) = pure $ toInt (x > y)
gt (BI x) (BI y) = pure $ toInt (x > y)
gt (Str x) (Str y) = pure $ toInt (x > y)
gt (Ch x) (Ch y) = pure $ toInt (x > y)
gt (Db x) (Db y) = pure $ toInt (x > y)
gt _ _ = Nothing

constTy : Constant -> Constant -> Constant -> ClosedTerm
constTy a b c = PrimVal a `fnType` (PrimVal b `fnType` PrimVal c)

predTy : Constant -> Constant -> ClosedTerm
predTy a b = PrimVal a `fnType` PrimVal b

arithTy : Constant -> ClosedTerm
arithTy t = constTy t t t

cmpTy : Constant -> ClosedTerm
cmpTy t = constTy t t IntType

export
getOp : PrimFn arity -> 
        {vars : List Name} -> Vect arity (NF vars) -> Maybe (NF vars)
getOp (Add ty) = binOp add
getOp (Sub ty) = binOp sub
getOp (Mul ty) = binOp mul
getOp (Div ty) = binOp div
getOp (Mod ty) = binOp div

getOp (LT ty) = binOp lt
getOp (LTE ty) = binOp lte
getOp (EQ ty) = binOp eq
getOp (GTE ty) = binOp gte
getOp (GT ty) = binOp gt

getOp StrLength = strLength
getOp StrHead = strHead
getOp StrTail = strTail

getOp _ = const Nothing

prim : String -> Name
prim str = UN $ "prim__" ++ str

opName : PrimFn arity -> Name
opName (Add ty) = prim $ "add_" ++ show ty
opName (Sub ty) = prim $ "sub_" ++ show ty
opName (Mul ty) = prim $ "mul_" ++ show ty
opName (Div ty) = prim $ "div_" ++ show ty
opName (Mod ty) = prim $ "mod_" ++ show ty
opName (LT ty) = prim $ "lt_" ++ show ty
opName (LTE ty) = prim $ "lte_" ++ show ty
opName (EQ ty) = prim $ "eq_" ++ show ty
opName (GTE ty) = prim $ "gte_" ++ show ty
opName (GT ty) = prim $ "gt_" ++ show ty
opName StrLength = prim "strLength"
opName StrHead = prim "strHead"
opName StrTail = prim "strTail"

allPrimitives : List Prim
allPrimitives =
    map (\t => MkPrim (Add t) (arithTy t) Total) [IntType, IntegerType, CharType, DoubleType] ++
    map (\t => MkPrim (Sub t) (arithTy t) Total) [IntType, IntegerType, CharType, DoubleType] ++
    map (\t => MkPrim (Mul t) (arithTy t) Total) [IntType, IntegerType, DoubleType] ++
    map (\t => MkPrim (Div t) (arithTy t) (Partial NotCovering)) [IntType, IntegerType, DoubleType] ++
    map (\t => MkPrim (Mod t) (arithTy t) (Partial NotCovering)) [IntType, IntegerType] ++
    
    map (\t => MkPrim (LT t) (cmpTy t) Total) [IntType, IntegerType, CharType, DoubleType, StringType] ++
    map (\t => MkPrim (LTE t) (cmpTy t) Total) [IntType, IntegerType, CharType, DoubleType, StringType] ++
    map (\t => MkPrim (EQ t) (cmpTy t) Total) [IntType, IntegerType, CharType, DoubleType, StringType] ++
    map (\t => MkPrim (GTE t) (cmpTy t) Total) [IntType, IntegerType, CharType, DoubleType, StringType] ++
    map (\t => MkPrim (GT t) (cmpTy t) Total) [IntType, IntegerType, CharType, DoubleType, StringType] ++

    [MkPrim StrLength (predTy StringType IntType) Total,
     MkPrim StrHead (predTy StringType CharType) (Partial NotCovering),
     MkPrim StrTail (predTy StringType StringType) (Partial NotCovering)]

addPrim : {auto c : Ref Ctxt Defs} ->
          Prim -> Core annot ()
addPrim p = addBuiltin (opName (fn p)) (type p) (totality p) (fn p)

export
addPrimitives : {auto c : Ref Ctxt Defs} -> Core annot ()
addPrimitives 
    = do traverse addPrim allPrimitives
         pure ()
