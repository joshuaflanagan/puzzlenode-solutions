class Circuit
  attr_accessor :bulb
  attr_reader :wires, :open_ends

  def initialize
    @wires = {}
    @open_ends = []
    @line_num = 0
  end

  def parse_line(line)
    return nil if line.strip.empty?

    next_start = 0
    while match = /[01OAXN]-+[|@]/.match(line, next_start)
      segment = match[0]
      next_start = match.end(0)
      wire = Wire.new @line_num, match.begin(0), match.end(0)
      wire.input = case segment[0]
                     when '0' then Switch.new(false)
                     when '1' then Switch.new(true) 
                     when 'A' then AndGate.new
                     when 'O' then OrGate.new
                     when 'N' then NotGate.new
                     when 'X' then XorGate.new
                   end
      wire.output = case segment[-1]
                    when '@' then Bulb.new
                    end
      @wires[wire.name] = wire
    end
    @line_num += 1
    self
  end

  def state
    return "incomplete" unless @bulb
    return "on" if @bulb.lit?
    return "off"
  end
end

class Wire
  attr_accessor :input, :output

  def initialize(row, first_col, last_col)
    @row = row
    @first_col = first_col
    @last_col = last_col
  end

  def name
    "#{@row}-#{@first_col}"
  end

  def value
    input.value
  end
end

class NotGate
  attr_accessor :input

  def value
    !input.value
  end
end

class AndGate
  attr_accessor :input1, :input2

  def value
  end
end

class XorGate
  attr_accessor :input1, :input2

  def value
  end
end

class OrGate
  attr_accessor :input1, :input2

  def value
  end
end

class Bulb
  attr_accessor :input

  def lit?
    @input.value
  end
end

class Switch
  attr_accessor :value
  def initialize(is_on)
    @value = is_on
  end
end


if $0 == __FILE__
  circuit_file = 'simple_circuits.txt'

  circuit = Circuit.new
  circuits = [circuit]

  File.new(circuit_file).each_line do |line|
    unless circuit.parse_line line
      circuit = Circuit.new
      circuits.push circuit
    end
  end

  circuits.each do |circuit|
    puts "#{circuit.state} - #{circuit.wires.size}"
  end
end
