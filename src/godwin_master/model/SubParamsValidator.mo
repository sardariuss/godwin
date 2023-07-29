import Types              "../Types";

import SubTypes           "../../godwin_sub/model/Types";
import TextUtils          "../../godwin_sub/utils/Text";
import Duration           "../../godwin_sub/utils/Duration";
import WRef               "../../godwin_sub/utils/wrappers/WRef";
import WMap               "../../godwin_sub/utils/wrappers/WMap";

import Set                "mo:map/Set";
import Map                "mo:map/Map";

import Result             "mo:base/Result";
import Array              "mo:base/Array";
import Principal          "mo:base/Principal";
import Text               "mo:base/Text";

module {

  type Result<Ok, Err>       = Result.Result<Ok, Err>;

  type CreateSubGodwinError  = Types.CreateSubGodwinError;
  type SetUserNameError      = Types.SetUserNameError;
  type ValidationParams      = Types.ValidationParams;
  
  type CategoryArray         = SubTypes.CategoryArray;
  type SubParameters         = SubTypes.SubParameters;
  type CategoryInfo          = SubTypes.CategoryInfo;
  type Category              = SubTypes.Category;

  type Duration              = Duration.Duration;

  type WRef<T>               = WRef.WRef<T>;
  type WMap<K, V>            = WMap.WMap<K, V>;

  public class SubParamsValidator(
    _params: WRef<ValidationParams>,
    _sub_godwins: WMap<Principal, Text>,
    _users: WMap<Principal, Text>) {

    public func getParams() : ValidationParams {
      _params.get();
    };

    public func setParams(params: ValidationParams) {
      _params.set(params);
    };

    public func validateSubGodwinParams(identifier: Text, params: SubParameters) : Result<(), CreateSubGodwinError> {

      type Res = Result<(), CreateSubGodwinError>;
      type Err = CreateSubGodwinError;

      let { name; categories; scheduler; convictions; character_limit; minimum_interest_score; } = params;

      Result.chain<(), (), Err>(validateSubIdentifier(identifier),                              func() : Res {
      Result.chain<(), (), Err>(validateSubName(name),                                          func() : Res {
      Result.chain<(), (), Err>(validateCategories(categories),                                 func() : Res {
      Result.chain<(), (), Err>(validateSchedulerDuration(scheduler.question_pick_period),      func() : Res {
      Result.chain<(), (), Err>(validateSchedulerDuration(scheduler.censor_timeout),            func() : Res {
      Result.chain<(), (), Err>(validateSchedulerDuration(scheduler.candidate_status_duration), func() : Res {
      Result.chain<(), (), Err>(validateSchedulerDuration(scheduler.open_status_duration),      func() : Res {
      Result.chain<(), (), Err>(validateSchedulerDuration(scheduler.rejected_status_duration),  func() : Res {
      Result.chain<(), (), Err>(validateConvictionDuration(convictions.vote_half_life),         func() : Res {
      Result.chain<(), (), Err>(validateConvictionDuration(convictions.late_ballot_half_life),  func() : Res {
      Result.chain<(), (), Err>(validateCharacterLimit(character_limit),                        func() : Res {
                                validateMinimumInterestScore(minimum_interest_score); })})})})})})})})})})});
    };

    public func validateSubIdentifier(new: Text) : Result<(), CreateSubGodwinError> {
      let { min_length; max_length; } = getParams().subgodwin.identifier;
      if (Text.size(new) < min_length){
        return #err(#IdentifierTooShort({min_length}));
      };
      if (Text.size(new) > max_length){
        return #err(#IdentifierTooLong({max_length}));
      };
      if (not TextUtils.isAlphaNumeric(new)){
        return #err(#InvalidIdentifier);
      };
      if (isIdentifierAlreadyTaken(new)){
        return #err(#IdentifierAlreadyTaken);
      };
      #ok;
    };

    public func validateSubName(name: Text) : Result<(), CreateSubGodwinError> {
      let { min_length; max_length; } = getParams().subgodwin.subname;
      if (Text.size(name) < min_length){
        return #err(#NameTooShort({min_length}));
      };
      if (Text.size(name) > max_length){
        return #err(#NameTooLong({max_length}));
      };
      #ok;
    };

    public func validateCategories(categories: CategoryArray) : Result<(), CreateSubGodwinError> {
      
      let set = Set.fromIter<Text>(Array.vals(Array.map(categories, func((c, _) : (Category, CategoryInfo)) : Category { c; })), Set.thash);

      if (Set.size(set) == 0){
        return #err(#NoCategories);
      };
      
      if (Set.size(set) > categories.size()){
        return #err(#CategoryDuplicate);
      };
      
      #ok;
    };

    public func validateSchedulerDuration(duration: Duration) : Result<(), CreateSubGodwinError> {

      let { minimum_duration; maximum_duration; } = getParams().subgodwin.scheduler_params;

      if (Duration.toTime(duration) < Duration.toTime(minimum_duration)){
        return #err(#DurationTooShort({minimum_duration}));
      };

      if (Duration.toTime(duration) > Duration.toTime(maximum_duration)){
        return #err(#DurationTooLong({maximum_duration}));
      };

      #ok;
    };

    public func validateConvictionDuration(duration: Duration) : Result<(), CreateSubGodwinError> {

      let { minimum_duration; maximum_duration; } = getParams().subgodwin.convictions_params;

      if (Duration.toTime(duration) < Duration.toTime(minimum_duration)){
        return #err(#DurationTooShort({minimum_duration}));
      };

      if (Duration.toTime(duration) > Duration.toTime(maximum_duration)){
        return #err(#DurationTooLong({maximum_duration}));
      };

      #ok;
    };

    public func validateCharacterLimit(character_limit: Nat) : Result<(), CreateSubGodwinError> {
      let { maximum; } = getParams().subgodwin.question_char_limit;
      
      if (character_limit > maximum){
        return #err(#CharacterLimitTooLong({maximum}));
      };

      #ok;
    };

    public func validateMinimumInterestScore(minimum_interest_score: Float) : Result<(), CreateSubGodwinError> {
      let { minimum; } = getParams().subgodwin.minimum_interest_score;
      
      if (minimum_interest_score < minimum){
        return #err(#MinimumInterestScoreTooLow({minimum}));
      };

      #ok;
    };

    // @todo: have a user name regexp (that e.g. does not allow only whitespaces, etc.)
    public func validateUserName(principal: Principal, name: Text) : Result<(), SetUserNameError> {
      
      // Check if the principal is anonymous
      if (Principal.isAnonymous(principal)){
        return #err(#AnonymousNotAllowed);
      };
      
      let { min_length; max_length; } = getParams().username;
      
      // Check if not too short
      if (name.size() < min_length){
        return #err(#NameTooShort({min_length}));
      };
      
      // Check if not too long
      if (name.size() > max_length){
        return #err(#NameTooLong({max_length}));
      };
      
      // Check if the name is already taken
      if (_users.some(func(key: Principal, value: Text) : Bool { Principal.notEqual(key, principal) and value == name; })){
        return #err(#NameAlreadyTaken);
      };

      #ok;
    };

    func isIdentifierAlreadyTaken(identifier: Text) : Bool {
      let identifiers = Set.fromIter(_sub_godwins.vals(), Map.thash);
      return Set.has(identifiers, Map.thash, identifier);
    };

  };

};