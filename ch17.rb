require 'distribution'

require_relative './feedback'

include Distribution::Shorthand

class CPUWithCooler < Component
  attr_accessor :temp

  def initialize(jumps: false, drift: false)
    @ambient = 20 # temperature in degrees Celsius
    @temp = @ambient # initial temperature

    @wattage = 75 # CPU heat output: J/sec
    @specific_heat = 1.0 / 50.0 # specific heat: degree/J

    @loss_factor = 1.0 / 120.0 # per second

    @load_wattage_factor = 10 # additional watts due to load
    @load_change_seconds = 50 # average seconds between changes
    @current_load = 0

    @ambient_drift = 1.0 / 3600 # degrees per second

    @jumps = jumps # jumps in CPU load?
    @drift = drift # drift in ambient temperature?
  end

  def work(u)
    u = [0, [u, 10].min].max # actuator saturation

    ambient_drift!
    load_changes!

    diff = @temp - @ambient # temperature difference
    loss = @loss_factor * (1 + u) # natural heat loss + fan

    flow = @wattage + @current_load # CPU heat flow

    @temp += DT * (@specific_heat * flow - loss * diff)
    @temp
  end

  def load_changes!
    return nil unless @jumps
    s = @load_change_seconds
    if Random.rand((2 * s / DT).to_i) == 0
      r = Random.rand(5)
      @current_load = @load_wattage_factor * r
    end
  end

  def ambient_drift!
    return nil unless @drift

    d = @ambient_drift
    @ambient += DT * norm_rng(mean: 0, stddev: d)
    @ambient = [0, [@ambient, 40].min].max
  end

  def monitoring
    "#{@current_load}"
  end
end

class Limiter < Component
  def initialize(lo, hi)
    @lo = lo
    @hi = hi
  end

  def work(x)
    [@lo, [x, @hi].min].max
  end
end

DT = 0.01

setpoint = -> t { t < 40000 ? 50 : 45 }

p = CPUWithCooler.new(jumps: true, drift: true)
p.temp = 50
c = AdvancedController.new(2, 0.5, 0, clamp = [0, 10])

Feedback.closed_loop(setpoint, c, p, 100000, inverted = true,
                    actuator = Limiter.new(0, 10))
