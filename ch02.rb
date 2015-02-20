r = 0.60         # Setpoint.
k = ARGV[0].to_f # Gain factor: 50..175

puts "t = #{r}\tk = #{k}"
puts "#{r},0,0,0,0"

def cache(size)
  case size
  when size < 0
    0.0
  when size > 100
    1.0
  else
    size / 100.0
  end
end

y, c = 0, 0
200.times do |_|
  e = r - y    # Tracking error.
  c += e       # Cumulative error.
  u = k * c    # Control action: cache size.
  y = cache(u) # Process output: hit rate.

  puts "#{r},#{e},#{c},#{u},#{y}"
end
