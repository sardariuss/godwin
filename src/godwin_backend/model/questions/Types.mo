import UtilsTypes "../../utils/Types";

import Buffer "mo:stablebuffer/StableBuffer";
import Map "mo:map/Map";

module {

  type Time = Int;
  type Map<K, V> = Map.Map<K, V>;
  type Buffer<K> = Buffer.StableBuffer<K>;

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
    date: Time;
  };

  public type StatusHistory = Buffer<StatusInfo>;
  public type IterationHistory = Buffer<StatusHistory>;

  
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