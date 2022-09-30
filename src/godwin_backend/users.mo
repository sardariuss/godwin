import Types "types";
import Votes "votes";
import Questions "questions/questions";
import Profile "profile";

import Trie "mo:base/Trie";
import Principal "mo:base/Principal";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;

  type Principal = Principal.Principal;

  // For convenience: from types module
  type User = Types.User;
  type Question = Types.Question;
  type VoteRegister<B> = Types.VoteRegister<B>;
  type Opinion = Types.Opinion;
  type Category = Types.Category;

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
    { principal = principal; name = null; convictions = { to_update = true; profile = Trie.empty<Category, Float>(); } };
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
            convictions = { to_update = true; profile = user.convictions.profile; };
          };
          users := Trie.put(users, Types.keyPrincipal(user.principal), Principal.equal, updated_user).0;
        };
      };
    };
    users;
  };

  public func updateConvictions(user: User, register: QuestionRegister, votes: VoteRegister<Opinion>, moderate_opinion_coef: Float) : User {
    if (user.convictions.to_update){
      {
        principal = user.principal;
        name = user.name;
        convictions = { to_update = false; profile = Profile.computeUserProfile(register, Votes.getUserBallots(votes, user.principal), moderate_opinion_coef); };
      };
    } else {
      user;
    };
  };

};