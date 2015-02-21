class PIDController
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
