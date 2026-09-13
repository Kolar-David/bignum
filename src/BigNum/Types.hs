module BigNum.Types (NumberType, BigNumber(..)) where

-- | Numeric type used internally for arithmetic operations with short numbers without overflowing
type NumberType = Integer

-- | Internal representation of a decimal number in the form
-- sign * coefficient * 10^exponent
data BigNumber = BigNumber
    { sign :: Int, exponent :: Int, coefficient :: String} deriving (Eq, Show)
