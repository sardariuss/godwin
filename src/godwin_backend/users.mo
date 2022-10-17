import Types "types";
import Questions "questions/questions";
import Opinions "votes/opinions";
import StageHistory "stageHistory";

import Trie "mo:base/Trie";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Float "mo:base/Float";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Option "mo:base/Option";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Principal = Principal.Principal;
  // For convenience: from types module
  type User = Types.User;
  type Question = Types.Question;
  type Category = Types.Category;
  type Categorization = Types.Categorization;
  type Opinion = Types.Opinion;
  type CategorizationArray = Types.CategorizationArray;
  // For convenience: from other modules
  type Questions = Questions.Questions;
  type Opinions = Opinions.Opinions;

  type Register = Trie<Principal, User>;
  type CursorMean = {
    dividend: Float;
    divisor: Float;
  };
  type CategorizationMeans = Trie<Category, CursorMean>;

  public func emptyRegister() : Register {
    Trie.empty<Principal, User>();
  };

  public func empty(): Users {
    Users(emptyRegister());
  };

  public class Users(register: Register) {

    var register_ = register;

    public func getRegister() : Register {
      register_;
    };

    public func putUser(user: User) {
      if (Principal.isAnonymous(user.principal)){
        Debug.trap("Cannot put a user which principal is anonymous.");
      };
      register_ := Trie.put(register_, Types.keyPrincipal(user.principal), Principal.equal, user).0;
    };

    public func getUser(principal: Principal) : ?User {
      if (Principal.isAnonymous(principal)){
        return null;
      };
      switch(Trie.get(register_, Types.keyPrincipal(principal), Principal.equal)){
        case(?user){ ?user; };
        case(null){
          let new_user = {
            principal = principal;
            name = null;
            // Important: set convictions.to_update to true, because the associated principal could have already voted
            convictions = { to_update = true; categorization = Trie.empty<Category, Float>(); } 
          };
          putUser(new_user);
          ?new_user;
        };
      };
    };

    public func pruneConvictions(opinions: Opinions, question_id: Nat) {
      for ((principal, user) in Trie.iter(register)){
        switch(opinions.getForUserAndQuestion(principal, question_id)){
          case(null){};
          case(?opinion){
            let updated_user = {
              principal = user.principal;
              name = user.name;
              convictions = { to_update = true; categorization = user.convictions.categorization; };
            };
            putUser(updated_user);
          };
        };
      };
    };

    public func updateConvictions(user: User, questions: Questions, opinions: Opinions) {
      if (user.convictions.to_update){
        let updated_user = {
          principal = user.principal;
          name = user.name;
          convictions = { to_update = false; categorization = computeCategorization(questions, opinions.getForUser(user.principal)); };
        };
        putUser(updated_user);
      };
    };

  };

  func computeCategorization(questions: Questions, user_opinions: Trie<Nat, Opinion>) : Categorization {
    var means = Trie.empty<Category, CursorMean>();
    // Iterate on the questions the user gave his opinion on
    for ((question_id, opinion) in Trie.iter(user_opinions)){
      let question = questions.getQuestion(question_id);
      // Check the categorization stage of the question
      switch(StageHistory.getActiveStage(question.categorization_stage).stage){
        case(#DONE(question_categorization)){
          means := addCategorization(means, question_categorization, getOpinionCoef(opinion));
        };
        case(_){}; // Ignore questions which categorization is not complete
      };
    };
    // "Aggregate" the means (i.e. compute the mean from accumulated dividend and divisor)
    aggregateMeans(means);
  };

  // Note: there is no check if the categorization is well-formed, but normally it should always be at this stage
  // (even an empty categorization shall have all a cursor for each defined category)
  // @todo: too risky to not check ?
  func addCategorization(means: CategorizationMeans, categorization: CategorizationArray, coef: Float) : CategorizationMeans {
    var updated_means = means;
    for ((category, cursor) in Array.vals(categorization)){
      let current_mean = Option.get(Trie.get(means, Types.keyText(category), Text.equal), { dividend = 0.0; divisor = 0.0; });
      let updated_mean = {
        dividend = current_mean.dividend + coef * cursor;
        divisor = current_mean.divisor + Float.abs(cursor);
      };
      updated_means := Trie.put(updated_means, Types.keyText(category), Text.equal, updated_mean).0;
    };
    updated_means;
  };

  func aggregateMeans(means: CategorizationMeans) : Categorization {
    var categorization = Trie.empty<Category, Float>();
    for ((category, mean) in Trie.iter(means)){
      var aggregate = 0.0;
      if (mean.divisor > 0.0) {
        aggregate := mean.dividend / mean.divisor;
      };
      categorization := Trie.put(categorization, Types.keyText(category), Text.equal, aggregate).0;
    };
    categorization;
  };

  func getOpinionCoef(opinion: Opinion) : Float {
    switch(opinion){
      case(#AGREE(agreement)){
        switch(agreement){
          case(#ABSOLUTE){  1.0; };
          case(#MODERATE){  0.5; };
        };
      };
      case(#NEUTRAL)     {  0.0; };
      case(#DISAGREE(agreement)){
        switch(agreement){
          case(#MODERATE){ -0.5; };
          case(#ABSOLUTE){ -1.0; };
        };
      };
    };
  };

};