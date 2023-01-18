import Types "types";
import Questions "questions/questions";
import Question "questions/question";
import Queries "questions/queries";
import Users "users";
import Utils "utils";
import WRef "wrappers/WRef";
import WMap "wrappers/WMap";

import Map "mo:map/Map";

import Buffer "mo:base/Buffer";
import Trie "mo:base/Trie";
import Option "mo:base/Option";

module {
  // For convenience: from base module
  type Time = Int;
  type Trie<K, V> = Trie.Trie<K, V>;
  // For convenience: from types module
  type Question = Types.Question;
  type Category = Types.Category;
  type Status = Types.Status;
  type Duration = Types.Duration;
  type Ref<V> = Types.Ref<V>;

  // For convenience: from map module
  type Map<K, V> = Map.Map<K, V>;

  // For convenience: from other modules
  type Questions = Questions.Questions;
  type Users = Users.Users;
  type Queries = Queries.Queries;
  type WRef<T> = WRef.WRef<T>;
  type WMap<K, V> = WMap.WMap<K, V>;

  public func build(
    selection_rate: Ref<Duration>,
    status_durations: Map<Status, Duration>,
    last_selection_date: Ref<Time>,
    questions: Questions,
    users: Users,
    queries: Queries
  ) : Scheduler {
    Scheduler(
      WRef.WRef(selection_rate),
      WMap.WMap<Status, Duration>(status_durations, Types.statushash),
      WRef.WRef(last_selection_date),
      questions,
      users,
      queries
    );
  };

  // @todo: make the return of functions uniform (always return an array of questions)
  public class Scheduler(
    selection_rate_: WRef<Duration>,
    status_durations_: WMap<Status, Duration>,
    last_selection_date_: WRef<Time>,
    questions_: Questions,
    users_: Users,
    queries_: Queries
  ){

    public func getSelectionRate() : Duration {
      selection_rate_.get();
    };

    public func setSelectionRate(duration: Duration) {
      selection_rate_.set(duration);
    };

    public func getStatusDuration(status: Status) : ?Duration {
      status_durations_.get(status);
    };

    public func setStatusDuration(status: Status, duration: Duration) {
      ignore status_durations_.put(status, duration);
    };

    public func rejectQuestions(time_now: Time) : [Question] {
      let buffer = Buffer.Buffer<Question>(0);
      Option.iterate(status_durations_.get(#CANDIDATE), func(duration: Duration){
        let iter = queries_.entries(#STATUS_DATE(#CANDIDATE), #fwd);
        label iter_oldest while(true){
          switch(questions_.next(iter)){
            case(null){ break iter_oldest; };
            case(?question){
              let interest = Question.unwrapInterest(question);
              // Stop iterating here if the question is not old enough
              if (time_now < interest.date + Utils.toTime(duration)){ break iter_oldest; };
              // If old enough, reject the question
              let rejected_question = Question.rejectQuestion(question, time_now);
              questions_.replaceQuestion(rejected_question);
              buffer.add(rejected_question);
            };
          };
        };
      });
      Buffer.toArray(buffer);
    };

    
    public func deleteQuestions(time_now: Time) : [Question] {
      let buffer = Buffer.Buffer<Question>(0);
      Option.iterate(status_durations_.get(#REJECTED), func(duration: Duration){
        let iter = queries_.entries(#STATUS_DATE(#REJECTED), #fwd);
        label iter_oldest while(true){
          switch(questions_.next(iter)){
            case(null){ break iter_oldest; };
            case(?question){
              // Stop iterating here if the question is not old enough
              if (time_now < Question.unwrapRejectedDate(question) + Utils.toTime(duration)){ break iter_oldest; };
              // If old enough, delete the question
              buffer.add(questions_.removeQuestion(question.id));
            };
          };
        };
      });
      Buffer.toArray(buffer);
    };

    public func openOpinionVote(time_now: Time) : ?Question {
      if (time_now > last_selection_date_.get() + Utils.toTime(selection_rate_.get())) {
        switch(questions_.first(queries_, #INTEREST, #bwd)){
          case(null){};
          case(?question){ 
            let updated_question = Question.openOpinionVote(question, time_now);
            questions_.replaceQuestion(updated_question);
            last_selection_date_.set(time_now);
            return ?updated_question;
          };
        };
      };
      null;
    };

    public func openCategorizationVote(time_now: Time, categories: [Category]) : ?Question {
      Option.chain(status_durations_.get(#OPEN(#OPINION)), func(duration: Duration) : ?Question{
        switch(questions_.first(queries_, #STATUS_DATE(#OPEN(#OPINION)), #fwd)){
          case(null){};
          case(?question){
            let iteration = Question.unwrapIteration(question);
            // If categorization date has come, open categorization vote
            if (time_now > iteration.opinion.date + Utils.toTime(duration)) {
              let updated_question = Question.openCategorizationVote(question, time_now, categories);
              questions_.replaceQuestion(updated_question);
              return ?updated_question;
            };
          };
        };
        null;
      });
    };

    public func closeQuestion(time_now: Time) : ?Question {
      Option.chain(status_durations_.get(#OPEN(#CATEGORIZATION)), func(duration: Duration) : ?Question{
        switch(questions_.first(queries_, #STATUS_DATE(#OPEN(#CATEGORIZATION)), #fwd)){
          case(null){};
          case(?question){
            let iteration = Question.unwrapIteration(question);
            // If categorization duration is over, close votes
            if (time_now > iteration.categorization.date + Utils.toTime(duration)) {
              // Need to update the users convictions
              users_.updateConvictions(Question.unwrapIteration(question), question.vote_history);
              // Finally close the question
              let closed_question = Question.closeQuestion(question, time_now);
              questions_.replaceQuestion(closed_question);
              return ?closed_question;
            };
          };
        };
        null;
      });
    };

  };

};