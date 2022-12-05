import Vote "vote";
import Types "../types";

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

  public func updateInterests(iteration: Iteration, interest: Vote<Interest, InterestAggregate>) : Iteration {
    {
      id = iteration.id;
      question_id = iteration.question_id;
      opening_date = iteration.opening_date;
      closing_date = iteration.closing_date;
      current = iteration.current;
      interest;
      opinion = iteration.opinion;
      categorization = iteration.categorization;
    };
  };

  public func updateOpinions(iteration: Iteration, opinion: Vote<Cursor, Polarization>) : Iteration {
    {
      id = iteration.id;
      question_id = iteration.question_id;
      opening_date = iteration.opening_date;
      closing_date = iteration.closing_date;
      current = iteration.current;
      interest = iteration.interest;
      opinion;
      categorization = iteration.categorization;
    };
  };

  public func updateCategorizations(iteration: Iteration, categorization: Vote<CategoryCursorTrie, CategoryPolarizationTrie>) : Iteration {
    {
      id = iteration.id;
      question_id = iteration.question_id;
      opening_date = iteration.opening_date;
      closing_date = iteration.closing_date;
      current = iteration.current;
      interest = iteration.interest;
      opinion = iteration.opinion;
      categorization;
    };
  };

};