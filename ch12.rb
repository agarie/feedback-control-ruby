class Component
  def work(u)
    return u
  end

  def monitoring
    ""
  end
end

class PIDController < Component
  attr_accessor :kp, :ki, :kd, :i, :d, :prev

  def initialize(kp, ki, kd = 0)
    @kp, @ki, @kd = kp, ki, kd

    @i = 0
    @d = 0
    @prev = 0
  end

  def work(e)
    @i += DT * e
    @d = (e - @prev) / DT
    @prev = e

    @kp * e + @ki * @i + @kd * @d
  end
end

class AdvancedController < Component
  attr_accessor :kp, :ki, :kd, :i, :d, :prev
  attr_accessor :unclamped, :clamp_lo, :clamp_hi, :alpha

  def initialize(kp, ki, kd = 0, clamp = [-1e10, 1e10], smooth = 1)
    @kp, @ki, @kd = kp, ki, kd
    @i = 0
    @d = 0
    @prev = 0

    @unclamped = true
    @clamp_lo, @clamp_hi = clamp

    @alpha = alpha
  end

  def work(e)
    if @unclamped
      @i += DT * e
    end

    @d = @alpha * (e - @prev) / DT + (1.0 - @alpha) * @d

    u = @kp * e + @ki * @i + @kd * @d

    @unclamped = u > @clamp_lo && u < @clamp_hi
    @prev = e

    u
  end
end

class Identity < Component
  def work(x)
    x
  end
end

class Integrator < Component
  def initialize
    @data = 0
  end

  def work(u)
    @data += u

    DT * @data
  end
end

class FixedFilter < Component
  def initialize(n)
    @n = n
    @data = []
  end

  def work(x)
    @data << x

    if @data.size > @n
      @data = @data.drop(1)
    end

    @data.reduce(:+).to_f / @data.size
  end
end

class RecursiveFilter < Component
  def initialize(alpha)
    @alpha = alpha
    @y = 0
  end

  def work(x)
    @y = @alpha * x + (1.0 - @alpha) * @y
    @y
  end
end

def closed_loop(setpoint, controller, plant, tm = 5000, inverted = false,
                actuator = Identity.new, return_filter = Identity.new)
  z = 0
  tm.times do |t|
    r = setpoint(t)
    e = r - z

    e = -e if inverted

    u = controller.work(e)
    v = actuator.work(u)
    y = plant.work(v)
    z = return_filter.work(y)

    puts "#{t},#{DT * t},#{r},#{e},#{u},#{v},#{y},#{z},#{plant.monitoring}"
  end
end
