import Vote "vote";
import Types "../types";
import Polarization "../representation/polarization";

import Option "mo:base/Option";
import Prelude "mo:base/Prelude";
import Trie "mo:base/Trie";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;

  // For convenience: from types modules
  type Vote<B, A> = Types.Vote<B, A>;
  type Iteration = Types.Iteration;
  type Interest = Types.Interest;
  type InterestAggregate = Types.InterestAggregate;
  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;
  type CategoryCursorTrie = Types.CategoryCursorTrie;
  type CategoryPolarizationTrie = Types.CategoryPolarizationTrie;

  public func new(id: Nat, opening_date: Int) : Iteration {
    {
      id;
      opening_date;
      closing_date = null;
      voting_stage = #INTEREST;
      interest = ?Vote.new<Interest, InterestAggregate>(opening_date, { ups = 0; downs = 0; score = 0; });
      opinion = null;
      categorization = null;
    };
  };

  public func openOpinionVote(iteration: Iteration, date: Int) : Iteration {
    assert(iteration.voting_stage == #INTEREST);
    { iteration with voting_stage = #OPINION; opinion = ?Vote.new<Cursor, Polarization>(date, Polarization.nil());};
  };

  public func openCategorizationVote(iteration: Iteration, date: Int) : Iteration {
    assert(iteration.voting_stage == #OPINION);
    { iteration with voting_stage = #CATEGORIZATION; categorization = ?Vote.new<CategoryCursorTrie, CategoryPolarizationTrie>(date, Trie.empty<Text, Polarization>()); };
  };

  public func closeVotes(iteration: Iteration, date: Int) : Iteration {
    { iteration with voting_stage = #CLOSED; closing_date = ?date; };
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