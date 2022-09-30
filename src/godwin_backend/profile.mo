import Questions "questions/questions";
import Types "types";

import Float "mo:base/Float";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Nat "mo:base/Nat";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;

  // For convenience: from types module
  type Profile = Types.Profile;
  type Category = Types.Category;
  type Opinion = Types.Opinion;

  // For convenience: from other modules
  type QuestionRegister = Questions.QuestionRegister;

  public func computeQuestionProfile(categorization: Trie<Principal, Profile>) : Profile {
    var question_profile = Trie.empty<Category, Float>();
    // Add the profiles given by all the users
    for ((_, given_profile) in Trie.iter(categorization)){
      question_profile := addProfile(question_profile, given_profile, 1.0);
    };
    // Normalize the summed profiles
    normalizeSummedProfiles(question_profile, Trie.size(categorization));
  };

  // @todo: iter only on categorized questions
  public func computeUserProfile(register: QuestionRegister, opinions: Trie<Nat, Opinion>, moderate_opinion_coef: Float) : Profile {
    var user_profile = Trie.empty<Category, Float>();
    var num_questions : Nat = 0;
    // Add the profiles of the questions the user voted on
    for ((question_id, opinion) in Trie.iter(opinions)){
      switch(Trie.get(register.questions, Types.keyNat(question_id), Nat.equal)){
        case(null){};
        case(?question){
          switch(question.categorization.current.categorization){
            case(#DONE(question_profile)){
              user_profile := addProfile(user_profile, question_profile, getOpinionCoef(opinion, moderate_opinion_coef));
              num_questions += 1;
            };
            case(_){};
          };
        };
      };
    };
    // Normalize the summed profiles
    normalizeSummedProfiles(user_profile, num_questions);
  };

  func addProfile(summed_profile: Profile, profile: Profile, coef: Float) : Profile {
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

  func getOpinionCoef(opinion: Opinion, moderate_coef: Float) : Float {
    switch(opinion){
      case(#AGREE(agreement)){
        switch(agreement){
          case(#ABSOLUTE){       1.0;       };
          case(#MODERATE){  moderate_coef;  };
        };
      };
      case(#NEUTRAL)     {       0.0;       };
      case(#DISAGREE(agreement)){
        switch(agreement){
          case(#MODERATE){  -moderate_coef; };
          case(#ABSOLUTE){      -1.0;       };
        };
      };
    };
  };

};