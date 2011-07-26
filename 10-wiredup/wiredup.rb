class Circuit
  attr_reader :bulb, :wires, :open_ends

  def initialize
    @wires = {}
    @open_ends = {}
    @line_num = 0
  end

  def parse_line(line)
    return nil if line.strip.empty?

    next_start = 0
    continuing_wires = []
    # find new wire segments
    while match = /[01OAXN]-+[|@]/.match(line, next_start)
      segment = match[0]
      start_col = match.begin(0)
      last_col = match.end(0) - 1

      wire = Wire.new @line_num, start_col, last_col 
      wire.input = case segment[0]
                     when '0' then Switch.new(false)
                     when '1' then Switch.new(true) 
                     when 'A' 
                       gate = AndGate.new
                       input_wire = @open_ends.delete start_col
                       if input_wire
                         input_wire.output = gate
                         gate.input1 = input_wire
                       end
                       @open_ends[start_col] = gate
                       continuing_wires.push start_col
                       gate
                     when 'O'
                       gate = OrGate.new
                       input_wire = @open_ends.delete start_col
                       if input_wire
                         input_wire.output = gate
                         gate.input1 = input_wire
                       end
                       @open_ends[start_col] = gate
                       continuing_wires.push start_col
                       gate
                     when 'N' 
                       gate = NotGate.new
                       input_wire = @open_ends.delete start_col
                       if input_wire
                         input_wire.output = gate
                         gate.input = input_wire
                       end
                       gate
                     when 'X'
                       gate = XorGate.new
                       input_wire = @open_ends.delete start_col
                       if input_wire
                         input_wire.output = gate
                         gate.input1 = input_wire
                       end
                       @open_ends[start_col] = gate
                       continuing_wires.push start_col
                       gate
                   end
      case segment[-1]
        when '@'
          @bulb = Bulb.new
          @bulb.input = wire
          wire.output = @bulb
        when '|'
          gate = @open_ends.delete last_col
          if gate
            wire.output = gate
            gate.input2 = wire
          else
            @open_ends[last_col] = wire
            continuing_wires.push last_col
          end
      end
      @wires[wire.name] = wire
      next_start = last_col + 1
    end
    # continue existing line segments
    line.to_enum(:scan, /\s(\|)/).map{ Regexp.last_match }.each do |match|
      wire_end = match.begin(1)
      puts "dangling wire at #{wire_end}" unless @open_ends.has_key? wire_end
      continuing_wires.push wire_end
    end
    @open_ends.keep_if {|col,wire| continuing_wires.include? col}

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

  def to_s
    "#{self.class}[#{@row} #{@first_col}-#{@last_col}]"
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
    @input1.value && @input2.value
  end
end

class XorGate
  attr_accessor :input1, :input2

  def value
    @input1.value ^ @input2.value
  end
end

class OrGate
  attr_accessor :input1, :input2

  def value
    @input1.value || @input2.value
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
  circuit_file = 'broken_circuit.txt'

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
