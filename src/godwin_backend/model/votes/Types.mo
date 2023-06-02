import RepresentationTypes "representation/Types";
import PayTypes            "../token/Types";

import Trie                "mo:base/Trie";
import Principal           "mo:base/Principal";
import Result              "mo:base/Result";

import Map                 "mo:map/Map";
import Set                 "mo:map/Set";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Principal = Principal.Principal;
  // For convenience: from other modules
  type Map<K, V> = Map.Map<K, V>;
  type Set<K> = Set.Set<K>;

  public type Category        = RepresentationTypes.Category;
  public type Cursor          = RepresentationTypes.Cursor;
  public type Polarization    = RepresentationTypes.Polarization;
  public type CursorMap       = RepresentationTypes.CursorMap;
  public type PolarizationMap = RepresentationTypes.PolarizationMap;
  public type Interest        = RepresentationTypes.Interest;
  public type Appeal          = RepresentationTypes.Appeal;

  public type VoteId = Nat;
  public let voteHash = Map.nhash;

  public type VoteHistory = [VoteId];
  public type VoterHistory = Set<VoteId>;

  public type Status = {
    #OPEN;
    #CLOSED;
  };

  public type Vote<T, A> = {
    id: VoteId;
    var status: Status;
    ballots: Map<Principal, Ballot<T>>;
    var aggregate: A;
  };

  public type Ballot<T> = {
    date: Int;
    answer: T;
  };

  public type InterestBallot = Ballot<Interest>;
  public type OpinionBallot = Ballot<Cursor>;
  public type CategorizationBallot = Ballot<CursorMap>;

  public type InterestVote = Vote<Interest, Appeal>;
  public type OpinionVote = Vote<Cursor, Polarization>;
  public type CategorizationVote = Vote<CursorMap, PolarizationMap>;

  public type Voter = {
    interests: Set<VoteId>;
    opinions: Set<VoteId>;
    categorizations: Set<VoteId>;
  };

  public type BallotChangeAuthorization = {
    #BALLOT_CHANGE_AUTHORIZED;
    #BALLOT_CHANGE_FORBIDDEN;
  };

  public type PrincipalError = {
    #PrincipalIsAnonymous;
  };

  public type FindVoteError = {
    #QuestionNotFound;
    #IterationOutOfBounds;
  };

  public type FindQuestionIterationError = {
    #VoteNotFound;
  };

  public type OpenVoteError = {
    #PayinError: PayTypes.PayinError;
  };

  public type GetVoteError = {
    #VoteNotFound;
  };

  public type RevealVoteError = {
    #VoteNotFound;
    #VoteOpen;
  };

  public type CloseVoteError = {
    #AlreadyClosed;
    #VoteNotFound;
    #NoSubacountLinked;
  };

  public type FindBallotError = {
    #BallotNotFound;
    #VoteNotFound;
  };

  public type AddBallotError = {
    #PrincipalIsAnonymous;
    #VoteClosed;
    #InvalidBallot;
  };

  public type RemoveBallotError = {
    #PrincipalIsAnonymous;
    #VoteNotFound;
    #VoteClosed;
    #ChangeBallotNotAllowed;
  };

  public type PutBallotError = AddBallotError or {
    #VoteLocked;
    #VoteNotFound;
    #ChangeBallotNotAllowed;
    #NoSubacountLinked;
    #PayinError: PayTypes.PayinError;
  };

};