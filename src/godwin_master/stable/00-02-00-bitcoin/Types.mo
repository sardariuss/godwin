import Map                "mo:map/Map";

module {

  type Map<K, V> = Map.Map<K, V>;

  public type State = {
    token                   : Ref<Principal>;
    admin                   : Ref<Principal>;
    cycles_parameters       : Ref<CyclesParameters>;
    price_parameters        : Ref<PriceParameters>;
    validation_parameters   : Ref<ValidationParams>;
    sub_godwins             : Map<Principal, Text>;
    users                   : Map<Principal, Text>;
  };

  public type Args = {
    #init: InitArgs;
    #upgrade: UpgradeArgs;
    #downgrade: DowngradeArgs;
    #none;
  };

  public type InitArgs = {
    token                  : Principal;
    admin                  : Principal;
    cycles_parameters      : CyclesParameters;
    price_parameters       : PriceParameters;
    validation_parameters  : ValidationParams;
  };
  public type UpgradeArgs = {
    price_parameters       : PriceParameters;
  };
  public type DowngradeArgs = {
  };

  type Duration = {
    #YEARS   : Nat;
    #DAYS    : Nat;
    #HOURS   : Nat;
    #MINUTES : Nat;
    #SECONDS : Nat;
    #NS      : Nat;
  };

  type Ref<V> = {
    var v: V;
  };

  public type ValidationParams = {
    username: {
      min_length: Nat;
      max_length: Nat;
    };
    subgodwin: {
      identifier: {
        min_length: Nat;
        max_length: Nat;
      };
      subname: {
        min_length: Nat;
        max_length: Nat;
      };
      scheduler_params: {
        minimum_duration: Duration;
        maximum_duration: Duration;
      };
      convictions_params: {
        minimum_duration: Duration;
        maximum_duration: Duration;
      };
      question_char_limit: {
        maximum: Nat;
      };
      minimum_interest_score: {
        minimum: Float;
      };
    };
  };

  public type PriceParameters = {
    open_vote_price_sats           : Nat;
    reopen_vote_price_sats         : Nat;
    interest_vote_price_sats       : Nat;
    categorization_vote_price_sats : Nat;
    sub_creation_price_sats        : Nat;
  };

  public type CyclesParameters = {
    create_sub_cycles             : Nat;
    upgrade_sub_cycles            : Nat;
  };

};