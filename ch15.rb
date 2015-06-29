require 'distribution'

require_relative './feedback'

include Distribution::Shorthand

class AbstractServerPool < Component

  def initialize(n, server, incoming_load)
    @n = n
    @queue = 0

    @server = server
    @incoming_load = incoming_load
  end

  def work(u)
    @n = [0, u.to_i]

    completed = 0
    @n.times do |_|
      completed += @server.call
      completed = @queue if completed >= @queue
    end
    @queue -= completed

    completed
  end

  def monitoring
    "#{@n} #{@queue}"
  end
end

class ServerPool < AbstractServerPool

  def work(u)
    incoming_load = @incoming_load.to_f # Additions to the queue.
    @queue = incoming_load

    return 1 if load == 0 # No work: 100% percent completion rate

    completed = super.to_f

    completed / incoming_load # completion rate
  end
end

load_queue = -> { norm_rng(mean: 1000, stddev: 5) }
consume_queue = -> { 100 * beta_rng(a: 20, b: 2) }

class SpecialController < Component
  def initialize(period1, period2)
    @period1 = period1
    @period2 = period2
    @t = 0
  end

  def work(u)
    if u > 0
      @t = @period1
      return 1
    end

    @t -= 1 # At this point: u <= 0 guaranteed!

    if @t == 0
      @t = @period2
      return -1
    end

    0
  end
end

setpoint = -> t { 1.0 }

DT = 1

p = ServerPool(0, consume_queue, load_queue)
c = SpecialController(100, 10)
Feedback.closed_loop(setpoint, c, p, actuator = Integrator.new)
