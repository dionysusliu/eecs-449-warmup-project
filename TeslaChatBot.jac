node faq_root; // entry point of FAQ handler
node faq_state{ // template of a FAQ entry
    has question;
    has answer;
}
// define the graph architecture
graph faq{
    has anchor faq_root; // denote the root of this graph
    spawn{ // spawn (define) a subgraph
        // spawning the nodes
        faq_root = spawn node::faq_root;

        faq_answer_1 = spawn node::faq_state(
            question = "How do I configure my order?",
            answer = "To configure your order, log into your Tesla account."
        );

        faq_answer_2 = spawn node::faq_state(
            question = "How do I order a tesla",
            answer = "Visit our design studio to place your order."
        );

        faq_answer_3 = spawn node::faq_state(
            question = "Can I request a test drive",
            answer = "Yes. You must be minimum of 25 years of age."
        );

        // connecting the nodes
        faq_root ++> faq_answer_1;
        faq_root ++> faq_answer_2;
        faq_root ++> faq_answer_3;
    }
}

# Initialize the graph
walker init{ // init is default walker to run 
    root { // the code inside runs only on root node
        spawn here ++> graph::faq; // create an instance of faq graph and connects its anchor node to "here"
        // "here" evaluates to the node that the walker is on
    }
}