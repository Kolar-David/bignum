module BigNum.NumberMultiplication (unsignedIntegerMultiplication, multiply, multiplyBigNumbers) where

import BigNum.Constants (multiplicationBlockSize, multiplicationMaximumNumberOfDigits)

import BigNum.Types (NumberType, BigNumber(..))

import qualified BigNum.PolynomialMultiplication as PM

import BigNum.Parser (removeLeadingZeroes, parseBigNumber, bigNumberToString, normalizeBigNumber)

-- Auxillary functions

-- | Splits a decimal integer string into fixed-size blocks starting from the least significant digits
splitNumberToBlocks :: String -> NumberType -> [NumberType]
splitNumberToBlocks number blockSize = map (read . reverse) (splitHelper size (reverse number))
     where
        size :: Int
        size = fromIntegral blockSize
        -- | Splits a string into consecutive blocks of the given size
        splitHelper :: Int -> String -> [String]
        splitHelper _ [] = []
        splitHelper n xs = block : splitHelper n rest
            where (block, rest) = splitAt n xs

-- | Pads a string on the left with the given character to the desired length
padLeft :: Int -> Char -> String -> String
padLeft desiredLength paddingChar text =
    replicate (desiredLength - length text) paddingChar ++ text

-- | Converts polynomial coefficients back to decimal blocks while propagating carries
polynomialToNumberHelper :: [NumberType] -> NumberType -> NumberType -> NumberType -> String
polynomialToNumberHelper [] _ _ 0 = ""
polynomialToNumberHelper [] _ _ carry = reverse (show carry)
polynomialToNumberHelper (x:xs) blockValue blockSize carry =
    blockText ++ polynomialToNumberHelper xs blockValue blockSize newCarry
    where currentBlockAfterCarry = x + carry
          blockRemainder = currentBlockAfterCarry `mod` blockValue
          blockText = reverse $ padLeft (fromIntegral blockSize) '0' (show blockRemainder)
          newCarry = currentBlockAfterCarry `div` blockValue

-- | Converts a polynomial representation of an integer back to a decimal string
polynomialToNumber :: [NumberType] -> NumberType -> String
polynomialToNumber polynomial blockSize =
    removeLeadingZeroes $ reverse (polynomialToNumberHelper polynomial blockValue blockSize 0)
    where blockValue = 10^blockSize

-- Number multiplication

-- | Multiplies two non-negative integers represented as decimal strings using polynomial multiplication
-- Throws an error if the combined number of digits exceeds the supported limit
unsignedIntegerMultiplication :: String -> String -> String
unsignedIntegerMultiplication number1 number2
    | fromIntegral (length number1 + length number2) > multiplicationMaximumNumberOfDigits = error "Number of digits exceeded!"
    | otherwise = result
    where polynomial1 = splitNumberToBlocks number1 multiplicationBlockSize
          polynomial2 = splitNumberToBlocks number2 multiplicationBlockSize
          productPolynomial = PM.multiply polynomial1 polynomial2
          result = polynomialToNumber productPolynomial multiplicationBlockSize

-- | Multiplies two BigNumber values by multiplying their coefficients, signs, and powers of ten
multiplyBigNumbers :: BigNumber -> BigNumber -> BigNumber
multiplyBigNumbers (BigNumber sign1 exponent1 coefficient1) (BigNumber sign2 exponent2 coefficient2) = normalizeBigNumber $ BigNumber resultSign resultExponent resultCoefficient
    where resultSign = sign1 * sign2
          resultExponent = exponent1 + exponent2
          resultCoefficient = unsignedIntegerMultiplication coefficient1 coefficient2

-- | Multiplies two decimal numbers represented as strings
-- Returns an error if either the input has an invalid format or something else goes wrong
multiply :: String -> String -> Either String String
multiply number1 number2 = do
    parsedNumber1 <- parseBigNumber number1
    parsedNumber2 <- parseBigNumber number2
    let resultNumber = multiplyBigNumbers parsedNumber1 parsedNumber2
    Right (bigNumberToString resultNumber)
