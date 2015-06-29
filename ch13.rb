require 'distribution'

require_relative './feedback'

# Use shorthand methods.
include Distribution::Shorthand

class Cache < Component
  attr_accessor :t, :size, :cache, :demand

  def initialize(size, demand)
    # Internal time counter. Needed for last access time.
    @t = 0

    #
    @size = size

    #
    @cache = {}

    #
    @demand = demand
  end

  def work(u)
    @t += 1

    @size = [0, u.to_i].max

    i = @demand.call(@t)

    if @cache.key? i
      @cache[i] = @t
      return 1
    end

    if @cache.size >= @size
      # number of elements to delete
      m = 1 + @cache.size - @size

      tmp = {}
      @cache.keys.each do |k|
        tmp[@cache[k]] = k
      end

      tmp.keys.sort.each do |j|
        @cache.delete tmp[j]
        m -= 1
        break if m == 0
      end
    end

    @cache[i] = @t
    0
  end
end

class SmoothedCache < Cache
  def initialize(size, demand, avg)
    super(size, demand)
    @f = FixedFilter.new(avg)
  end

  def work(u)
    y = super(u)
    @f.work(y)
  end
end

def demand(t)
  norm_rng(mean = 0, stddev = 15).call.to_i
end

def setpoint(t)
  0.7
end

def demand2(t)
  case t
  when t < 3000
    norm_rng(mean: 0, stddev: 15).call.to_i
  when t < 5000
    norm_rng(mean:0, stddev: 35).call.to_i
  else
    norm_rng(mean: 100, stddev: 15).call.to_i
  end
end

# the actual plant stuff.
DT = 1

plant = SmoothedCache.new(0, method(:demand), 100)
controller = PIDController.new(100, 250)

closed_loop(method(:setpoint), controller, plant, 10000)
