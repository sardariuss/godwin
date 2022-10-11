import Types "../types";
import Queries "queries";

import Debug "mo:base/Debug";

module {

  // For convenience: from types module
  type Question = Types.Question;
  type Categorization = Types.Categorization;

  public type QuestionsPerCategorization = {
    pending_rbts: Queries.QuestionRBTs;
    ongoing_rbts: Queries.QuestionRBTs;
    done_rbts: Queries.QuestionRBTs;
  };

  public func empty() : QuestionsPerCategorization {
    let pending_rbts = Queries.init();
    var ongoing_rbts = Queries.init();
    ongoing_rbts := Queries.addOrderBy(ongoing_rbts, #CATEGORIZATION_DATE);
    let done_rbts = Queries.init();
    { pending_rbts; ongoing_rbts; done_rbts; };
  };

  func getCategorizationRBTs(per_cat: QuestionsPerCategorization, categorization: Categorization) : Queries.QuestionRBTs {
    switch(categorization){
      case(#PENDING){ per_cat.pending_rbts; };
      case(#ONGOING){ per_cat.ongoing_rbts; };
      case(#DONE(_)){ per_cat.done_rbts; };
    };
  };

  func setCategorizationRBTs(per_cat: QuestionsPerCategorization, categorization: Categorization, rbts: Queries.QuestionRBTs) : QuestionsPerCategorization {
    switch(categorization){
      case(#PENDING){ { pending_rbts = rbts;                 ongoing_rbts = per_cat.ongoing_rbts; done_rbts = per_cat.done_rbts; }; };
      case(#ONGOING){ { pending_rbts = per_cat.pending_rbts; ongoing_rbts = rbts;                 done_rbts = per_cat.done_rbts; }; };
      case(#DONE(_)){ { pending_rbts = per_cat.pending_rbts; ongoing_rbts = per_cat.ongoing_rbts; done_rbts = rbts;              }; };
    };
  };

  public func addQuestion(per_cat: QuestionsPerCategorization, question: Question) : QuestionsPerCategorization {
    if (question.categorization.current.categorization != #PENDING) {
      Debug.trap("Cannot add a question which categorization is different from #PENDING");
    };
    {
      pending_rbts = Queries.add(per_cat.pending_rbts, question);
      ongoing_rbts = per_cat.ongoing_rbts;
      done_rbts = per_cat.done_rbts;
    };
  };

  public func replaceQuestion(per_cat: QuestionsPerCategorization, old_question: Question, new_question: Question) : QuestionsPerCategorization {
    var updated_per_cat = per_cat;
    let old_categorization = old_question.categorization.current.categorization;
    let new_categorization = new_question.categorization.current.categorization;
    if (old_categorization == new_categorization) {
      // Replace in current categorization
      var rbts = getCategorizationRBTs(updated_per_cat, old_categorization);
      rbts := Queries.replace(rbts, old_question, new_question);
      updated_per_cat := setCategorizationRBTs(updated_per_cat, old_categorization, rbts);
    } else {
      // Remove from previous categorization
      var rbts_1 = getCategorizationRBTs(updated_per_cat, old_categorization);
      rbts_1 := Queries.remove(rbts_1, old_question);
      updated_per_cat := setCategorizationRBTs(updated_per_cat, old_categorization, rbts_1);
      // Add in new categorization
      var rbts_2 = getCategorizationRBTs(updated_per_cat, new_categorization);
      rbts_2 := Queries.add(rbts_2, new_question);
      updated_per_cat := setCategorizationRBTs(updated_per_cat, new_categorization, rbts_2);
    };
    updated_per_cat;
  };

  public func removeQuestion(per_cat: QuestionsPerCategorization, question: Question) : QuestionsPerCategorization {
    let current_categorization = question.categorization.current.categorization;
    var rbts = getCategorizationRBTs(per_cat, current_categorization);
    rbts := Queries.remove(rbts, question);
    setCategorizationRBTs(per_cat, current_categorization, rbts);
  };

};