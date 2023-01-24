# import the graph and walker 
import {*} with "./graph.jac";
import {*} with "./walker.jac";

# the walker for booting the program
walker init {
    root {
        # create an instance of the graph
        spawn here ++> graph::main_graph;
        spawn --> walker::talker;
    }
}