$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'
require 'matrice'

class Mandelbrot

  MAX_COULEUR = 255 # 2**8-1

  BORNE = 2.0

  class << self
    def distance( x, y )
      Math.sqrt( x * x + y * y )
    end

    def nb_iterations( x, y, max_iterations )
      xk, yk = x, y
      nb_iterations = 0
      while distance(xk, yk) < BORNE && nb_iterations < max_iterations
        xkp1 = xk * xk - yk * yk + x
        ykp1 = 2 * xk * yk + y

        xk = xkp1
        yk = ykp1
        nb_iterations += 1
      end

      nb_iterations
    end

    def intensite( x, y, max_iterations )
      k = nb_iterations( x, y, max_iterations )
      k * MAX_COULEUR / max_iterations
    end

    def generer( taille, nb_points, max_iterations,
                 x_min = -2.0, x_max =  1.0,
                 y_min = -1.5, y_max =  1.5 )

      delta_x = (x_max - x_min) / taille
      delta_y = (y_max - y_min) / taille


      mandelbrot = Matrice.new( nb_points, nb_points, nil, true )

      (0...nb_points).peach( static: 5 ) do |i|
        (0...nb_points).each do |j|
          x = x_min + j * delta_x
          y = y_min + i * delta_y

          mandelbrot[j,i] = intensite( x, y, max_iterations )
        end
      end

      mandelbrot
    end

  end
end
