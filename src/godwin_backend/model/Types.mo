import PayTypes      "token/Types";
import QuestionTypes "questions/Types";
import VoteTypes     "votes/Types";

import MasterTypes   "../../godwin_master/Types";

import Duration      "../utils/Duration";

import Set           "mo:map/Set";

import Principal     "mo:base/Principal";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  type Time = Int;

  type Set<K> = Set.Set<K>;
  
  type Duration = Duration.Duration;

  // @todo: are all these types required in the canister interface?
  public type QuestionId                 = QuestionTypes.QuestionId;  
  public type Question                   = QuestionTypes.Question;
  public type Status                     = QuestionTypes.Status;
  public type StatusInfo                 = QuestionTypes.StatusInfo;
  public type StatusData                 = QuestionTypes.StatusData;
  public type StatusHistory              = [(Status, [Time])];
  public type OpenQuestionError          = QuestionTypes.OpenQuestionError or { #OpenInterestVoteFailed: OpenVoteError; };

  // @todo: are all these types required in the canister interface?
  public type VoteId                     = VoteTypes.VoteId;
  public type VoteHistory                = VoteTypes.VoteHistory;
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
  
  public type FindCurrentVoteError       = VoteTypes.FindCurrentVoteError;
  public type FindHistoricalVoteError    = VoteTypes.FindHistoricalVoteError;
  public type OpenVoteError              = VoteTypes.OpenVoteError;
  public type GetVoteError               = VoteTypes.GetVoteError;
  public type RevealVoteError            = VoteTypes.RevealVoteError;
  public type CloseVoteError             = VoteTypes.CloseVoteError;
  public type GetBallotError             = VoteTypes.GetBallotError;
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

  public type User = {
    convictions: VoteTypes.PolarizationMap;
    opinions: Set<Nat>;
  };

  public type Category = Text;
  
  public type CategoryArray = [(Category, CategoryInfo)];

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