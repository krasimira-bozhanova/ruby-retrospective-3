class Integer
  def prime?
    return false if self < 2
    2.upto(pred).all? { |divisor| remainder(divisor).nonzero? }
  end

  def prime_factors
    return [] if abs < 2
    divisor = 2.upto(abs).find { |divisor| remainder(divisor).zero? }
    [divisor] + (abs / divisor).prime_factors
  end

  def harmonic
    1.upto(self).map { |number| Rational(1, number) }.reduce(:+)
  end

  def digits
    abs.to_s.chars.map(&:to_i)
  end
end

class Array
  def frequencies
    frequencies = Hash.new(0)
    each { |element| frequencies[element] += 1 }
    frequencies
  end

  def average
   reduce(:+) / size.to_f unless empty?
  end

  def drop_every(n)
    values_at(*each_index.reject { |index| (index + 1).remainder(n).zero? })
  end

  def combine_with(other)
    smaller_size = [size, other.size].min
    remainder = drop(smaller_size) + other.drop(smaller_size)
    zip(other).flatten.take(2 * smaller_size) + remainder
  end
end