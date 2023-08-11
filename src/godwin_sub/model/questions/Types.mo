import Types      "../../stable/Types";
import UtilsTypes "../../utils/Types";
import Queries    "../../utils/Queries";

module {

  type Time = Int;

  public type QuestionId       = Types.Current.QuestionId;
  public type Question         = Types.Current.Question;
  public type Status           = Types.Current.Status;
  public type OrderBy          = Types.Current.OrderBy;
  public type Key              = Types.Current.Key;
  public type DateEntry        = Types.Current.DateEntry;
  public type TextEntry        = Types.Current.TextEntry;
  public type AuthorEntry      = Types.Current.AuthorEntry;
  public type StatusEntry      = Types.Current.StatusEntry;
  public type InterestScore    = Types.Current.InterestScore;
  public type OpinionVoteEntry = Types.Current.OpinionVoteEntry;

  public type QuestionQueries = Queries.Queries<OrderBy, Key>;

  public type OpenQuestionError = {
    #PrincipalIsAnonymous;
    #TextTooLong;
  };

  public type ScanLimitResult = UtilsTypes.ScanLimitResult<QuestionId>;
  
};