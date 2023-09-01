import Types         "../stable/Types";

import Ref           "../utils/Ref";
import WRef          "../utils/wrappers/WRef";
import Duration      "../utils/Duration";

import Int           "mo:base/Int";
import Float         "mo:base/Float";

module {

  type Ref<K>               = Ref.Ref<K>;
  type WRef<K>              = WRef.WRef<K>;

  type BasePriceParameters  = Types.Current.BasePriceParameters;
  type SelectionParameters  = Types.Current.SelectionParameters;
  type PriceRegister        = Types.Current.PriceRegister;

  public func computeSubPrices(base_price_params: BasePriceParameters, selection_params: SelectionParameters) : PriceRegister {
    let { base_selection_period; reopen_vote_price_e9s; open_vote_price_e9s; interest_vote_price_e9s; categorization_vote_price_e9s; } = base_price_params;
    let { selection_period } = selection_params;
    let coef = Float.fromInt(Duration.toTime(selection_period)) / Float.fromInt(Duration.toTime(base_selection_period));
    return {
      open_vote_price_e9s           = Int.abs(Float.toInt(Float.fromInt(open_vote_price_e9s          ) * coef));
      reopen_vote_price_e9s         = Int.abs(Float.toInt(Float.fromInt(reopen_vote_price_e9s        ) * coef));
      interest_vote_price_e9s       = Int.abs(Float.toInt(Float.fromInt(interest_vote_price_e9s      ) * coef));
      categorization_vote_price_e9s = Int.abs(Float.toInt(Float.fromInt(categorization_vote_price_e9s) * coef));
    };
  };

  public func build(price_register: Ref<PriceRegister>) : SubPrices {
    SubPrices(WRef.WRef(price_register));
  };

  public class SubPrices(_price_register: WRef<PriceRegister>) {

    public func updatePrices(base_price_params: BasePriceParameters, selection_params: SelectionParameters) {
      _price_register.set(computeSubPrices(base_price_params, selection_params));
    };

    public func getPrices() : PriceRegister {
      _price_register.get();
    };

  };

};
