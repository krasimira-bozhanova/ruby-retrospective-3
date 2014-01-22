module Asm
  def self.asm(&block)
    parser = BlockParser.new
    parser.instance_eval &block
    EvaluateAssembler.new(parser.block_array, parser.labels).get_registers
  end

  class BlockParser
    attr_reader :block_array, :labels

    ASSEMBLER_METHODS = [
      :mov,
      :inc,
      :dec,
      :cmp,
      :jmp,
      :je,
      :jne,
      :jg,
      :jge,
      :jle,
      :jl
    ]

    ASSEMBLER_METHODS.each do |method_name|
      define_method method_name do |*args|
        @block_array << [method_name, *args]
      end
    end

    def initialize
      @block_array = []
      @labels = {}
    end

    def label(label_name)
      @labels[label_name] = @block_array.size
    end

    def method_missing(method_name, *args, &block)
      method_name.to_sym
    end
  end

  class EvaluateAssembler
    attr_accessor :register_ax, :register_bx, :register_cx, :register_dx

    METHODS_JUMP = {
      je:   :==,
      jne:  :!=,
      jl:   :<,
      jle:  :<=,
      jg:   :>,
      jge:  :>=,
    }

    METHODS_MODIFY = {
      inc:  :+,
      dec:  :-,
    }

    METHODS_JUMP.each do |method_name, operation|
      define_method method_name do |where|
        @last_comparing.send operation, 0 and jmp where
      end
    end

    METHODS_MODIFY.each do |method_name, operation|
      define_method method_name do |destination_register, value=1|
        destination_value = send "register_" + destination_register.to_s
        modify_with = destination_value.send operation, get_value(value)
        send "register_" + "#{destination_register}=", modify_with
      end
    end

    def initialize(block_array, labels)
      @register_ax, @register_bx, @register_cx, @register_dx = 0, 0, 0, 0
      @commands = block_array
      @labels = labels
      @current_command, @last_comparing = 0, 0
      evaluate
    end

    def get_registers
      [@register_ax, @register_bx, @register_cx, @register_dx]
    end

    def mov(destination_register, source)
      send "register_" + "#{destination_register}=", get_value(source)
    end

    def cmp(register, value)
      @last_comparing = (send "register_" + register.to_s) <=> get_value(value)
    end

    def jmp(where)
      if where.is_a?(Numeric)
        @current_command = where - 1
      else
        @current_command = @labels[where] - 1
      end
    end

    private

    def evaluate
      while @current_command < @commands.size
        send *@commands[@current_command]
        @current_command = @current_command + 1
      end
    end

    def get_value(value)
      value.is_a?(Symbol) ? (send "register_" + value.to_s) : value
    end
  end
end