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
import TrieSet "mo:base/TrieSet";

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
  type DecayParams = Types.DecayParams;

  public type Register = {
    var users : Trie<Principal, User>;
  };

  public func initRegister() : Register {
    {
      var users = Trie.empty<Principal, User>();
    };
  };

  public class Users(register: Register) {

    let register_ = register;

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
      Trie.get(register_.users, Types.keyPrincipal(principal), Principal.equal);
    };

    public func setUserName(principal: Principal, name: Text) {
      putUser({getUser(principal) with name = ?name; });
    };

    public func getOrCreateUser(principal: Principal, categories: [Category]) : User {
      if (Principal.isAnonymous(principal)){
        Debug.trap("User's principal cannot be anonymous.");
      };
      let user = Option.get(Trie.get(register_.users, Types.keyPrincipal(principal), Principal.equal),
        {
          principal;
          name = null;
          convictions = CategoryPolarizationTrie.nil(categories);
        }
      );
      putUser(user);
      user;
    };

    /// Put the user in the register.
    /// \param[in] user The user to put in the register.
    /// \trap If the user principal is anonymous.
    public func putUser(user: User) {
      if (Principal.isAnonymous(user.principal)){
        Debug.trap("User's principal cannot be anonymous.");
      };
      register_.users := Trie.put(register_.users, Types.keyPrincipal(user.principal), Principal.equal, user).0;
    };

    public func removeCategory(category: Category) {
      for ((principal, user) in Trie.iter(register_.users)) {
        putUser({ user with convictions = Trie.remove(user.convictions, Types.keyText(category), Text.equal).0 });
      };
    };

    public func addCategory(category: Category) {
      for ((principal, user) in Trie.iter(register_.users)) {
        putUser({ user with convictions = Trie.put(user.convictions, Types.keyText(category), Text.equal, Polarization.nil()).0 });
      };
    };

    // Warning: assumes that the question is not closed yet but will be after convictions have been updated
    public func updateConvictions(new_iteration: Iteration, old_iterations: [Iteration], decay_params: ?DecayParams) {

      let new_categorization = new_iteration.categorization.aggregate;

      // Process the ballos from the question's history of iterations
      if (old_iterations.size() > 0){
        // The categorization used to compute all convictions from the history is the last one
        let old_categorization = old_iterations[old_iterations.size() - 1].categorization.aggregate;
        for (old_iteration in Array.vals(old_iterations)){
          for ((principal, opinion) in Trie.iter(old_iteration.opinion.ballots)){
            putUser(updateBallotContribution(getUser(principal), opinion, old_iteration.opinion.date, decay_params, new_categorization, ?old_categorization));
          };
        };
      };

      // Process the ballos from the question's current iteration
      for ((principal, opinion) in Trie.iter(new_iteration.opinion.ballots)) {
        putUser(updateBallotContribution(getUser(principal), opinion, new_iteration.opinion.date, decay_params, new_categorization, null));
      };
    };

    // \note To compute the users convictions, the user's opinion (cursor converted into a polarization) 
    // is multiplied by the categorization (polarization converted into a cursor)
    // This is done for every category using a trie of polarization initialized with the opinion.
    // The CategoryPolarizationTrie.mul uses a leftJoin, so that the resulting convictions contains
    // only the categories from the definitions.
    func updateBallotContribution(user: User, opinion: Cursor, date: Int, decay_params: ?DecayParams, new: CategoryPolarizationTrie, old: ?CategoryPolarizationTrie) : User {
      // Get the categories from the convictions
      let categories = TrieSet.toArray(CategoryPolarizationTrie.keys(user.convictions));
      
      // Create a Polarization trie from the cursor, based on given categories.
      let opinion_trie = Utils.make(categories, Types.keyText, Text.equal, Cursor.toPolarization(opinion));

      // Compute the decay coefficient
      let decay_coef = Option.getMapped(decay_params, func(params: DecayParams) : Float { Float.exp(Float.fromInt(date) * params.lambda - params.shift); }, 1.0);

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