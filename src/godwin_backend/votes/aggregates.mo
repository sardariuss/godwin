import Option "mo:base/Option";

module {

  public func updateAggregate<B, A>(
    aggregate: A,
    new_ballot: ?B,
    old_ballot: ?B,
    add_to_aggregate: (A, B) -> A,
    remove_from_aggregate: (A, B) -> A
  ) : A {
    var new_aggregate = aggregate;
    // If there is a new ballot, add it to the aggregate
    Option.iterate(new_ballot, func(ballot: B) {
      new_aggregate := add_to_aggregate(new_aggregate, ballot);
    });
    // If there was an old ballot, remove it from the aggregate
    Option.iterate(old_ballot, func(ballot: B) {
      new_aggregate := remove_from_aggregate(new_aggregate, ballot);
    });
    new_aggregate;
  };

};