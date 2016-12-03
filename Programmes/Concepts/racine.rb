
# (2x - 4) * (6x + 6)
# 12x^2 -12 x - 24

a = 12
b = -12
c = -24

t0 = -1 * b
t1 = b * b
t2 = 4 * a
t3 = t2 * c
t4 = t1 - t3
t5 = Math.sqrt t4
t6 = t0 + t5
t7 = 2 * a
r1 = t6 / t7

puts "OK" if r1 == 2.0

