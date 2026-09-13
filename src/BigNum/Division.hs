module BigNum.Division (divide, divide0, divide10, divide30, divide100, divideWithAbsoluteTolerance) where

import BigNum.Types (BigNumber(..))

import BigNum.Constants (initialReciprocalPrecision)

import BigNum.Parser (parseBigNumber, bigNumberToString, normalizeBigNumber)

import BigNum.Rounding (roundToDecimalPlaces, truncateToSignificantDigits)

import BigNum.Addition (absoluteBigNumber, subtractBigNumbers)

import BigNum.NumberMultiplication (multiplyBigNumbers)

import BigNum.Comparison (compareBigNumbers, compareAbsoluteBigNumbers)

-- Constants

-- | Represents 0 in the BigNumber format
zero :: BigNumber
zero = BigNumber 1 0 "0"

-- | Represents 1 in the BigNumber format
one :: BigNumber
one = BigNumber 1 0 "1"

-- | Represents 2 in the BigNumber format
two :: BigNumber
two = BigNumber 1 0 "2"

-- | Represents 0.5 in the BigNumber format
half :: BigNumber
half = BigNumber 1 (-1) "5"


-- Auxiliary functions


-- | Computes an initial approximation of the reciprocal of a positive BigNumber
-- The approximation is constructed from the leading digits and the decimal exponent
initialReciprocalApproximation :: BigNumber -> BigNumber
initialReciprocalApproximation number = normalizeBigNumber $ BigNumber 1 approximationExponent (show approximationCoefficient)
    where
        BigNumber _ numberExponent numberCoefficient = normalizeBigNumber number
        coefficientLength = length numberCoefficient
        prefixLength = min initialReciprocalPrecision coefficientLength
        prefix = read (take prefixLength numberCoefficient) :: Integer
        s = prefixLength + initialReciprocalPrecision
        approximationCoefficient = (10 ^ s) `div` prefix
        approximationExponent = -(numberExponent + coefficientLength - prefixLength + s)

-- | Converts a requested number of decimal places into an internal absolute tolerance
decimalPlacesToTolerance :: Int -> BigNumber
decimalPlacesToTolerance decimalPlaces = BigNumber 1 (-(decimalPlaces + 5)) "1"

-- | Divides two BigNumber values a and b with the given absolute error tolerance
-- The reciprocal of the denominator is approximated using Newton method
divideWithAbsoluteTolerance :: BigNumber -> BigNumber -> BigNumber -> Either String BigNumber

divideWithAbsoluteTolerance tolerance numerator denominator
    | normalizedDenominator == zero = Left "Division by zero!"
    | compareBigNumbers normalizedTolerance zero /= GT = Left "Tolerance must be positive!"
    | normalizedNumerator == zero = Right zero
    | otherwise = Right $ applyResultSign $ newtonIteration initialReciprocalPrecision initialApproximation
    where
        normalizedTolerance = normalizeBigNumber tolerance
        normalizedNumerator = normalizeBigNumber numerator
        normalizedDenominator = normalizeBigNumber denominator
        positiveNumerator = absoluteBigNumber normalizedNumerator
        positiveDenominator = absoluteBigNumber normalizedDenominator
        resultSign = sign normalizedNumerator * (sign normalizedDenominator)
        initialApproximation = initialReciprocalApproximation positiveDenominator
        errorBound = multiplyBigNumbers normalizedTolerance positiveDenominator
        -- | Improves the reciprocal approximation using Newton's iteration until the required tolerance is reached
        -- The working precision is roughly doubled after each iteration
        newtonIteration :: Int -> BigNumber -> BigNumber
        newtonIteration workingPrecision approximation
            | approximationIsPreciseEnough = multiplyBigNumbers positiveNumerator approximation
            | otherwise = newtonIteration nextWorkingPrecision nextApproximation
            where
                -- b * x_k
                denominatorTimesApproximation = multiplyBigNumbers positiveDenominator approximation
                -- 1 - b * x_k
                residual = subtractBigNumbers one denominatorTimesApproximation
                -- |a| * (1 - b * x_k)
                absoluteErrorNumerator = multiplyBigNumbers positiveNumerator residual
                approximationIsPreciseEnough = compareAbsoluteBigNumbers absoluteErrorNumerator errorBound /= GT
                -- 2 - b * x_k
                correction = subtractBigNumbers two denominatorTimesApproximation
                -- x_(k+1) = x_k * (2 - b * x_k)
                nextWorkingPrecision = 2 * workingPrecision
                nextApproximation = truncateToSignificantDigits workingPrecision $ multiplyBigNumbers approximation correction
        -- | Applies the sign of the quotient to the computed absolute result
        applyResultSign :: BigNumber -> BigNumber
        applyResultSign result =
            case normalizeBigNumber result of
                BigNumber _ _ "0" -> zero
                BigNumber _ resultExponent resultCoefficient -> BigNumber resultSign resultExponent resultCoefficient


-- | Divides two decimal numbers represented as strings and rounds the result to the requested number of decimal places
divide :: Int -> String -> String -> Either String String
divide decimalPlaces numerator denominator
    | decimalPlaces < 0 = Left "The number of decimal places must be non-negative!"
    | otherwise = do
        parsedNumerator <- parseBigNumber numerator
        parsedDenominator <- parseBigNumber denominator
        let tolerance = decimalPlacesToTolerance decimalPlaces
        approximation <- divideWithAbsoluteTolerance tolerance parsedNumerator parsedDenominator
        roundedResult <- roundToDecimalPlaces decimalPlaces approximation
        Right (bigNumberToString roundedResult)


-- | Divides two decimal numbers and rounds the result to 0 decimal places
divide0 :: String -> String -> Either String String
divide0 numerator denominator = divide 0 numerator denominator

-- | Divides two decimal numbers and rounds the result to 10 decimal places
divide10 :: String -> String -> Either String String
divide10 numerator denominator = divide 10 numerator denominator

-- | Divides two decimal numbers and rounds the result to 30 decimal places
divide30 :: String -> String -> Either String String
divide30 numerator denominator = divide 30 numerator denominator

-- | Divides two decimal numbers and rounds the result to 100 decimal places
divide100 :: String -> String -> Either String String
divide100 numerator denominator = divide 100 numerator denominator
