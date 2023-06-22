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

  public type CursorVotes = {
    opinion_vote_id: Nat;
    categorization_vote_id: Nat;
  };

  public type StatusInput = {
    #INTEREST_VOTE: Nat;
    #CURSOR_VOTES: CursorVotes;
  };

  public type StatusInfo = {
    status: Status;
    date: Time;
    iteration: Nat;
  };

  public type StatusHistory = Buffer<StatusInfo>;

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
    #OPINION_VOTE;
  };
  
  public type Key = {
    #AUTHOR: AuthorEntry;
    #TEXT: TextEntry;
    #DATE: DateEntry;
    #STATUS: StatusEntry;
    #INTEREST_SCORE: InterestScore;
    #ARCHIVE: DateEntry;
    #OPINION_VOTE: OpinionVoteEntry;
  };

  public type DateEntry        = { question_id: Nat; date: Time; };
  public type TextEntry        = DateEntry and { text: Text; };
  public type AuthorEntry      = DateEntry and { author: Principal; };
  public type StatusEntry      = DateEntry and { status: Status; };
  public type InterestScore    = { question_id: Nat; score: Float; };
  public type OpinionVoteEntry = DateEntry and { is_early: Bool; };

  public type OpenQuestionError = {
    #PrincipalIsAnonymous;
    #TextTooLong;

  };

  public type ScanLimitResult = UtilsTypes.ScanLimitResult<QuestionId>;
  
}