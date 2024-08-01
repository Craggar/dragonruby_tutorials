class Dice
  def self.roll(count)
    total = 0
    count.times do
      total += (min_value..max_value).to_a.sample
    end
    total
  end

  def self.min_value
    1
  end

  def self.max_value
    6
  end
end
