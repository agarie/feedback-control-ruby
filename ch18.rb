require 'distribution'

require_relative './feedback'

include Distribution::Shorthand

class GameEngine < Component
  def initialize
    @n = 0 # Number of game objects
    @t = 0 # Steps since last change

    # For each level: memory per game object.
    @resolutions = [100, 200, 400, 800, 1600]
  end

  def work(u)
    @t += 1

    # 1 change every 10 steps on average.
    if @t > expo_rng.call(0.1)
      @t = 0
      @n += [-1, 1].shuffle.first
      @n = [1, [@n, 50].min].max # 1 <= n <= 50
    end

    crr = @resolutions[u] # current resolution
    crr * @n              # current memory consumption
  end

  def monitoring
    "#{@n}"
  end
end

class DeadzoneController < Component
  def initialize(deadzone)
    @deadzone = deadzone
  end

  def work(u)
    return 0 if Math.abs(u) < @deadzone

    if u < 0
      -1
    else
      1
    end
  end
end

class ConstrainingIntegrator < Component
  def initialize
    @state = 0
  end

  def work(u)
    @state += u
    @state = [0, [@state, 4].min].max # Allow 0..4
    @state
  end
end

class Logarithm < Component
  def work(u)
    if u <= 0
      0
    else
      Math.log(u)
    end
  end
end

DT = 1

setpoint = -> t { 3.5 * Math.log(10.0) }

c = DeadzoneController.new(0.5 * Math.log(8.0)) # Width of deadzone.
p = GameEngine.new

Feedback.closed_loop(setpoint, c, p,
                     actuator = ConstrainingIntegrator.new,
                     return_filter = Logarithm.new)
