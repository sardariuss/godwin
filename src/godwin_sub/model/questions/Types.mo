import UtilsTypes "../../utils/Types";
import Queries    "../../utils/Queries";

module {

  type Time = Int;

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
    #HOTNESS;
    #ARCHIVE;
    #OPINION_VOTE;
  };
  
  public type Key = {
    #AUTHOR: AuthorEntry;
    #TEXT: TextEntry;
    #DATE: DateEntry;
    #STATUS: StatusEntry;
    #HOTNESS: InterestScore;
    #ARCHIVE: DateEntry;
    #OPINION_VOTE: OpinionVoteEntry;
  };

  public type DateEntry        = { question_id: Nat; date: Time; };
  public type TextEntry        = DateEntry and { text: Text; };
  public type AuthorEntry      = DateEntry and { author: Principal; };
  public type StatusEntry      = DateEntry and { status: Status; };
  public type InterestScore    = { question_id: Nat; score: Float; };
  public type OpinionVoteEntry = DateEntry and { is_late: Bool; };

  public type OpenQuestionError = {
    #PrincipalIsAnonymous;
    #TextTooLong;

  };

  public type ScanLimitResult = UtilsTypes.ScanLimitResult<QuestionId>;
  
};