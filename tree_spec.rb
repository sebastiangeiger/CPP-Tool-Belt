require "./tree.rb"
class MyTreeNode
  include TreeNode
end
class MyStringTreeNode
  include TreeNode
  def initialize(string)
    @string = string
  end
  def to_s
    @string
  end
end
describe TreeNode do
  describe "#root?" do
    it "returns true for a new TreeNode" do
      node = MyTreeNode.new
      node.root?.should be_true
    end
  end
  describe "#children" do
    it "returns an empty array for a new TreeNode" do
      node = MyTreeNode.new
      node.children.should == []
    end
  end
  describe "#parent" do
    it "returns nil for a new TreeNode" do
      node = MyTreeNode.new
      node.parent.should be_nil
    end
  end
  describe "#operator <<" do
    it "sets the first argument to the parent of the second" do
      node1 = MyTreeNode.new
      node2 = MyTreeNode.new
      node1 << node2
      node2.parent.should == node1
    end
    it "adds the second operand to the children of the first" do
      node1 = MyTreeNode.new
      node2 = MyTreeNode.new
      node1 << node2
      node1.children.should include(node2)
    end
    it "adding a node twice to the same parent does not have any effect" do
      node1 = MyTreeNode.new
      node2 = MyTreeNode.new
      node3 = MyTreeNode.new
      node1.children.size.should == 0
      node1 << node2
      node1 << node2
      node1.children.size.should == 1
    end
    it "removes the second operand from any previous children lists" do
      node1 = MyTreeNode.new
      node2 = MyTreeNode.new
      node3 = MyTreeNode.new
      node1 << node2
      node1.children.should include(node2)
      node3 << node2
      node3.children.should include(node2)
      node1.children.should_not include(node2)
    end
  end
  describe "#remove(child)" do
    it "should not do anything to a child that is not a child" do
      node1 = MyTreeNode.new
      node2 = MyTreeNode.new
      node3 = MyTreeNode.new
      node2 << node3
      node1.remove(node3)
      node3.parent.should == node2
      node2.children.should include(node3)
    end
    it "should remove a node that is a child from the list of children" do
      node1 = MyTreeNode.new
      node2 = MyTreeNode.new
      node1 << node2
      node1.remove(node2)
      node1.children.should_not include(node2)
    end
    it "should set the parent node to nil for the removed child" do
      node1 = MyTreeNode.new
      node2 = MyTreeNode.new
      node1 << node2
      node1.remove(node2)
      node2.parent.should be_nil
    end
  end
  describe "#subtree_to_s" do
    it "should put one line if there is only the root node" do
      a = MyStringTreeNode.new("ROOT")
      a.to_s.should == "ROOT"
      a.subtree_to_s.should == "+ ROOT"
    end
    it "should put two lines if there is the root node and a child" do
      a = MyStringTreeNode.new("ROOT")
      b = MyStringTreeNode.new("CHILD 1")
      a << b
      a.subtree_to_s.should == ["+ ROOT","+-- CHILD 1"].join("\r\n")
    end
    it "should put three lines if there is the root node and two children" do
      a = MyStringTreeNode.new("ROOT")
      b = MyStringTreeNode.new("CHILD 1")
      c = MyStringTreeNode.new("CHILD 2")
      a << b
      a << c
      a.subtree_to_s.should == ["+ ROOT","+-- CHILD 1","+-- CHILD 2"].join("\r\n")
    end
    it "should put three lines if there is the root node and a child with a child" do
      a = MyStringTreeNode.new("ROOT")
      b = MyStringTreeNode.new("CHILD 1")
      c = MyStringTreeNode.new("CHILD 2")
      a << b
      b << c
      a.subtree_to_s.should == ["+ ROOT","+-- CHILD 1","+---- CHILD 2"].join("\r\n")
    end
  end
end
