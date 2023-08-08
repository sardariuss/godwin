import InterestRules "votes/InterestRules";

import Types        "../stable/Types";

import Ref          "../utils/Ref";
import WRef         "../utils/wrappers/WRef";
import Duration     "../utils/Duration";

module {

  type Time                = Int;

  type Ref<T>              = Ref.Ref<T>;
  type WRef<T>             = WRef.WRef<T>;

  type SelectionParameters = Types.Current.SelectionParameters;
  type Appeal              = Types.Current.Appeal;
  type Momentum            = Types.Current.Momentum;

  public func build(momentum: Ref<Momentum>, selection_params: Ref<SelectionParameters>) : SubMomentum {
    SubMomentum(WRef.WRef<Momentum>(momentum), WRef.WRef<SelectionParameters>(selection_params));
  };

  public class SubMomentum(_momentum: WRef<Momentum>, _selection_params: WRef<SelectionParameters>) {

    public func get() : Momentum {
      _momentum.get();
    };

    public func setMinimumScore(minimum_score: Float) {
      _momentum.set({ _momentum.get() with minimum_score; });
    };

    public func setLastPick(date: Time, appeal: Appeal) {
      let old = _momentum.get();
      _momentum.set({ old with 
        last_pick = ?{ 
          date;
          vote_score = appeal.score;
          total_votes = appeal.ups + appeal.downs; 
        }; 
        num_votes_opened = old.num_votes_opened + 1; 
      });
      update(date);
    };

    public func update(date: Time) {
      switch(_momentum.get().last_pick){
        case(null) {}; // Nothing to do
        case(?last_pick){
          let { selection_period; minimum_score; } = _selection_params.get();
          let selection_score = InterestRules.computeSelectionScore({
            last_pick_date_ns    = last_pick.date;
            last_pick_score      = last_pick.vote_score;
            num_votes_opened     = _momentum.get().num_votes_opened;
            minimum_score        = minimum_score;
            pick_period          = Duration.toTime(selection_period);
            current_time         = date;
          });
          _momentum.set({_momentum.get() with selection_score;});
        };
      };
    };

  };

};