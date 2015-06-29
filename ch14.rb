require 'distribution'

require_relative './feedback'

include Distribution::Shorthand

class AdPublisher < Component

  def initialize(scale, min_price, relative_width: 0.1)
    @scale = scale.to_f
    @min = min_price.to_f
    @width = relative_width.to_f
  end

  def work(u)
    return 0 if u <= @min

    # `demand` is the number of impressions served per day. The demand is
    # modeled (!) as a Gaussian distribution with a mean that depends
    # logarithmically on the price `u`.
    mean = @scale * Math.log(u / @min)
    demand = norm_rng(mean: mean, stddev: @width * mean).to_i

    # Impression demand is greater than zero.
    [0, demand].max
  end

  def self.closed_loop(kp, ki, f: Identity.new)
    setpoint = -> t { t > 1000 ? 125 : 100 }

    k = 1.0 / 20.0

    p = AdPublisher.new(100, 2)
    c = PIDController.new(k * kp, k * ki)

    Feedback.closed_loop(setpoint, c, p, return_filter = f)
  end
end
