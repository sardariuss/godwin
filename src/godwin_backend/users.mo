import Types "types";
import Questions "questions/questions";
import Opinions "votes/opinions";
import StageHistory "stageHistory";
import Utils "utils";
import Polarization "representation/polarization";
import Cursor "representation/cursor";

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

  // For convenience: from other modules
  type Questions = Questions.Questions;
  type Opinions = Opinions.Opinions;

  type Register = Trie<Principal, User>;

  public func empty(): Users {
    Users(Trie.empty<Principal, User>());
  };

  /// 
  public class Users(register: Register) {

    /// Map of <key=Principal, value=User>
    var register_ = register;

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
            // Important: set convictions.to_update to true, because the principal could have already voted
            // before findUser is called (we don't want to assume the frontend called findUser right after the
            // user logged in).
            convictions = { to_update = true; array = []; };
          };
          putUser(new_user);
          ?new_user;
        };
      };
    };

    /// Prune the convictions of the users who gave their opinions on the question.
    /// In this context, pruning means putting the convictions.to_update flag to false,
    /// so the users' convictions need to be re-computed.
    /// \param[in] opinions The voting register of opinions.
    /// \param[in] question_id The question identifier.
    public func pruneConvictions(opinions: Opinions, question_id: Nat) {
      for ((principal, user) in Trie.iter(register_)){
        switch(opinions.getForUserAndQuestion(principal, question_id)){
          case(null){};
          case(?opinion){
            putUser({
              principal = user.principal;
              name = user.name;
              convictions = { to_update = true; array = user.convictions.array; };
            });
          };
        };
      };
    };

    /// Update the convictions of the user, i.e. computes the user's specific polarization for each 
    /// category based on the opinion he gave on the questions and the final categorization the community
    /// has decided for this question.
    /// \param[in] user The user which convictions to update.
    /// \param[in] questions The register of questions.
    /// \param[in] opinions The register of opinions.
    /// \return The update user if his convictions needed to be updated, null otherwise.
    public func updateConvictions(principal: Principal, questions: Questions, opinions: Opinions) : ?User {
      var user = getUser(principal);
      if (user.convictions.to_update){
        user := {
          principal = user.principal;
          name = user.name;
          convictions = { to_update = false; array = computeConvictions(questions, opinions.getForUser(user.principal)); };
        };
        putUser(user);
        ?user;
      } else {
        null;
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

  };

  /// Compute the user's convictions (i.e. polarization for each category) based on 
  /// the opinion he gave on the questions he voted upon and the final categorization 
  /// the community has decided for these questions.
  /// \param[in] questions The register of questions.
  /// \param[in] user_opinions The opinions the user gave for each question he voted on.
  /// \return The up-to-date user's convictions as an array: [(Category, Polarization)]
  func computeConvictions(questions: Questions, user_opinions: Trie<Nat, Cursor>) : CategoryPolarizationArray {
    var convictions = Trie.empty<Category, Polarization>();
    // Iterate on the questions the user gave his opinion on.
    for ((question_id, opinion_cursor) in Trie.iter(user_opinions)){
      let question = questions.getQuestion(question_id);
      // Check the categorization stage of the question.
      switch(StageHistory.getActiveStage(question.categorization_stage).stage){
        case(#DONE(question_categorization)){
          // Iterate on the categories.
          for ((category, question_polarization) in Array.vals(question_categorization)){
            // It is possible to have a nil polarization (if nobody voted, or if some users voted but then removed their vote).
            // It shouldn't be added because Polarization.toCursor would trap (there is no cursor to reprensent a nil polarization indeed).
            if (not Polarization.isNil(question_polarization)){
              var category_conviction = Option.get(Trie.get(convictions, Types.keyText(category), Text.equal), Polarization.nil());
              // Add the opinion cursor to the convictions, which will be "softened" by how "extreme" the question polarization was.
              category_conviction := Polarization.add(category_conviction, 
                Polarization.mul(Cursor.toPolarization(opinion_cursor), Polarization.toCursor(question_polarization)));
              // Update the conviction for this category in the trie.
              convictions := Trie.put(convictions, Types.keyText(category), Text.equal, category_conviction).0;
            };
          };
        };
        case(_){}; // Ignore the questions which categorization is not done.
      };
    };
    Utils.trieToArray(convictions);
  };

};