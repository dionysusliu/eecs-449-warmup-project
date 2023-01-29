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

walker ask {
    can use.qa_classify;
    has question;
    root {
        question = std.input(">");
        take --> node::faq_root;
    }
    faq_root {
        answers = -->.answer;
        best_answer = use.qa_classify(
            text = question,
            classes = answers
        );
        take --> node::faq_state(answer==best_answer["match"]);
    }
    faq_state {
        std.out(here.answer);
    }
}

walker ingest_faq{
    has kb_file;
    root: take --> node::faq_root;
    faq_root {
        kb = file.load_json(kb_file);
        for faq in kb{
            answer = faq["answer"];
            spawn here ++> node::faq_state(answer=answer);
        }
    }
}

walker init{ // init is default walker to run 
    root { // the code inside runs only on root node
        spawn here ++> node::faq_root; // create an instance of faq graph and connects its anchor node to "here"
        // "here" evaluates to the node that the walker is on
        spawn here walker::ingest_faq(kb_file="tesla_faq.json");
        spawn here walker::ask;
    }
}