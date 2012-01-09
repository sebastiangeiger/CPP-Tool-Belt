def all_messages
  stdin = []
  while line=STDIN.gets do
    stdin << line 
  end
  Output.new(stdin)
end

def output
  all_messages.select{|line| line =~ /output>>/}
end

class Output
  def initialize(array)
    @array = array
  end
  def interpreted_as_numeric_array
    return @array.collect{|line| line.gsub(/$[\n|\r|\r\n]/, "").gsub(/output>>/,"").strip.to_i}
  end
  def select(&block)
    Output.new(@array.select &block)
  end
  def collect(&block)
    Output.new(@array.collect &block)
  end
  def filter(regexp, capture_group = 1)
    self.select{|line| line =~ regexp}.collect{|line| regexp.match(line)[capture_group]}
  end
end

class Array
  def should_equal(another_array)
    if self.eql?(another_array) then
      success
    else
      failure(self,another_array)
    end
  end
end

def success
  puts "1 Test passed"
end

def failure(array_1, array_2)
  puts "1 Test failed: #{array_1.inspect} is different from #{array_2.inspect}"
end

EMBEDDED_RUBY_LINE_START = /^\s*\/\/RUBY:/

def find_embedded_ruby(file)
  embedded_ruby = File.open(file, "r+"){|file_handle|
    file_handle.read.split(/[\r\n]/)
  }.select{|line| line =~ EMBEDDED_RUBY_LINE_START}
  raise "More than one line of embedded ruby found" if embedded_ruby.size > 1
  raise "No embedded ruby found, needs to start with \"#{EMBEDDED_RUBY_LINE_START}\"" if embedded_ruby.size <= 0
  embedded_ruby.first.gsub(EMBEDDED_RUBY_LINE_START, "").strip
end

if __FILE__ == $0
  eval(find_embedded_ruby(ARGV.first))
end
