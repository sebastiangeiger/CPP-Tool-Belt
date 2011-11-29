class MakefileTarget
  attr_reader :errors

  def initialize(name)
    @name = name
    @errors = []
    @state = :initial
    @additional_parameters = []
  end

  def make
    ensure_in_state(:initial) do
      FileUtils.mkdir("bin") unless File.exists?("bin")
      puts "Compiling #{@name}"
      result = `make #{@name} 2>&1`
      unless $?.success? then 
        puts "....... failed"
        error "Compilation error for #{@name}", result
      else
        puts "....... OK"
        @state = :compiled
      end
    end
  end

  def run(parameters, options)
    ensure_in_state(:compiled) do
      puts "Running #{@name}"
      executed_command = "bin/#{@name} #{all_parameters(parameters)} 2>&1"
      result = `#{executed_command}`
      puts executed_command if options[:verbose]
      if $?.success? then
        puts result if options[:verbose]
        puts "....... OK"
        @state = :finished
      elsif dumpExists then 
        result += startDebugger(@name) if options[:debugger]
        puts "....... failed"
        error "Had to start a debugging session for #{@name}", result
      else
        puts "....... failed"
        error "Execution for #{@name} was not successful", result
      end
    end
  end

  def startDebugger(name)
    core = Dir.glob("/cores/core.*").first
    result = `echo "bt" | gdb bin/#{name} #{core}`
    puts "The debugging session: #{result}"
    FileUtils.rm(Dir.glob("/cores/core.*"))
    return result
  end

  def has_errors?
    @state == :error or @errors.size>0
  end

  def to_s
    @name
  end

 private
  def all_parameters(parameters)
    ([parameters] + @additional_parameters).join(" ")
  end

  def dumpExists
    Dir.glob("/cores/core.*").size > 0
  end
  
  def ensure_in_state(state)
    if state!=@state
      puts "#{@name} not running anymore"
    else
      yield
    end
  end

  def error(message,cause="")
    @state = :error
    @errors << Error.new(message,cause)
  end
end

class Message
  def initialize(heading,short_description,cause)
    @heading = heading
    @short_description = short_description
    @cause = cause
  end
  def to_s
    "=================== #{@heading} : #{@short_description} ===============\n #{@cause}"
  end
  def format_for_growlnotify
    "-t \"#{@heading}.\" -m \"#{@short_description}\" --image \"#{@heading}.png\""
  end
  def format_for_notifysend
    "\"#{@heading}.\" \"#{@short_description}\" --icon \"#{@heading}.png\""
  end
end
class Error < Message
  def initialize(message,cause="")
    super("Failure",message,cause)
  end
end

module ImageProducing
  def removeOldImages
    images = @image_pattern.collect{|image| Dir.glob(image)}.flatten.select{|image| File.exists?(image)}
    images.each do |image|
      FileUtils.rm(image)
    end
    puts "Deleted #{images.size} files for #{@image_pattern}"
  end 

  def compareWith(example_2)
    return ImageProducing::compareImagePairs(self, example_2)
  end

  def numberOfImages
    images.size
  end

  def images
    Dir.glob(@image_pattern)
  end

 private
  class<<self
    def compareImagePairs(example_1, example_2)
      if example_1.numberOfImages != example_2.numberOfImages then
        return Error.new("#{example_1} has #{example_1.numberOfImages} images, but #{example_2} has #{example_2.numberOfImages}")
      elsif example_1.numberOfImages == 0 and example_2.numberOfImages == 0
        return Error.new("No Images found!")
      else
        return analyzePairs(formPairs(example_1.images, example_2.images))
      end
    end

    def formPairs(array_1,array_2)
      throw "Arrays need to have the same length" unless array_1.size == array_2.size
      result = []
      array_1.each_with_index do |element_1,i|
        element_2 = array_2[i]
        result << Pair.new(element_1,element_2)
      end
      return result
    end

    def analyzePairs(pairs)
      samePairs,differingPairs = partition(pairs)
      summary = "#{samePairs.empty? ? "No" : samePairs.size} pairs are the same"
      result = "#{summary}:\n"
      result += samePairs.collect{|pair| "  - #{pair} are the same"}.join("\n")
      unless differingPairs.empty? then
        string = "#{differingPairs.size} are different"
        result += "#{string}:\n"
        summary += " / #{string}"
        result += differingPairs.collect{|pair| "  - #{pair} are different"}.join("\n")
      end
      heading = differingPairs.empty? ? "Success" : "Failure"
      return Message.new(heading, summary, result)
    end

    def partition(pairs)
      samePairs = []
      differingPairs = []
      pairs.each do |pair|
        if pair.images_are_the_same then
         samePairs << pair
        else
         differingPairs << pair
        end 
      end
      return samePairs, differingPairs
    end

  end #class<<self
end

class Pair
  def initialize(image_1,image_2)
    @image_1 = image_1
    @image_2 = image_2
    @result = ""
  end

  def images_are_the_same
    @result = `diff #{@image_1} #{@image_2}`
    return $?.success?
  end 
  
  def to_s
    "[#{@image_1} and #{@image_2}]"
  end
end

module System
  def System::enableCoreDumpsOnRuntimeErrorsAndCleanUpOldDumps
    FileUtils.rm(Dir.glob("/cores/core.*"))
  end

  def System::showNotifications(messages)
    messages = [messages] unless messages.is_a?Array
    messages.each do |message|
      puts message
      if(notification_system_installed and message.is_a?Message) then
        `#{notification_system} #{message.send("format_for_#{notification_system.gsub("-","")}")}`
      end
    end
  end

 private
  def System::notification_system
    systems = %w[growlnotify notify-send]
    systems.each do |system|
      return system if executable_exists(system)
    end
    return nil
  end

  def System::notification_system_installed
    return !notification_system.nil?
  end

  def System::executable_exists(executable)
    `hash #{executable} 2>&-`
    return $?.success?
  end
end
