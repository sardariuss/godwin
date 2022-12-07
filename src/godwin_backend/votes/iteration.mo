import Vote "vote";
import Types "../types";

import Option "mo:base/Option";
import Prelude "mo:base/Prelude";

module {

  // For convenience: from types modules
  type Vote<B, A> = Types.Vote<B, A>;
  type Iteration = Types.Iteration;
  type Interest = Types.Interest;
  type InterestAggregate = Types.InterestAggregate;
  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;
  type CategoryCursorTrie = Types.CategoryCursorTrie;
  type CategoryPolarizationTrie = Types.CategoryPolarizationTrie;
  type VotingStage = Types.VotingStage;

  public func new(id: Nat, question_id: Nat, opening_date: Int) : Iteration {
    {
      id;
      question_id;
      opening_date;
      closing_date = null;
      voting_stage = #INTEREST;
      interest = ?Vote.new<Interest, InterestAggregate>(opening_date, #OPEN, { ups = 0; downs = 0; score = 0; });
      opinion = null; // Vote.new<Cursor, Polarization>(opening_date, #PENDING, Polarization.nil()); @todo
      categorization = null; // Vote.new<CategoryCursorTrie, CategoryPolarizationTrie>(opening_date, #PENDING, Trie.empty<Text, Polarization>()); @todo
    };
  };

  public func unwrapInterest(iteration: Iteration) : Vote<Interest, InterestAggregate> {
    switch(iteration.interest){
      case(null) { Prelude.unreachable(); };
      case(?interest) { return interest; };
    };
  };

  public func unwrapOpinion(iteration: Iteration) : Vote<Cursor, Polarization> {
    switch(iteration.opinion){
      case(null) { Prelude.unreachable(); };
      case(?opinion) { return opinion; };
    };
  };

  public func unwrapCategorization(iteration: Iteration) : Vote<CategoryCursorTrie, CategoryPolarizationTrie> {
    switch(iteration.categorization){
      case(null) { Prelude.unreachable(); };
      case(?categorization) { return categorization; };
    };
  };
  
};