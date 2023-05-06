import VoteTypes           "votes/Types";
import QuestionTypes       "questions/Types";
import State               "State";
import Model               "Model";
import Categories          "Categories";
import Users               "Users";
import Facade              "Facade";
import StatusManager       "questions/StatusManager";
import Questions           "questions/Questions";
import QuestionQueries     "questions/QuestionQueries";
import Controller          "controller/Controller";
import Votes               "votes/Votes";
import VotesHistory        "votes/VotesHistory";
import Interests           "votes/Interests";
import Categorizations     "votes/Categorizations";
import Opinions            "votes/Opinions";
import Polarization        "votes/representation/Polarization";
import PolarizationMap     "votes/representation/PolarizationMap";
import SubaccountGenerator "token/SubaccountGenerator";
import PayInterface        "token/PayInterface";
import PayForNew           "token/PayForNew";

module {

  type Question        = QuestionTypes.Question;
  type Status          = QuestionTypes.Status;
  type Cursor          = VoteTypes.Cursor;
  type Polarization    = VoteTypes.Polarization;
  type CursorMap       = VoteTypes.CursorMap;
  type PolarizationMap = VoteTypes.PolarizationMap;
  type Facade          = Facade.Facade;
  type State           = State.State;

  public func build(state: State) : Facade {

    let master = state.master;
    
    let categories = Categories.build(state.categories);
    
    let questions = Questions.build(
      state.questions.register,
      state.questions.index,
      state.questions.character_limit
    );

    let status_manager = StatusManager.build(state.status.register);

    let queries = QuestionQueries.build(state.queries.register);

    let pay_interface = PayInterface.build(state.master.v);
    let pay_to_open_question = PayForNew.build(
      pay_interface,
      #OPEN_QUESTION,
      state.opened_questions.register,
      state.opened_questions.index
    );

    let interest_votes = Votes.Votes<Cursor, Polarization>(state.votes.interest, Polarization.nil());
    let interest_history = VotesHistory.build(state.votes.interest_history);
    
    let interests = Interests.build(
      interest_votes,
      interest_history,
      queries,
      pay_interface,
      pay_to_open_question
    );
    
    let opinion_votes = Votes.Votes<Cursor, Polarization>(state.votes.opinion, Polarization.nil());
    let opinion_history = VotesHistory.build(state.votes.opinion_history);
    
    let opinions = Opinions.build(
      opinion_votes,
      opinion_history,
    );
    
    let categorization_votes = Votes.Votes<CursorMap, PolarizationMap>(state.votes.categorization, PolarizationMap.nil(categories));
    let categorization_history = VotesHistory.build(state.votes.categorization_history);
    
    let categorizations = Categorizations.build(
      categories,
      categorization_votes,
      categorization_history,
      pay_interface
    );

    let users = Users.build(
      state.users.register,
      opinion_history,
      opinion_votes,
      categorization_history,
      categorization_votes,
      state.users.convictions_half_life,
      state.creation_date,
      categories);

    let model = Model.build(
      state.name,
      state.master,
      state.controller.model.last_pick_date,
      state.controller.model.params,
      categories,
      questions,
      status_manager,
      users,
      queries,
      interests,
      opinions,
      categorizations
    );

    let controller = Controller.build(model);

    let facade = Facade.Facade(controller);

    facade;
  };

};