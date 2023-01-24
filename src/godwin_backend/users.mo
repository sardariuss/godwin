import Types "types";
import Utils "utils";
import Polarization "representation/polarization";
import Cursor "representation/cursor";
import CategoryPolarizationTrie "representation/categoryPolarizationTrie";
import WMap "wrappers/WMap";
import Opinion "votes/opinion";
import Categorization "votes/categorization";
import StatusInfoHelper "StatusInfoHelper";
import Questions "questions/questions";

import Map "mo:map/Map";

import Trie "mo:base/Trie";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Debug "mo:base/Debug";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Float "mo:base/Float";
import TrieSet "mo:base/TrieSet";
import Iter "mo:base/Iter";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Principal = Principal.Principal;

  type Map<K, V> = Map.Map<K, V>;

  // For convenience: from types module
  type User = Types.User;
  type Question = Types.Question;
  type Category = Types.Category;
  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;
  type CategoryPolarizationTrie = Types.CategoryPolarizationTrie;
  type Decay = Types.Decay;
  type WMap<K, V> = WMap.WMap<K, V>;
  type Questions = Questions.Questions;
  type Categorizations = Categorization.Categorizations;
  type Opinions = Opinion.Opinions;
  type QuestionStatus = Types.QuestionStatus;

  public func build(
    register: Map<Principal, User>,
    decay_params: ?Decay,
    questions: Questions,
    opinions: Opinions,
    categorizations: Categorizations
  ) : Users {
    let users = Users(WMap.WMap(register, Map.phash), decay_params);

    questions.addObs(func(old: ?Question, new: ?Question) {
      let old_status = Option.map(old, func(question: Question): QuestionStatus { question.status_info.current.status; });
      let new_status = Option.map(new, func(question: Question): QuestionStatus { question.status_info.current.status; });
      if (not Utils.equalOpt(old_status, new_status, Types.equalQuestionStatus)){
        Option.iterate(new, func(question: Question) {
          if (question.status_info.current.status == #CLOSED){
            users.updateConvictions(question, opinions, categorizations);
          };
        });
      };
    });

    users;
  };

  public class Users(register_: WMap<Principal, User>, decay_params_: ?Decay) {

    public func getDecay() : ?Decay {
      decay_params_;
    };

    /// Get the user associated with the given principal.
    /// \param[in] principal The principal associated to the user.
    /// \trap If the given principal is anonymous
    /// \return The user if in the register
    public func getUser(principal: Principal) : User {
      switch(findUser(principal)){
        case(null) { Debug.trap("The user does not exist."); };
        case(?user) { user; };
      };
    };

    /// Find the user associated with the given principal or create it 
    /// if it is not in the register.
    /// \param[in] principal The principal associated to the user.
    /// \return Null if the principal is anonymous, the user otherwise.
    public func findUser(principal: Principal) : ?User {
      register_.get(principal);
    };

    public func setUserName(principal: Principal, name: Text) {
      register_.set(principal, {getUser(principal) with name = ?name; });
    };

    public func getOrCreateUser(principal: Principal, categories: [Category]) : User {
      if (Principal.isAnonymous(principal)){
        Debug.trap("User's principal cannot be anonymous.");
      };
      switch (register_.get(principal)){
        case(?user) { user; };
        case(null) {
          let new_user = {
            principal;
            name = null;
            convictions = CategoryPolarizationTrie.nil(categories);
          };
          putUser(new_user);
          new_user;
        };
      };
    };

    /// Put the user in the register.
    /// \param[in] user The user to put in the register.
    /// \trap If the user principal is anonymous.
    public func putUser(user: User) {
      if (Principal.isAnonymous(user.principal)){
        Debug.trap("User's principal cannot be anonymous.");
      };
      register_.set(user.principal, user);
    };

    public func removeCategory(category: Category) {
      register_.forEach(func(principal, user) {
        putUser({ user with convictions = Trie.remove(user.convictions, Types.keyText(category), Text.equal).0 });
      });
    };

    public func addCategory(category: Category) {
      register_.forEach(func(principal, user) {
        putUser({ user with convictions = Trie.put(user.convictions, Types.keyText(category), Text.equal, Polarization.nil()).0 });
      });
    };

    // Warning: assumes that the question is not closed yet but will be after convictions have been updated
    public func updateConvictions(question: Question, opinions: Opinions, categorizations: Categorizations) {

      let status_info = StatusInfoHelper.build(question.status_info);

      let new_categorization = categorizations.getVote(question.id, status_info.getIteration(#VOTING(#CATEGORIZATION)));
      let new_opinion = opinions.getVote(question.id, status_info.getIteration(#VOTING(#OPINION)));

      let opinion_iteration = status_info.getIteration(#VOTING(#OPINION)) - 1;
      let categorization_iteration = status_info.getIteration(#VOTING(#CATEGORIZATION)) - 1;

      // Process the ballos from the question's history of iterations
      if (categorization_iteration > 0 and opinion_iteration > 0){
        // The categorization used to compute all convictions from the history is the last one
        let old_categorization = categorizations.getVote(question.id, categorization_iteration);
        for (opinion_it in Iter.range(0, opinion_iteration)){
          let old_opinion = opinions.getVote(question.id, opinion_it);
          for ((principal, {answer; date;}) in Map.entries(old_opinion.ballots)){
            putUser(updateBallotContribution(getUser(principal), answer, date, new_categorization.aggregate, ?old_categorization.aggregate));
          };
        };
      };

      for ((principal, {answer; date;}) in Map.entries(new_opinion.ballots)){
        putUser(updateBallotContribution(getUser(principal), answer, date, new_categorization.aggregate, null));
      };
    };

    // \note To compute the users convictions, the user's opinion (cursor converted into a polarization) 
    // is multiplied by the categorization (polarization converted into a cursor)
    // This is done for every category using a trie of polarization initialized with the opinion.
    // The CategoryPolarizationTrie.mul uses a leftJoin, so that the resulting convictions contains
    // only the categories from the definitions.
    func updateBallotContribution(user: User, opinion: Cursor, date: Int, new: CategoryPolarizationTrie, old: ?CategoryPolarizationTrie) : User {
      // Get the categories from the convictions
      let categories = TrieSet.toArray(CategoryPolarizationTrie.keys(user.convictions));
      
      // Create a Polarization trie from the cursor, based on given categories.
      let opinion_trie = Utils.make(categories, Types.keyText, Text.equal, Cursor.toPolarization(opinion));

      // Compute the decay coefficient
      let decay_coef = Option.getMapped(decay_params_, func(params: Decay) : Float { Float.exp(Float.fromInt(date) * params.lambda - params.shift); }, 1.0);

      // Add the opinion times new categorization.
      var contribution = CategoryPolarizationTrie.mul(
        CategoryPolarizationTrie.mulCategoryCursorTrie(opinion_trie, CategoryPolarizationTrie.toCategoryCursorTrie(new)),
        decay_coef);

      // Remove the opinion times old categorization if any.
      Option.iterate(old, func(old_cat: CategoryPolarizationTrie) {
        let old_contribution = CategoryPolarizationTrie.mul(
          CategoryPolarizationTrie.mulCategoryCursorTrie(opinion_trie, CategoryPolarizationTrie.toCategoryCursorTrie(old_cat)),
          decay_coef);
        contribution := CategoryPolarizationTrie.sub(contribution, old_contribution);
      });

      { user with convictions = CategoryPolarizationTrie.add(user.convictions, contribution); };
    };

  };

};