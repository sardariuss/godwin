import Types "Types";

import WSet "../utils/wrappers/WSet";

module {

  type Category = Types.Category;
  type WSet<K> = WSet.WSet<K>;

  public type Categories = WSet<Category>;

};