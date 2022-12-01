import Types "../types";
import Cursor "../representation/cursor";
import Polarization "../representation/polarization";
import Questions "../questions/questions";
import Question "../questions/question";
import Users "../users";
import User "../user";
import Aggregates "aggregates";

import Trie "mo:base/Trie";
import Nat "mo:base/Nat";

module {
  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;

  // For convenience: from types modules
  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;
  type User = Types.User;
  type Question = Types.Question;

  // For convenience: from other modules
  type Questions = Questions.Questions;
  type Users = Users.Users;

  public func put(users: Users, principal: Principal, questions: Questions, question_id: Nat, new_opinion: Cursor){
    let user = users.getUser(principal);
    let question = questions.getQuestion(question_id);

    let (user_opinions, old_opinion) = Trie.put(user.ballots.opinions, Types.keyNat(question.id), Nat.equal, new_opinion);
    users.putUser(User.updateOpinions(user, user_opinions));
    
    let question_opinions = Aggregates.updateAggregate(question.aggregates.opinion, ?new_opinion, old_opinion, Polarization.addCursor, Polarization.subCursor);
    questions.replaceQuestion(Question.updateOpinionAggregate(question, question_opinions));
  };
  
  public func remove(users: Users, principal: Principal, questions: Questions, question_id: Nat){
    let user = users.getUser(principal);
    let question = questions.getQuestion(question_id);

    let (user_opinions, old_opinion) = Trie.remove(user.ballots.opinions, Types.keyNat(question.id), Nat.equal);
    users.putUser(User.updateOpinions(user, user_opinions));

    let question_opinions = Aggregates.updateAggregate(question.aggregates.opinion, null, old_opinion, Polarization.addCursor, Polarization.subCursor);
    questions.replaceQuestion(Question.updateOpinionAggregate(question, question_opinions));
  };

};