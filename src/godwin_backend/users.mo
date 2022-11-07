import Types "types";
import Questions "questions/questions";
import Opinions "votes/opinions";
import StageHistory "stageHistory";
import Utils "utils";
import Math "math";
import Polarization "representation/polarization";
import CategoryPolarizationTrie "representation/categoryPolarizationTrie";
import Cursor "representation/cursor";

import Trie "mo:base/Trie";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
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
  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;
  type CategoryPolarizationArray = Types.CategoryPolarizationArray;
  type CategoryPolarizationTrie = Types.CategoryPolarizationTrie;
  // For convenience: from other modules
  type Questions = Questions.Questions;
  type Opinions = Opinions.Opinions;
  type WeightedMean<K> = Math.WeightedMean<K>;

  type Register = Trie<Principal, User>;

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
            convictions = { to_update = true; categorization = []; }  // @todo: init with Categories
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

  func computeCategorization(questions: Questions, user_opinions: Trie<Nat, Cursor>) : CategoryPolarizationArray {
    var polarization_means = Trie.empty<Category, WeightedMean<Polarization>>(); // @todo: init with Categories
    // Iterate on the questions the user gave his opinion on
    for ((question_id, opinion_cursor) in Trie.iter(user_opinions)){
      let question = questions.getQuestion(question_id);
      // Check the categorization stage of the question
      switch(StageHistory.getActiveStage(question.categorization_stage).stage){
        case(#DONE(categorization_array)){
          let question_categorization = Utils.arrayToTrie(categorization_array, Types.keyText, Text.equal);
          // It is possible to have a nil categorization (if nobody voted, or if some users voted but removed their vote)
          // They shouldn't be added, because the it could make Polarization.toCursor trap later
          // @todo: should we return a centered cursor in Polarization.toCursor to avoid handling that case?
          if (not CategoryPolarizationTrie.isNil(question_categorization)) {
            polarization_means := addCategorization(polarization_means, question_categorization , opinion_cursor);
          };
        };
        case(_){}; // Ignore questions which categorization is not complete
      };
    };
    // Compute the mean from accumulated dividend and divisor
    Utils.trieToArray(computeMeans(polarization_means));
  };

  func addCategorization(
    user_polarization_trie: Trie<Category, WeightedMean<Polarization>>,
    question_categorization: CategoryPolarizationTrie,
    opinion_cursor: Cursor)
  : Trie<Category, WeightedMean<Polarization>> {
    var updated_means = user_polarization_trie;
    for ((category, polarization) in Trie.iter(question_categorization)){
      // Get the current accumulated weighted mean for this category
      var category_mean = Option.get(
        Trie.get(user_polarization_trie, Types.keyText(category), Text.equal),
        Math.emptyMean<Polarization>(Polarization.nil) // Initialize the mean with a null polarization if no mean is found
      );
      // Add the opinion cursor to the mean, which will be "softened" by how "extreme" the question polarization was 
      category_mean := Math.addToMean<Polarization>(
        category_mean,
        Polarization.add,
        Polarization.mul,
        Cursor.toPolarization(opinion_cursor), // the opinion cursor is transformed into a polarization
        Polarization.toCursor(polarization)); // the question polarization is transformed into a cursor to be used as a weight
      // Replace the mean for this category in the trie
      updated_means := Trie.put(updated_means, Types.keyText(category), Text.equal, category_mean).0;
    };
    updated_means;
  };

  func computeMeans(means: Trie<Category, WeightedMean<Polarization>>) : Trie<Category, Polarization> {
    var categorization = Trie.empty<Category, Polarization>();
    for ((category, mean) in Trie.iter(means)){
      // If all the answered questions are categorized absolutley in the center for a category,
      // the resulting weithed mean will be { dividend = 0; divisor = 0; } for that category.
      // Hence a centered polarization is used to handle this case.
      var final_polarization = { left = 0.0; center = 1.0; right = 0.0 };
      if(mean.divisor > 0.0) {
        final_polarization := Polarization.div(mean.dividend, mean.divisor);
      };
      categorization := Trie.put(categorization, Types.keyText(category), Text.equal, final_polarization).0;
    };
    categorization;
  };

};