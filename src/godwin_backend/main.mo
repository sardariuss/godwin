import Register "register";

import RBT "mo:stableRBT/StableRBTree";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Result "mo:base/Result";
import TrieSet "mo:base/TrieSet";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";

shared({ caller = initializer }) actor class Godwin() = {
  
  type QuestionStatus = {
    #CREATED;
    #CAN_VOTE;
    #CAN_CATEGORIZE;
    #CLOSED;
  };

  type Question = {
    id: Nat;
    author: Principal;
    title: Text;
    text: Text;
    status: QuestionStatus;
    endorsements: Nat; // Number of endorsements
    votes: Trie<Opinion, Nat>; // Number of votes for each opinion
    categorization: Trie<PoliticalDimension, PoliticalSideTotal>; // Number of categorization votes for each political dimension
  };

  type PoliticalDimension = Text;
  type PoliticalSide = Text;
  type PoliticalSides = (PoliticalSide, PoliticalSide);

  type Direction = {
    #LR;
    #RL;
  };

  type PoliticalSideTotal = {
    lr: Nat;
    rl: Nat;
  };

  type CategorizationVote = {
    dimension: PoliticalDimension;
    direction: Direction;
  };

  type User = {
    principal: Principal;
    name: ?Text;
    profile: Trie<PoliticalDimension, Float>;
  };

  type Trie<K, V> = Trie.Trie<K, V>;
  type Key<K> = Trie.Key<K>;
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Principal = Principal.Principal;
  type Set<K> = TrieSet.Set<K>;

  func keyText(t: Text) : Key<Text> { { key = t; hash = Text.hash(t) } };
  func keyNat(n: Nat) : Key<Nat> { { key = n; hash = Int.hash(n) } };
  func keyPrincipal(p: Principal) : Key<Principal> { { key = p; hash = Principal.hash(p) } };
  func keyOpinion(o: Opinion) : Key<Opinion> { 
    switch(o){
      case(#ABS_AGREE){
        { key = #ABS_AGREE; hash = Int.hash(0); }
      };
      case(#RATHER_AGREE){
        { key = #RATHER_AGREE; hash = Int.hash(1); }
      };
      case(#NEUTRAL){
        { key = #NEUTRAL; hash = Int.hash(2); }
      };
      case(#RATHER_DISAGREE){
        { key = #RATHER_DISAGREE; hash = Int.hash(3); }
      };
      case(#ABS_DISAGREE){
        { key = #ABS_DISAGREE; hash = Int.hash(4); }
      };
    };
  };

  func equalOpinion(a: Opinion, b:Opinion) : Bool {
    return a == b;
  };

  type Opinion = {
    #ABS_AGREE;
    #RATHER_AGREE;
    #NEUTRAL;
    #RATHER_DISAGREE;
    #ABS_DISAGREE;
  };

  private stable var admin_ = initializer;

  private stable var opinion_parameters_ = Trie.empty<Opinion, Float>();
  opinion_parameters_ := Trie.put(opinion_parameters_, keyOpinion(#ABS_AGREE), equalOpinion, 1.0).0;
  opinion_parameters_ := Trie.put(opinion_parameters_, keyOpinion(#RATHER_AGREE), equalOpinion, 0.5).0;
  opinion_parameters_ := Trie.put(opinion_parameters_, keyOpinion(#NEUTRAL), equalOpinion, 0.0).0;
  opinion_parameters_ := Trie.put(opinion_parameters_, keyOpinion(#RATHER_DISAGREE), equalOpinion, -0.5).0;
  opinion_parameters_ := Trie.put(opinion_parameters_, keyOpinion(#ABS_DISAGREE), equalOpinion, -1.0).0;

  private stable var political_categories_ = Trie.empty<PoliticalDimension, PoliticalSides>();
  political_categories_ := Trie.put(political_categories_, keyText("IDENTITY"), Text.equal, ("CONSTRUCTIVISM", "ESSENTIALISM")).0;
  political_categories_ := Trie.put(political_categories_, keyText("COOPERATION"), Text.equal, ("INTERNATIONALISM", "NATIONALISM")).0;
  political_categories_ := Trie.put(political_categories_, keyText("PROPERTY"), Text.equal, ("COMMUNISM", "CAPITALISM")).0;
  political_categories_ := Trie.put(political_categories_, keyText("ECONOMY"), Text.equal, ("REGULATION", "LAISSEZFAIRE")).0;
  political_categories_ := Trie.put(political_categories_, keyText("CULTURE"), Text.equal, ("PROGRESSIVISM", "CONSERVATISM")).0;
  political_categories_ := Trie.put(political_categories_, keyText("TECHNOLOGY"), Text.equal, ("ECOLOGY", "PRODUCTION")).0;
  political_categories_ := Trie.put(political_categories_, keyText("JUSTICE"), Text.equal, ("REHABILITATION", "PUNITION")).0;
  political_categories_ := Trie.put(political_categories_, keyText("CHANGE"), Text.equal, ("REVOLUTION", "REFORM")).0;

  // key = question_id, value = question
  private stable var questions_ = RBT.init<Nat, Question>();
  private stable var question_index_ : Nat = 0;

  // key = user_id, value = set( question_id )
  private stable var endorsements_ = Trie.empty<Principal, Set<Nat>>();

  // key = user_id, value = map( key = question_id, value = opinion )
  private stable var votes_ = Trie.empty<Principal, Trie<Nat, Opinion>>();

  // key = user_id, value = map ( key = question_id, value = categorization_vote )
  private stable var categorizations_ = Trie.empty<Principal, Trie<Nat, CategorizationVote>>();

  public func getQuestion(question_id: Nat) : async ?Question {
    return RBT.get<Nat, Question>(questions_, Nat.compare, question_id);
  };

  public func getQuestions() : async RBT.ScanLimitResult<Nat, Question> {
    return RBT.scanLimit<Nat, Question>(questions_, Nat.compare, 0, 10, #fwd, 10);
  };

  public shared({caller}) func createQuestion(title: Text, text: Text) : async Question {
    let question = {
      id = question_index_;
      author = caller;
      title = title;
      text = text;
      status = #CREATED;
      endorsements = 0;
      votes = Trie.empty<Opinion, Nat>();
      categorization = Trie.empty<PoliticalDimension, PoliticalSideTotal>();
    };
    questions_ := RBT.put(questions_, Nat.compare, question_index_, question);
    question_index_ := question_index_ + 1;
    return question;
  };

  type EndorsementError = {
    #QuestionNotFound;
    #AlreadyEndorsed;
  };

  type GetQuestionError = {
    #QuestionNotFound;
  };

  func getQuestion_(question_id: Nat) : Result<Question, GetQuestionError> {
    switch(RBT.get<Nat, Question>(questions_, Nat.compare, question_id)){
      case(null){
        return #err(#QuestionNotFound);
      };
      case(?question){
        return #ok(question);
      };
    };
  };

  func getUserEndorsements_(user: Principal) : Set<Nat> {
    var user_endorsements = TrieSet.empty<Nat>();
    switch(Trie.get(endorsements_, keyPrincipal(user), Principal.equal)){
      case(null){};
      case(?endorsements){
        user_endorsements := endorsements;
      };
    };
    return user_endorsements;
  };

  // @todo: maybe one shall be able to remove endorsement
  public shared({caller}) func endorse(question_id: Nat) : async Result<(), EndorsementError> {
    Result.chain<Question, (), EndorsementError>(getQuestion_(question_id), func(question) {
      // Get the user endorsements (initialized with an empty set if none is found)
      var user_endorsements = getUserEndorsements_(caller);
      // Check if the question has already been endorsed
      switch(Trie.get(user_endorsements, keyNat(question_id), Nat.equal)){
        case(?question_id){
          // The user has already given his endorsement
          return #err(#AlreadyEndorsed);
        };
        case(null){
          // Add the question to the user endorsements
          user_endorsements := TrieSet.put(user_endorsements, question_id, Int.hash(question_id), Nat.equal);
          endorsements_ := Trie.put(endorsements_, keyPrincipal(caller), Principal.equal, user_endorsements).0;
          // Increase the question's endorsements
          let updated_question = {
            id = question.id;
            author = question.author;
            title = question.title;
            text = question.text;
            status = question.status;
            endorsements = question.endorsements + 1;
            votes = question.votes;
            categorization = question.categorization;
          };
          questions_ := RBT.put(questions_, Nat.compare, question_index_, updated_question);
          // Success
          return #ok;
        };
      };
    });
  };

  type VoteError = {
    #QuestionNotFound;
    #QuestionNotOpen;
    #AlreadyVoted;
  };

  func addVote_(question: Question, opinion: Opinion) : Question {
    // Get the current number of votes for this opinion
    var opinion_votes : Nat = 0;
    switch(Trie.get(question.votes, keyOpinion(opinion), equalOpinion)){
      case(null){};
      case(?total){
        opinion_votes := total;
      };
    };
    // Update the question
    return {
      id = question.id;
      author = question.author;
      title = question.title;
      text = question.text;
      status = question.status;
      endorsements = question.endorsements;
      votes = Trie.put(question.votes, keyOpinion(opinion), equalOpinion, opinion_votes).0;
      categorization = question.categorization;
    };
  };

  public shared({caller}) func vote(question_id: Nat, opinion: Opinion) : async Result<(), VoteError> {
    Result.chain<Question, (), VoteError>(getQuestion_(question_id), func(question) {
      // Verify the question status
      if (question.status == #CREATED){
        return #err(#QuestionNotOpen);
      };
      // Get the user votes (initialized with an empty list if none is found)
      var user_votes = Trie.empty<Nat, Opinion>();
      switch(Trie.get(votes_, keyPrincipal(caller), Principal.equal)){
        case(null){};
        case(?votes){
          user_votes := votes;
        };
      };
      // Check if the user has already vote on this question
      switch(Trie.get(user_votes, keyNat(question_id), Nat.equal)){
        case(?opinion){
          return #err(#AlreadyVoted);
        };
        case(null){
          // Add the vote
          user_votes := Trie.put(user_votes, keyNat(question_id), Nat.equal, opinion).0;
          votes_ := Trie.put(votes_, keyPrincipal(caller), Principal.equal, user_votes).0;
          // Add the vote to the question
          questions_ := RBT.put(questions_, Nat.compare, question_index_, addVote_(question, opinion));
          // Success
          return #ok;
        };
      };
    });
  };

  type CategorizeError = {
    #InsufficientCredentials;
    #DimensionNotFound;
    #QuestionNotFound;
    #AlreadyCategorized;
  };

  func getUserCategorizations_(user: Principal) :Trie<Nat, CategorizationVote> {
    var user_categorizations = Trie.empty<Nat, CategorizationVote>();
    switch(Trie.get(categorizations_, keyPrincipal(user), Principal.equal)){
      case(null){};
      case(?categorizations){
        user_categorizations := categorizations;
      };
    };
    return user_categorizations;
  };

  public shared({caller}) func categorize(
    question_id: Nat,
    categorization_vote: CategorizationVote
  ) : async Result<(), CategorizeError> {
    Result.chain<(), (), CategorizeError>(verifyCredentials_(caller), func () {
      Result.chain<(), (), CategorizeError>(verifyDimension_(categorization_vote.dimension), func () {
        Result.chain<Question, (), CategorizeError>(getQuestion_(question_id), func(question) {     
          // Get the user categorizations     
          var user_categorizations = getUserCategorizations_(caller);
          // Check if the user has already categorized on this question
          switch(Trie.get(user_categorizations, keyNat(question_id), Nat.equal)){
            case(?id){
              return #err(#AlreadyCategorized);
            };
            case(null){
              // Add the vote
              user_categorizations := Trie.put(user_categorizations, keyNat(question_id), Nat.equal, categorization_vote).0;
              categorizations_ := Trie.put(categorizations_, keyPrincipal(caller), Principal.equal, user_categorizations).0;
              // Add the vote to the question
              //questions_ := RBT.put(questions_, Nat.compare, question_index_, addVote_(question, opinion));
              // Success
              return #ok;
            };
          };
          return #ok; // @todo
        })
      })
    });
  };

  type VerifyCredentialsError = {
    #InsufficientCredentials;
  };

  func verifyCredentials_(caller: Principal) : Result<(), VerifyCredentialsError> {
    if (caller != admin_) {
      return #err(#InsufficientCredentials);
    };
    return #ok;
  };

  type VerifyDimensionError = {
    #DimensionNotFound;
  };

  func verifyDimension_(dimension: PoliticalDimension) : Result<(), VerifyDimensionError> {
    switch(Trie.get(political_categories_, keyText(dimension), Text.equal)){
      case(null){
        return #err(#DimensionNotFound);
      };
      case(?categorization){
        return #ok;
      };
    };
  };

};
