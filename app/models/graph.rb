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
    if !@vertices.include?(from)
      false
    elsif !@vertices.include?(to)
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

  def dijkstra(src, dst = nil)
    distances = {}
    previouses = {}
    @vertices.each do |vertex|
      distances[vertex] = nil # Infinity
      previouses[vertex] = nil
    end
    distances[src] = 0
    vertices_copy = @vertices
    until vertices_copy.empty?
      nearest_vertex = vertices_copy.inject do |a, b|
        next b unless distances[a]
        next a unless distances[b]
        next a if distances[a] < distances[b]
        b
      end
      break unless distances[nearest_vertex] # Infinity
      if dst and nearest_vertex == dst
        return distances[dst]
      end
      neighbors = neighbors(nearest_vertex)
      p neighbors
      neighbors.each do |vertex|
        alt = distances[nearest_vertex] + length_between(nearest_vertex, vertex)
        if distances[vertex].nil? or alt < distances[vertex]
          distances[vertex] = alt
          previouses[vertices] = nearest_vertex
          # decrease-key v in Q # ???
        end
      end
    vertices_copy.delete nearest_vertex
    end
    if dst
      return nil
    else
      return distances
    end
  end

  #inspired from https://gist.github.com/yaraki/1730288
end
