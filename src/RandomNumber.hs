module RandomNumber (generateUnsignedNumber, generateSignedNumber) where

import System.Random (StdGen, randomR)

generateDigits :: Int -> StdGen -> (String, StdGen)
generateDigits 0 generator = ("", generator)

generateDigits count generator =
    (digit : rest, finalGenerator)
    where
        (digit, nextGenerator) = randomR ('0', '9') generator
        (rest, finalGenerator) = generateDigits (count - 1) nextGenerator

generateUnsignedNumber :: Int -> Int -> StdGen -> (String, StdGen)
generateUnsignedNumber integerDigits fractionalDigits generator
    | integerDigits <= 0 = error "The number of integer digits must be positive!"
    | fractionalDigits < 0 = error "The number of fractional digits must non-negative!"
    | otherwise = (result, finalGenerator)
    where
        (firstDigit, generator1) = randomR ('1', '9') generator
        (remainingIntegerDigits, generator2) = generateDigits (integerDigits - 1) generator1
        (fractionalPart, finalGenerator) = generateDigits fractionalDigits generator2
        integerPart = firstDigit : remainingIntegerDigits
        result
            | fractionalDigits == 0 = integerPart
            | otherwise = integerPart ++ "." ++ fractionalPart

generateSignedNumber :: Int -> Int -> StdGen -> (String, StdGen)
generateSignedNumber integerDigits fractionalDigits generator0 = (signedNumber, generator2)
    where
        (number, generator1) = generateUnsignedNumber integerDigits fractionalDigits generator0
        (isNegative, generator2) = randomR (False, True) generator1
        signedNumber
            | isNegative = '-' : number
            | otherwise = number
