walker talker{
    has utterance;

    state {
        // print the message and prompts of current node
        std.out(here.message, here.prompts);

        // ere we take the input from the terminal
        utterance = std.input("> ");

        if(utterance=="quit"): disengage;

        take -[transition(intent==utterance)] -> node::state else{
            take here;
        }
    }
}