module BigNum.Rounding (roundToDecimalPlaces, truncateToSignificantDigits) where

import Data.Char (digitToInt, intToDigit)

import BigNum.Types (NumberType, BigNumber(..))
import BigNum.Parser (normalizeBigNumber)
import BigNum.Addition (integerAddition)

truncateToSignificantDigits :: Int -> BigNumber -> BigNumber
truncateToSignificantDigits precision inputNumber
    | precision <= 0 = error "Precision must be positive!"
    | length numberCoefficient <= precision = number
    | otherwise = normalizeBigNumber $ BigNumber numberSign (numberExponent + removedDigitCount) truncatedCoefficient
    where
        number@(BigNumber numberSign numberExponent numberCoefficient) = normalizeBigNumber inputNumber
        removedDigitCount = length numberCoefficient - precision
        truncatedCoefficient = take precision numberCoefficient


shouldRoundUp :: String -> Bool
shouldRoundUp [] = False
shouldRoundUp (digit:_) = digit >= '5'


roundToDecimalPlaces :: Int -> BigNumber -> Either String BigNumber
roundToDecimalPlaces decimalPlaces inputNumber
    | decimalPlaces < 0 = Left "Number of decimal places must be non-negative"
    | numberExponent >= targetExponent = Right number
    | otherwise = Right $ normalizeBigNumber $ BigNumber numberSign targetExponent roundedCoefficient
    where
        (BigNumber numberSign numberExponent numberCoefficient) = normalizeBigNumber inputNumber
        number = BigNumber numberSign numberExponent numberCoefficient
        targetExponent = negate decimalPlaces
        removedDigitCount = targetExponent - numberExponent
        coefficientLength = length numberCoefficient
        paddingLength = max 0 (removedDigitCount - coefficientLength)
        paddedCoefficient = replicate paddingLength '0' ++ numberCoefficient
        keptDigitCount = length paddedCoefficient - removedDigitCount
        (rawKeptDigits, removedDigits) = splitAt keptDigitCount paddedCoefficient
        keptDigits
            | null rawKeptDigits = "0"
            | otherwise = rawKeptDigits
        roundedCoefficient
            | shouldRoundUp removedDigits = integerAddition keptDigits "1"
            | otherwise = keptDigits
