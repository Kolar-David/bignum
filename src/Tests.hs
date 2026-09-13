module Main where

import RandomNumber (generateSignedNumber, generateUnsignedNumber)

import System.Random (StdGen, mkStdGen)

import Numeric (readFloat, readSigned)

import BigNum (add, multiply, divide)

import Text.Read (readMaybe)

import System.Environment (getArgs)

defaultSeed :: Int
defaultSeed = 314159265

-- Wrong result / Error

failOperationWithError :: String -> String -> String -> String-> IO a
failOperationWithError operationName number1 number2 message = error $ operationName ++ " returned an error: " ++ " number1 = " ++ number1 ++ " number2 = " ++ number2
        ++ " error: " ++ message


failOperationWithWrongResult :: String -> String -> String -> String -> String -> IO a
failOperationWithWrongResult operationName number1 number2 expectedResult actualResult = error $ operationName ++ " test failed: " ++ " number1 = " ++ number1 ++ " number2 = " ++ number2 ++ " expected = " ++ expectedResult ++ " actual = " ++ actualResult

-- Decimal string to rational

decimalToRational :: String -> Rational
decimalToRational input =
    case readSigned readFloat input of
        [(value, "")] -> value
        _ -> error "Invalid decimal number!"

-- Rounding

scaledIntegerToString :: Int -> Integer -> String
scaledIntegerToString decimalPlaces value
    | decimalPlaces == 0 = show value
    | otherwise = signPrefix ++ integerPart ++ fractionalPartWithDot
    where
        signPrefix | value < 0 = "-"
                   | otherwise = ""
        digits = show (abs value)
        paddedDigits = replicate (max 0 (decimalPlaces + 1 - length digits)) '0' ++ digits
        splitPosition = length paddedDigits - decimalPlaces
        (integerPart, fractionalPart) = splitAt splitPosition paddedDigits
        fractionalPartWithDot = "." ++ fractionalPart

roundDecimalString :: Int -> String -> String
roundDecimalString decimalPlaces input = scaledIntegerToString decimalPlaces roundedValue
    where
        value = decimalToRational input
        scale = 10 ^ decimalPlaces
        scaledValue = value * fromInteger scale
        roundedValue
            | scaledValue >= 0 = floor (scaledValue + 1 / 2)
            | otherwise = ceiling (scaledValue - 1 / 2)

-- Short operation

shortNumberOfIntegerDigits :: Int
shortNumberOfIntegerDigits = 5

shortNumberOfFractionalDigits :: Int
shortNumberOfFractionalDigits = 3

testSingleShortNumberOperation :: String -> (String -> String -> Either String String) -> (Rational -> Rational -> Rational)
    -> String -> String -> IO ()

testSingleShortNumberOperation operationName testedOperation referenceOperation number1 number2 =
        case testedOperation number1 number2 of
            Left message -> failOperationWithError operationName number1 number2 message
            Right actualResult ->
                 if actualValue == expectedValue
                     then return ()
                 else failOperationWithWrongResult operationName number1 number2 (show expectedValue) actualResult
                 where
                    actualValue = decimalToRational actualResult
                    expectedValue = referenceOperation (decimalToRational number1) (decimalToRational number2)

testShortNumberOperation :: Int -> String -> (String -> String -> Either String String) -> (Rational -> Rational -> Rational) -> StdGen -> IO StdGen
testShortNumberOperation 0 _ _ _ generator = return generator

testShortNumberOperation numberOfTests operationName testedOperation referenceOperation generator = do
        let (number1, generator1) = generateSignedNumber shortNumberOfIntegerDigits shortNumberOfFractionalDigits generator
            (number2, generator2) = generateSignedNumber shortNumberOfIntegerDigits shortNumberOfFractionalDigits generator1
        testSingleShortNumberOperation operationName testedOperation referenceOperation number1 number2
        testShortNumberOperation (numberOfTests - 1) operationName testedOperation referenceOperation generator2

-- Short addition

testAddition :: Int -> StdGen -> IO StdGen
testAddition numberOfTests generator = testShortNumberOperation numberOfTests "Addition" add (+) generator

-- Short addition

testMultiplication :: Int -> StdGen -> IO StdGen
testMultiplication numberOfTests generator = testShortNumberOperation numberOfTests "Short signed rational multiplication" multiply (*) generator


-- Long integer multiplication

