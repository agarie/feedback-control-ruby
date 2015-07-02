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

class QueueingServerPool < AbstractServerPool
  def work(u)
    incoming_load = @incoming_load
    @queue += incoming_load

    completed = super

    incoming_load - completed
  end
end

class InnerLoop < Component
  def initialize(kp, ki, loader)
    k = 0.01

    @c = PIDController.new(kp * k, ki * k)
    @p = QueueingServerPool.new(0, consume_queue, loader)

    @y = 0
  end

  def work(u)
    e = u - @y # u is setpoint from outer loop
    e = -e     # inverted dynamics
    v = @c.work(e)
    @y = @p.work(v) # y is net change
    @p.queue
  end

  def monitoring
    "#{@p.monitoring} #{@y}"
  end
end

$global_time = 0
load_queue = -> {
  $global_time += 1

 case $global_time
 when $global_time > 2500
   norm_rng(mean: 1200, stddev: 5)
 when $global_time > 2200
   norm_rng(mean: 800, stddev: 5)
 else
   norm_rng(mean: 1000, stddev: 5)
 end
}

setpoint = -> t {
  case t
  when t < 2000
    100
  when t < 3000
    125
  else
    25
  end
}

DT = 1

p = InnerLoop(0.5, 0.25, load_queue) # "plant" for outer loop
c = AdvancedController.new(0.35, 0.0025, 4.5, smooth = 0.15)

Feedback.closed_loop(setpoint, c, p, actuator = RecursiveFilter.new(0.5))
