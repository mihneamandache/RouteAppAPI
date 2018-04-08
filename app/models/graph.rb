class Edge
  attr_accessor :from, :to, :distance

  def initialize(from, to , distance)
    @from = from
    @to = to
    @distance = distance
  end
end

class Vertex
  attr_accessor :id, :reference

  def initialize(id, reference)
    @id = id
    @reference = reference
  end
end

class Graph
  attr_reader :edges, :vertices, :vertex_references

  def initialize
    @edges = []
    @vertices = []
    @vertex_references = []
  end

  def addVertex(v_id, v_reference)
    if @vertex_references.include?(v_reference)
      false
    else
      @vertex_references.push(v_reference)
      @vertices.push(Vertex.new(v_id, v_reference))
      true
    end
  end

  def connect(from, to, distance)
    if !@vertex_references.include?(from)
      false
    elsif !@vertex_references.include?(to)
      false
    else
      @edges.push(Edge.new(from, to, distance))
      true
    end
  end

  def connect_mutually(vertex_r1, vertex_r2, distance)
    self.connect vertex_r1, vertex_r2, distance
    self.connect vertex_r2, vertex_r1, distance
  end

  def neighbors(vertex)
    neighbours = []
    @edges.each do |edge|
      if edge.from == vertex
        neighbours.push(edge.to)
      end
    end
    return neighbours.uniq
  end

  def length_between(from, to)
    @edges.each do |edge|
      if edge.from == from and edge.to == to
        return edge.distance
      end
    end
    nil
  end

  #inspired from https://gist.github.com/yaraki/1730288
end
