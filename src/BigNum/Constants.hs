module BigNum.Constants
    ( NumberType
    , primitiveRootW
    , maximumNumberOfCoefficients
    , usedPrime
    , multiplicationBlockSize
    , multiplicationMaximumNumberOfDigits
    ) where

-- Types

type NumberType = Integer

-- Constants

primitiveRootW :: NumberType
primitiveRootW = 1753635133440165772

maximumNumberOfCoefficients :: NumberType
maximumNumberOfCoefficients = 2^32

usedPrime :: NumberType
usedPrime = 18446744069414584321

-- Preliminary values! -------------------------

multiplicationBlockSize :: NumberType
multiplicationBlockSize = 6

multiplicationMaximumNumberOfDigits :: NumberType
multiplicationMaximumNumberOfDigits = 2^23

------------------------------------------------
