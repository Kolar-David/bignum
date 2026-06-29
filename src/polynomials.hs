-- Constants

primitiveRootW = 125
numberOfCoefficients = 2^30
usedPrime = 3*(2^30) + 1

-- Auxillary functions

moduloPower :: Int -> Int -> Int -> Int
moduloPower _ 0 _ = 1
moduloPower base exponent modulo
    | odd exponent = (val * val * base) `mod` modulo
    | otherwise = (val * val) `mod` modulo
    where val = moduloPower base (exponent `div` 2) modulo


nextPowerOfTwo :: Int -> Int
nextPowerOfTwo n = nextPowerHelper 1 n
    where nextPowerHelper x n
              | x >= n = x
              | otherwise = nextPowerHelper (2*x) n


extendWithZeroes :: [Int] -> Int -> [Int]
extendWithZeroes list n = list ++ (replicate (n - (length list)) 0)

splitEvenOdd :: [Int] -> ([Int], [Int])
splitEvenOdd [] = ([], [])
splitEvenOdd [x] = ([x], [])
splitEvenOdd (x:y:xs) = ((x:evenXs), (y:oddXs))
    where (evenXs, oddXs) = splitEvenOdd xs

-- FFT

-- The length of the list must be a power of 2 and w must correspond to it!
fft :: [Int] -> Int -> Int -> [Int]
fft [x] _ _ = [x]
fft list w p = firstHalfOfFinalResult ++ secondHalfOfFinalResult
    where (evenList, oddList) = splitEvenOdd list
          newW = w * w
          evenResult = fft evenList newW p
          oddResult = fft oddList newW p
          combineResults :: [Int] -> [Int] -> Int -> Int -> ([Int], [Int])
          combineResults [] [] _ _ = ([], [])
          combineResults (x:xs) (y:ys) w powerOfW = ((x + (powerOfW*y)) : resultXs, (x - (powerOfW*y)) : resultYs)
              where (resultXs, resultYs) = combineResults xs ys w (powerOfW*w)
          (firstHalfOfFinalResult, secondHalfOfFinalResult) = combineResults evenResult oddResult w 1

-- fft list = fftHelper list primitiveRootW usedPrime 
