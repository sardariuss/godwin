import Types "types";
import Votes "votes";
import Convictions "convictions";
import Questions "questions/questions";

import Trie "mo:base/Trie";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Array "mo:base/Array";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Iter<T> = Iter.Iter<T>;
  type Principal = Principal.Principal;

  // For convenience: from types module
  type User = Types.User;
  type ArrayConvictions = Types.ArrayConvictions;
  type Question = Types.Question;
  type VoteRegister<B> = Types.VoteRegister<B>;
  type Opinion = Types.Opinion;
  type Category = Types.Category;
  type Conviction = Types.Conviction;

  // For convenience: from other modules
  type QuestionRegister = Questions.QuestionRegister;

  public type UserRegister = Trie<Principal, User>;

  public func empty() : UserRegister {
    Trie.empty<Principal, User>();
  };

  public func getUser(register: UserRegister, principal: Principal) : ?User {
    Trie.get(register, Types.keyPrincipal(principal), Principal.equal);
  };

  public func putUser(register: UserRegister, user: User) : (UserRegister, ?User) {
    Trie.put(register, Types.keyPrincipal(user.principal), Principal.equal, user);
  };

  public func newUser(principal: Principal) : User {
    // Important: set convictions.to_update to true, because the associated principal could have already voted
    { principal = principal; name = null; convictions = { to_update = true; array = []; } };
  };

  public func pruneConvictions(register: UserRegister, votes: VoteRegister<Opinion>, question: Question) : Trie<Principal, User>{
    var users = Trie.empty<Principal, User>();
    for ((principal, user) in Trie.iter(register)){
      switch(Votes.getBallot(votes, principal, question.id)){
        case(null){};
        case(?opinion){
          let updated_user = {
            principal = user.principal;
            name = user.name;
            convictions = { to_update = true; array = user.convictions.array; };
          };
          users := Trie.put(users, Types.keyPrincipal(user.principal), Principal.equal, updated_user).0;
        };
      };
    };
    users;
  };

  // Watchout: O(n) where n is the number of questions
  // @todo: iter only on categorized questions
  public func computeUserConvictions(user: User, register: QuestionRegister, votes: VoteRegister<Opinion>, moderate_opinion_coef: Float) : User {
    if (not user.convictions.to_update){ user; }
    else {
      var convictions = Trie.empty<Category, Conviction>();
      for ((question_id, opinion) in Trie.iter(Votes.getUserBallots(votes, user.principal))){
        switch(Trie.get(register.questions, Types.keyNat(question_id), Nat.equal)){
          case(null){};
          case(?question){
            switch(question.categorization.current.categorization){
              case(#DONE(oriented_categories)){
                for (oriented_category in Array.vals(oriented_categories)){
                  convictions := Convictions.addConviction(convictions, oriented_category, opinion, moderate_opinion_coef);
                };
              };
              case(_){};
            };
          };
        }
      };
      {
        principal = user.principal;
        name = user.name;
        convictions = { to_update = false; array = Convictions.toArray(convictions);};
      };
    };
  };

};