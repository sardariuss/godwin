import Types "types";
import Questions "questions/questions";
import Queries "questions/queries";
import Categories "categories";

import Array "mo:base/Array";
import Trie "mo:base/Trie";
import Nat "mo:base/Nat";
import Time "mo:base/Time";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Time = Time.Time;

  // For convenience: from types module
  type Question = Types.Question;
  type OrientedCategory = Types.OrientedCategory;
  type CategoriesDefinition = Types.CategoriesDefinition;
  type AggregationParameters = Types.AggregationParameters;
  type VoteRegister<B> = Types.VoteRegister<B>;

  // For convenience: from other modules
  type QuestionRegister = Questions.QuestionRegister;

  public func selectQuestion(register: QuestionRegister, last_selection_date: Time, selection_frequence: Time, time_now: Time) : ?Question {
    if (last_selection_date + selection_frequence > time_now) { null; }
    else switch (Queries.entriesRev(register.per_pool.spawn_rbts, #ENDORSEMENTS).next()){
      case(null){ null; };
      case(?key_val){
        switch(Trie.get(register.questions, Types.keyNat(key_val.0.id), Nat.equal)){
          case(null){ null; };
          case(?question){
            ?{
              id = question.id;
              author = question.author;
              title = question.title;
              text = question.text;
              date = question.date;
              endorsements = question.endorsements;
              pool = {
                current = { date = time_now; pool = #REWARD; };
                history = Array.append(question.pool.history, [ question.pool.current ]);
              };
              categorization = question.categorization;
            };
          };
        };
      };
    };
  };

  public func archiveQuestion(register: QuestionRegister, reward_duration: Time, time_now: Time) : ?Question {
    switch (Queries.entries(register.per_pool.reward_rbts, #POOL_DATE).next()){
      case(null){ null; };
      case(?key_val){
        switch(Trie.get(register.questions, Types.keyNat(key_val.0.id), Nat.equal)){
          case(null){ null; };
          case(?question){
            if (question.pool.current.date + reward_duration > time_now) { null; }
            else {
              ?{
                id = question.id;
                author = question.author;
                title = question.title;
                text = question.text;
                date = question.date;
                endorsements = question.endorsements;
                pool = {
                  current = { date = time_now; pool = #ARCHIVE; };
                  history = Array.append(question.pool.history, [ question.pool.current ]);
                };
                categorization = {
                  current = { date = time_now; categorization = #ONGOING(Trie.empty<Principal, [OrientedCategory]>()); };
                  history = Array.append(question.categorization.history, [ question.categorization.current ]);
                };
              };
            };
          };
        };
      };
    };
  };

  public func closeCategorization(
    register: QuestionRegister,
    categorization_duration: Time,
    time_now: Time,
    definitions: CategoriesDefinition,
    aggregation_params: AggregationParameters
  ) : ?Question {
    // Get the oldest question currently being categorized
    switch (Queries.entries(register.per_categorization.ongoing_rbts, #CATEGORIZATION_DATE).next()){
      case(null){ null; };
      case(?key_val){
        // Find the question from the question ID
        switch(Trie.get(register.questions, Types.keyNat(key_val.0.id), Nat.equal)){
          case(null){ null; }; // @todo: trap instead?
          case(?question){
            switch(question.categorization.current.categorization){
              case(#ONGOING(categorizations)){
                // If enough time has passed (categorization_duration), aggregate the votes and put categorization at done
                if (question.categorization.current.date + categorization_duration > time_now) { null; }
                else {
                  let categories = Categories.computeAggregation(definitions, aggregation_params, categorizations);
                  ?{
                    id = question.id;
                    author = question.author;
                    title = question.title;
                    text = question.text;
                    date = question.date;
                    endorsements = question.endorsements;
                    pool = question.pool;
                    categorization = {
                      current = { date = time_now; categorization = #DONE(categories); };
                      history = Array.append(question.categorization.history, [ question.categorization.current ]);
                    };
                  };
                };
              };
              case(_){ null; }; // @todo: trap instead?
            };
          };
        };
      };
    };
  };

};