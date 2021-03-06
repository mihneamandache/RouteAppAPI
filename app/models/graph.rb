class Edge
  attr_accessor :from, :to, :distance

  def initialize(from, to , distance)
    @from = from
    @to = to
    @distance = distance
  end
end

class Vertex
  attr_accessor :id, :reference, :extras

  def initialize(id, reference, extras)
    @id = id
    @reference = reference
    @extras = extras
  end
end

class Graph
  attr_reader :edges, :vertices, :vertex_references

  def initialize
    @edges = []
    @vertices = []
    @vertex_references = []
  end

  def addVertex(v_id, v_reference, v_extras)
    if @vertex_references.include?(v_reference)
      false
    else
      @vertex_references.push(v_reference)
      new_vertex = Vertex.new(v_id, v_reference, v_extras)
      @vertices.push(new_vertex)
      new_vertex
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

  def can_be_reached(vertex)
    previous_vertex = []
    @edges.each do |edge|
      if edge.to == vertex
        previous_vertex.push(edge.to)
      end
    end
    return !previous_vertex.empty?
  end

  def length_between(from, to)
    @edges.each do |edge|
      if edge.from == from and edge.to == to
        return edge.distance
      end
    end
    nil
  end

  def find_vertex(reference)
    @vertices.each do |vertex|
      if vertex.reference == reference
        return vertex
      end
    end
    nil
  end

  def dijkstra(src, dst)
    distances = {}
    previouses = {}
    @vertices.each do |vertex|
      distances[vertex] = nil
      previouses[vertex] = nil
    end
    distances[src] = 0
    vertices_copy = self.clone
    until vertices_copy.vertices.empty?
      nearest_vertex = vertices_copy.vertices.inject do |a, b|
        next b unless distances[a]
        next a unless distances[b]
        next a if distances[a] < distances[b]
        b
      end
      break unless distances[nearest_vertex]
      if dst and nearest_vertex == dst
        path = get_path(previouses, src, dst)
        return {path => distances[dst]}
      end
      neighbors = vertices_copy.neighbors(nearest_vertex)

      neighbors.each do |vertex|
        alt = distances[nearest_vertex] + vertices_copy.length_between(nearest_vertex, vertex)
        if distances[vertex].nil? or alt < distances[vertex]
          distances[vertex] = alt
          previouses[vertex] = nearest_vertex
        end
      end
    vertices_copy.vertices.delete nearest_vertex
    end
    nil
  end

  def adapted_dijkstra(src, dst)
    distances = {}
    previouses = {}
    no_of_obstacles = {}

    @vertices.each do |vertex|
      distances[vertex] = nil
      previouses[vertex] = nil
      no_of_obstacles[vertex] = nil
    end

    distances[src] = 0
    no_of_obstacles[src] = 0
    vertices_copy = self.clone
    until vertices_copy.vertices.empty?
      nearest_vertex = vertices_copy.vertices.inject do |a, b|
        next b unless distances[a]
        next a unless distances[b]
        next a if distances[a] < distances[b]
        b
      end
      break unless distances[nearest_vertex]
      if nearest_vertex != dst
        neighbors = vertices_copy.neighbors(nearest_vertex)
        neighbors.each do |vertex|
          obstacle = 0
          if vertex.extras.include?("marked")
            obstacle = 1
          end
          alt = distances[nearest_vertex] + vertices_copy.length_between(nearest_vertex, vertex)
          if distances[vertex].nil?
            distances[vertex] = alt
            previouses[vertex] = nearest_vertex
            no_of_obstacles[vertex] = no_of_obstacles[nearest_vertex] + obstacle
          elsif no_of_obstacles[vertex] > no_of_obstacles[nearest_vertex] + obstacle
            distances[vertex] = alt
            previouses[vertex] = nearest_vertex
            no_of_obstacles[vertex] = no_of_obstacles[nearest_vertex] + obstacle
          elsif (no_of_obstacles[vertex] == no_of_obstacles[nearest_vertex] + obstacle and alt < distances[vertex])
            distances[vertex] = alt
            previouses[vertex] = nearest_vertex
          end
        end
      end
    vertices_copy.vertices.delete nearest_vertex
    end
    if !@vertices.include?(dst)
      path = get_path(previouses, src, dst)
      return {path => distances[dst]}
    else
      return nil
    end
  end

  private
  def get_path(previouses, src, dest)
    path = get_path_recursively(previouses, src, dest)
    path.is_a?(Array) ? path.reverse : path
  end

  # Unroll through previouses array until we get to source
  def get_path_recursively(previouses, src, dest)
    return src.reference if src == dest
    if previouses[dest].nil?
      return false
    end
    [dest.reference, get_path_recursively(previouses, src, previouses[dest])].flatten
  end

  #inspired from https://gist.github.com/yaraki/1730288
end
