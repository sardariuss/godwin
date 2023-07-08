import Types               "Types";
import Votes               "Votes";
import VotePolicy          "VotePolicy";
import VotersHistory       "VotersHistory";
import Polarization        "representation/Polarization";
import Cursor              "representation/Cursor";

module {

  type VoteId              = Types.VoteId;
  type Cursor              = Types.Cursor;
  type Polarization        = Types.Polarization;
  type OpinionBallot       = Types.OpinionBallot;
  type DecayParameters     = Types.DecayParameters;
  type VotersHistory       = VotersHistory.VotersHistory;

  public type Register     = Votes.Register<Cursor, Polarization>;

  public func initRegister() : Register {
    Votes.initRegister<Cursor, Polarization>();
  };

  public type Opinions = Votes.Votes<Cursor, Polarization>;

  public func build(
    vote_register: Votes.Register<Cursor, Polarization>,
    voters_history: VotersHistory,
    decay_params: DecayParameters
  ) : Opinions {
    Votes.Votes<Cursor, Polarization>(
      vote_register,
      voters_history,
      VotePolicy.VotePolicy<Cursor, Polarization>(
        #BALLOT_CHANGE_AUTHORIZED,
        Cursor.isValid,
        addOpinionBallot,
        removeOpinionBallot,
        Polarization.nil()
      ),
      null,
      decay_params,
      #REVEAL_BALLOT_ALWAYS
    );
  };

  func addOpinionBallot(polarization: Polarization, ballot: OpinionBallot) : Polarization {
    Polarization.addCursor(polarization, ballot.answer);
  };

  func removeOpinionBallot(polarization: Polarization, ballot: OpinionBallot) : Polarization {
    Polarization.subCursor(polarization, ballot.answer);
  };

};