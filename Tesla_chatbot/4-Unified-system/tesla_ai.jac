import {*} with "./2-FAQ-bot/TeslaChatBot.jac";
import {*} with "./dialogue.jac";

# shared node architecture
node cai_state {
    has name;
    can init_wlk_ctx {
        new_wlk_ctx = {
            "intent": null,
            "entities": {},
            "prev_state": null,
            "next_state": null,
            "respond": false
        };
        if("entities" in visitor.wlk_ctx){ # if visitor has attribute called "entities"
            // carry over the historical records
            new_wlk_ctx["entities"] = visitor.wlk_ctx["entities"];
        }
        visitor.wlk_ctx= new_wlk_ctx;
    }
    can nlu{}
    can process {
        if(visitor.wlk_ctx["prev_state"]): visitor.wlk_ctx["respond"] = true; // check whether this node is not leaf
        else {
            visitor.wlk_ctx["next_state"] = net.root();
            visitor.wlk_ctx["prev_state"] = here;
        }
    }
    can nlg{}
}

node faq_root:cai_state{
    can use.qa_classify;
    can nlu { // get the intent from user input
        if(!visitor.wlk_ctx["prev_state"]) {
            answers = -->.answer;
            best_answer = use.qa_classify(
                text = visitor.question,
                classes = answers
            );
            visitor.wlk_ctx["intent"] = best_answer["match"];
        }
    }
    can process {
        if (visitor.wlk_ctx["prev_state"]):visitor.wlk_ctx["respond"] = true;
        else {
            for n in -->{  // iterate through all nodes
                if (n.context["answer"] == visitor.wlk_ctx["intent"]) { // find the next node with desired intent
                    visitor.wlk_ctx["next_state"] = n;
                    break;
                }
            }
            visitor.wlk_ctx["prev_state"] = here;
        }
    }
    can nlg{
        visitor.response = "I can answer a variety of FAQs related to Tesla. What can I help you with？";
    }
}

node faq_state:cai_state {
    has question;
    has answer;
    can nlg {
        visitor.response = here.answer;
    }
}

graph tesla_ai {
    has anchor dialogue_root;
    spawn {
        dialogue_root = spawn node::dialogue_root;
        test_drive_state = spawn node::test_drive_state;
        td_confirmation = spawn node::td_confirmation;
        td_confirmed = spawn node::td_confirmed;
        td_canceled = spawn node::td_canceled;

        dialogue_root +[intent_transition(intent="test drive")]+> test_drive_state;
        test_drive_state +[intent_transition(intent="cancel")]+> td_canceled;
        test_drive_state +[entity_transition(entities=["name", "address"])]+> td_confirmation;
        test_drive_state +[intent_transition(intent="provide name or address")]+> test_drive_state;
        td_confirmation +[intent_transition(intent="yes")]+> td_confirmed;
        td_confirmation +[intent_transition(intent="no")]+> test_drive_state;
        td_confirmation +[intent_transition(intent="cancel")]+> td_canceled;

        faq_root = spawn graph::faq;
        dialogue_root +[intent_transition(intent="i have a question")]+> faq_root;
    }
}

walker talk {
    has question;
    has wlk_ctx = {};
    has response;
    root {
        take --> node::dialogue_root;
    }
    // dialogue_state {
    //     if (!question) {
    //         question = std.input("Question (Ctrl-C to exit)> ");
    //         here::init_wlk_ctx;
    //     }
    //     here::nlu;
    //     here::process;
    //     if (visitor.wlk_ctx["respond"]) {
    //         here::nlg;
    //         std.out(response);
    //         question = null;
    //         take here;
    //     } else {
    //         take visitor.wlk_ctx["next_state"] else: take here;
    //     }
    // }
    cai_state { // unified-version
        if (!question){
            question = std.input("Question (Ctrl-C to exit)> ");
            here::init_wlk_ctx;
        }
        here::nlu;
        here::process;
        if (visitor.wlk_ctx["respond"]) {
            here::nlg;
            std.out(response);
            question = null;
            take here;
        } else {
            take visitor.wlk_ctx["next_state"] else: take here;
        }
    }
}

walker init {
    root {
        spawn here ++> graph::tesla_ai;
        spawn here walker::talk;
    }
}