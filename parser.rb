#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"
require "./tree.rb"
Bundler.require(:default)


class String
  def remove_linebreak
    self.gsub(/\r|\n|\r\n/,"")  
  end
end

class Token
  attr_accessor :closing
  include TreeNode
  def self.order
    1
  end
  def try_closing_with(line)
    puts "Trying to close: #{line.inspect} with #{@closing}"
    if line =~ @closing 
      @closing = nil
      @my_lines << line
      return true
    end
    false
  end
  def is_closed?
    @closing.nil?
  end
  def is_open?
    ! is_closed?
  end
  def to_s
    "#<#{self.class}: #{@name.gsub(/\r\n|\r|\n/,"")||""}>"
  end
end

class UnknownToken < Token
  def UnknownToken::first_line
    /.*/
  end
  def initialize(lines)
    @name = @my_lines = lines.shift
  end
  def self.order
    0
  end
end

class EmptyLineToken < Token
  def self.first_line
    /^\s*$/
  end
  def initialize(lines)
    @name = @my_lines = [lines.shift]
  end
end

class CompileOnceFlag < Token
  def CompileOnceFlag::first_line
    /#ifndef\s+([A-Z_]+)/
  end
  def initialize(lines)
    @my_lines = [lines.first]
    @name = CompileOnceFlag::first_line.match(lines.shift)[1] if lines
    throw :parse_error unless lines.first =~ Regexp.compile("#define\s+(#{@name})") 
    @my_lines << lines.shift
    @remainder = lines
    @closing = /#endif/
  end
end

class IncludeStatement < Token
  def IncludeStatement::first_line
    /^#include\s+[\"|<](.*)[\"|>]\s*$/
  end
  def initialize(lines)
    @name = IncludeStatement::first_line.match(lines.first)[1]
    @my_lines = [lines.shift]
  end
end

class NamespaceStatement < Token
  def self.first_line
    /namespace\s+([a-zA-Z_0-9]+)\s*\{/
  end
  def initialize(lines)
    @name = NamespaceStatement::first_line.match(lines.first)[1]
    @my_lines = [lines.shift]
  end
end

class RootNode < Token
  def initialize(name)
    @name = name
  end
  def is_closed?
    false
  end
  def is_open?
    true
  end
  def try_closing_with(line)
    false
  end
end

class Parser
  def initialize(name)
    @root_node = RootNode.new(name)
  end

  def Parser::parse_constructs
    [CompileOnceFlag, IncludeStatement, NamespaceStatement, UnknownToken, EmptyLineToken]
  end

  def parse(lines,lowest_open_node=@root_node)
    # puts "Calling parser_helper with #{lines.size} lines, beginning with #{lines.collect{|l| l.remove_linebreak}.join(" ")[0..100]}"
    # puts "The lowest_open_node is #{lowest_open_node.inspect}"
    unless lines.empty? then
      throw :node_is_not_open_or_nil if lowest_open_node.nil? or lowest_open_node.is_closed?
      if lowest_open_node.try_closing_with(lines.first) then
        lines.shift
        parse(lines,lowest_open_node.parent)
      else
        new_node = Parser::find_token(lines.first).send(:new, lines)
        # puts "Connecting #{lowest_open_node.inspect} and #{new_node.inspect}"
        lowest_open_node << new_node
        parse(lines,new_node) 
      end
    end
  end

  def Parser::find_token(line)
    applicable_constructs = []
    Parser::parse_constructs.each do |construct|
      applicable_constructs << construct if construct.send(:first_line).match(line)
    end
    if applicable_constructs.size > 1 then
      applicable_constructs.reject!{|c| c.order==0}
    end
    if applicable_constructs.empty? then
      # puts "Could not find token for #{line.inspect}"
      throw :no_constructs_found
    end
    if applicable_constructs.size>1 then
      # puts "Found multiple constructs for #{line.inspect}: [#{applicable_constructs.join(", ")}]"
      throw :multiple_constructs_found
    end
    applicable_constructs.first
  end

  def print_tree
    puts @root_node.subtree_to_s 
  end
end

if __FILE__ == $0 then
  parser = Parser.new(ARGV[0])
  file_contents = IO.readlines(ARGV[0])
  parser.parse(file_contents)
  parser.print_tree
end
