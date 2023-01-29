import {*} with "./2-FAQ-bot/TeslaChatBot.jac"


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
        visitor.wlk_ctx["entities"] = new_wlk_ctx["entities"];
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

node faq_root::cai_state{
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
        visitor.response = "I can answer a variety of FAQs related to Tesla. What can I help you with？"
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

    }
}