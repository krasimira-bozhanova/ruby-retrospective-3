module Graphics
  class Canvas
    attr_reader :width, :height

    def initialize(width, height)
      @width = width
      @height = height
      @canvas = {}
    end

    def set_pixel(x, y)
      @canvas[[x,y]] = true
    end

    def pixel_at?(x, y)
      @canvas[[x,y]] == true
    end

    def draw(figure)
      figure.pixels.each { |point| set_pixel point.x, point.y }
    end

    def render_as(renderer)
      renderer.new(self).render
    end
  end

  class Figure
    def ==(other_figure)
      identify_by == other_figure.identify_by
    end

    def eql?(other_figure)
      self == other_figure
    end

    def hash
      identify_by.hash
    end
  end

  class Point < Figure
    attr_reader :x, :y

    def initialize(x, y)
      @x = x
      @y = y
    end

    def identify_by
      [x, y]
    end

    def <=>(other_point)
      return -1 if x < other_point.x or (x == other_point.x and y < other_point.y)
      return 0 if self == other_point
      1
    end

    def pixels
      [self]
    end
  end

  class Line < Figure
    attr_reader :from, :to

    def initialize(first_end, second_end)
      @from, @to = [first_end, second_end].sort
    end

    def identify_by
      [from, to]
    end

    def pixels
      BresenhamRasterization.new.rasterize self
    end

    class BresenhamRasterization
      def difference(axis)
        (@line.from.public_send(axis) - @line.to.public_send(axis)).abs
      end

      def delta
        if [difference(:x), difference(:y)].any? { |difference| difference == 0 }
          return 0
        end
        [difference(:x), difference(:y)].map(&:to_r).sort.reduce(&:/)
      end

      def point_based_on_steepness(x, y)
        difference(:y) > difference(:x) ? Point.new(y, x) : Point.new(x, y)
      end

      def rasterize(line)
        @line = line
        @from, @to = line.identify_by.map do |point|
          point_based_on_steepness(*point.identify_by)
        end.sort
        perform_rasterization(0, @from.y)
      end

      def switch_to_next_line(y, error)
        [y + (@to.y <=> @from.y), error - 1.0]
      end

      def perform_rasterization(error, y)
        @from.x.upto(@to.x).each_with_object([]) do |x, gen_pixels|
          gen_pixels << (point_based_on_steepness(x, y))
          error += delta
          if error >= 0.5
            y, error = switch_to_next_line(y, error)
          end
        end
      end
    end
  end

  class Rectangle < Figure
    attr_reader :top_left, :top_right, :bottom_left, :bottom_right, :left, :right

    def initialize(first_point, second_point)
      @left, @right = [first_point, second_point].sort
      @top_left, @bottom_left, @top_right, @bottom_right = [
        first_point, second_point,
        Point.new(first_point.x, second_point.y),
        Point.new(second_point.x, first_point.y)].sort
    end

    def identify_by
      [top_left, bottom_left, bottom_right, top_right]
    end

    def generate_lines_of_rectangle
      [
        Line.new(top_left, bottom_left),
        Line.new(bottom_left, bottom_right),
        Line.new(bottom_right, top_right),
        Line.new(top_right, top_left),
      ]
    end

    def pixels
      generate_lines_of_rectangle.map { |line| line.pixels }.flatten
    end
  end

  module Renderers
    class Base
      attr_reader :canvas

      def initialize(canvas)
        @canvas = canvas
      end

      def render
        raise NotImplementedError
      end
    end

    class Ascii < Base
      def render
        pixels = 0.upto(canvas.height.pred).map do |y|
          0.upto(canvas.width.pred).map { |x| pixel_at(x, y) }
        end

        join_lines pixels.map { |line| line.join('') }
      end

      private

      def pixel_at(x, y)
        canvas.pixel_at?(x, y) ? full_pixel : blank_pixel
      end

      def full_pixel
        '@'
      end

      def blank_pixel
        '-'
      end

      def join_lines(lines)
        lines.join("\n")
      end
    end

    class Html < Ascii
      TEMPLATE = '<!DOCTYPE html>
        <html>
        <head>
          <title>Rendered Canvas</title>
          <style type="text/css">
            .canvas {
              font-size: 1px;
              line-height: 1px;
            }
            .canvas * {
              display: inline-block;
              width: 10px;
              height: 10px;
              border-radius: 5px;
            }
            .canvas i {
              background-color: #eee;
            }
            .canvas b {
              background-color: #333;
            }
          </style>
        </head>
        <body>
          <div class="canvas">
            %s
          </div>
        </body>
        </html>
      '.freeze

      def render
        TEMPLATE % super
      end

      private

      def full_pixel
        '<b></b>'
      end

      def blank_pixel
        '<i></i>'
      end

      def join_lines(lines)
        lines.join('<br>')
      end
    end
  end
end