class Component
  def work(u)
    u
  end

  def monitoring
    ""
  end
end

class Plant < Component
  def work(u)
    u
  end
end

class PidController < Component
  attr_accessor :kp, :ki, :kd
  attr_accessor :i, :d, :prev

  def initialize(kp, ki, kd = 0)
    self.kp = kp
    self.ki = ki
    self.kd = kd

    self.i = 0
    self.d = 0
    self.prev = 0
  end

  def work(e)
    self.i += DT * e
    self.d = (e - self.prev) / DT
    self.prev = e

    self.kp * e + self.ki * self.i + self.kd + self.d
  end
end


