r = ARGV[0].to_f
k = ARGV[1].to_f

u = 0
200.times do |t|
  y = u

  e = r - y
  u = k * e

  puts "#{r},#{e},0,#{u},#{y}"
end
