module BigNum.Constants
    ( NumberType
    , primitiveRootW
    , maximumNumberOfCoefficients
    , usedPrime
    , multiplicationBlockSize
    , multiplicationMaximumNumberOfDigits
    ) where

import BigNum.Types (NumberType)

-- Constants

primitiveRootW :: NumberType
primitiveRootW = 1753635133440165772

maximumNumberOfCoefficients :: NumberType
maximumNumberOfCoefficients = 2^32

usedPrime :: NumberType
usedPrime = 18446744069414584321

multiplicationBlockSize :: NumberType
multiplicationBlockSize = 6

multiplicationMaximumNumberOfDigits :: NumberType
multiplicationMaximumNumberOfDigits = 2^23
