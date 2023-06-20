import PayTypes      "token/Types";
import QuestionTypes "questions/Types";
import VoteTypes     "votes/Types";

import UtilsTypes    "../utils/Types";
import MasterTypes   "../../godwin_master/Types";

import Set           "mo:map/Set";

import Principal     "mo:base/Principal";

module {

  // For convenience: from base module
  type Principal                         = Principal.Principal;
  type Time                              = Int;

  type Set<K>                            = Set.Set<K>;
  
  public type Duration                   = UtilsTypes.Duration;
  public type Direction                  = UtilsTypes.Direction;
  public type ScanLimitResult<K>         = UtilsTypes.ScanLimitResult<K>;

  // @todo: are all these types required in the canister interface?
  public type QuestionId                 = QuestionTypes.QuestionId;  
  public type Question                   = QuestionTypes.Question;
  public type Status                     = QuestionTypes.Status;
  public type StatusInfo                 = QuestionTypes.StatusInfo;
  public type StatusInput                = QuestionTypes.StatusInput;
  public type OpenQuestionError          = QuestionTypes.OpenQuestionError or PayTypes.TransferFromMasterError;
  public type QuestionOrderBy            = QuestionTypes.OrderBy;

  public type TransactionsRecord         = PayTypes.TransactionsRecord;

  // @todo: are all these types required in the canister interface?
  public type VoteId                     = VoteTypes.VoteId;
  public type Interest                   = VoteTypes.Interest;
  public type Appeal                     = VoteTypes.Appeal;
  public type Cursor                     = VoteTypes.Cursor;
  public type Polarization               = VoteTypes.Polarization;
  public type CursorArray                = [(VoteTypes.Category, VoteTypes.Cursor)];
  public type PolarizationArray          = [(VoteTypes.Category, VoteTypes.Polarization)];

  public type InterestBallot             = VoteTypes.InterestBallot;
  public type OpinionBallot              = VoteTypes.OpinionBallot;
  public type CategorizationBallot       = VoteTypes.Ballot<CursorArray>;
  public type Vote<T, A> = {
    id: VoteId;
    ballots: [(Principal, VoteTypes.Ballot<T>)];
    aggregate: A;
  };
  public type InterestVote               = Vote<Interest, Appeal>;
  public type OpinionVote                = Vote<Cursor, Polarization>;
  public type CategorizationVote         = Vote<CursorArray, PolarizationArray>;
  public type RevealedInterestBallot     = VoteTypes.RevealedBallot<Interest>;
  public type RevealedOpinionBallot      = VoteTypes.RevealedBallot<Cursor>;
  public type RevealedCategorizationBallot = VoteTypes.RevealedBallot<CursorArray>;

  public type FindVoteError              = VoteTypes.FindVoteError;
  public type FindQuestionIterationError = VoteTypes.FindQuestionIterationError;
  public type OpenVoteError              = VoteTypes.OpenVoteError;
  public type GetVoteError               = VoteTypes.GetVoteError;
  public type RevealVoteError            = VoteTypes.RevealVoteError;
  public type CloseVoteError             = VoteTypes.CloseVoteError;
  public type FindBallotError            = VoteTypes.FindBallotError;
  public type AddBallotError             = VoteTypes.AddBallotError;
  public type PutBallotError             = VoteTypes.PutBallotError;

  public type HistoryParameters = {
    convictions_half_life: ?Duration;
  };

  public type SchedulerParameters = {
    question_pick_rate        : Duration;
    censor_timeout            : Duration;
    candidate_status_duration : Duration;
    open_status_duration      : Duration;
    rejected_status_duration  : Duration;
  };

  public type PriceParameters = {
    open_vote_price_e8s: Nat;
    interest_vote_price_e8s: Nat;
    categorization_vote_price_e8s: Nat;
  };

  public type QuestionsParameters = {
    character_limit: Nat;
  };

  public type Parameters = {
    name: Text;
    categories: CategoryArray;
    history: HistoryParameters;
    scheduler: SchedulerParameters;
    questions: QuestionsParameters;
    prices: PriceParameters;
  };

  public type Decay = {
    lambda: Float;
    shift: Float; // Used to shift X so that the exponential does not underflow/overflow
  };

  public type Category = Text;
  
  public type CategoryArray = [(Category, CategoryInfo)];

  public type VoteKind = {
    #INTEREST;
    #OPINION;
    #CATEGORIZATION;
  };

  public type CategoryInfo = {
    left: CategorySide;
    right: CategorySide;
  };

  public type CategorySide = {
    name: Text;
    symbol: Text;
    color: Text;
  };

  public type PrincipalError = {
    #PrincipalIsAnonymous;
  };

  public type VerifyCredentialsError = {
    #InsufficientCredentials;
  };

  public type AddCategoryError = VerifyCredentialsError or {
    #CategoryAlreadyExists;
  };

  public type RemoveCategoryError = VerifyCredentialsError or {
    #CategoryDoesntExist;
  };

  public type GetQuestionError = {
    #QuestionNotFound;
  };

  public type ReopenQuestionError = PrincipalError or GetQuestionError or {
    #InvalidStatus;
    #OpenInterestVoteFailed: OpenVoteError;
  };

  public type SetPickRateError = VerifyCredentialsError;

  public type SetSchedulerParametersError = VerifyCredentialsError;

  public type GetUserConvictionsError = PrincipalError;

  public type GetUserVotesError = PrincipalError;

};