import UtilsTypes "../../utils/Types";
import Queries    "../../utils/Queries";

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
    #REJECTED: {
      #TIMED_OUT;
      #CENSORED;
    };
  };

  public type StatusInfo = {
    status: Status;
    date: Time;
  };

  public type StatusHistory = Buffer<StatusInfo>;
  public type IterationHistory = Buffer<StatusHistory>;

  public type QuestionQueries = Queries.Queries<OrderBy, Key>;
  
  // @todo: AUTHOR, TEXT and DATE are not used
  public type OrderBy = {
    #AUTHOR;
    #TEXT;
    #DATE;
    #STATUS: {
      #CANDIDATE;
      #OPEN;
      #CLOSED;
      #REJECTED;
    };
    #INTEREST_SCORE;
    #ARCHIVE;
  };
  
  public type Key = {
    #AUTHOR: AuthorEntry;
    #TEXT: TextEntry;
    #DATE: DateEntry;
    #STATUS: StatusEntry;
    #INTEREST_SCORE: InterestScore;
    #ARCHIVE: DateEntry;
  };

  public type DateEntry     = { question_id: Nat; date: Time; };
  public type TextEntry     = DateEntry and { text: Text; };
  public type AuthorEntry   = DateEntry and { author: Principal; };
  public type StatusEntry   = DateEntry and { status: Status; };
  public type InterestScore = { question_id: Nat; score: Float; };

  public type OpenQuestionError = {
    #PrincipalIsAnonymous;
    #TextTooLong;
  };

  public type ScanLimitResult = UtilsTypes.ScanLimitResult<QuestionId>;
  
}