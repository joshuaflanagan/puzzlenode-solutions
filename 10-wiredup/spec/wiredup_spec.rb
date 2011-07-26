require './wiredup.rb'
require 'ostruct'

describe Circuit do
  before :each do
    @circuit = Circuit.new
  end

  it "should be incomplete if it has no bulb" do
    @circuit.state.should == "incomplete"
  end

  describe "when parsing a line" do
    it "should return Nil if no content found" do
      @circuit.parse_line("  ").should be_nil
    end

    it "should return itself if content found" do
      @circuit.parse_line("0----|").should == @circuit
    end

    describe "containing wire connected to off switch and open-ended" do
      before :each do
        @circuit.parse_line "0----|"
      end

      it "should find a wire" do
        @circuit.should have(1).wires
      end

      it "should detect the switch" do
        wire = @circuit.wires.values[0]
        wire.input.should be_a Switch
      end

      it "should be an off switch" do
        wire = @circuit.wires.values[0]
        wire.input.value.should be_false
      end

      it "should not have an output" do
        wire = @circuit.wires.values[0]
        wire.output.should be_nil
      end
    end

    describe "containing wire connected to an on switch and open-ended" do
      before :each do
        @circuit.parse_line "   1--------|   "
        @wire = @circuit.wires.values[0]
      end

      it "should detect the switch" do
        @wire.input.should be_a Switch
      end

      it "should be an on switch" do
        @wire.input.value.should be_true
      end

      it "should not have an output" do
        @wire.output.should be_nil
      end
    end

    describe "containing wire connected to a gate and a bulb" do
      before :each do
        @circuit.parse_line " A-----@   "
        @wire = @circuit.wires.values[0]
      end

      it "should have a bulb output" do
        @wire.output.should be_a Bulb
      end

      it "should set the wire as the bulb input" do
        @circuit.bulb.input.should equal(@wire)
      end
    end

    describe "containing wire connected to an OR gate" do
      before :each do
        @circuit.parse_line "  O---| "
        @wire = @circuit.wires.values[0]
      end

      it "should detect the OR gate" do
        @wire.input.should be_a OrGate
      end
    end

    describe "containing wire connected to an AND gate" do
      before :each do
        @circuit.parse_line "A---| "
        @wire = @circuit.wires.values[0]
      end

      it "should detect the AND gate" do
        @wire.input.should be_a AndGate
      end
    end

    describe "containing wire connected to an XOR gate" do
      before :each do
        @circuit.parse_line " X------------| "
        @wire = @circuit.wires.values[0]
      end

      it "should detect the XOR gate" do
        @wire.input.should be_a XorGate
      end
    end
    
    describe "containing wire connected to a NOT gate" do
      before :each do
        @circuit.parse_line "     N---------| "
        @wire = @circuit.wires.values[0]
      end

      it "should detect the NOT gate" do
        @wire.input.should be_a NotGate
      end
    end
  end

  describe "when a wire spans multiple lines" do
    before :each do
      @circuit.parse_line " 1----|  "
      @circuit.parse_line "      |  "
      @circuit.parse_line "      A-@"
      @wire = @circuit.wires.values[0]
    end

    it "should identify the input" do
      @wire.input.should be_a Switch
    end
    
    it "should identify the output" do
      @wire.output.should be_a AndGate
    end
  end

  describe "when a gate has two input wires" do
    before :each do
      @circuit.parse_line " 1----|  "
      @circuit.parse_line "      |  "
      @circuit.parse_line "      O-@"
      @circuit.parse_line "      |  "
      @circuit.parse_line "      |  "
      @circuit.parse_line " 0----|  "
      @top_wire = @circuit.wires["0-1"]
      @bottom_wire = @circuit.wires["5-1"]
    end

    it "should set the output on both wires" do
      @top_wire.output.should be_a OrGate
      @bottom_wire.output.should be_a OrGate
    end
  end

  describe "when a not gate connects two wires" do
    before :each do
      @circuit.parse_line " 1----|  "
      @circuit.parse_line "      |  "
      @circuit.parse_line "      N-@"
      @in_wire = @circuit.wires["0-1"]
      @out_wire = @circuit.wires["2-6"]
    end

    it "should set the output of the first to a NotGate" do
      @in_wire.output.should be_a NotGate
    end

    it "should set the input of the second to a NotGate" do
      @in_wire.output.should be_a NotGate
    end

    it "should set the ouput of first wire to the input of the second" do
      @out_wire.input.should equal(@in_wire.output)
    end
  end
end

describe Bulb do
  before :each do
    @bulb = Bulb.new
    @bulb.input = OpenStruct.new :value => false
  end

  it "should be lit if it's input is on" do
    @bulb.input.value = true
    @bulb.should be_lit
  end

  it "should not be lit if it's input is off" do
    @bulb.input.value = false
    @bulb.should_not be_lit
  end
end

describe Wire do
  before :each do
    @wire = Wire.new 2, 3, 7
    @wire.input = OpenStruct.new :value => false
  end

  it "should be named after its location" do
    @wire.name.should == "2-3"
  end

  it "should be false if its input is false" do
    @wire.value.should be_false
  end

  it "should be true if its input is true" do
    @wire.input.value = true
    @wire.value.should be_true
  end

  it "should describe its location with to_s" do
    @wire.to_s.should == "Wire[2 3-7]"
  end
end

describe AndGate do
  [ [false, false, false],
    [false, true, false],
    [true, false, false],
    [true, true, true] ].each do |run|

    it "should be #{run[2]} if input1=#{run[0]} and input2=#{run[1]}" do
      gate = AndGate.new
      gate.input1 = OpenStruct.new :value => run[0]
      gate.input2 = OpenStruct.new :value => run[1]
      gate.value.should == run[2]
    end
  end
end

describe OrGate do
  [ [false, false, false],
    [false, true, true],
    [true, false, true],
    [true, true, true] ].each do |run|

    it "should be #{run[2]} if input1=#{run[0]} and input2=#{run[1]}" do
      gate = OrGate.new
      gate.input1 = OpenStruct.new :value => run[0]
      gate.input2 = OpenStruct.new :value => run[1]
      gate.value.should == run[2]
    end
  end
end

describe XorGate do
  [ [false, false, false],
    [false, true, true],
    [true, false, true],
    [true, true, false] ].each do |run|

    it "should be #{run[2]} if input1=#{run[0]} and input2=#{run[1]}" do
      gate = XorGate.new
      gate.input1 = OpenStruct.new :value => run[0]
      gate.input2 = OpenStruct.new :value => run[1]
      gate.value.should == run[2]
    end
  end
end

describe NotGate do
  it "should be true if the input is false" do
    gate = NotGate.new
    gate.input = OpenStruct.new :value => false
    gate.value.should be_true
  end

  it "should be false if the input is true" do
    gate = NotGate.new
    gate.input = OpenStruct.new :value => true
    gate.value.should be_false
  end
end
