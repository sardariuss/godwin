import Buffer "mo:stablebuffer/StableBuffer";
import RBT    "mo:stableRBT/StableRBTree";

import Trie   "mo:base/Trie";
import Result "mo:base/Result";
import Error  "mo:base/Error";

import Map    "mo:map/Map";
import Set    "mo:map/Set";


// please do not import any types from your project outside migrations folder here
// it can lead to bugs when you change those types later, because migration types should not be changed
// you should also avoid importing these types anywhere in your project directly from here
// use MigrationTypes.Current property instead
module {

  type Time            = Int;
  type Trie<K, V>      = Trie.Trie<K, V>;
  type Buffer<T>       = Buffer.StableBuffer<T>;
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Map<K, V>       = Map.Map<K, V>;
  type Set<K>          = Set.Set<K>;
  type OrderedSet<K>   = RBT.Tree<K, ()>;

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type State = {
    name                        : Ref<Text>; // @todo: this shouldn't be a ref
    master                      : Ref<Principal>; // @todo: this shouldn't be a ref
    creation_date               : Time;
    categories                  : Map<Category, CategoryInfo>;
    questions                   : QuestionsRegister;
    momentum_args               : Ref<InterestMomentumArgs>;
    price_params                : Ref<PriceParameters>;
    scheduler_params            : Ref<SchedulerParameters>;
    decay_params                : {
      opinion_vote                 : Ref<DecayParameters>;
      late_opinion_ballot          : Ref<DecayParameters>;
    };
    status                      : {
      register                     : Map<Nat, StatusHistory>;
    };
    queries                     : {
      register                     : QueriesRegister;
    };
    opened_questions            : {
      register                     : Map<Nat, (Principal, Blob)>;
      index                        : Ref<Nat>;
      transactions                 : Map<Principal, Map<VoteId, TransactionsRecord>>;
    };
    votes                       : {
      interest                     : {
        register                      : InterestVoteRegister;
        transactions                  : Map<Principal, Map<VoteId, TransactionsRecord>>;
       };
      opinion                      : {
        register                      : OpinionVoteRegister;
      };
      categorization               : {
        register                      : CategorizationVoteRegister;
        transactions                  : Map<Principal, Map<VoteId, TransactionsRecord>>;
      };
    };
    joins                       : {
      interests                    : JoinsRegister;
      opinions                     : JoinsRegister;
      categorizations              : JoinsRegister;
    };
  };

  public type Args = {
    #init: InitArgs;
    #upgrade: UpgradeArgs;
    #downgrade: DowngradeArgs;
    #none;
  };

  public type InitArgs = {
    master: Principal;
    parameters: Parameters;
  };
  public type UpgradeArgs = {
  };
  public type DowngradeArgs = {
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public type Ref<V> = {
    var v: V;
  };

  public type QuestionId = Nat;

  public type Question = {
    id: QuestionId;
    author: Principal;
    text: Text;
    date: Time;
  };

  public type QuestionsRegister = {
    questions: Map<QuestionId, Question>;
    var question_index: QuestionId;
    var character_limit: Nat;
    by_author: Map<Principal, Set<QuestionId>>;
  };

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

  public type QueriesRegister = Map<OrderBy, Inner<Key>>;
  
  type Inner<Key> = {
    key_map: Map<Nat, Key>;
    var ordered_set: OrderedSet<Key>;
  };

  public type VoteRegister<T, A> = {
    votes: Map<VoteId, Vote<T, A>>;
    voters_history: Map<Principal, Set<VoteId>>;
    var index: VoteId;
  };

  public type VoteStatus = {
    #OPEN;
    #CLOSED;
  };

  public type Vote<T, A> = {
    id: VoteId;
    var status: VoteStatus;
    ballots: Map<Principal, Ballot<T>>;
    var aggregate: A;
  };

  public type InterestVoteRegister = VoteRegister<Interest, Appeal>;
  public type OpinionVoteRegister = VoteRegister<OpinionAnswer, OpinionAggregate>;
  public type CategorizationVoteRegister = VoteRegister<CursorMap, PolarizationMap>;

  public type JoinsRegister = {
    indexed_by_question : Map<QuestionId, Map<Nat, VoteId>>;
    indexed_by_vote     : Map<VoteId, (QuestionId, Nat)>;
  };

  public type Ballot<T> = {
    date: Time;
    answer: T;
  };

  public type Interest = {
    #UP;
    #DOWN;
  };

  public type Appeal = {
    ups: Nat;
    downs: Nat;
    score: Float;
    last_score_switch: ?Time;
  };

  public type DateEntry        = { question_id: Nat; date: Time; };
  public type TextEntry        = DateEntry and { text: Text; };
  public type AuthorEntry      = DateEntry and { author: Principal; };
  public type StatusEntry      = DateEntry and { status: Status; };
  public type InterestScore    = { question_id: Nat; score: Float; };
  public type OpinionVoteEntry = DateEntry and { is_late: Bool; };

  public type Status = {
    #CANDIDATE;
    #OPEN;
    #CLOSED;
    #REJECTED: {
      #TIMED_OUT;
      #CENSORED;
    };
  };

  public type VoteKind = {
    #INTEREST;
    #OPINION;
    #CATEGORIZATION;
  };

  public type VoteLink = {
    vote_kind: VoteKind;
    vote_id: Nat;
  };

  public type StatusInfo = {
    status: Status;
    date: Time;
    iteration: Nat;
    votes: [VoteLink];
  };

  public type StatusHistory = Buffer<StatusInfo>;

  public type Duration = {
    #DAYS: Nat;
    #HOURS: Nat;
    #MINUTES: Nat;
    #SECONDS: Nat;
    #NS: Nat;
  };

  public type InterestMomentumArgs = {
    last_pick_date : Time;
    last_pick_score: Float;
    num_votes_opened: Nat;
    minimum_score: Float;
  };

  public type Parameters = {
    name: Text;
    categories: CategoryArray;
    scheduler: SchedulerParameters;
    questions: QuestionsParameters;
    prices: PriceParameters;
    opinion: {
      vote_half_life: Duration;
      late_ballot_half_life: Duration;
    };
    minimum_interest_score: Float;
  };

  public type DecayParameters = {
    half_life: Duration;
    lambda: Float;
    shift: Float;
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

  public type VoteId = Nat;
  public type Cursor = Float;

  public type OpinionAnswer = {
    cursor: Cursor;
    is_late: ?Float;
  };

  public type OpinionAggregate = { 
    polarization: Polarization;
    is_locked: ?Float;
  };

  public type Polarization = {
    left: Float;
    center: Float;
    right: Float;
  };

  public type CursorMap = Trie<Category, Cursor>;
  
  public type PolarizationMap = Trie<Category, Polarization>;

  // ICRC-1 types
  public type TxIndex = Nat;
  public type Balance = Nat;
  public type Subaccount = Blob;
  public type Timestamp = Nat64;
  public type Account = {
    owner : Principal;
    subaccount : ?Subaccount;
  };
  public type TransferArgs = {
    from_subaccount : ?Subaccount;
    to : Account;
    amount : Balance;
    fee : ?Balance;
    memo : ?Blob;
    created_at_time : ?Nat64;
  };
  public type Mint = {
    to : Account;
    amount : Balance;
    memo : ?Blob;
    created_at_time : ?Nat64;
  };
  public type TimeError = {
    #TooOld;
    #CreatedInFuture : { ledger_time : Timestamp };
  };
  public type TransferError = TimeError or {
    #BadFee : { expected_fee : Balance };
    #BadBurn : { min_burn_amount : Balance };
    #InsufficientFunds : { balance : Balance };
    #Duplicate : { duplicate_of : TxIndex };
    #TemporarilyUnavailable;
    #GenericError : { error_code : Nat; message : Text };
  };

  // canister token types
  public type GodwinTokenReapAccountError = {
    #InsufficientFunds : { balance : Balance; };
    #NoRecipients;
    #NegativeShare: GodwinTokenReapAccountRecipient;
    #DivisionByZero : { sum_shares : Float; };
  };
  public type GodwinTokenReapAccountRecipient = {
    account : Account;
    share : Float;
  };

  // master types
  public type MasterTransferError = TransferError or {
    #NotAllowed;
  };

  // sub/model/token types
  public type ReapAccountResult = Result<TxIndex, ReapAccountError>;
  public type CanisterCallError = {
    #CanisterCallError: Error.ErrorCode;
  };
  public type ReapAccountError = TransferError or GodwinTokenReapAccountError or CanisterCallError or {
    #SingleReapLost: {
      share: Float;
      subgodwin_subaccount: Subaccount;
    };
    #SingleTransferError: {
      args: TransferArgs;
      error: TransferError;
    };
  };
  public type MintResult = Result<TxIndex, MintError>;
  public type MintError  = MasterTransferError or CanisterCallError or { 
    #SingleMintLost: {
      amount: Balance;
    };
    #SingleMintError: {
      args: Mint;
      error: TransferError;
    };
  };

  public type TransactionsRecord = {
    payin: TxIndex;
    payout: {
      #PENDING;
      #PROCESSED: {
        refund: ?ReapAccountResult;
        reward: ?MintResult;
      };
    };
  };
  
};