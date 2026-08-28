module BigNum.PolynomialMultiplication
    (moduloPower, nextPowerOfTwo, extendWithZeroes, splitEvenOdd,
      getCorrectW, fft, multiply
    ) where

import BigNum.Types (NumberType)

import BigNum.Constants (primitiveRootW, maximumNumberOfCoefficients, usedPrime)

-- Constants

primitiveRootWInverse :: NumberType
primitiveRootWInverse = moduloPower primitiveRootW (maximumNumberOfCoefficients - 1) usedPrime

-- Auxillary functions

moduloPower :: NumberType -> NumberType -> NumberType -> NumberType
moduloPower _ 0 _ = 1
moduloPower base exponent modulo
    | odd exponent = (val * val * base) `mod` modulo
    | otherwise = (val * val) `mod` modulo
    where val = moduloPower base (exponent `div` 2) modulo

nextPowerOfTwo :: NumberType -> NumberType
nextPowerOfTwo n = nextPowerHelper 1 n
    where nextPowerHelper x n
              | x >= n = x
              | otherwise = nextPowerHelper (2*x) n


extendWithZeroes :: [NumberType] -> NumberType -> [NumberType]
extendWithZeroes list n = list ++ replicate (fromIntegral n - length list) 0

splitEvenOdd :: [NumberType] -> ([NumberType], [NumberType])
splitEvenOdd [] = ([], [])
splitEvenOdd [x] = ([x], [])
splitEvenOdd (x:y:xs) = ((x:evenXs), (y:oddXs))
    where (evenXs, oddXs) = splitEvenOdd xs

getCorrectW :: NumberType -> NumberType -> NumberType -> NumberType
getCorrectW currentN desiredN currentW
    | currentN == desiredN = currentW
    | currentN > desiredN = getCorrectW (currentN `div` 2) desiredN ((currentW * currentW) `mod` usedPrime)
    | otherwise = error "desiredN must not be greater than currentN"

-- FFT

-- The length of the list must be a power of 2 and w must correspond to it!

fft :: [NumberType] -> NumberType -> NumberType -> [NumberType]
fft [x] _ p = [x `mod` p]
fft list w p = firstHalfOfFinalResult ++ secondHalfOfFinalResult
    where (evenList, oddList) = splitEvenOdd list
          newW = (w * w) `mod` p
          evenResult = fft evenList newW p
          oddResult = fft oddList newW p

          combineResults :: [NumberType] -> [NumberType] -> NumberType -> NumberType -> NumberType -> ([NumberType], [NumberType])
          combineResults [] [] _ _ _ = ([], [])
          combineResults (x:xs) (y:ys) p w powerOfW = (((x + t) `mod` p) : resultXs, ((x - t) `mod` p) : resultYs)
              where t = (powerOfW * y) `mod` p
                    (resultXs, resultYs) = combineResults xs ys p w ((powerOfW * w) `mod` p)

          (firstHalfOfFinalResult, secondHalfOfFinalResult) =
              combineResults evenResult oddResult p w 1

-- Polynomial multiplication

multiply :: [NumberType] -> [NumberType] -> [NumberType]
multiply polynomialA polynomialB = scaledProduct
    where resultLength = length polynomialA + length polynomialB - 1
          n = nextPowerOfTwo (fromIntegral resultLength)

          extendedPolynomialA = extendWithZeroes polynomialA n
          extendedPolynomialB = extendWithZeroes polynomialB n

          correctW = getCorrectW maximumNumberOfCoefficients n primitiveRootW
          evaluationsOfA = fft extendedPolynomialA correctW usedPrime
          evaluationsOfB = fft extendedPolynomialB correctW usedPrime

          evaluationsOfProduct = zipWith (\a b -> (a * b) `mod` usedPrime) evaluationsOfA evaluationsOfB

          correctWInverse = getCorrectW maximumNumberOfCoefficients n primitiveRootWInverse
          unscaledProduct = fft evaluationsOfProduct correctWInverse usedPrime

          nInverse = moduloPower n (usedPrime - 2) usedPrime
          scaledProduct = take resultLength $ map (\x -> (x * nInverse) `mod` usedPrime) unscaledProduct
