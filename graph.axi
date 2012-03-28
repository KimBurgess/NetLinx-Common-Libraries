program_name='graph'
#if_not_defined __NCL_LIB_GRAPH
#define __NCL_LIB_GRAPH


define_constant
// Bounds for array sizes returned internally. These may be tweaked to optimise
// memory utilization.
GRAPH_MAX_NODES = 128
GRAPH_MAX_EDGES = 1024
GRAPH_MAX_ADJACENT_NODES = 16
GRAPH_MAX_HOPS = 8

// Internal constants
GRAPH_NULL_NODE_ID = 0
GRAPH_MAX_DISTANCE = $FFFF


define_type
structure graph_node {
	integer id
	char name[32]
	char settled
	integer distance
	integer previous
}

structure graph_edge {
	integer id
	integer source
	integer destination
	integer weight
}

structure graph {
	integer nextNodeID
	integer nextEdgeID
	graph_node nodes[GRAPH_MAX_NODES]
	graph_edge edges[GRAPH_MAX_EDGES]
}


define_function integer defineNode(graph g, char name[32]) {
	stack_var graph_node newNode
	g.nextNodeID++
	newNode.id = g.nextNodeID
	newNode.name = name
	g.nodes[newNode.id] = newNode
	set_length_array(g.nodes, g.nextNodeID + 1)
	return newNode.id
}

define_function integer defineWeightedEdge(graph g, integer source, integer destination, integer weight) {
	stack_var graph_edge newEdge
	g.nextEdgeID++
	newEdge.id = g.nextEdgeID
	newEdge.source = source
	newEdge.destination = destination
	newEdge.weight = weight
	g.edges[newEdge.id] = newEdge
	set_length_array(g.edges, g.nextEdgeID + 1)
	return newEdge.id
}

define_function integer defineEdge(graph g, integer source, integer destination) {
	return defineWeightedEdge(g, source, destination, 1)
}

define_function integer getClosestUnsettledNode(graph g) {
	stack_var integer i
	stack_var graph_node n
	stack_var graph_node closest

	closest.distance = GRAPH_MAX_DISTANCE

	for (i = 1; i <= length_array(g.nodes); i++) {
		n = g.nodes[i]
		if (n.settled == false && (n.distance < closest.distance)) {
			closest = n
		}
	}

	return closest.id
}

define_function integer[GRAPH_MAX_ADJACENT_NODES] getNeighbors(graph g, integer n) {
	stack_var integer i
	stack_var integer j
	stack_var integer neighbors[GRAPH_MAX_ADJACENT_NODES]
	stack_var graph_edge e

	for (i = length_array(g.edges); i > 0; i--) {
		e = g.edges[i]
		if (e.destination != GRAPH_NULL_NODE_ID) {
			if (e.source == n && g.nodes[e.destination].settled == false) {
				j++
				neighbors[j] = e.destination
			}
		}
	}

	set_length_array(neighbors, j)
	return neighbors
}

define_function integer getDistance(graph g, integer source, integer destination) {
	stack_var integer i
	stack_var graph_edge e

	for (i = 1; i <= length_array(g.edges); i++) {
		e = g.edges[i]
		if (e.source == source && e.destination == destination) {
			return e.weight
		}
	}

	return GRAPH_MAX_DISTANCE
}

define_function computePaths(graph g, integer source) {
	stack_var integer i
	stack_var integer n
	stack_var integer altDist

	for (i = length_array(g.nodes); i > 0; i--) {
		g.nodes[i].settled = false
		g.nodes[i].distance = GRAPH_MAX_DISTANCE
		g.nodes[i].previous = GRAPH_NULL_NODE_ID
	}

	g.nodes[source].distance = 0

	while (true) {
		stack_var integer adjacentNodes[GRAPH_MAX_ADJACENT_NODES]

		n = getClosestUnsettledNode(g)
		if (n == GRAPH_NULL_NODE_ID) break
		if (g.nodes[n].distance == GRAPH_MAX_DISTANCE) break

		g.nodes[n].settled = true

		adjacentNodes = getNeighbors(g, n)

		for (i = 1; i <= length_array(adjacentNodes); i++) {
			if (adjacentNodes[i] == GRAPH_NULL_NODE_ID) break

			altDist = g.nodes[n].distance+ getDistance(g, n, adjacentNodes[i])
			if (g.nodes[adjacentNodes[i]].distance > altDist) {
				g.nodes[adjacentNodes[i]].distance = altDist
				g.nodes[adjacentNodes[i]].previous = n
				g.nodes[adjacentNodes[i]].settled = false
			}
		}
	}
}

define_function integer[GRAPH_MAX_HOPS] getPath(graph g, integer destination) {
	stack_var integer path[GRAPH_MAX_HOPS]
	stack_var integer step
	stack_var integer hop

	step = destination
	hop++
	path[hop] = step

	while (g.nodes[step].previous != GRAPH_NULL_NODE_ID) {
		step = g.nodes[step].previous
		hop++
		path[hop] = step
	}

	set_length_array(path, hop)
	return path
}

#end_if