testLongIntegerMultiplication :: Int -> Int -> StdGen -> IO StdGen

testLongIntegerMultiplication 0 _ generator = return generator

testLongIntegerMultiplication numberOfTests numberOfDigits generator = do
        let (number1, generator1) = generateUnsignedNumber numberOfDigits 0 generator
            (number2, generator2) = generateUnsignedNumber numberOfDigits 0 generator1

        testSingleLongIntegerMultiplication number1 number2
        testLongIntegerMultiplication (numberOfTests - 1) numberOfDigits generator2


testSingleLongIntegerMultiplication :: String -> String -> IO ()
testSingleLongIntegerMultiplication number1 number2 =
    case (multiply number1 number2) of
        Left message -> failOperationWithError "Long integer multiplication" number1 number2 message
        Right actualResult ->
            if actualValue == expectedValue
                then return ()
            else
                failOperationWithWrongResult "Long integer multiplication" number1 number2 (show expectedValue) actualResult
            where
                actualValue = read actualResult :: Integer
                expectedValue = (read number1 :: Integer) * (read number2 :: Integer)


-- Test division

testSingleDivision :: Int -> String -> String -> IO ()
testSingleDivision fractionalDigits number1 number2 =
    case multiply number1 number2 of
        Left message -> failOperationWithError "Division test - multiplication" number1 number2 message
        Right product ->
            case divide fractionalDigits product number2 of
                Left message -> failOperationWithError "Division" product number2 message
                Right actualResult ->
                    if (decimalToRational actualResult) == (decimalToRational number1)
                        then return ()
                        else
                            failOperationWithWrongResult "Division" product number2 number1 actualResult

testDivision :: Int -> Int -> Int -> StdGen -> IO StdGen
testDivision 0 _ _ generator =
    return generator

testDivision numberOfTests integerDigits fractionalDigits generator = do
        let (number1, generator1) = generateSignedNumber integerDigits fractionalDigits generator
            (number2, generator2) = generateSignedNumber integerDigits fractionalDigits generator1

        testSingleDivision fractionalDigits number1 number2
        testDivision (numberOfTests - 1) integerDigits fractionalDigits generator2

-- Division with precision

testSingleDivision2 :: Int -> String -> String -> IO ()
testSingleDivision2 precision number1 number2 =
    case multiply number1 number2 of
        Left message -> failOperationWithError "Division test multiplication" number1 number2 message
        Right product -> case divide precision product number1 of
                Left message -> failOperationWithError "Division" product number1 message
                Right actualResult ->
                    if (decimalToRational actualResult) == (decimalToRational expectedResult)
                        then return ()
                        else
                            failOperationWithWrongResult "Division" product number1 expectedResult actualResult
                    where
                        expectedResult = roundDecimalString precision number2

testDivision2 :: Int -> Int -> Int -> Int -> StdGen -> IO StdGen
testDivision2 0 _ _ _  generator = return generator

testDivision2 numberOfTests integerDigits fractionalDigits precision generator = do
        let (number1, generator1) = generateSignedNumber integerDigits fractionalDigits generator
            (number2, generator2) = generateSignedNumber integerDigits fractionalDigits generator1

        testSingleDivision2 precision number1 number2
        testDivision2 (numberOfTests - 1) integerDigits fractionalDigits precision generator2

-- Run all tests

main :: IO ()
main = do
    arguments <- getArgs
    seed <- case arguments of
            [] -> return defaultSeed
            [seedString] ->
                case readMaybe seedString of
                    Just value -> return value
                    Nothing    -> error "Seed must be an integer."
            _ -> error "Correct usage: Tests [seed]"

    runAllTests seed (mkStdGen seed)

runAllTests :: Int -> StdGen -> IO ()
runAllTests seed generator = do
    putStrLn $ "Running tests with seed " ++ show seed ++ "..."
    putStrLn "Testing addition!"
    generator1 <- testAddition 1000 generator
    putStrLn "Testing multiplication!"
    generator2 <- testMultiplication 500 generator1
    generator3 <- testLongIntegerMultiplication 100 1000 generator2
    generator31 <- testLongIntegerMultiplication 10 100000 generator3
    putStrLn "Testing division!"
    generator4 <- testDivision 20 100 50 generator31
    generator5 <- testDivision2 100 10 20 5 generator4
    generator6 <- testDivision2 10 3000 5000 4000 generator5
    putStrLn "All tests passed!"
