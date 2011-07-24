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

    describe "containing wire conntected to a gate and a bulb" do
      before :each do
        @circuit.parse_line " A-----@   "
        @wire = @circuit.wires.values[0]
      end

      it "should have a bulb output" do
        @wire.output.should be_a Bulb
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
end

