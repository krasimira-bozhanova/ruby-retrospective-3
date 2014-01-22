module Graphics
  class Canvas
    attr_reader :width, :height

    def initialize(width, height)
      @width = width
      @height = height
      @canvas = Array.new(height) { Array.new(width) {0} }
    end

    def set_pixel(x, y)
      @canvas[y][x] = 1
    end

    def pixel_at?(x, y)
      not @canvas[y][x].zero?
    end

    def draw(figure)
      figure.pixels.each { |point| set_pixel point.x, point.y }
    end

    def render_as(renderer)
      renderer_string = renderer::RENDER_TABLE[:start]
      renderer_string += @canvas.map do |line|
        line.map { |symbol| renderer::RENDER_TABLE[symbol] }.join
      end.join(renderer::RENDER_TABLE[:line_separator])
      renderer_string += renderer::RENDER_TABLE[:end]
    end
  end

  class GeometryFigure
    def ==(other_figure)
      sufficient == other_figure.sufficient
    end

    def eql?(other_figure)
      self == other_figure
    end

    def hash
      sufficient.hash
    end
  end

  class Point < GeometryFigure
    attr_reader :x, :y

    def initialize(x, y)
      @x = x
      @y = y
    end

    def sufficient
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

  class Line < GeometryFigure
    attr_reader :from, :to

    def initialize(first_end, second_end)
      @from, @to = *[first_end, second_end].sort
    end

    def sufficient
      [from, to]
    end

    def difference(axis)
      (@from.public_send(axis) - @to.public_send(axis)).abs
    end

    def delta
      [difference(:x), difference(:y)].map(&:to_r).sort.reduce(&:/)
    end

    def point_based_on_steep(x, y)
      difference(:y) > difference(:x) ? Point.new(y, x) : Point.new(x, y)
    end

    def bresenham_generation(from, to, error, y)
      from.x.upto(to.x).each_with_object([]) do |x, gen_pixels|
        gen_pixels << (point_based_on_steep(x, y))
        error += delta
        if error >= 0.5
          y += to.y <=> from.y
          error -= 1.0
        end
      end
    end

    def pixels
      from, to = sufficient.map { |point| point_based_on_steep(*point.sufficient) }.sort
      bresenham_generation(from, to, 0, from.y)
    end
  end

  class Rectangle < GeometryFigure
    attr_reader :top_left, :top_right, :bottom_left, :bottom_right, :left, :right

    def initialize(first_point, second_point)
      @left, @right = [first_point, second_point].sort
      @top_left, @bottom_left, @top_right, @bottom_right = *[first_point, second_point,
                      Point.new(first_point.x, second_point.y),
                      Point.new(second_point.x, first_point.y)].sort
    end

    def sufficient
      [top_left, bottom_left, bottom_right, top_right]
    end

    def pixels
      (sufficient << top_left).each_cons(2).each_with_object([]) do |points, gen_pixels|
        gen_pixels.concat Line.new(*points).pixels
      end
    end
  end

  module Renderers
    module Ascii
      RENDER_TABLE = { 0 => '-', 1 => '@', :start => "",
        :end => "", :line_separator => "\n" }
    end

    module Html
      RENDER_TABLE = { 0 => '<i></i>', 1 => '<b></b>',
        :start => <<START_HTML, :end => <<END_HTML, :line_separator => "<br>" }
<!DOCTYPE html>
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
START_HTML
  </div>
</body>
</html>
END_HTML
    end
  end
end