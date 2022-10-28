import Types "types";
import Questions "questions/questions";
import Opinions "votes/opinions";
import StageHistory "stageHistory";
import Utils "utils";

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
    // @todo: have neutral
  };
  type CategorizationMeans = Trie<Category, CursorMean>;

  public func empty(): Users {
    Users(Trie.empty<Principal, User>());
  };

  public class Users(register: Register) {

    /// Members
    var register_ = register;

    public func share() : Register {
      register_;
    };

    public func getUser(principal: Principal) : User {
      switch(findUser(principal)){
        case(null) { Debug.trap("The user does not exist."); };
        case(?user) { user; };
      };
    };

    public func findUser(principal: Principal) : ?User {
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
            convictions = { to_update = true; categorization = []; } 
          };
          putUser(new_user);
          ?new_user;
        };
      };
    };

    public func pruneConvictions(opinions: Opinions, question_id: Nat) {
      for ((principal, user) in Trie.iter(register_)){
        switch(opinions.getForUserAndQuestion(principal, question_id)){
          case(null){};
          case(?opinion){
            putUser({
              principal = user.principal;
              name = user.name;
              convictions = { to_update = true; categorization = user.convictions.categorization; };
            });
          };
        };
      };
    };

    public func updateConvictions(user: User, questions: Questions, opinions: Opinions) {
      if (user.convictions.to_update){
        putUser({
          principal = user.principal;
          name = user.name;
          convictions = { to_update = false; categorization = computeCategorization(questions, opinions.getForUser(user.principal)); };
        });
      };
    };

    func putUser(user: User) {
      if (Principal.isAnonymous(user.principal)){
        Debug.trap("User's principal cannot be anonymous.");
      };
      register_ := Trie.put(register_, Types.keyPrincipal(user.principal), Principal.equal, user).0;
    };

  };

  func computeCategorization(questions: Questions, user_opinions: Trie<Nat, Opinion>) : CategorizationArray {
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
    Utils.trieToArray(aggregateMeans(means));
  };

  // Note: at this stage the categorizations are guaranteed to be well-formed (because only well-formed categorizations
  // can be put in the categorizations register)
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