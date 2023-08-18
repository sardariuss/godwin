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
    creator                     : Principal;
    creation_date               : Time;
    name                        : Ref<Text>;
    master                      : Ref<Principal>;
    categories                  : Map<Category, CategoryInfo>;
    scheduler_params            : Ref<SchedulerParameters>;
    base_price_params           : Ref<BasePriceParameters>;
    selection_params            : Ref<SelectionParameters>;
    questions                   : QuestionsRegister;
    momentum                    : Ref<Momentum>;
    price_register              : Ref<PriceRegister>;
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
      creator_rewards              : Map<VoteId, MintResult>;
    };
    votes                       : {
      interest                     : {
        register                      : InterestVoteRegister;
        open_by                       : Map<Principal, Map<VoteId, Time>>;
        voters_history                : Map<Principal, Map<QuestionId, Map<Nat, VoteId>>>;
        joins                         : JoinsRegister;
        transactions                  : Map<Principal, Map<VoteId, TransactionsRecord>>;
       };
      opinion                      : {
        register                      : OpinionVoteRegister;
        voters_history                : Map<Principal, Map<QuestionId, Map<Nat, VoteId>>>;
        joins                         : JoinsRegister;
        vote_decay_params             : Ref<DecayParameters>;
        late_ballot_decay_params      : Ref<DecayParameters>;
      };
      categorization               : {
        register                      : CategorizationVoteRegister;
        voters_history                : Map<Principal, Map<QuestionId, Map<Nat, VoteId>>>;
        joins                         : JoinsRegister;
        transactions                  : Map<Principal, Map<VoteId, TransactionsRecord>>;
      };
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
    creator: Principal;
    sub_parameters: SubParameters;
    price_parameters: BasePriceParameters;
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
    #HOTNESS;
    #ARCHIVE;
    #TRASH;
    #OPINION_VOTE;
  };
  
  public type Key = {
    #AUTHOR: AuthorEntry;
    #TEXT: TextEntry;
    #DATE: DateEntry;
    #STATUS: StatusEntry;
    #HOTNESS: InterestScore;
    #ARCHIVE: DateEntry;
    #TRASH: DateEntry;
    #OPINION_VOTE: OpinionVoteEntry;
  };

  public type QueriesRegister = Map<OrderBy, Inner<Key>>;
  
  type Inner<Key> = {
    key_map: Map<Nat, Key>;
    var ordered_set: OrderedSet<Key>;
  };

  public type VoteRegister<T, A> = {
    votes: Map<VoteId, Vote<T, A>>;
    var index: VoteId;
  };

  public type VoteStatus = {
    #OPEN;
    #LOCKED;
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
    negative_score_date: ?Time;
    hot_timestamp: Float;
    hotness: Float;
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
    #YEARS: Nat;
    #DAYS: Nat;
    #HOURS: Nat;
    #MINUTES: Nat;
    #SECONDS: Nat;
    #NS: Nat;
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

  public type ConvictionsParameters = {
    vote_half_life: Duration;
    late_ballot_half_life: Duration;
  };

  public type SubParameters = {
    name: Text;
    categories: CategoryArray;
    scheduler: SchedulerParameters;
    character_limit: Nat;
    convictions: ConvictionsParameters;
    selection: SelectionParameters;
  };

  public type SelectionParameters = {
    selection_period : Duration;
    minimum_score    : Float;
  };

  public type DecayParameters = {
    half_life: Duration;
    lambda: Float;
    shift: Float;
  };

  public type SchedulerParameters = {
    censor_timeout            : Duration;
    candidate_status_duration : Duration;
    open_status_duration      : Duration;
    rejected_status_duration  : Duration;
  };

  public type BasePriceParameters = {
    base_selection_period         : Duration;
    open_vote_price_e8s           : Nat;
    reopen_vote_price_e8s         : Nat;
    interest_vote_price_e8s       : Nat;
    categorization_vote_price_e8s : Nat;
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

  public type VoteId = Nat;
  public type Cursor = Float;

  public type OpinionAnswer = {
    cursor: Cursor;
    late_decay: ?Float;
  };

  public type OpinionAggregate = { 
    polarization: Polarization;
    decay: ?Float;
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
  public type AccessControlRole = {
    #ADMIN;
    #SUB;
  };

  public type AccessControlError = {
    #AccessDenied: ({ required_role: AccessControlRole });
  };

  public type MasterTransferError = TransferError or AccessControlError;

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