import Types "../types";
import Questions "../questions/questions";
import Question "../questions/question";
import Users "../users";
import User "../user";
import Aggregates "aggregates";

import Trie "mo:base/Trie";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Float "mo:base/Float";

module {
  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  
  // For convenience: from types module
  type Interest = Types.Interest;
  type InterestAggregate = Types.InterestAggregate;
  type User = Types.User;
  type Question = Types.Question;
  
  // For convenience: from other modules
  type Questions = Questions.Questions;
  type Users = Users.Users;

  // Warning: the user and question are assumed to exist! if ever not, they will be added as new
  public func put(users: Users, principal: Principal, questions: Questions, question_id: Nat, new_interest: Interest){
    let user = users.getUser(principal);
    let question = questions.getQuestion(question_id);
    
    let (user_interests, old_interest) = Trie.put(user.ballots.interests, Types.keyNat(question.id), Nat.equal, new_interest);
    users.putUser(User.updateInterests(user, user_interests));
    
    let question_interests = Aggregates.updateAggregate(question.aggregates.interest, ?new_interest, old_interest, addToAggregate, removeFromAggregate);
    questions.replaceQuestion(Question.updateInterestAggregate(question, question_interests));
  };
  
  public func remove(users: Users, principal: Principal, questions: Questions, question_id: Nat){
    let user = users.getUser(principal);
    let question = questions.getQuestion(question_id);
    
    let (user_interests, old_interest) = Trie.remove(user.ballots.interests, Types.keyNat(question.id), Nat.equal);
    users.putUser(User.updateInterests(user, user_interests));

    let question_interests = Aggregates.updateAggregate(question.aggregates.interest, null, old_interest, addToAggregate, removeFromAggregate);
    questions.replaceQuestion(Question.updateInterestAggregate(question, question_interests));
  };

  func addToAggregate(aggregate: InterestAggregate, ballot: Interest) : InterestAggregate {
    var ups = aggregate.ups;
    var downs = aggregate.downs;
    switch(ballot){
      case(#UP){ ups := aggregate.ups + 1; };
      case(#DOWN){ downs := aggregate.downs + 1; };
    };
    { ups; downs; score = computeScore(ups, downs) };
  };

  func removeFromAggregate(aggregate: InterestAggregate, ballot: Interest) : InterestAggregate {
    var ups = aggregate.ups;
    var downs = aggregate.downs;
    switch(ballot){
      case(#UP){ ups := aggregate.ups - 1; };
      case(#DOWN){ downs := aggregate.downs - 1; };
    };
    { ups; downs; score = computeScore(ups, downs) };
  };

  func computeScore(ups: Nat, downs: Nat) : Int {
    if (ups + downs == 0) { return 0; };
    let f_ups = Float.fromInt(ups);
    let f_downs = Float.fromInt(downs);
    let x = f_ups / (f_ups + f_downs);
    let growth_rate = 20.0;
    let mid_point = 0.5;
    // https://stackoverflow.com/a/3787645: this will underflow to 0 for large negative values of x,
    // but that may be OK depending on your context since the exact result is nearly zero in that case.
    let sigmoid = 1.0 / (1.0 + Float.exp(-1.0 * growth_rate * (x - mid_point)));
    Float.toInt(Float.nearest(f_ups * sigmoid - f_downs * (1.0 - sigmoid)));
  };

};