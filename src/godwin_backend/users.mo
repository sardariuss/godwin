import Types "types";
import Questions "questions/questions";
import Opinions "votes/opinions";
import StageHistory "stageHistory";
import Utils "utils";
import Polarization "representation/polarization";
import Cursor "representation/cursor";
import CategoryPolarizationTrie "representation/categoryPolarizationTrie";
import Categories "categories";
import Iterations "votes/register";
import Iteration "votes/iteration";

import Trie "mo:base/Trie";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Debug "mo:base/Debug";
import Option "mo:base/Option";
import Array "mo:base/Array";

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
  type Iteration = Types.Iteration;
  type CategoryPolarizationTrie = Types.CategoryPolarizationTrie;

  // For convenience: from other modules
  type Questions = Questions.Questions;
  type Opinions = Opinions.Opinions;
  type Categories = Categories.Categories;
  type UpdateType = Categories.UpdateType;

  type Register = Trie<Principal, User>;

  public func empty(categories: Categories): Users {
    Users(Trie.empty<Principal, User>(), categories);
  };

  public class Users(register: Register, categories: Categories) {

    /// Map of <key=Principal, value=User>
    var register_ = register;
    let categories_ : Categories = categories;

    /// Get the shareable representation of the class.
    /// \return The shareable representation of the class.
    public func share() : Register {
      register_;
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
      if (Principal.isAnonymous(principal)){
        return null;
      };
      switch(Trie.get(register_, Types.keyPrincipal(principal), Principal.equal)){
        case(?user){ ?user; };
        case(null){
          let new_user = {
            principal = principal;
            name = null;
            convictions = CategoryPolarizationTrie.nil(categories_);
          };
          putUser(new_user);
          ?new_user;
        };
      };
    };

    /// Put the user in the register.
    /// \param[in] user The user to put in the register.
    /// \trap If the user principal is anonymous.
    func putUser(user: User) {
      if (Principal.isAnonymous(user.principal)){
        Debug.trap("User's principal cannot be anonymous.");
      };
      register_ := Trie.put(register_, Types.keyPrincipal(user.principal), Principal.equal, user).0;
    };

    public func updateConvictions(question: Question, iterations: Iterations.Register) {
      let current_iteration = Iterations.get(iterations, question.iterations.current);
      assert(current_iteration.voting_stage == #COMPLETE);
      let categorization = Iteration.unwrapCategorization(current_iteration).aggregate;

      // Process the ballos from the question's history of iterations
      for (iteration_id in Array.vals(question.iterations.history)){
        let iteration = Iterations.get(iterations, iteration_id);
        let old_categorization = Iteration.unwrapCategorization(iteration).aggregate;
        for ((principal, opinion) in Trie.iter(Iteration.unwrapOpinion(iteration).ballots))
        {
          updateBallotContribution(getUser(principal), opinion, categories_.share(), categorization, ?old_categorization);
        };
      };

      // Process the ballos from the question's current iteration
      for ((principal, opinion) in Trie.iter(Iteration.unwrapOpinion(current_iteration).ballots)) {
        updateBallotContribution(getUser(principal), opinion, categories_.share(), categorization, null);
      };
    };

    func updateBallotContribution(user: User, opinion: Cursor, categories: [Category], new: CategoryPolarizationTrie, old: ?CategoryPolarizationTrie) {
      // Create a Polarization trie from the cursor, based on given categories.
      let opinion_trie = Utils.make(categories, Types.keyText, Text.equal, Cursor.toPolarization(opinion));

      // Add the opinion times new categorization.
      var contribution = CategoryPolarizationTrie.mulCategoryCursorTrie(opinion_trie, CategoryPolarizationTrie.toCategoryCursorTrie(new));

      // Remove the opinion times old categorization if any.
      Option.iterate(old, func(old_cat: CategoryPolarizationTrie) {
        let old_contribution = CategoryPolarizationTrie.mulCategoryCursorTrie(opinion_trie, CategoryPolarizationTrie.toCategoryCursorTrie(old_cat));
        contribution := CategoryPolarizationTrie.sub(contribution, old_contribution);
      });

      putUser({ user with convictions = CategoryPolarizationTrie.add(user.convictions, contribution); });
    };

    /// Add an observer on the categories at construction, so that every time a category
    /// is removed, it is removed from every use profile.
    categories_.addCallback(func(category: Category, update_type: UpdateType) { 
      if (update_type == #CATEGORY_REMOVED) {
        for ((principal, user) in Trie.iter(register_)) {
          putUser({ user with convictions = Trie.remove(user.convictions, Types.keyText(category), Text.equal).0 });
        };
      };
     });

  };

};