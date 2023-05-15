import UtilsTypes "../../utils/Types";

import Map "mo:map/Map";

module {

  type Time = Int;
  type Map<K, V> = Map.Map<K, V>;

  public type QuestionId = Nat;

  public type Question = {
    id: QuestionId;
    author: Principal;
    text: Text;
    date: Time;
  };

  public type Status = {
    #CANDIDATE;
    #OPEN;
    #CLOSED;
    #REJECTED;
  };

  public type StatusInfo = {
    status: Status;
    iteration: Nat;
    date: Time;
  };

  public type StatusData = {
    var current: StatusInfo;
    history: StatusHistory;
  };

  public type StatusHistory = Map<Status, [Time]>;
  
  // @todo: AUTHOR, TEXT and DATE are not used
  public type OrderBy = {
    #AUTHOR;
    #TEXT;
    #DATE;
    #STATUS: Status;
    #INTEREST_SCORE;
  };

  public type Key = {
    #AUTHOR: AuthorEntry;
    #TEXT: TextEntry;
    #DATE: DateEntry;
    #STATUS: StatusEntry;
    #INTEREST_SCORE: InterestScore;
  };

  public type DateEntry     = { question_id: Nat; date: Time; };
  public type TextEntry     = { question_id: Nat; text: Text; date: Time; };
  public type AuthorEntry   = { question_id: Nat; author: Principal; date: Time; };
  public type StatusEntry   = { question_id: Nat; status: Status; date: Int; };
  public type InterestScore = { question_id: Nat; score: Float; };

  public type OpenQuestionError = {
    #PrincipalIsAnonymous;
    #TextTooLong;
  };

  public type ScanLimitResult = UtilsTypes.ScanLimitResult<QuestionId>;
  
}