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
    diff1 = 0.1 - (locations[0].latitude - locations[1].latitude).abs
    diff2 = 0.1 - (locations[0].longitude - locations[1].longitude).abs
    diff1 = diff2 = 0
    api_url += (minx - diff2/2).to_s + ',' +  (miny - diff1/2).to_s + ',' + (maxx + diff2/2).to_s + ',' + (maxy + diff1/2).to_s
    puts api_url
    xml_response = Nokogiri::XML(RestClient.get(api_url))
    node_information = xml_response.xpath("//node")

    node_information = create_node_information_hash(node_information)
    ways = get_ways(xml_response.xpath("//way"), motor_tags)
    graph = create_graph(ways, node_information)
    p 'graph ready'
    start_location = get_start_location_id(graph)
    p start_location
    goal_location = get_goal_location_id(graph)
    p goal_location
    p 'going in'
    p graph.neighbors(graph.find_vertex(goal_location))
    graph.adapted_dijkstra(graph.find_vertex(start_location), graph.find_vertex(goal_location)).to_s

  end

  def get_start_location_id(graph)
    api_url = "http://overpass-api.de/api/interpreter?data=node(around:"
    start_location_id = nil

    start_lat = locations[0].latitude
    start_lon = locations[0].longitude
    start = "," + start_lat.to_s + "," + start_lon.to_s + ");out;"

    radius = 10
    found = false
    while found == false do
      p 'still searching'
      nodes = Nokogiri::XML(RestClient.get(api_url + radius.to_s + start)).xpath("//node")
      p api_url + radius.to_s + start
      if nodes.empty?
        radius += 10
      else
        nodes.each do |node|
          possible_start = graph.find_vertex(node.attribute("id").value)
          if (!possible_start.nil? and found == false and !graph.neighbors(possible_start).empty?)
            found = true
            start_location_id = node.attribute("id").value
          end
        end
        if found == false
          radius += 10
        end
      end
    end

    start_location_id
  end

  def get_goal_location_id(graph)
    api_url = "http://overpass-api.de/api/interpreter?data=node(around:"
    goal_location_id = nil

    goal_lat = locations[1].latitude
    goal_lon = locations[1].longitude
    goal = "," + goal_lat.to_s + "," + goal_lon.to_s + ");out;"

    radius = 10
    found = false
    while found == false do
      nodes = Nokogiri::XML(RestClient.get(api_url + radius.to_s + goal)).xpath("//node")
      if nodes.empty?
        radius += 10
      else
        nodes.each do |node|
          if (!graph.find_vertex(node.attribute("id").value).nil? and found == false)
            found = true
            goal_location_id = node.attribute("id").value
          end
        end
        if found == false
          radius += 10
        end
      end
    end
    goal_location_id
  end

  def get_ways(ways, tags)
    tagged_ways = []
    ways.to_a.each do |way|
      contains = false
      way.children.each do |child|
        if tags.include?(child.to_s)
          contains = true
        end
      end
      if contains == true
        tagged_ways.push(way)
      end
    end
    tagged_ways
  end

  def create_graph(ways, node_information)
    graph = Graph.new
    current_nodes = []
    id_counter = 1
    ways.to_a.each do |way|
      current_nodes = []
      oneway = false
      way.children.each do |child|
        if is_node(child.to_s) == true
          current_nodes.push(child)
        end
        if child.to_s == "<tag k=\"oneway\" v=\"yes\"/>"
          oneway = true
        end
      end
      id_counter = add_nodes_to_graph(graph, current_nodes, node_information, false, id_counter)
    end
    #puts 'LALALA'
    graph
  end

  def add_nodes_to_graph(graph, nodes, node_information, oneway, id_counter)
    current_node = nil
    nodes.to_a.each do |node|
      vertex_address = graph.addVertex(id_counter, node.attribute("ref").value, node_information[node.attribute("ref").value][2])
      if vertex_address != false
        id_counter += 1
      else
        vertex_address = graph.find_vertex(node.attribute("ref").value)
      end
      if !current_node.nil?
        #graph.connect_mutually(current_node, vertex_address, 1)
        if oneway
          graph.connect(current_node, vertex_address, get_distance(current_node.reference, vertex_address.reference, node_information))
        else
          graph.connect_mutually(current_node, vertex_address, get_distance(current_node.reference, vertex_address.reference, node_information))
        end
      end
      current_node = vertex_address
    end
    id_counter
  end

  def is_node(current_item)
    if current_item.include?("nd ref=")
      true
    else
      false
    end
  end

  def get_distance(reference_x, reference_y, node_information)
    node_x_lat = node_information[reference_x][0].to_f
    node_x_lon = node_information[reference_x][1].to_f
    node_y_lat = node_information[reference_y][0].to_f
    node_y_lon = node_information[reference_y][1].to_f

    distance_formulae(node_x_lat, node_x_lon, node_y_lat, node_y_lon)
  end

  def distance_formulae(lat1, lon1, lat2, lon2)
    r = 6371e3
    x1 = lat1 * Math::PI / 180
    x2 = lat2 * Math::PI / 180
    y = (lat2 - lat1) * Math::PI / 180
    z = (lon2 - lon1) * Math::PI / 180

    a = Math.sin(y/2) * Math.sin(y/2) +
        Math.cos(x1) * Math.cos(x2) * Math.sin(z/2) * Math.sin(z/2)
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
    return r * c / 1000
  end

  def create_node_information_hash(nodes)
    node_information = {}
    nodes.each do |node|
      node_ref = node.attribute("id").value
      extras = [node.attribute("lat").value, node.attribute("lon").value]
      extra_information = []
      node.children.each do |child|
        extra_information.push("traffic_light") if child.to_s == "<tag k=\"highway\" v=\"traffic_signals\"/>"
      end
      extras.push extra_information
      node_information[node_ref] = extras
    end
    node_information
  end

  def motor_tags
    [
      "<tag k=\"highway\" v=\"motorway\"/>",
      "<tag k=\"highway\" v=\"motorway_link\"/>",
      "<tag k=\"highway\" v=\"trunk\"/>",
      "<tag k=\"highway\" v=\"trunk_link\"/>",
      "<tag k=\"highway\" v=\"primary\"/>",
      "<tag k=\"highway\" v=\"primary_link\"/>",
      "<tag k=\"highway\" v=\"secondary\"/>",
      "<tag k=\"highway\" v=\"secondary_link\"/>",
      "<tag k=\"highway\" v=\"tertiary\"/>",
      "<tag k=\"highway\" v=\"tertiary_link\"/>",
      "<tag k=\"highway\" v=\"unclassified\"/>",
      "<tag k=\"highway\" v=\"residential\"/>",
      "<tag k=\"highway\" v=\"living_street\"/>",
      "<tag k=\"highway\" v=\"road\"/>"
    ]
  end

  def foot_tags
    [
      "<tag k=\"highway\" v=\"trunk\"/>",
      "<tag k=\"highway\" v=\"trunk_link\"/>",
      "<tag k=\"highway\" v=\"primary\"/>",
      "<tag k=\"highway\" v=\"primary_link\"/>",
      "<tag k=\"highway\" v=\"secondary\"/>",
      "<tag k=\"highway\" v=\"secondary_link\"/>",
      "<tag k=\"highway\" v=\"tertiary\"/>",
      "<tag k=\"highway\" v=\"tertiary_link\"/>",
      "<tag k=\"highway\" v=\"unclassified\"/>",
      "<tag k=\"highway\" v=\"residential\"/>",
      "<tag k=\"highway\" v=\"living_street\"/>",
      "<tag k=\"highway\" v=\"road\"/>",
      "<tag k=\"highway\" v=\"footway\"/>",
      "<tag k=\"highway\" v=\"pedestrian\"/>",
      "<tag k=\"highway\" v=\"path\"/>",
      "<tag k=\"foot\" v=\"yes\"/>",
      "<tag k=\"sidewalk\" v=\"both\"/>",
      "<tag k=\"foot\" v=\"designated\"/>",
      "<tag k=\"foot\" v=\"permissive\"/>"
    ]
  end

  def cycle_tags
    [
      "<tag k=\"highway\" v=\"trunk\"/>",
      "<tag k=\"highway\" v=\"trunk_link\"/>",
      "<tag k=\"highway\" v=\"primary\"/>",
      "<tag k=\"highway\" v=\"primary_link\"/>",
      "<tag k=\"highway\" v=\"secondary\"/>",
      "<tag k=\"highway\" v=\"secondary_link\"/>",
      "<tag k=\"highway\" v=\"tertiary\"/>",
      "<tag k=\"highway\" v=\"tertiary_link\"/>",
      "<tag k=\"highway\" v=\"unclassified\"/>",
      "<tag k=\"highway\" v=\"residential\"/>",
      "<tag k=\"highway\" v=\"living_street\"/>",
      "<tag k=\"highway\" v=\"road\"/>",
      "<tag k=\"highway\" v=\"cycleway\"/>",
      "<tag k=\"highway\" v=\"path\"/>",
      "<tag k=\"cycleway:right\" v=\"opposite_lane\"/>",
      "<tag k=\"cycleway:right\" v=\"lane\"/>",
      "<tag k=\"cycleway:right\" v=\"track\"/>",
      "<tag k=\"cycleway:left\" v=\"lane\"/>",
      "<tag k=\"cycleway:both\" v=\"lane\"/>",
      "<tag k=\"cycleway\" v=\"lane\"/>",
      "<tag k=\"bicycle\" v=\"use_sidepath\"/>",
      "<tag k=\"cycleway\" v=\"track\"/>",
      "<tag k=\"cycleway\" v=\"opposite\"/>"
    ]
  end
end
