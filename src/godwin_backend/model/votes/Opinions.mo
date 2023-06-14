import Types               "Types";
import Votes               "Votes";
import VotePolicy          "VotePolicy";
import Polarization        "representation/Polarization";
import Cursor              "representation/Cursor";

module {

  type VoteId              = Types.VoteId;
  type Cursor              = Types.Cursor;
  type Polarization        = Types.Polarization;
  type OpinionBallot       = Types.OpinionBallot;

  public type Register     = Votes.Register<Cursor, Polarization>;

  public func initRegister() : Register {
    Votes.initRegister<Cursor, Polarization>();
  };

  public type Opinions = Votes.Votes<Cursor, Polarization>;

  public func build(
    vote_register: Votes.Register<Cursor, Polarization>
  ) : Opinions {
    Votes.Votes<Cursor, Polarization>(
      vote_register,
      VotePolicy.VotePolicy<Cursor, Polarization>(
        #BALLOT_CHANGE_AUTHORIZED,
        Cursor.isValid,
        addOpinionBallot,
        removeOpinionBallot,
        Polarization.nil()
      ),
      null
    );
  };

  func addOpinionBallot(polarization: Polarization, ballot: OpinionBallot) : Polarization {
    Polarization.addCursor(polarization, ballot.answer);
  };

  func removeOpinionBallot(polarization: Polarization, ballot: OpinionBallot) : Polarization {
    Polarization.subCursor(polarization, ballot.answer);
  };

};