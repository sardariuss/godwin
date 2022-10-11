import Types "types";
import Questions "questions/questions";
import Opinions "votes/opinions";

import Trie "mo:base/Trie";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Float "mo:base/Float";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Principal = Principal.Principal;
  // For convenience: from types module
  type User = Types.User;
  type Question = Types.Question;
  type Category = Types.Category;
  type Profile = Types.Profile;
  type Opinion = Types.Opinion;
  // For convenience: from other modules
  type Questions = Questions.Questions;
  type Opinions = Opinions.Opinions;

  type Register = Trie<Principal, User>;

  public func emptyRegister() : Register {
    Trie.empty<Principal, User>();
  };

  public func empty(): Users {
    Users(emptyRegister());
  };

  public class Users(register: Register) {

    var register_ = register;

    public func getRegister() : Register {
      register_;
    };

    public func getUser(principal: Principal) : ?User {
      Trie.get(register_, Types.keyPrincipal(principal), Principal.equal);
    };

    public func putUser(user: User) {
      register_ := Trie.put(register_, Types.keyPrincipal(user.principal), Principal.equal, user).0;
    };

    public func createUser(principal: Principal) : User {
      let new_user = {
        principal = principal;
        name = null;
        // Important: set convictions.to_update to true, because the associated principal could have already voted
        convictions = { to_update = true; profile = Trie.empty<Category, Float>(); } 
      };
      putUser(new_user);
      new_user;
    };

    public func pruneConvictions(opinions: Opinions, question: Question) {
      for ((principal, user) in Trie.iter(register)){
        switch(opinions.getForUserAndQuestion(principal, question.id)){
          case(null){};
          case(?opinion){
            let updated_user = {
              principal = user.principal;
              name = user.name;
              convictions = { to_update = true; profile = user.convictions.profile; };
            };
            putUser(updated_user);
          };
        };
      };
    };

    // @todo: watchout, user might not exist
    public func updateConvictions(user: User, questions: Questions, opinions: Opinions) : User {
      if (user.convictions.to_update){
        let updated_user = {
          principal = user.principal;
          name = user.name;
          convictions = { to_update = false; profile = computeProfile(questions, opinions.getForUser(user.principal)); };
        };
        putUser(updated_user);
        updated_user;
      } else {
        user;
      };
    };

  };

  func computeProfile(questions: Questions, user_opinions: Trie<Nat, Opinion>) : Profile {
    var user_profile = Trie.empty<Category, Float>();
    var num_questions : Nat = 0;
    // Add the profiles of the questions the user voted on
    for ((question_id, opinion) in Trie.iter(user_opinions)){
      let question = questions.getQuestion(question_id);
      switch(question.categorization.current.categorization){
        case(#DONE(question_profile)){
          user_profile := sumProfile(user_profile, question_profile, getOpinionCoef(opinion));
          num_questions += 1;
        };
        case(_){};
      };
    };
    // Normalize the summed profiles
    normalizeSummedProfiles(user_profile, num_questions);
  };

  func sumProfile(summed_profile: Profile, profile: Profile, coef: Float) : Profile {
    // @todo: what if they don't have the same size and keys ?
    var new_summed_profile = summed_profile;
    for ((category, cursor) in Trie.iter(profile)){
      let summed_cursor = switch (Trie.get(summed_profile, Types.keyText(category), Text.equal)){
        case(null) { 0.0; };
        case(?old_cursor) { old_cursor; };
      };
      new_summed_profile := Trie.put(new_summed_profile, Types.keyText(category), Text.equal, summed_cursor + (cursor * coef)).0;
    };
    new_summed_profile;
  };

  func normalizeSummedProfiles(summed_profile: Profile, num_elements: Nat) : Profile {
    var normalized_profile = summed_profile;
    if (num_elements > 0) {
      for ((category, cursor) in Trie.iter(normalized_profile)){
        normalized_profile := Trie.put(normalized_profile, Types.keyText(category), Text.equal, cursor / Float.fromInt(num_elements)).0;
      };
    };
    normalized_profile;
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