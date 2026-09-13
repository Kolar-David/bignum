module BigNum.Comparison (compareBigNumbers, compareAbsoluteBigNumbers, compareUnsignedIntegers) where

import BigNum.Types (BigNumber(..))
import BigNum.Parser (normalizeBigNumber)

-- | Compares two non-negative integers represented as decimal strings
-- The comparison is based on their length and, if the lengths are equal, the numbers are compared lexicographically
compareUnsignedIntegers :: String -> String -> Ordering
compareUnsignedIntegers number1 number2
    | length number1 < length number2 = LT
    | length number1 > length number2 = GT
    | otherwise = compare number1 number2


-- | Compares the absolute values of two BigNumber values
-- The numbers are normalized, their decimal magnitudes are compared first
-- and coefficients are padded with trailing zeroes if necessary
compareAbsoluteBigNumbers :: BigNumber -> BigNumber -> Ordering
compareAbsoluteBigNumbers number1 number2
    | coefficient1 == "0" && coefficient2 == "0" = EQ
    | coefficient1 == "0" = LT
    | coefficient2 == "0" = GT
    | lengthExp1 < lengthExp2 = LT
    | lengthExp1 > lengthExp2 = GT
    | otherwise = compare paddedCoefficient1 paddedCoefficient2
    where
        BigNumber _ exponent1 coefficient1 = normalizeBigNumber number1
        BigNumber _ exponent2 coefficient2 = normalizeBigNumber number2
        lengthExp1 = length coefficient1 + exponent1
        lengthExp2 = length coefficient2 + exponent2
        maximumCoefficientLength = max (length coefficient1) (length coefficient2)
        paddedCoefficient1 = padCoefficient coefficient1 maximumCoefficientLength
        paddedCoefficient2 = padCoefficient coefficient2 maximumCoefficientLength
        -- | Pads a coefficient with trailing zeroes to the given length
        padCoefficient :: String -> Int -> String
        padCoefficient coefficient maximumCoefficientLength =
                               coefficient ++ replicate (maximumCoefficientLength - length coefficient) '0' 

-- | Compares two BigNumber values including their signs
-- Negative values reverse the ordering of their absolute values
compareBigNumbers :: BigNumber -> BigNumber -> Ordering
compareBigNumbers number1 number2
    | coefficient1 == "0" && coefficient2 == "0" = EQ
    | sign1 < sign2 = LT
    | sign1 > sign2 = GT
    | sign1 == 1 = absoluteComparison
    | otherwise = reverseOrdering absoluteComparison
    where
        normalizedNumber1@(BigNumber sign1 _ coefficient1) =  normalizeBigNumber number1
        normalizedNumber2@(BigNumber sign2 _ coefficient2) = normalizeBigNumber number2
        absoluteComparison = compareAbsoluteBigNumbers normalizedNumber1 normalizedNumber2
        -- | Reverses an Ordering value
        reverseOrdering LT = GT
        reverseOrdering GT = LT
        reverseOrdering EQ = EQ
