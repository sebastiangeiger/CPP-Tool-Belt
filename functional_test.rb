def output
  stdin = []
  while line=STDIN.gets do
    stdin << line if line =~ /output>>/
  end
  Output.new(stdin)
end

class Output
  def initialize(array)
    @array = array
  end
  def interpreted_as_numeric_array
    return @array.collect{|line| line.gsub(/$[\n|\r|\r\n]/, "").gsub(/output>>/,"").strip.to_i}
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
    file_handle.read.split(/[\n|\r|\r\n]/)
  }.select{|line| line =~ EMBEDDED_RUBY_LINE_START}
  raise "More than one line of embedded ruby found" if embedded_ruby.size > 1
  raise "No embedded ruby found, needs to start with \"#{EMBEDDED_RUBY_LINE_START}\"" if embedded_ruby.size <= 0
  embedded_ruby.first.gsub(EMBEDDED_RUBY_LINE_START, "").strip
end

eval(find_embedded_ruby(ARGV.first))
