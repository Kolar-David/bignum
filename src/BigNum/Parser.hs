module BigNum.Parser (parseBigNumber, removeLeadingZeroes, bigNumberToString, normalizeBigNumber) where

import Data.Char (isDigit)

import BigNum.Types (BigNumber(..))

-- Auxiliary functions

-- | Removes leading zeroes from a decimal string.
-- Returns 0 if the input represents zero
removeLeadingZeroes :: String -> String
removeLeadingZeroes text =
    case dropWhile (== '0') text of
        "" -> "0"
        result -> result

-- | Removes trailing zeroes from a decimal string and returns their count
removeTrailingZeroes :: String -> (String, Int)
removeTrailingZeroes text = (reverse reversedWithoutZeroes, removedZeroCount)
    where
        reversedText = reverse text
        reversedWithoutZeroes = dropWhile (== '0') reversedText
        removedZeroCount = length reversedText - length reversedWithoutZeroes

-- Parser

-- | Parses a decimal string into the internal BigNumber representation
-- Returns an error if the input format is invalid
parseBigNumber :: String -> Either String BigNumber
parseBigNumber input =
    case input of
        "" -> Left "Input is empty."
        '-' : rest -> parseWithoutSign (-1) rest
        rest -> parseWithoutSign 1 rest

-- | Parses the unsigned part of a decimal number using the given sign
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

-- | Converts BigNumber into its canonical internal representation
-- Leading and trailing zeroes are removed and zero is normalized to a unique form
normalizeBigNumber :: BigNumber -> BigNumber
normalizeBigNumber (BigNumber numberSign numberExponent numberCoefficient) =
    case removeLeadingZeroes numberCoefficient of
        -- the unique form of zero
        "0" -> BigNumber 1 0 "0"
        coefficientWithoutLeadingZeroes ->
            let (coefficientWithoutTrailingZeroes, removedTrailingZeroCount) = 
                    removeTrailingZeroes coefficientWithoutLeadingZeroes
            in BigNumber numberSign (numberExponent + removedTrailingZeroCount) coefficientWithoutTrailingZeroes

-- | Converts a normalized BigNumber into a decimal string
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

-- | Converts a BigNumber into its normalized decimal string representation
bigNumberToString :: BigNumber -> String
bigNumberToString number = normalizedBigNumberToString (normalizeBigNumber number)
