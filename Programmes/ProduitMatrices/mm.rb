def multiply_matrices( a, b, c, n )
  for i in 0...n
    for j in 0...n
      c[i][j] = 0.0
      for k in 0...n
        c[i][j] += a[i][k] * b[k][j]
      end
    end
  end
end


a = [ [10, 20],
      [30, 40] ]

b = [ [1, 2],
      [3, 4]]

c = Array.new(2) { Array.new(2) }

p c

multiply_matrices( a, b, c, 2 )

p c


