module BigNum.Types
    ( NumberType
    , BigNumber(..)
    ) where

type NumberType = Integer

data BigNumber = BigNumber
    { sign :: Int
    , exponent :: Int
    , coefficient :: String
    } deriving (Eq, Show)
