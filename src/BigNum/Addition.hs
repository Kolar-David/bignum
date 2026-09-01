module BigNum.Addition (add, integerAddition, negateBigNumber, subtractBigNumbers, absoluteBigNumber) where

import Data.Char (digitToInt, intToDigit)

import BigNum.Parser (removeLeadingZeroes, parseBigNumber, bigNumberToString, normalizeBigNumber)

import BigNum.Types (BigNumber(..))

import BigNum.Comparison (compareUnsignedIntegers)

-- Auxillary functions

integerAddition :: String -> String -> String
integerAddition number1 number2 = reverse $ integerAdditionHelper (reverse number1) (reverse number2) 0
     where
          integerAdditionHelper :: String -> String -> Int -> String
          integerAdditionHelper [] y 0 = y
          integerAdditionHelper x [] 0 = x

          integerAdditionHelper x [] carry = integerAdditionHelper x (show carry) 0
          integerAdditionHelper [] y carry = integerAdditionHelper y (show carry) 0 
          integerAdditionHelper (x:xs) (y:ys) carry = digit : (integerAdditionHelper xs ys newCarry) 
              where currentSum = (digitToInt x) + (digitToInt y) + carry
                    digit = intToDigit $ currentSum `mod` 10
                    newCarry = currentSum `div` 10


-- number1 needs to be larger or equal to number2!
integerSubtraction :: String -> String -> String
integerSubtraction number1 number2 = removeLeadingZeroes $ reverse $ integerSubtractionHelper (reverse number1) (reverse number2) 0
     where
         integerSubtractionHelper :: String -> String -> Int -> String
         integerSubtractionHelper [] [] 0 = []
         integerSubtractionHelper xs [] 0 = xs
         integerSubtractionHelper (x:xs) [] carry = digit : integerSubtractionHelper xs [] newCarry
              where currentSum = digitToInt x + carry
                    digit = intToDigit $ currentSum `mod` 10
                    newCarry = currentSum `div` 10
         integerSubtractionHelper (x:xs) (y:ys) carry = digit : integerSubtractionHelper xs ys newCarry 
              where currentSum = digitToInt x - digitToInt y + carry
                    digit = intToDigit $ currentSum `mod` 10
                    newCarry = currentSum `div` 10    
         integerSubtractionHelper [] _ _ = error "number2 > number1!"


-- Main functions

absoluteBigNumber :: BigNumber -> BigNumber
absoluteBigNumber number = case normalizeBigNumber number of
                               BigNumber _ numberExponent numberCoefficient -> BigNumber 1 numberExponent numberCoefficient


negateBigNumber :: BigNumber -> BigNumber
negateBigNumber number = case normalizeBigNumber number of
                             BigNumber _ _ "0" -> BigNumber 1 0 "0"
                             BigNumber numberSign numberExponent numberCoefficient -> BigNumber (-numberSign) numberExponent numberCoefficient

addBigNumbers :: BigNumber -> BigNumber -> BigNumber
addBigNumbers (BigNumber sign1 exponent1 coefficient1) (BigNumber sign2 exponent2 coefficient2) = normalizeBigNumber $ BigNumber resultSign commonExponent resultCoefficient
    where
        commonExponent = min exponent1 exponent2
        alignedCoefficient1 = coefficient1 ++ replicate (exponent1 - commonExponent) '0'
        alignedCoefficient2 = coefficient2 ++ replicate (exponent2 - commonExponent) '0'
        (resultSign, resultCoefficient)
             | sign1 == sign2 = (sign1, integerAddition alignedCoefficient1 alignedCoefficient2)
             | otherwise =
                 case compareUnsignedIntegers alignedCoefficient1 alignedCoefficient2 of
                    GT -> (sign1, integerSubtraction alignedCoefficient1 alignedCoefficient2)
                    LT -> (sign2, integerSubtraction alignedCoefficient2 alignedCoefficient1)
                    EQ -> (1, "0")

subtractBigNumbers :: BigNumber -> BigNumber -> BigNumber
subtractBigNumbers number1 number2 = addBigNumbers number1 (negateBigNumber number2)

add :: String -> String -> Either String String
add number1 number2 = do
    parsedNumber1 <- parseBigNumber number1
    parsedNumber2 <- parseBigNumber number2
    let resultNumber = addBigNumbers parsedNumber1 parsedNumber2
    Right (bigNumberToString resultNumber)
