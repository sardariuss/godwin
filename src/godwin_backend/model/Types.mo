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
  public type StatusHistory              = [StatusInfo];
  public type IterationHistory           = [StatusHistory];
  public type OpenQuestionError          = QuestionTypes.OpenQuestionError or { #OpenInterestVoteFailed: OpenVoteError; };
  public type QuestionOrderBy            = QuestionTypes.OrderBy;

  // @todo: are all these types required in the canister interface?
  public type VoteId                     = VoteTypes.VoteId;
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
  public type InterestVote               = Vote<Cursor, Polarization>;
  public type OpinionVote                = Vote<Cursor, Polarization>;
  public type CategorizationVote         = Vote<CursorArray, PolarizationArray>;

  public type FindVoteError              = VoteTypes.FindVoteError;
  public type FindQuestionIterationError = VoteTypes.FindQuestionIterationError;
  public type OpenVoteError              = VoteTypes.OpenVoteError;
  public type GetVoteError               = VoteTypes.GetVoteError;
  public type RevealVoteError            = VoteTypes.RevealVoteError;
  public type CloseVoteError             = VoteTypes.CloseVoteError;
  public type FindBallotError             = VoteTypes.FindBallotError;
  public type AddBallotError             = VoteTypes.AddBallotError;
  public type PutBallotError             = VoteTypes.PutBallotError;

  public type HistoryParameters = {
    convictions_half_life: ?Duration;
  };

  public type SchedulerParameters = {
    interest_pick_rate: Duration;
    interest_duration: Duration;
    opinion_duration: Duration;
    rejected_duration: Duration;
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

  public type SetDurationError = VerifyCredentialsError;

  public type GetUserConvictionsError = PrincipalError;

  public type GetUserVotesError = PrincipalError;

  public type TransitionError = OpenVoteError or {
    #WrongStatusIteration;
    #EmptyQueryInterestScore;
    #NotMostInteresting;
    #TooSoon;
    #PrincipalIsAnonymous;
    #QuestionNotFound;
  };

};