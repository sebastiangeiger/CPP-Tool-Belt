require "rubygems"
require "bundler/setup"
Bundler.require(:default)

module TreeNode
  attr_accessor :parent, :children
  def root?
    return @parent.nil?
  end
  def children
    @children ||= []
  end
  def << (other)
    if other.is_a? TreeNode
      other.parent = self
      # puts "Children: #{@children.inspect}, Other: #{other.inspect}"
      children << other
    end
  end
  def remove(child)
    if(children.include?(child))
      children.delete(child)
      child.parent = nil
    end
  end
  def subtree_to_s
    ToStringVisitor::visit(self).join("\r\n")
  end
end

module ToStringVisitor #TODO: try to do this with a block
  def ToStringVisitor::visit(tree_node,decoration="+")
    lines = ["#{decoration} #{tree_node.to_s}"]
    tree_node.children.each do |child|
      lines += visit(child,decoration+"--")
    end
    lines
  end
end
