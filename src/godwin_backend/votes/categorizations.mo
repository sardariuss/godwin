import Aggregates "aggregates";
import Types "../types";
import CategoryPolarizationTrie "../representation/categoryPolarizationTrie";
import Questions "../questions/questions";
import Question "../questions/question";
import Users "../users";
import User "../user";

import Trie "mo:base/Trie";
import Nat "mo:base/Nat";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  
  // For convenience: from types modules  
  type CategoryCursorTrie = Types.CategoryCursorTrie;
  type User = Types.User;
  type Question = Types.Question;

  // For convenience: from other modules
  type Questions = Questions.Questions;
  type Users = Users.Users;

  // @todo: assert the categorization is well formed
  public func put(users: Users, principal: Principal, questions: Questions, question_id: Nat, new_categorization: CategoryCursorTrie){
    let user = users.getUser(principal);
    let question = questions.getQuestion(question_id);

    let (user_categorizations, old_categorization) = Trie.put(user.ballots.categorizations, Types.keyNat(question.id), Nat.equal, new_categorization);
    users.putUser(User.updateCategorizations(user, user_categorizations));
    
    let question_categorizations = Aggregates.updateAggregate(question.aggregates.categorization, ?new_categorization, old_categorization, CategoryPolarizationTrie.add, CategoryPolarizationTrie.sub);
    questions.replaceQuestion(Question.updateCategorizationAggregate(question, question_categorizations));
  };
  
  public func remove(users: Users, principal: Principal, questions: Questions, question_id: Nat){
    let user = users.getUser(principal);
    let question = questions.getQuestion(question_id);

    let (user_categorizations, old_categorization) = Trie.remove(user.ballots.categorizations, Types.keyNat(question.id), Nat.equal);
    users.putUser(User.updateCategorizations(user, user_categorizations));

    let question_categorizations = Aggregates.updateAggregate(question.aggregates.categorization, null, old_categorization, CategoryPolarizationTrie.add, CategoryPolarizationTrie.sub);
    questions.replaceQuestion(Question.updateCategorizationAggregate(question, question_categorizations));
  };

};