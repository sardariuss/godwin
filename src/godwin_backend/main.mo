import Question "questions/question";
import Questions "questions/questions";
import Iterations "votes/register";
import CategoryCursorTrie "representation/categoryCursorTrie";
import Cursor "representation/cursor";
import Types "types";
import Categories "categories";
import Users "users";
import Utils "utils";
import Scheduler "scheduler";
import Junctions "junctions";
import Votes "votes/voteRegister";
import Status "questionStatus";

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Text "mo:base/Text";

// @todo: one need to call getOrCreateUser when voting or doing anything that takes the caller as input
shared({ caller = admin_ }) actor class Godwin(parameters: Types.Parameters) = {

  // For convenience: from base module
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Principal = Principal.Principal;
  // For convenience: from types module
  type Question = Types.Question;
  type Interest = Types.Interest;
  type Cursor = Types.Cursor;
  type User = Types.User;
  type SchedulerParams = Types.SchedulerParams;
  type InterestAggregate = Types.InterestAggregate;
  type Category = Types.Category;
  type CategoryCursorArray = Types.CategoryCursorArray;
  type CategoryCursorTrie = Types.CategoryCursorTrie;
  type Iteration = Types.Iteration;
  type IterationId = Types.IterationId;
  type Polarization = Types.Polarization;
  type CategoryPolarizationTrie = Types.CategoryPolarizationTrie;

  // Members
  stable var categories_ = Categories.fromArray(parameters.categories);
  stable var users_ = Users.empty();
  stable var questions_ = Questions.empty();
  stable var iterations_ = Iterations.empty();
  stable var junctions_ = Junctions.empty();
  stable var interests_ = Votes.empty<Interest, InterestAggregate>();
  stable var opinions_ = Votes.empty<Cursor, Polarization>();
  stable var categorizations_ = Votes.empty<CategoryCursorTrie, CategoryPolarizationTrie>();
  stable var status_ = Status.empty();
  var scheduler_ = Scheduler.Scheduler({ params = parameters.scheduler; last_selection_date = Time.now(); });

  // For upgrades
  stable var scheduler_shareable_ = scheduler_.share();

  public func getSchedulerParams() : async SchedulerParams {
    scheduler_.share().params;
  };

  public func getCategories() : async [Category] {
    Categories.toArray(categories_);
  };

  public type AddCategoryError = {
    #InsufficientCredentials;
    #CategoryAlreadyExists;
  };

  public shared({caller}) func addCategory(category: Category) : async Result<(), AddCategoryError> {
    Result.chain<(), (), AddCategoryError>(verifyCredentials(caller), func () {
      if (Categories.contains(categories_, category)) { #err(#CategoryAlreadyExists); }
      else { #ok(categories_ := Categories.add(categories_, category)); };
    });
  };

  public type RemoveCategoryError = {
    #InsufficientCredentials;
    #CategoryDoesntExist;
  };

  public shared({caller}) func removeCategory(category: Category) : async Result<(), RemoveCategoryError> {
    Result.chain<(), (), RemoveCategoryError>(verifyCredentials(caller), func () {
      if (not Categories.contains(categories_, category)) { #err(#CategoryDoesntExist); }
      else { 
        categories_ := Categories.remove(categories_, category); 
        // Also remove the category from users' profile
        users_ := Users.removeCategory(users_, category);
        #ok;
      };
    });
  };

  public shared({caller}) func setSchedulerParams(scheduler_params : SchedulerParams) : async Result<(), VerifyCredentialsError> {
    Result.mapOk<(), (), VerifyCredentialsError>(verifyCredentials(caller), func () {
      scheduler_.setParams(scheduler_params);
    });
  };

  public type GetQuestionError = {
    #QuestionNotFound;
  };

  public shared query func getQuestion(question_id: Nat) : async Result<Question, GetQuestionError> {
    Result.fromOption(Questions.findQuestion(questions_, question_id), #QuestionNotFound);
  };

  public shared({caller}) func createQuestion(title: Text, text: Text) : async Question {
    let time_now = Time.now();
    let (questions, interests, question) = Questions.createQuestion(questions_, interests_, caller, time_now, title, text, 0);
    questions_ := questions;
    interests_ := interests;
    question;
  };

  func getVoteType(vote_link: Types.VoteLink) : Types.VoteType {
    switch(vote_link){
      case(#INTEREST(_)) { #INTEREST; };
      case(#OPINION(_)) { #OPINION; };
      case(#CATEGORIZATION(_)) { #CATEGORIZATION; };
    };
  };

  func getVoteType2(ballot: Types.Ballot) : Types.VoteType {
    switch(ballot){
      case(#INTEREST(_)) { #INTEREST; };
      case(#OPINION(_)) { #OPINION; };
      case(#CATEGORIZATION(_)) { #CATEGORIZATION; };
    };
  };

  public shared({caller}) func putBallot(question_id: Nat, ballot: Types.Ballot) : async Result<(), InterestError> {
    Result.chain<Question, (), InterestError>(Result.fromOption(Questions.findQuestion(questions_, question_id), #QuestionNotFound), func(question) {
      let vote_link = question.votes[question.votes.size() - 1];
      if (getVoteType(vote_link) != getVoteType2(ballot)) { return #err(#InvalidVotingStage); }
      #ok;
    });
  };

  public type InterestError = {
    #QuestionNotFound;
    #InvalidVotingStage;
  };

  public shared query func getInterest(question_id: Nat, principal: Principal) : async Result<?Interest, InterestError> {
    Result.mapOk<IterationId, ?Interest, InterestError>(Result.fromOption(Junctions.findCurrentIteration(junctions_, question_id), #QuestionNotFound), func(iteration) {
      Iterations.getInterest(iterations_, iteration, principal);
    });
  };

  public shared({caller}) func setInterest(question_id: Nat, interest: Interest) : async Result<(), InterestError> {
    Result.chain<IterationId, (), InterestError>(Result.fromOption(Junctions.findCurrentIteration(junctions_, question_id), #QuestionNotFound), func(iteration) {
      if (Iterations.get(iterations_, iteration).voting_stage != #INTEREST) { return #err(#InvalidVotingStage); };
      #ok(iterations_ := Iterations.putInterest(iterations_, iteration, caller, interest));
    });
  };

  public shared({caller}) func removeInterest(question_id: Nat) : async Result<(), InterestError> {
    Result.chain<IterationId, (), InterestError>(Result.fromOption(Junctions.findCurrentIteration(junctions_, question_id), #QuestionNotFound), func(iteration) {
      if (Iterations.get(iterations_, iteration).voting_stage != #INTEREST) { return #err(#InvalidVotingStage); };
      #ok(iterations_ := Iterations.removeInterest(iterations_, iteration, caller));
    });
  };

  public type OpinionError = {
    #InvalidOpinion;
    #QuestionNotFound;
    #InvalidVotingStage;
  };

  public shared query func getOpinion(question_id: Nat, principal: Principal) : async Result<?Cursor, OpinionError> {
    Result.mapOk<IterationId, ?Cursor, OpinionError>(Result.fromOption(Junctions.findCurrentIteration(junctions_, question_id), #QuestionNotFound), func(iteration) {
      Iterations.getOpinion(iterations_, iteration, principal);
    });
  };

  public shared({caller}) func setOpinion(question_id: Nat, cursor: Cursor) : async Result<(), OpinionError> {
    Result.chain<Cursor, (), OpinionError>(Result.fromOption(Cursor.verifyIsValid(cursor), #InvalidOpinion), func(cursor) {
      Result.chain<IterationId, (), OpinionError>(Result.fromOption(Junctions.findCurrentIteration(junctions_, question_id), #QuestionNotFound), func(iteration) {
        if (Iterations.get(iterations_, iteration).voting_stage != #OPINION) { return #err(#InvalidVotingStage); };
        #ok(iterations_ := Iterations.putOpinion(iterations_, iteration, caller, cursor));
      })
    });
  };

  public type CategorizationError = {
    #InvalidVotingStage;
    #InsufficientCredentials;
    #InvalidCategorization;
    #QuestionNotFound;
  };

  public shared({caller}) func setCategorization(question_id: Nat, cursor_array: CategoryCursorArray) : async Result<(), CategorizationError> {
    Result.chain<(), (), CategorizationError>(verifyCredentials(caller), func () {
      Result.chain<IterationId, (), CategorizationError>(Result.fromOption(Junctions.findCurrentIteration(junctions_, question_id), #QuestionNotFound), func(iteration) {
        if (Iterations.get(iterations_, iteration).voting_stage != #CATEGORIZATION) { return #err(#InvalidVotingStage); };
        let cursor_trie = Utils.arrayToTrie(cursor_array, Types.keyText, Text.equal);
        if (not CategoryCursorTrie.isValid(cursor_trie, categories_)) { return #err(#InvalidCategorization); };
        #ok(iterations_ := Iterations.putCategorization(iterations_, iteration, caller, Utils.arrayToTrie(cursor_array, Types.keyText, Text.equal)));
      })
    });
  };

  public shared func run() {
    let time_now = Time.now();
    iterations_ := scheduler_.selectQuestion(iterations_, time_now).0;
    iterations_ := scheduler_.archiveQuestion(iterations_, time_now).0;
    let (iterations, iteration) = scheduler_.closeCategorization(iterations_, time_now);
    iterations_ := iterations;
    Option.iterate(iteration, func(it: Iteration) {
      let question_id = Junctions.getQuestionId(junctions_, it.id);
      users_ := Users.updateConvictions(users_, Junctions.getIterations(junctions_, question_id), Categories.toArray(categories_), iterations_);
    });
  };

  public type GetUserError = {
    #IsAnonymous;
  };

  public shared func findUser(principal: Principal) : async Result<User, GetUserError> {
    // @todo: do case if anonymous
    let (users, user) = Users.getOrCreateUser(users_, principal, Categories.toArray(categories_));
    users_ := users;
    #ok(user);
  };

  public type VerifyCredentialsError = {
    #InsufficientCredentials;
  };

  func verifyCredentials(caller: Principal) : Result<(), VerifyCredentialsError> {
    if (caller != admin_) { #err(#InsufficientCredentials); }
    else { #ok; };
  };

  system func preupgrade(){
    scheduler_shareable_ := scheduler_.share();
  };

  system func postupgrade(){
    scheduler_ := Scheduler.Scheduler(scheduler_shareable_);
  };

};
