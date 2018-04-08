class Route < ApplicationRecord
  has_many :locations
  accepts_nested_attributes_for :locations

  def make_api_call
    api_url = "https://api.openstreetmap.org/api/0.6/map?bbox="

    minx = 181
    miny = 91
    maxx = -181
    maxy = -91

    locations.each do |location|
      if location.longitude < minx
        minx = location.longitude
      end
      if location.latitude < miny
        miny = location.latitude
      end
      if location.longitude > maxx
        maxx = location.longitude
      end
      if location.latitude > maxy
        maxy = location.latitude
      end
    end

    api_url += minx.to_s + ',' +  miny.to_s + ',' + maxx.to_s + ',' + maxy.to_s

    #puts api_url
    xml_response = Nokogiri::XML(RestClient.get(api_url))
    ways = xml_response.xpath("//way")

    get_ways(ways, "highway")
  end

  def get_ways(ways, tag)
    tagged_ways = []
    ways.to_a.each do |way|
      contains = false
      way.children.each do |child|
        if highway_tags.include?(child.to_s)
          contains = true
        end
      end
      if contains == true
        tagged_ways.push(way)
      end
    end
    create_graph(tagged_ways)
  end

  def create_graph(ways)
    graph = Graph.new
    current_nodes = []
    ways.to_a.each do |way|
      current_nodes = []
      way.children.each do |child|
        if is_node(child.to_s) == true
          current_nodes.push(child)
        end
      end
      add_nodes_to_graph(graph, current_nodes)
    end
    'graph'
  end

  def add_nodes_to_graph(graph, nodes)
    current_node = nil
    id_counter = 1
    nodes.to_a.each do |node|
      if graph.addVertex(id_counter, node.attribute("ref"))
        id_counter += 1
      end
      if !current_node.nil?
        graph.connect_mutually(current_node, node, 1)
        current_node = node
      end
    end
    puts graph.vertex_references
  end

  def is_node(current_item)
    if current_item.include?("nd ref=")
      true
    else
      false
    end
  end
  def highway_tags
    [
      "<tag k=\"highway\" v=\"motorway\"/>",
      "<tag k=\"highway\" v=\"trunk\"/>",
      "<tag k=\"highway\" v=\"primary\"/>",
      "<tag k=\"highway\" v=\"secondary\"/>",
      "<tag k=\"highway\" v=\"tertiary\"/>",
      "<tag k=\"highway\" v=\"unclassified\"/>",
      "<tag k=\"highway\" v=\"residential\"/>",
      "<tag k=\"highway\" v=\"service\"/>",
      "<tag k=\"highway\" v=\"living_street\"/>",
      "<tag k=\"highway\" v=\"track\"/>",
      "<tag k=\"highway\" v=\"path\"/>",
      "<tag k=\"highway\" v=\"road\"/>",
    ]
  end

end
