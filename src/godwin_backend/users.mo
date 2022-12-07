import Types "types";
import Utils "utils";
import Polarization "representation/polarization";
import Cursor "representation/cursor";
import CategoryPolarizationTrie "representation/categoryPolarizationTrie";
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
  type Iteration = Types.Iteration;
  type CategoryPolarizationTrie = Types.CategoryPolarizationTrie;
  type QuestionIterations = Types.QuestionIterations;

  type Register = Trie<Principal, User>;

  public func empty() : Register {
    Trie.empty<Principal, User>();
  };

  /// Get the user associated with the given principal.
  /// \param[in] principal The principal associated to the user.
  /// \trap If the given principal is anonymous
  /// \return The user if in the register
  public func getUser(register: Register, principal: Principal) : User {
    switch(findUser(register, principal)){
      case(null) { Debug.trap("The user does not exist."); };
      case(?user) { user; };
    };
  };

  /// Find the user associated with the given principal or create it 
  /// if it is not in the register.
  /// \param[in] principal The principal associated to the user.
  /// \return Null if the principal is anonymous, the user otherwise.
  public func findUser(register: Register, principal: Principal) : ?User {
    Trie.get(register, Types.keyPrincipal(principal), Principal.equal);
  };

  public func getOrCreateUser(register: Register, principal: Principal, categories: [Category]) : (Register, User) {
    if (Principal.isAnonymous(principal)){
      Debug.trap("User's principal cannot be anonymous.");
    };
    let user = Option.get(Trie.get(register, Types.keyPrincipal(principal), Principal.equal),
      {
        principal;
        name = null;
        convictions = CategoryPolarizationTrie.nil(categories);
      }
    );
    (
      putUser(register, user),
      user
    );
  };

  /// Put the user in the register.
  /// \param[in] user The user to put in the register.
  /// \trap If the user principal is anonymous.
  public func putUser(register: Register, user: User) : Register {
    if (Principal.isAnonymous(user.principal)){
      Debug.trap("User's principal cannot be anonymous.");
    };
    Trie.put(register, Types.keyPrincipal(user.principal), Principal.equal, user).0;
  };

  public func removeCategory(register: Register, category: Category) : Register {
    var updated_register = Trie.clone(register);
    for ((principal, user) in Trie.iter(register)) {
      updated_register := putUser(updated_register, { user with convictions = Trie.remove(user.convictions, Types.keyText(category), Text.equal).0 });
    };
    updated_register;
  };

  public func updateConvictions(register: Register, question_iterations: QuestionIterations, categories: [Category], iterations: Iterations.Register) : Register {
    var updated_register = Trie.clone(register);

    let current_iteration = Iterations.get(iterations, question_iterations.current);
    assert(current_iteration.voting_stage == #COMPLETE);
    let categorization = Iteration.unwrapCategorization(current_iteration).aggregate;

    // Process the ballos from the question's history of iterations
    for (iteration_id in Array.vals(question_iterations.history)){
      let iteration = Iterations.get(iterations, iteration_id);
      let old_categorization = Iteration.unwrapCategorization(iteration).aggregate;
      for ((principal, opinion) in Trie.iter(Iteration.unwrapOpinion(iteration).ballots))
      {
        updated_register := putUser(
          updated_register, 
          updateBallotContribution(getUser(updated_register, principal), opinion, categories, categorization, ?old_categorization)
        );
      };
    };

    // Process the ballos from the question's current iteration
    for ((principal, opinion) in Trie.iter(Iteration.unwrapOpinion(current_iteration).ballots)) {
      updated_register := putUser(
        updated_register, 
        updateBallotContribution(getUser(updated_register, principal), opinion, categories, categorization, null)
      );
    };

    updated_register;
  };

  func updateBallotContribution(user: User, opinion: Cursor, categories: [Category], new: CategoryPolarizationTrie, old: ?CategoryPolarizationTrie) : User {
    // Create a Polarization trie from the cursor, based on given categories.
    let opinion_trie = Utils.make(categories, Types.keyText, Text.equal, Cursor.toPolarization(opinion));

    // Add the opinion times new categorization.
    var contribution = CategoryPolarizationTrie.mulCategoryCursorTrie(opinion_trie, CategoryPolarizationTrie.toCategoryCursorTrie(new));

    // Remove the opinion times old categorization if any.
    Option.iterate(old, func(old_cat: CategoryPolarizationTrie) {
      let old_contribution = CategoryPolarizationTrie.mulCategoryCursorTrie(opinion_trie, CategoryPolarizationTrie.toCategoryCursorTrie(old_cat));
      contribution := CategoryPolarizationTrie.sub(contribution, old_contribution);
    });

    { user with convictions = CategoryPolarizationTrie.add(user.convictions, contribution); };
  };

};