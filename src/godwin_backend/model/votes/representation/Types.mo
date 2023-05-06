import Trie "mo:base/Trie";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  
  // @todo: duplicate definition in root Types
  public type Category = Text;

  // Cursor used for voting, shall be between -1 and 1, where usually:
  //  -1 means voting totally for A
  //   0 means voting totally neutral
  //   1 means voting totally for B
  //  in between values mean voting for A or B with more or less reserve.
  //
  // Example: cursor of 0.5, which means voting for B with some reserve.
  // -1                            0                             1
  // [-----------------------------|--------------()-------------]
  //
  public type Cursor = Float;

  // Polarization, used mainly to store the result of a vote.
  // Polarizations are never normalized in the backend in order to not
  // loosing its magnitude (which can represent different things, usually
  // how many people voted).
  //
  // Example: { left = 13; center = 8; right = 36; }
  // [$$$$$$$$$$$$$|@@@@@@@@|&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&]
  //     left        center                 right 
  // 
  public type Polarization = {
    left: Float;
    center: Float;
    right: Float;
  };

  // Mapping of <key=Category, value=Cursor>, used to vote to determine a question political affinity
  public type CursorMap = Trie<Category, Cursor>;
  
  // Mapping of <key=Category, value=Polarization>, used to represent a question political affinity
  public type PolarizationMap = Trie<Category, Polarization>;
}