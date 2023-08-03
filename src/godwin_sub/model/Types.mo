import PayTypes      "token/Types";
import QuestionTypes "questions/Types";
import VoteTypes     "votes/Types";

import UtilsTypes    "../utils/Types";
import MasterTypes   "../../godwin_master/Types";

import Set           "mo:map/Set";
import Buffer        "mo:stablebuffer/StableBuffer";

import Principal     "mo:base/Principal";

module {

  // For convenience: from base module
  type Principal                           = Principal.Principal;
  type Time                                = Int;

  type Set<K>                              = Set.Set<K>;
  type Buffer<K>                           = Buffer.StableBuffer<K>;
  
  public type Duration                     = UtilsTypes.Duration;
  public type Direction                    = UtilsTypes.Direction;
  public type ScanLimitResult<K>           = UtilsTypes.ScanLimitResult<K>;

  // @todo: are all these types required in the canister interface?
  public type QuestionId                   = QuestionTypes.QuestionId;  
  public type Question                     = QuestionTypes.Question;
  public type Status                       = QuestionTypes.Status;
  public type OpenQuestionError            = QuestionTypes.OpenQuestionError or PayTypes.TransferFromMasterError;
  public type QuestionOrderBy              = QuestionTypes.OrderBy;

  public type TransactionsRecord           = PayTypes.TransactionsRecord;

  public type StatusInfo = {
    status: Status;
    date: Time;
    iteration: Nat;
    votes: [VoteLink];
  };

  // @todo: are all these types required in the canister interface?
  public type VoteId                       = VoteTypes.VoteId;
  public type Interest                     = VoteTypes.Interest;
  public type Appeal                       = VoteTypes.Appeal;
  public type Cursor                       = VoteTypes.Cursor;
  public type OpinionAnswer                = VoteTypes.OpinionAnswer;
  public type Polarization                 = VoteTypes.Polarization;
  public type VoteKind                     = VoteTypes.VoteKind;
  public type VoteLink                     = VoteTypes.VoteLink;
  public type VoteStatus                   = VoteTypes.VoteStatus;
  public type CursorArray                  = [(VoteTypes.Category, VoteTypes.Cursor)];
  public type PolarizationArray            = [(VoteTypes.Category, VoteTypes.Polarization)];
  public type InterestBallot               = VoteTypes.InterestBallot;
  public type OpinionBallot                = VoteTypes.OpinionBallot;
  public type OpinionAggregate             = VoteTypes.OpinionAggregate;
  public type CategorizationBallot         = VoteTypes.Ballot<CursorArray>;
  public type InterestVote                 = Vote<Interest, Appeal>;
  public type OpinionVote                  = Vote<OpinionAnswer, OpinionAggregate>;
  public type CategorizationVote           = Vote<CursorArray, PolarizationArray>;
  public type RevealedInterestBallot       = VoteTypes.RevealedBallot<Interest>;
  public type RevealedOpinionBallot        = VoteTypes.RevealedBallot<OpinionAnswer>;
  public type RevealedCategorizationBallot = VoteTypes.RevealedBallot<CursorArray>;
  public type DecayParameters               = VoteTypes.DecayParameters;

  public type FindVoteError                = VoteTypes.FindVoteError;
  public type FindQuestionIterationError   = VoteTypes.FindQuestionIterationError;
  public type OpenVoteError                = VoteTypes.OpenVoteError;
  public type GetVoteError                 = VoteTypes.GetVoteError;
  public type RevealVoteError              = VoteTypes.RevealVoteError;
  public type CloseVoteError               = VoteTypes.CloseVoteError;
  public type FindBallotError              = VoteTypes.FindBallotError;
  public type AddBallotError               = VoteTypes.AddBallotError;
  public type PutBallotError               = VoteTypes.PutBallotError;

  public type SubInfo = {
    name: Text;
    character_limit: Nat;
    categories: CategoryArray;
    selection_parameters: SelectionParameters;
    scheduler_parameters: SchedulerParameters;
    prices: PriceRegister;
    momentum: Momentum;
  };

  public type SchedulerParameters = {
    censor_timeout            : Duration;
    candidate_status_duration : Duration;
    open_status_duration      : Duration;
    rejected_status_duration  : Duration;
  };

  public type ConvictionsParameters = {
    vote_half_life: Duration;
    late_ballot_half_life: Duration;
  };

  public type BasePriceParameters = {
    base_selection_period         : Duration;
    open_vote_price_e8s           : Nat;
    reopen_vote_price_e8s         : Nat;
    interest_vote_price_e8s       : Nat;
    categorization_vote_price_e8s : Nat;
  };

  public type BallotConvictionInput = {
    cursor: Cursor;
    date: Time;
    categorization: CursorArray;
    vote_decay: Float;
    late_ballot_decay: ?Float;
  };

  public type SubParameters = {
    name: Text;
    character_limit: Nat;
    categories: CategoryArray;
    scheduler: SchedulerParameters;
    selection: SelectionParameters;
    convictions: ConvictionsParameters;
  };

  public type SelectionParameters = {
    selection_period : Duration;
    minimum_score    : Float;
  };

  public type Momentum = {
    num_votes_opened     : Nat;
    selection_score      : Float;
    last_pick: ?{
      date        : Time;
      vote_score  : Float;
      total_votes : Nat;
    };
  };

  public type PriceRegister = {
    open_vote_price_e8s           : Nat;
    reopen_vote_price_e8s         : Nat;
    interest_vote_price_e8s       : Nat;
    categorization_vote_price_e8s : Nat;
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

  public type Vote<T, A> = {
    id: VoteId;
    ballots: [(Principal, VoteTypes.Ballot<T>)];
    aggregate: A;
  };
  public type StatusHistory = Buffer<StatusInfo>;

  public type VoteKindAggregate = {
    #INTEREST: Appeal;
    #OPINION: OpinionAggregate;
    #CATEGORIZATION: PolarizationArray;
  };

  public type VoteKindBallot = {
    #INTEREST: RevealedInterestBallot;
    #OPINION: RevealedOpinionBallot;
    #CATEGORIZATION: RevealedCategorizationBallot;
  };

  public type VoteAggregate = {
    vote_id: VoteId;
    aggregate: VoteKindAggregate;
  };

  public type StatusVoteAggregates = {
    vote_aggregates: [VoteAggregate];
  };

  public type StatusData = {
    status_info: StatusInfo;
    previous_status: ?StatusVoteAggregates;
  };

  public type VoteData = {
    id: VoteId;
    iteration: Nat;
    status: VoteStatus;
    user_ballot: ?VoteKindBallot;
  };

  public type QueryQuestionItem = {
    question: Question;
    status_data: StatusData;
  };

  public type QueryVoteItem = {
    question_id: QuestionId;
    question: ?Question;
    vote: (VoteKind, VoteData);
  };

  public type PrincipalError = {
    #PrincipalIsAnonymous;
  };

  public type AccessControlRole = {
    #MASTER;
  };
  
  public type AccessControlError = {
    #AccessDenied: ({required_role: AccessControlRole;})
  };

  public type AddCategoryError = AccessControlError or {
    #CategoryAlreadyExists;
  };

  public type RemoveCategoryError = AccessControlError or {
    #CategoryDoesntExist;
  };

  public type GetQuestionError = {
    #QuestionNotFound;
  };

  public type ReopenQuestionError = PrincipalError or GetQuestionError or {
    #InvalidStatus;
    #OpenInterestVoteFailed: OpenVoteError;
  };

  public type SetPickRateError = AccessControlError;

  public type SetSchedulerParametersError = AccessControlError;

  public type GetUserConvictionsError = PrincipalError;

  public type GetUserVotesError = PrincipalError;

};