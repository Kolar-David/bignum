module BigNum.NumberMultiplication
    ( unsignedIntegerMultiplication
    , multiply
    ) where

import BigNum.Constants
    ( multiplicationBlockSize
    , multiplicationMaximumNumberOfDigits
    )

import BigNum.Types (NumberType, BigNumber(..))

import qualified BigNum.PolynomialMultiplication as PM

import BigNum.Parser (removeLeadingZeroes, parseBigNumber, bigNumberToString, normalizeBigNumber)

-- Auxillary functions

splitNumberToBlocks :: String -> NumberType -> [NumberType]
splitNumberToBlocks number blockSize = map (read . reverse) (splitHelper size (reverse number))
     where
        size :: Int
        size = fromIntegral blockSize

        splitHelper :: Int -> String -> [String]
        splitHelper _ [] = []
        splitHelper n xs = block : splitHelper n rest
            where (block, rest) = splitAt n xs

padLeft :: Int -> Char -> String -> String
padLeft desiredLength paddingChar text =
    replicate (desiredLength - length text) paddingChar ++ text

polynomialToNumberHelper :: [NumberType] -> NumberType -> NumberType -> NumberType -> String
polynomialToNumberHelper [] _ _ 0 = ""
polynomialToNumberHelper [] _ _ carry = reverse (show carry)
polynomialToNumberHelper (x:xs) blockValue blockSize carry =
    blockText ++ polynomialToNumberHelper xs blockValue blockSize newCarry
    where currentBlockAfterCarry = x + carry
          blockRemainder = currentBlockAfterCarry `mod` blockValue
          blockText = reverse $ padLeft (fromIntegral blockSize) '0' (show blockRemainder)
          newCarry = currentBlockAfterCarry `div` blockValue

polynomialToNumber :: [NumberType] -> NumberType -> String
polynomialToNumber polynomial blockSize =
    removeLeadingZeroes $ reverse (polynomialToNumberHelper polynomial blockValue blockSize 0)
    where blockValue = 10^blockSize

-- Number multiplication

unsignedIntegerMultiplication :: String -> String -> String
unsignedIntegerMultiplication number1 number2
    | fromIntegral (length number1 + length number2) > multiplicationMaximumNumberOfDigits = error "Number of digits exceeded!"
    | otherwise = result
    where polynomial1 = splitNumberToBlocks number1 multiplicationBlockSize
          polynomial2 = splitNumberToBlocks number2 multiplicationBlockSize
          productPolynomial = PM.multiply polynomial1 polynomial2
          result = polynomialToNumber productPolynomial multiplicationBlockSize

multiplyBigNumbers :: BigNumber -> BigNumber -> BigNumber
multiplyBigNumbers (BigNumber sign1 exponent1 coefficient1) (BigNumber sign2 exponent2 coefficient2) = normalizeBigNumber $ BigNumber resultSign resultExponent resultCoefficient
    where resultSign = sign1 * sign2
          resultExponent = exponent1 + exponent2
          resultCoefficient = unsignedIntegerMultiplication coefficient1 coefficient2

multiply :: String -> String -> Either String String
multiply number1 number2 = do
    parsedNumber1 <- parseBigNumber number1
    parsedNumber2 <- parseBigNumber number2
    let resultNumber = multiplyBigNumbers parsedNumber1 parsedNumber2
    Right (bigNumberToString resultNumber)
