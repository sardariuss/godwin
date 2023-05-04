import PayTypes      "../token/Types";

import Trie          "mo:base/Trie";
import Principal     "mo:base/Principal";

import Map           "mo:map/Map";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Principal = Principal.Principal;
  // For convenience: from other modules
  type Map<K, V> = Map.Map<K, V>;

  public type VoteId = Nat;
  public let voteHash = Map.nhash;

  public type VoteHistory = {
    current: ?VoteId;
    history: [VoteId];
  };

  public type Vote<T, A> = {
    id: VoteId;
    ballots: Map<Principal, Ballot<T>>;
    var aggregate: A;
  };

  public type PublicVote<T, A> = {
    id: VoteId;
    ballots: [(Principal, Ballot<T>)];
    aggregate: A;
  };

  public type Ballot<T> = {
    date: Int;
    answer: T;
  };

  // @todo: duplicate definition in root Types
  public type Category = Text;

  // Cursor used for voting, shall be between -1 and 1, where usually:
  //  -1 means voting totally for A
  //   0 means voting totally neutral
  //   1 means voting totally for B
  //  in between values mean voting for A or B with more or less reserve.
  //
  // Example: cursor of 0.5, which means voting for B with some reserve.
  // -1                            0                             1
  // [-----------------------------|--------------()-------------]
  //
  public type Cursor = Float;

  // Polarization, used mainly to store the result of a vote.
  // Polarizations are never normalized in the backend in order to not
  // loosing its magnitude (which can represent different things, usually
  // how many people voted).
  //
  // Example: { left = 13; center = 8; right = 36; }
  // [$$$$$$$$$$$$$|@@@@@@@@|&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&]
  //     left        center                 right 
  // 
  public type Polarization = {
    left: Float;
    center: Float;
    right: Float;
  };

  // Mapping of <key=Category, value=Cursor>, used to vote to determine a question political affinity
  public type CursorMap = Trie<Category, Cursor>;
  public type CursorArray = [(Category, Cursor)];
  
  // Mapping of <key=Category, value=Polarization>, used to represent a question political affinity
  public type PolarizationMap = Trie<Category, Polarization>;
  public type PolarizationArray = [(Category, Polarization)];

  public type InterestBallot = Ballot<Cursor>;
  public type OpinionBallot = Ballot<Cursor>;
  public type CategorizationBallot = Ballot<CursorMap>;
  public type PublicCategorizationBallot = Ballot<CursorArray>;

  public type InterestVote = Vote<Cursor, Polarization>;
  public type OpinionVote = Vote<Cursor, Polarization>;
  public type CategorizationVote = Vote<CursorMap, PolarizationMap>;

  public type PrincipalError = {
    #PrincipalIsAnonymous;
  };

  public type FindCurrentVoteError = {
    #VoteLinkNotFound;
    #VoteClosed;
  };

  public type FindHistoricalVoteError = {
    #VoteLinkNotFound;
    #IterationOutOfBounds;
  };

  public type OpenVoteError = {
    #PayInError: PayTypes.PayInError;
  };

  public type GetVoteError = {
    #VoteNotFound;
  };

  public type RevealVoteError = FindHistoricalVoteError;

  public type CloseVoteError = {
    #AlreadyClosed;
    #VoteNotFound;
    #NoSubacountLinked;
  };

  public type GetBallotError = FindCurrentVoteError or {
    #BallotNotFound;
    #VoteNotFound;
  };

  public type AddBallotError = {
    #PrincipalIsAnonymous;
    #VoteClosed;
    #InvalidBallot;
  };

  public type PutBallotError = PrincipalError or FindCurrentVoteError or AddBallotError or {
    #VoteNotFound;
    #AlreadyVoted;
    #NoSubacountLinked;
    #PayInError: PayTypes.PayInError;
  };

};