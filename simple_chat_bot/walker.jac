walker talker{
    has utterance;

    state {
        # print the message and prompts of current node
        std.out(here.message, here.prompts);

        # here we take the input from the terminal
        utterance = std.input("> ");

        # if the user enters quit, the program ends
        if(utterance=="quit"): disengage;

        # checks the utterance and determine which node to traverse to
        take -[transition(intent==utterance)] -> node::state else{
            take here;
        }
    }
}