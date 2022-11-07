module {
  
  // The weighted arithmetic mean: https://en.wikipedia.org/wiki/Weighted_arithmetic_mean
  public type WeightedMean<T> = {
    dividend: T; // Sum of elements multipled by their respective weight
    divisor: Float; // Sum of weights
  };

  public func emptyMean<T>(init: () -> T) : WeightedMean<T> {
    {
      dividend = init();
      divisor = 0;
    };
  };

  public func addToMean<T>(weighted_mean: WeightedMean<T>, add: (T, T) -> T, mul: (T, Float) -> T, elem: T, weight: Float) : WeightedMean<T> {
    {
      dividend = add(weighted_mean.dividend, mul(elem, weight));
      divisor = weighted_mean.divisor + weight;
    };
  };
  
}