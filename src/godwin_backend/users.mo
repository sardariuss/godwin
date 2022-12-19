import Types "types";
import Utils "utils";
import Polarization "representation/polarization";
import Cursor "representation/cursor";
import CategoryPolarizationTrie "representation/categoryPolarizationTrie";

import Trie "mo:base/Trie";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Debug "mo:base/Debug";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Float "mo:base/Float";

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

  public type Register = Trie<Principal, User>;

  // October 2096
  let MAX_DATE = 4_000_000_000_000_000_000;

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

  public func addCategory(register: Register, category: Category) : Register {
    var updated_register = Trie.clone(register);
    for ((principal, user) in Trie.iter(register)) {
      updated_register := putUser(updated_register, { user with convictions = Trie.put(user.convictions, Types.keyText(category), Text.equal, Polarization.nil()).0 });
    };
    updated_register;
  };

  // Warning: assumes that the question is not closed yet but will be after convictions have been updated
  public func updateConvictions(register: Register, new_iteration: Iteration, old_iterations: [Iteration], categories: [Category], decay: ?Float) : Register {
    var updated_register = Trie.clone(register);

    let new_categorization = new_iteration.categorization.aggregate;

    // Process the ballos from the question's history of iterations
    if (old_iterations.size() > 0){
      // The categorization used to compute all convictions from the history is the last one
      let old_categorization = old_iterations[old_iterations.size() - 1].categorization.aggregate;
      for (old_iteration in Array.vals(old_iterations)){
        for ((principal, opinion) in Trie.iter(old_iteration.opinion.ballots))
        {
          updated_register := putUser(
            updated_register, 
            updateBallotContribution(getUser(updated_register, principal), opinion, old_iteration.opinion.date, categories, decay, new_categorization, ?old_categorization)
          );
        };
      };
    };

    // Process the ballos from the question's current iteration
    for ((principal, opinion) in Trie.iter(new_iteration.opinion.ballots)) {
      updated_register := putUser(
        updated_register, 
        updateBallotContribution(getUser(updated_register, principal), opinion, new_iteration.opinion.date, categories, decay, new_categorization, null)
      );
    };

    updated_register;
  };

  func updateBallotContribution(user: User, opinion: Cursor, date: Int, categories: [Category], decay: ?Float, new: CategoryPolarizationTrie, old: ?CategoryPolarizationTrie) : User {
    // Create a Polarization trie from the cursor, based on given categories.
    let opinion_trie = Utils.make(categories, Types.keyText, Text.equal, Cursor.toPolarization(opinion));

    // Compute the decay coefficient
    let normalized_date = Float.fromInt(date) / Float.fromInt(MAX_DATE); // To have a time < 1 to avoid exponential to overflow
    let decay_coef = Option.getMapped(decay, func(lambda: Float) : Float { Float.exp(lambda * normalized_date); }, 1.0);

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