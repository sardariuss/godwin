import Types "../types";
import Utils "../utils";
import Interest "interest";
import Opinion "opinion";
import Categorization "categorization";

import Option "mo:base/Option";

module {

  type Interests2 = Interest.Interests2;
  type Opinions = Opinion.Opinions;
  type Categorizations = Categorization.Categorizations;
  type Question = Types.Question;
  type IndexedStatus = Types.IndexedStatus;

  public class Manager(interests_: Interests2, opinions_: Opinions, categorizations_: Categorizations){

    func todo(a: IndexedStatus, b: IndexedStatus) : Bool {
      true;
    };

    public func onQuestionUpdated(old_question: ?Question, new_question: ?Question) {
      let old = Option.chain(old_question, func(question: Question) : ?IndexedStatus {
        ?question.status_info.current;
      });
      let new = Option.chain(new_question, func(question: Question) : ?IndexedStatus {
        ?question.status_info.current;
      });
      if (not Utils.equalOpt<IndexedStatus>(old, new, todo)) {
        Option.iterate(old_question, func(old: Question) { closeVote(old.id, old.status_info.current); });
        Option.iterate(new_question, func(new: Question) { openVote( new.id, new.status_info.current); });
      };
    };

    func openVote(question_id: Nat, new_status: IndexedStatus){
      switch(new_status.status){
        case(#CANDIDATE)      { interests_.newVote(      question_id, new_status.index, new_status.date); };
        case(#OPINION)        { opinions_.newVote(       question_id, new_status.index, new_status.date); };
        case(#CATEGORIZATION) { categorizations_.newVote(question_id, new_status.index, new_status.date); };
        case(_) {};
      };
    };

    func closeVote(question_id: Nat, old_status: IndexedStatus){
      switch(old_status.status){
        case(#CANDIDATE)      { interests_.closeVote(      question_id, old_status.index); };
        case(#OPINION)        { opinions_.closeVote(       question_id, old_status.index); };
        case(#CATEGORIZATION) { categorizations_.closeVote(question_id, old_status.index); };
        case(_) {};
      };
    };
    
  };
}