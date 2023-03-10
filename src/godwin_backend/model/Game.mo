import Types "Types";
import Users "Users";
import QuestionQueries "QuestionQueries";
import Scheduler "Scheduler";
import Controller "Controller";
import Questions "Questions";
import Votes "votes/Votes";
import Polls "votes/Polls";
import Categories "Categories";
import StatusHelper "StatusHelper";
import Duration "Duration";
import Utils "../utils/Utils";

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Iter "mo:base/Iter";

import TokenVote "TokenVote";
import Token "canister:godwin_token";

module {

  // For convenience: from base module
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Principal = Principal.Principal;
  type Time = Int;

  // For convenience: from types module
  type Question = Types.Question;
  type User = Types.User;
  type Category = Types.Category;
  type Decay = Types.Decay;
  type Duration = Types.Duration;
  type Status = Types.Status;
  type IndexedStatus = Types.IndexedStatus;
  type Poll = Types.Poll;
  type TypedBallot = Types.TypedBallot;
  type TypedAnswer = Types.TypedAnswer;
  type PolarizationArray = Types.PolarizationArray;
  // Errors
  type AddCategoryError = Types.AddCategoryError;
  type RemoveCategoryError = Types.RemoveCategoryError;
  type GetQuestionError = Types.GetQuestionError;
  type OpenQuestionError = Types.OpenQuestionError;
  type ReopenQuestionError = Types.ReopenQuestionError;
  type SetUserNameError = Types.SetUserNameError;
  type VerifyCredentialsError = Types.VerifyCredentialsError;
  type GetUserError = Types.GetUserError;
  type PutBallotError = Types.PutBallotError;
  type GetBallotError = Types.GetBallotError;
  type SetPickRateError = Types.SetPickRateError;
  type SetDurationError = Types.SetDurationError;
  type TypedAggregate = Types.TypedAggregate;
  type GetUserConvictionsError = Types.GetUserConvictionsError;

  public class Game(
    admin_: Principal,
    categories_: Categories.Categories,
    users_: Users.Users,
    questions_: Questions.Questions,
    queries_: QuestionQueries.QuestionQueries,
    controller_: Controller.Controller,
    scheduler_: Scheduler.Scheduler,
    polls_: Polls.Polls
  ) = {

    let interest_vote_accounts_ = TokenVote.TokenVote();
    let categorization_vote_accounts_ = TokenVote.TokenVote();

    let subaccount_generator_ = TokenVote.SubaccountGenerator();

    public func getDecay() : ?Decay {
      users_.getDecay();
    };

    public func getCategories() : [Category] {
      Iter.toArray(categories_.keys());
    };

    public func addCategory(caller: Principal, category: Category) : Result<(), AddCategoryError> {
      Result.chain<(), (), AddCategoryError>(verifyCredentials(caller), func() {
        Result.mapOk<(), (), AddCategoryError>(Utils.toResult(not categories_.has(category), #CategoryAlreadyExists), func() {
          categories_.add(category);
          // Also add the category to users' profile // @todo: use an obs instead?
          users_.addCategory(category);
        })
      });
    };

    public func removeCategory(caller: Principal, category: Category) : Result<(), RemoveCategoryError> {
      Result.chain<(), (), RemoveCategoryError>(verifyCredentials(caller), func () {
        Result.mapOk<(), (), RemoveCategoryError>(Utils.toResult(categories_.has(category), #CategoryDoesntExist), func() {
          categories_.add(category);
          // Also remove the category from users' profile // @todo: use an obs instead?
          users_.removeCategory(category);
        })
      });
    };

    public func getPickRate(/*status: Status*/) : Duration {
      //Duration.fromTime(scheduler_.getPickRate(status));
      controller_.getPickRate();
    };

    public func setPickRate(caller: Principal, /*status: Status,*/ rate: Duration) : Result<(), SetPickRateError> {
      Result.mapOk<(), (), SetPickRateError>(verifyCredentials(caller), func () {
        //scheduler_.setPickRate(status, Duration.toTime(rate));
        controller_.setPickRate(rate);
      });
    };

    public func getDuration(status: Status) : Duration {
      //Duration.fromTime(scheduler_.getDuration(status));
      controller_.getDuration(status);
    };

    public func setDuration(caller: Principal, status: Status, duration: Duration) : Result<(), SetDurationError> {
      Result.mapOk<(), (), SetDurationError>(verifyCredentials(caller), func () {
        //scheduler_.setDuration(status, Duration.toTime(duration));
        controller_.setDuration(status, duration);
      });
    };

    public func getQuestion(question_id: Nat) : Result<Question, GetQuestionError> {
      Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound);
    };

    public func getQuestions(order_by: QuestionQueries.OrderBy, direction: QuestionQueries.Direction, limit: Nat, previous_id: ?Nat) : QuestionQueries.QueryQuestionsResult {
      queries_.queryItems(order_by, direction, limit, Option.map(previous_id, func(id: Nat) : Question { questions_.getQuestion(id); }));
    };

    public func openQuestion(master: Types.Master, caller: Principal, title: Text, text: Text, date: Time) : async Result<Question, OpenQuestionError> {
      switch(getUser(caller)){
        case(#err(err)) { #err(err); }; 
        case(#ok(_)){
          let voting_price = 1321321;
          let subaccount = subaccount_generator_.generateSubaccount();
          switch(await master.transferToSubGodwin(caller, voting_price, subaccount)){
            case(#err(err)) { #err(#PrincipalIsAnonymous); }; // @todo
            case(#ok){
              let question = questions_.createQuestion(caller, date, title, text); // @todo: make sure it cannot trap
              polls_.openVote(question, #INTEREST);
              interest_vote_accounts_.linkSubaccount(question.id, 0, subaccount);
              #ok(question);
            };
          };
        };
      };
    };

    public func reopenQuestion(master: Types.Master, caller: Principal, question_id: Nat, date: Time) : async Result<(), ReopenQuestionError> {
      let precondition = Result.chain<User, (), ReopenQuestionError>(getUser(caller), func(_) {
        Result.chain<Question, (), ReopenQuestionError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          Utils.toResult(StatusHelper.isCurrentStatus(question, #CLOSED), #InvalidStatus);
        })
      });

      switch(precondition){
        case(#err(err)) { #err(err); }; 
        case(#ok(_)){
          let question = questions_.getQuestion(question_id);
          let voting_price = 1321321;
          let subaccount = subaccount_generator_.generateSubaccount();
          switch(await master.transferToSubGodwin(caller, voting_price, subaccount)){
            case(#err(err)) { #err(#PrincipalIsAnonymous); }; // @todo
            case(#ok){
              controller_.reopenQuestion(question, date);
              interest_vote_accounts_.linkSubaccount(question.id, 1, subaccount); // @todo
              #ok();
            };
          };
        };
      };
    };

    public func putBallot(caller: Principal, question_id: Nat, answer: TypedAnswer, date: Time) : Result<(), PutBallotError> {
      Result.chain<User, (), PutBallotError>(getUser(caller), func(_) {
        Result.chain<Question, (), PutBallotError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          Result.mapOk<(), (), PutBallotError>(Utils.toResult(Polls.matchCurrentPoll(question, answer), #InvalidStatus), func(_) {
            polls_.putBallot(caller, question, answer, date);
          })
        })
      });
    };

    // Reveal the ballot for the current vote, put a default neutral ballot if no ballot has been given yet
    // @todo: if the questions is revealed itself, this method has no benefit. The getQuestion and getQuestions 
    // methods shall reveal the ballot of the questions. But this might bring performance issues (update method isntead of query).
    public func revealBallot(caller: Principal, question_id: Nat, date: Time) : Result<TypedBallot, GetBallotError> {
      Result.chain<User, TypedBallot, GetBallotError>(getUser(caller), func(_) {
        Result.chain<Question, TypedBallot, GetBallotError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          Result.mapOk<Poll, TypedBallot, GetBallotError>(Result.fromOption(StatusHelper.getCurrentPoll(question), #QuestionNotFound), func(poll) {
            polls_.revealBallot(caller, question.id, StatusHelper.getIteration(question, #VOTING(poll)), poll, date);
          })
        })
      });
    };

    public func getBallot(principal: Principal, question_id: Nat, iteration: Nat, poll: Poll) : Result<?TypedBallot, GetBallotError> {
      Result.chain<User, ?TypedBallot, GetBallotError>(getUser(principal), func(_) {
        Result.chain<Question, ?TypedBallot, GetBallotError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          Result.mapOk<(), ?TypedBallot, GetBallotError>(Utils.toResult(StatusHelper.isHistoryIteration(question, #VOTING(poll), iteration), #InvalidIteration), func() {
            polls_.getBallot(principal, question.id, iteration, poll);
          })
        })
      });
    };

    // Get the aggregate of any vote, for any vote except the current one
    public func getAggregate(question_id: Nat, iteration: Nat, poll: Poll) : Result<TypedAggregate, GetBallotError> {
      Result.chain<Question, TypedAggregate, GetBallotError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
        Result.mapOk<(), TypedAggregate, GetBallotError>(Utils.toResult(StatusHelper.isHistoryIteration(question, #VOTING(poll), iteration), #InvalidIteration), func() {
          polls_.getAggregate(question.id, iteration, poll);
        })
      });
    };

    public func run(date: Time) {
      controller_.run(date, Option.map(queries_.entries(#INTEREST_SCORE, #FWD).next(), func(question: Question) : Nat { question.id; }));
    };

    public func setUserName(principal: Principal, name: Text) : Result<(), SetUserNameError> {
      Result.mapOk<User, (), SetUserNameError>(getUser(principal), func(_) {
        users_.setUserName(principal, name);
      });
    };

    public func getUserConvictions(principal: Principal) : Result<PolarizationArray, GetUserConvictionsError> {
      Result.mapOk<User, Types.PolarizationArray, GetUserConvictionsError>(getUser(principal), func(user) {
        Utils.trieToArray(user.convictions);
      });
    };

    func verifyCredentials(principal: Principal) : Result<(), VerifyCredentialsError> {
      Result.mapOk<(), (), VerifyCredentialsError>(Utils.toResult(principal == admin_, #InsufficientCredentials), (func(){}));
    };

    func getUser(principal: Principal) : Result<User, GetUserError> {
      Result.mapOk<(), User, GetUserError>(Utils.toResult(not Principal.isAnonymous(principal), #PrincipalIsAnonymous), func(){
        users_.getOrCreateUser(principal, categories_);
      });
    };

    // @todo
//    public func createQuestions(principal: Principal, inputs: [(Text, CreateStatus)]) : Result<[Question], CreateQuestionError> {
//      Result.chain<(), [Question], CreateQuestionError>(verifyCredentials(principal), func () {
//        Result.mapOk<User, [Question], CreateQuestionError>(getUser(principal), func(_) {
//          Admin.createQuestions(questions_, principal, inputs);
//        })
//      });
//    };

  };

};
