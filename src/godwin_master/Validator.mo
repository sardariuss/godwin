import Types              "Types";

import GodwinSub          "../godwin_sub/main";
import SubTypes           "../godwin_sub/model/Types";
import TextUtils          "../godwin_sub/utils/Text";
import Duration           "../godwin_sub/utils/Duration";

import Set                "mo:map/Set";
import Map                "mo:map/Map";

import Result             "mo:base/Result";
import Array              "mo:base/Array";
import Principal          "mo:base/Principal";
import Option             "mo:base/Option";
import Text               "mo:base/Text";

module {

  type Result<Ok, Err>       = Result.Result<Ok, Err>;
  type Set<K>                = Set.Set<K>;
  type Map<K, V>             = Map.Map<K, V>;

  type CreateSubGodwinError  = Types.CreateSubGodwinError;
  type SetUserNameError      = Types.SetUserNameError;
  type ValidationParams      = Types.ValidationParams;
  
  type CategoryArray         = SubTypes.CategoryArray;
  type SubParameters         = SubTypes.SubParameters;
  type SchedulerParameters   = SubTypes.SchedulerParameters;
  type ConvictionsParameters = SubTypes.ConvictionsParameters;
  type CategoryInfo          = SubTypes.CategoryInfo;
  type Category              = SubTypes.Category;
  type PriceParameters       = SubTypes.PriceParameters;

  type Duration              = Duration.Duration;

  public class Validator(_validation: ValidationParams) {

    public func validateSubGodwinParams(identifier: Text, params: SubParameters, sub_identifiers: Set<(Principal, Text)>) : Result<(), CreateSubGodwinError> {

      type Res = Result<(), CreateSubGodwinError>;
      type Err = CreateSubGodwinError;

      let { name; categories; scheduler; convictions; character_limit; minimum_interest_score; } = params;

      Result.chain<(), (), Err>(validateSubIdentifier(identifier, sub_identifiers),             func() : Res {
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

    public func validateSubIdentifier(new: Text, sub_identifiers: Set<(Principal, Text)>) : Result<(), CreateSubGodwinError> {
      let { min_length; max_length; } = _validation.subgodwin.identifier;
      if (Text.size(new) < min_length){
        return #err(#IdentifierTooShort({min_length}));
      };
      if (Text.size(new) > max_length){
        return #err(#IdentifierTooLong({max_length}));
      };
      if (not TextUtils.isAlphaNumeric(new)){
        return #err(#InvalidIdentifier);
      };
      if (Option.isSome(Set.find(sub_identifiers, func((_, identifier) : (Principal, Text)) : Bool { identifier == new; }))){
        return #err(#IdentifierAlreadyTaken);
      };
      #ok;
    };

    public func validateSubName(name: Text) : Result<(), CreateSubGodwinError> {
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

      let { minimum_duration; maximum_duration; } = _validation.subgodwin.scheduler_params;

      if (Duration.toTime(duration) < Duration.toTime(minimum_duration)){
        return #err(#DurationTooShort({minimum_duration}));
      };

      if (Duration.toTime(duration) > Duration.toTime(maximum_duration)){
        return #err(#DurationTooLong({maximum_duration}));
      };

      #ok;
    };

    public func validateConvictionDuration(duration: Duration) : Result<(), CreateSubGodwinError> {

      let { minimum_duration; maximum_duration; } = _validation.subgodwin.convictions_params;

      if (Duration.toTime(duration) < Duration.toTime(minimum_duration)){
        return #err(#DurationTooShort({minimum_duration}));
      };

      if (Duration.toTime(duration) > Duration.toTime(maximum_duration)){
        return #err(#DurationTooLong({maximum_duration}));
      };

      #ok;
    };

    public func validateCharacterLimit(character_limit: Nat) : Result<(), CreateSubGodwinError> {
      let { maximum; } = _validation.subgodwin.question_char_limit;
      
      if (character_limit > maximum){
        return #err(#CharacterLimitTooLong({maximum}));
      };

      #ok;
    };

    public func validateMinimumInterestScore(minimum_interest_score: Float) : Result<(), CreateSubGodwinError> {
      let { minimum; } = _validation.subgodwin.minimum_interest_score;
      
      if (minimum_interest_score < minimum){
        return #err(#MinimumInterestScoreTooLow({minimum}));
      };

      #ok;
    };

    // @todo: have a user name regexp (that e.g. does not allow only whitespaces, etc.)
    public func validateUserName(principal: Principal, name: Text, users: Map<Principal, Text>) : Result<(), SetUserNameError> {
      
      // Check if the principal is anonymous
      if (Principal.isAnonymous(principal)){
        return #err(#AnonymousNotAllowed);
      };
      
      let { min_length; max_length; } = _validation.username;
      
      // Check if not too short
      if (name.size() < min_length){
        return #err(#NameTooShort({min_length}));
      };
      
      // Check if not too long
      if (name.size() > max_length){
        return #err(#NameTooLong({max_length}));
      };
      
      // Check if the name is already taken
      if (Map.some(users, func(key: Principal, value: Text) : Bool { Principal.notEqual(key, principal) and value == name; })){
        return #err(#NameAlreadyTaken);
      };

      #ok;
    };

  };

};