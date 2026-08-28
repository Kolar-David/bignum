module BigNum.Parser (parseBigNumber, removeLeadingZeroes, bigNumberToString, normalizeBigNumber) where

import Data.Char (isDigit)

import BigNum.Types (BigNumber(..))

-- Auxiliary functions

removeLeadingZeroes :: String -> String
removeLeadingZeroes text =
    case dropWhile (== '0') text of
        "" -> "0"
        result -> result

removeTrailingZeroes :: String -> (String, Int)
removeTrailingZeroes text = (reverse reversedWithoutZeroes, removedZeroCount)
    where
        reversedText = reverse text
        reversedWithoutZeroes = dropWhile (== '0') reversedText
        removedZeroCount = length reversedText - length reversedWithoutZeroes

-- Parser

parseBigNumber :: String -> Either String BigNumber
parseBigNumber input =
    case input of
        "" -> Left "Input is empty."
        '-' : rest -> parseWithoutSign (-1) rest
        rest -> parseWithoutSign 1 rest

parseWithoutSign :: Int -> String -> Either String BigNumber
parseWithoutSign numberSign text =
    case break (== '.') text of
        -- With decimal point
        (integerPart, '.' : fractionalPart)
            | null integerPart -> Left "Integer part is empty."
            | null fractionalPart -> Left "Fractional part is empty."
            | '.' `elem` fractionalPart -> Left "Input contains more than one decimal point."
            | not (all isDigit integerPart) -> Left "Integer part contains a non-digit character."
            | not (all isDigit fractionalPart) -> Left "Fractional part contains a non-digit character."
            | otherwise -> Right $ normalizeBigNumber $ BigNumber numberSign rawExponent rawCoefficient
            where
                rawCoefficient = integerPart ++ fractionalPart
                rawExponent = negate (length fractionalPart)

        -- Without decimal point
        (integerPart, "")
            | null integerPart -> Left "Input is empty."
            | not (all isDigit integerPart) -> Left "Input contains a non-digit character."
            | otherwise -> Right $ normalizeBigNumber $ BigNumber numberSign 0 integerPart
        _ ->
            Left "Invalid input."

normalizeBigNumber :: BigNumber -> BigNumber
normalizeBigNumber (BigNumber numberSign numberExponent numberCoefficient) =
    case removeLeadingZeroes numberCoefficient of
        "0" -> BigNumber 1 0 "0"
        coefficientWithoutLeadingZeroes ->
            let (coefficientWithoutTrailingZeroes, removedTrailingZeroCount) = 
                    removeTrailingZeroes coefficientWithoutLeadingZeroes
            in BigNumber numberSign (numberExponent + removedTrailingZeroCount) coefficientWithoutTrailingZeroes

normalizedBigNumberToString :: BigNumber -> String
normalizedBigNumberToString (BigNumber numberSign numberExponent numberCoefficient)
    | numberCoefficient == "0" = "0"
    | numberExponent >= 0 = signPrefix ++ numberCoefficient ++ (replicate numberExponent '0')
    | fractionalDigits < length numberCoefficient = signPrefix ++ integerPart ++ "." ++ fractionalPart
    | otherwise = signPrefix ++ "0." ++ (replicate missingZeroes '0') ++ numberCoefficient
    where signPrefix = case numberSign of
                           1 -> ""
                           (-1) -> "-"
          fractionalDigits = abs numberExponent
          splitPosition = length numberCoefficient + numberExponent
          (integerPart, fractionalPart) = splitAt splitPosition numberCoefficient
          missingZeroes = fractionalDigits - length numberCoefficient


bigNumberToString :: BigNumber -> String
bigNumberToString number = normalizedBigNumberToString (normalizeBigNumber number)
