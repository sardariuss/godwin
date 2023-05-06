import RepresentationTypes "representation/Types";
import PayTypes            "../token/Types";

import Trie                "mo:base/Trie";
import Principal           "mo:base/Principal";

import Map                 "mo:map/Map";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Principal = Principal.Principal;
  // For convenience: from other modules
  type Map<K, V> = Map.Map<K, V>;

  public type Category        = RepresentationTypes.Category;
  public type Cursor          = RepresentationTypes.Cursor;
  public type Polarization    = RepresentationTypes.Polarization;
  public type CursorMap       = RepresentationTypes.CursorMap;
  public type PolarizationMap = RepresentationTypes.PolarizationMap;

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

  public type Ballot<T> = {
    date: Int;
    answer: T;
  };

  public type InterestBallot = Ballot<Cursor>;
  public type OpinionBallot = Ballot<Cursor>;
  public type CategorizationBallot = Ballot<CursorMap>;

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