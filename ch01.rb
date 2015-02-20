module ControlTheory
  class Buffer
    attr_accessor :queued, :wip

    def initialize(max_wip, max_flow)
      @queued = 0
      @wip = 0 # Work-in-progress or "ready pool".

      @max_wip = max_wip
      @max_flow = max_flow
    end

    def work(u)
      # Add to ready pool.
      u = [0, u.round].max
      u = [u, @max_wip].min
      @wip += u

      # Transfer from ready pool to queue.
      r = Random.rand(0..@wip)
      @wip -= r
      @queued += r

      # Release from queue to downstream process.
      r = Random.rand(0..@max_flow)
      r = [r, @queued].min
      @queued -= r

      @queued
    end
  end

  class Controller
    attr_accessor :i, :kp, :ki

    def initialize(kp, ki)
      @kp = kp
      @ki = ki
      @i = 0
    end

    def work(e)
      @i += e
      @kp * e + @ki * @i
    end
  end

  def self.open_loop(p, tm = 5000)
    target = Proc.new { |t| 5.0 }

    (1..tm).each do |t|
      u = target.call(t)
      y = p.work(u)

      puts "#{t},#{u},0,#{u},#{y}"
    end
  end

  def self.closed_loop(c, p, tm=5000)
    setpoint = Proc.new do |t|
      case t
      when t < 100
        0
      when t >= 100 && t < 300
        50
      else
        10
      end
    end

    y = 0
    (1..tm).each do |t|
      r = setpoint.call(t)
      e = r - y
      u = c.work(e)
      y = p.work(u)

      puts "#{t},#{r},#{e},#{u},#{y}"
    end
  end
end

c = ControlTheory::Controller.new(1.25, 0.01)
p = ControlTheory::Buffer.new(10, 3)

puts "OPEN LOOP"
ControlTheory.open_loop(p, 1000)

puts "CLOSED LOOP"
ControlTheory.closed_loop(c, p, 1000)
