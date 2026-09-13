module BigNum.Constants
    (NumberType, primitiveRootW, maximumNumberOfCoefficients, usedPrime,
      multiplicationBlockSize, multiplicationMaximumNumberOfDigits, initialReciprocalPrecision
    ) where

import BigNum.Types (NumberType)

-- Constants

--- FFT

-- | Primitive root of unity of maximum supported order modulo 'usedPrime'
primitiveRootW :: NumberType
primitiveRootW = 1753635133440165772

-- | Maximum supported number of coefficients in FFT
maximumNumberOfCoefficients :: NumberType
maximumNumberOfCoefficients = 2^32

-- | Prime modulus used by FFT
usedPrime :: NumberType
usedPrime = 18446744069414584321

--- Multiplication

-- | Number of decimal digits stored in one coefficient during integer multiplication
multiplicationBlockSize :: NumberType
multiplicationBlockSize = 6

-- | Maximum combined number of decimal digits supported by multiplication
multiplicationMaximumNumberOfDigits :: NumberType
multiplicationMaximumNumberOfDigits = 2^26

--- Division

-- | Initial number of significant digits used for the reciprocal approximation in division
initialReciprocalPrecision :: Int
initialReciprocalPrecision = 16
