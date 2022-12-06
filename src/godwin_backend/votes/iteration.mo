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
  type VoteType = Types.VoteType;

  public func updateInterests(iteration: Iteration, interest: ?Vote<Interest, InterestAggregate>) : Iteration {
    {
      id = iteration.id;
      question_id = iteration.question_id;
      opening_date = iteration.opening_date;
      closing_date = iteration.closing_date;
      current_vote = iteration.current_vote;
      interest;
      opinion = iteration.opinion;
      categorization = iteration.categorization;
    };
  };

  public func updateOpinions(iteration: Iteration, opinion: ?Vote<Cursor, Polarization>) : Iteration {
    {
      id = iteration.id;
      question_id = iteration.question_id;
      opening_date = iteration.opening_date;
      closing_date = iteration.closing_date;
      current_vote = iteration.current_vote;
      interest = iteration.interest;
      opinion;
      categorization = iteration.categorization;
    };
  };

  public func updateCategorizations(iteration: Iteration, categorization: ?Vote<CategoryCursorTrie, CategoryPolarizationTrie>) : Iteration {
    {
      id = iteration.id;
      question_id = iteration.question_id;
      opening_date = iteration.opening_date;
      closing_date = iteration.closing_date;
      current_vote = iteration.current_vote;
      interest = iteration.interest;
      opinion = iteration.opinion;
      categorization;
    };
  };

  public func updateCurrentVote(iteration: Iteration, current_vote: VoteType, closing_date: ?Int) : Iteration {
    {
      id = iteration.id;
      question_id = iteration.question_id;
      opening_date = iteration.opening_date;
      closing_date;
      current_vote;
      interest = iteration.interest;
      opinion = iteration.opinion;
      categorization = iteration.categorization;
    };
  };

  public func unwrapInterest(iteration: Iteration) : Vote<Interest, InterestAggregate> {
    assert(iteration.interest != null);
    switch(iteration.interest){
      case(null) { Prelude.unreachable(); };
      case(?interest) { return interest; };
    };
  };

  public func unwrapOpinion(iteration: Iteration) : Vote<Cursor, Polarization> {
    assert(iteration.opinion != null);
    switch(iteration.opinion){
      case(null) { Prelude.unreachable(); };
      case(?opinion) { return opinion; };
    };
  };

  public func unwrapCategorization(iteration: Iteration) : Vote<CategoryCursorTrie, CategoryPolarizationTrie> {
    assert(iteration.categorization != null);
    switch(iteration.categorization){
      case(null) { Prelude.unreachable(); };
      case(?categorization) { return categorization; };
    };
  };
  
};