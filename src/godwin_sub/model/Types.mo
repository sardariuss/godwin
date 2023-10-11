import PayTypes      "token/Types";
import QuestionTypes "questions/Types";
import VoteTypes     "votes/Types";
import StableTypes   "../stable/Types";

import UtilsTypes    "../utils/Types";

import Principal     "mo:base/Principal";

module {

  // For convenience: from base module
  type Principal                             = Principal.Principal;
  type Time                                  = Int;
  
  public type Duration                       = UtilsTypes.Duration;
  public type Direction                      = UtilsTypes.Direction;
  public type ScanLimitResult<K>             = UtilsTypes.ScanLimitResult<K>;

  public type QuestionId                     = QuestionTypes.QuestionId;  
  public type Question                       = QuestionTypes.Question;
  public type Status                         = QuestionTypes.Status;
  public type OpenQuestionError              = QuestionTypes.OpenQuestionError or PayTypes.PullBtcError;
  public type QuestionOrderBy                = QuestionTypes.OrderBy;

  public type TransactionsRecord             = PayTypes.TransactionsRecord;

  public type VoteId                         = VoteTypes.VoteId;
  public type Interest                       = VoteTypes.Interest;
  public type Appeal                         = VoteTypes.Appeal;
  public type Cursor                         = VoteTypes.Cursor;
  public type OpinionAnswer                  = VoteTypes.OpinionAnswer;
  public type Polarization                   = VoteTypes.Polarization;
  public type VoteKind                       = VoteTypes.VoteKind;
  public type VoteLink                       = VoteTypes.VoteLink;
  public type VoteStatus                     = VoteTypes.VoteStatus;
  public type DecayParameters                = VoteTypes.DecayParameters;

  public type FindVoteError                  = VoteTypes.FindVoteError;
  public type OpenVoteError                  = VoteTypes.OpenVoteError;
  public type GetVoteError                   = VoteTypes.GetVoteError;
  public type RevealVoteError                = VoteTypes.RevealVoteError;
  public type CloseVoteError                 = VoteTypes.CloseVoteError;
  public type FindBallotError                = VoteTypes.FindBallotError;
  public type AddBallotError                 = VoteTypes.AddBallotError;
  public type PutBallotError                 = VoteTypes.PutBallotError;

  public type StatusInfo                     = StableTypes.Current.StatusInfo;
  public type SchedulerParameters            = StableTypes.Current.SchedulerParameters;
  public type ConvictionsParameters          = StableTypes.Current.ConvictionsParameters;
  public type PriceParameters                = StableTypes.Current.PriceParameters;
  public type SubParameters                  = StableTypes.Current.SubParameters;
  public type SelectionParameters            = StableTypes.Current.SelectionParameters;
  public type Momentum                       = StableTypes.Current.Momentum;
  public type Category                       = StableTypes.Current.Category;
  public type CategoryArray                  = StableTypes.Current.CategoryArray;
  public type CategoryInfo                   = StableTypes.Current.CategoryInfo;
  public type CategorySide                   = StableTypes.Current.CategorySide;
  public type StatusHistory                  = StableTypes.Current.StatusHistory;

  public type BallotConvictionInput = {
    cursor: Cursor;
    date: Time;
    categorization: CursorArray;
    vote_decay: Float;
    late_ballot_decay: ?Float;
  };

  public type SubInfo = {
    name: Text;
    character_limit: Nat;
    categories: CategoryArray;
    selection_parameters: SelectionParameters;
    scheduler_parameters: SchedulerParameters;
    momentum: Momentum;
  };

  // Specific to the vote facade
  public type Vote<T, A> = {
    id: VoteId;
    ballots: [(Principal, VoteTypes.Ballot<T>)];
    aggregate: A;
  };
  public type CursorArray                    = [(Category, Cursor)];
  public type PolarizationArray              = [(Category, Polarization)];
  public type InterestBallot                 = VoteTypes.InterestBallot;
  public type OpinionBallot                  = VoteTypes.OpinionBallot;
  public type OpinionAggregate               = VoteTypes.OpinionAggregate;
  public type CategorizationBallot           = VoteTypes.Ballot<CursorArray>;
  public type InterestVote                   = Vote<Interest, Appeal>;
  public type OpinionVote                    = Vote<OpinionAnswer, OpinionAggregate>;
  public type CategorizationVote             = Vote<CursorArray, PolarizationArray>;
  public type RevealableInterestBallot       = VoteTypes.RevealableBallot<Interest>;
  public type RevealableOpinionBallot        = VoteTypes.RevealableBallot<OpinionAnswer>;
  public type RevealableCategorizationBallot = VoteTypes.RevealableBallot<CursorArray>;
  public type KindAggregate = {
    #INTEREST      : Appeal;
    #OPINION       : OpinionAggregate;
    #CATEGORIZATION: PolarizationArray;
  };
  public type KindRevealableBallot = {
    #INTEREST       : RevealableInterestBallot;
    #OPINION        : RevealableOpinionBallot;
    #CATEGORIZATION : RevealableCategorizationBallot;
  };
  public type KindBallot = {
    #INTEREST       : InterestBallot;
    #OPINION        : OpinionBallot;
    #CATEGORIZATION : CategorizationBallot;
  };
  public type KindAnswer = {
    #INTEREST       : Interest;
    #OPINION        : Cursor;
    #CATEGORIZATION : CursorArray;
  };
  public type KindVote = {
    #INTEREST       : InterestVote;
    #OPINION        : OpinionVote;
    #CATEGORIZATION : CategorizationVote;
  };

  public type VoteAggregate = {
    vote_id: VoteId;
    aggregate: KindAggregate;
  };

  public type StatusVoteAggregates = {
    vote_aggregates: [VoteAggregate];
  };

  public type StatusData = {
    status_info: StatusInfo;
    previous_status: ?StatusVoteAggregates;
    is_current: Bool;
    ending_date: ?Time;
  };

  public type VoteData = {
    id: VoteId;
    iteration: Nat;
    status: VoteStatus;
    user_ballot: ?KindRevealableBallot;
  };

  public type QueryQuestionItem = {
    question: Question;
    can_reopen: Bool;
    status_data: StatusData;
  };

  public type QueryVoteItem = {
    question_id: QuestionId;
    question: ?Question;
    vote: (VoteKind, VoteData);
  };

  public type QueryOpenedVoteItem = {
    vote_id     : VoteId;
    date        : Time;
    question_id : QuestionId;
    iteration   : Nat;
    question    : ?Question;
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

  public type GetQuestionError = {
    #QuestionNotFound;
  };

  public type ReopenQuestionError = PrincipalError or GetQuestionError or {
    #InvalidStatus;
    #OpenInterestVoteFailed: OpenVoteError;
  };

  public type SetSchedulerParametersError = AccessControlError;

  public type GetUserConvictionsError = PrincipalError;

  public type GetUserVotesError = PrincipalError;

};